//
//  OnTextChangeIsTheUsersStreamTests.swift
//  SwiftJsonUITests
//
//  A TextField / TextView's onTextChange fires for the user's edit and not
//  for a change of the value made from elsewhere — a view model's updateData,
//  the test runner's initialState. KotlinJsonUI and web already had it so;
//  iOS Dynamic observed the value with `.onChange(of:)` and fired for every
//  change (ticket sjui-ontextchange-fires-on-programmatic-data-change).
//
//  Two kinds of arm:
//  - drawn: the converter's view on screen, the value changed from outside,
//    the handler NOT called — with the drawn text printed next to it, so a
//    view that never saw the change cannot pass as "did not fire";
//  - the binding the control writes through: setting it calls the handler
//    with the viewId and the value, once per real change.
//

import XCTest
import SwiftUI
import UIKit
@testable import SwiftJsonUI

#if DEBUG
final class OnTextChangeIsTheUsersStreamTests: XCTestCase {

    private final class Model: ObservableObject {
        @Published var text = ""
    }

    /// Renders `convert` over a data dict built from the model on every pass.
    private struct Host: View {
        @ObservedObject var model: Model
        let bound: Bool
        let build: ([String: Any]) -> AnyView
        let handler: (String, String) -> Void
        var body: some View {
            build([
                // A two-way binding in the data, or a plain value (the
                // DynamicLocalState path, where the VM's word replaces the
                // user's).
                "t": bound ? ($model.text as Any) : (model.text as Any),
                "h": handler,
            ])
        }
    }

    private func component(_ json: [String: Any]) throws -> DynamicComponent {
        try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: json))
    }

    private func spin(_ host: UIViewController) {
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
    }

    /// Lets the main queue run what the setter deferred.
    private func drain() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }

    private func allSubviews(_ view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap { allSubviews($0) }
    }

    /// The text the drawn control shows: UITextField for TextField, UITextView
    /// for TextView.
    private func drawnText(_ root: UIView) -> [String] {
        allSubviews(root).compactMap { v in
            if let f = v as? UITextField { return f.text ?? "" }
            if let t = v as? UITextView { return t.text ?? "" }
            return nil
        }
    }

    private func assertAProgrammaticChangeDoesNotFire(
        _ json: [String: Any],
        bound: Bool,
        convert: @escaping (DynamicComponent, [String: Any]) -> AnyView,
        file: StaticString = #filePath, line: UInt = #line
    ) throws {
        let c = try component(json)
        let model = Model()
        model.text = "seed"
        var calls: [String] = []
        let host = UIHostingController(rootView: Host(
            model: model, bound: bound,
            build: { convert(c, $0) },
            handler: { id, value in calls.append("\(id)=\(value)") }
        ))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        spin(host)
        XCTAssertEqual(drawnText(host.view), ["seed"], "control: the seed is drawn", file: file, line: line)

        // The view model's updateData / the runner's initialState.
        model.text = "from the view model"
        spin(host)
        model.text = "again"
        spin(host)

        // The view saw the change — otherwise "not called" below proves nothing.
        XCTAssertEqual(drawnText(host.view), ["again"], "control: the new value is drawn", file: file, line: line)
        XCTAssertEqual(calls, [], "onTextChange fired for a change that was not the user's", file: file, line: line)
    }

    // MARK: - drawn: a programmatic change does not fire

    func testTextFieldWithAnIdDoesNotFireForTheViewModelsChange() throws {
        for bound in [true, false] {
            try assertAProgrammaticChangeDoesNotFire(
                ["type": "TextField", "id": "email_field", "text": "@{t}", "onTextChange": "@{h}"],
                bound: bound, convert: TextFieldConverter.convert
            )
        }
    }

    func testTextFieldWithoutAnIdDoesNotFireForTheViewModelsChange() throws {
        for bound in [true, false] {
            try assertAProgrammaticChangeDoesNotFire(
                ["type": "TextField", "text": "@{t}", "onTextChange": "h", "clearButtonMode": "always"],
                bound: bound, convert: TextFieldConverter.convert
            )
        }
    }

    func testTextViewDoesNotFireForTheViewModelsChange() throws {
        for bound in [true, false] {
            try assertAProgrammaticChangeDoesNotFire(
                ["type": "TextView", "id": "memo", "text": "@{t}", "onTextChange": "@{h}"],
                bound: bound, convert: TextViewConverter.convert
            )
        }
    }

    // MARK: - drawn: the user's edit fires (TextView)
    //
    // TextView only. SwiftUI's TextField does not take a programmatic edit in
    // this test host — measured on iOS 26.2 (Xcode 26.3): after
    // becomeFirstResponder + insertText the UITextField shows the new text,
    // its coordinator is the target and the delegate, and neither
    // sendActions(.editingChanged), textDidChangeNotification nor the
    // delegate's shouldChangeCharactersIn writes the binding. That holds with
    // or without this fix, so an arm here could not tell them apart; the
    // TextField's typing is covered by the consumer's XCUITest. The TextField
    // gets the same UserEditBinding (the arms below pin it).

    /// A TextView drawn over `model`, focused, with `handler` as onTextChange.
    private func drawFocusedTextView(
        _ model: Model,
        handler: @escaping (String, String) -> Void,
        file: StaticString = #filePath, line: UInt = #line
    ) throws -> (UIWindow, UIHostingController<Host>, UITextView) {
        let c = try component(["type": "TextView", "id": "memo", "text": "@{t}", "onTextChange": "@{h}"])
        let host = UIHostingController(rootView: Host(
            model: model, bound: true, build: { TextViewConverter.convert(component: c, data: $0) }, handler: handler
        ))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = host
        window.makeKeyAndVisible()
        spin(host)
        let input = try XCTUnwrap(
            allSubviews(host.view).first { $0 is UITextView } as? UITextView, "no UITextView drawn", file: file, line: line
        )
        XCTAssertTrue(input.becomeFirstResponder(), "control: the editor took focus", file: file, line: line)
        spin(host)
        return (window, host, input)
    }

    /// Typing calls the handler once with the new text, and the edit reaches
    /// the view model — so the "does not fire" arms above cannot be passed by
    /// a converter that stopped calling it at all.
    func testTypingIntoATextViewFires() throws {
        let model = Model()
        model.text = "seed"
        var calls: [String] = []
        let (window, host, input) = try drawFocusedTextView(model) { id, v in calls.append("\(id)=\(v)") }
        defer { window.isHidden = true }
        input.insertText("!")
        spin(host)
        XCTAssertEqual(calls, ["memo=seed!"])
        XCTAssertEqual(model.text, "seed!")
    }

    /// Japanese conversion (marked text). Measured, not assumed: the editor
    /// writes the binding while the text is still marked, so onTextChange
    /// fires for each marked step and for the commit when its text differs —
    /// the same as Android, where the composing text is in TextFieldState.text.
    /// Writing the binding is the editor's doing, not this library's; the
    /// observer this replaced fired on exactly the same writes.
    func testMarkedTextFiresAsTheEditorWritesTheBinding() throws {
        let model = Model()
        var calls: [String] = []
        let (window, host, input) = try drawFocusedTextView(model) { _, v in calls.append(v) }
        defer { window.isHidden = true }
        input.setMarkedText("か", selectedRange: NSRange(location: 1, length: 0))
        spin(host)
        input.setMarkedText("かん", selectedRange: NSRange(location: 2, length: 0))
        spin(host)
        input.setMarkedText("漢", selectedRange: NSRange(location: 1, length: 0))
        spin(host)
        input.unmarkText()
        spin(host)
        print("MEASURED marked-text calls=\(calls) model=\(model.text) drawn=\(input.text ?? "")")
        XCTAssertEqual(input.text, "漢", "control: the conversion committed")
        XCTAssertEqual(model.text, "漢")
        XCTAssertEqual(calls, ["か", "かん", "漢"], "marked steps fire; the commit of the same text does not fire again")
    }

    /// A handler that narrows the value and writes it back to the same
    /// property (digits only, at most 6). It writes the data, not the
    /// control's binding, so it does not re-enter the setter: one call per
    /// edit, no loop, and the editor shows the narrowed value. (The observer
    /// this replaced fired again for the write-back: measured
    /// ["12a", "12", "1234567", "123456"].)
    func testAHandlerThatNarrowsTheValueWinsAndDoesNotLoop() throws {
        let model = Model()
        model.text = "12"
        var calls: [String] = []
        let (window, host, input) = try drawFocusedTextView(model) { _, v in
            calls.append(v)
            model.text = String(v.filter(\.isNumber).prefix(6))
        }
        defer { window.isHidden = true }
        input.insertText("a")
        spin(host)
        print("MEASURED narrow after 'a': calls=\(calls) model=\(model.text) drawn=\(input.text ?? "")")
        XCTAssertEqual(model.text, "12")
        XCTAssertEqual(input.text, "12", "the editor shows the value the handler wrote back")
        input.insertText("34567")
        spin(host)
        print("MEASURED narrow after '34567': calls=\(calls) model=\(model.text) drawn=\(input.text ?? "")")
        XCTAssertEqual(model.text, "123456")
        XCTAssertEqual(input.text, "123456")
        XCTAssertEqual(calls, ["12a", "1234567"], "one call per edit; the write-back did not fire again")
    }

    // MARK: - the binding the control writes through: the user's edit fires

    func testSettingTheControlsBindingCallsTheHandlerWithTheViewIdAndTheValue() throws {
        for (type, handler) in [("TextField", "@{h}"), ("TextField", "h"), ("TextView", "@{h}")] {
            var storage = "seed"
            var calls: [String] = []
            let source = SwiftUI.Binding<String>(get: { storage }, set: { storage = $0 })
            let c = try component(["type": type, "id": "f", "text": "@{t}", "onTextChange": handler])
            let data: [String: Any] = ["t": source, "h": { (id: String, v: String) in calls.append("\(id)=\(v)") }]
            let control = UserEditBinding.text(source, component: c, id: LayoutPath.viewId(of: c), data: data)

            control.wrappedValue = "a"
            // Stored at once; the handler runs on the main queue's next turn.
            XCTAssertEqual(storage, "a")
            XCTAssertEqual(calls, [], "\(type): not called inside the setter")
            drain()
            control.wrappedValue = "a" // no change: not an edit
            storage = "outside"        // not through the control: not an edit
            XCTAssertEqual(control.wrappedValue, "outside", "the control reads the storage")
            control.wrappedValue = ""  // the clear button writes "" through the same binding
            drain()

            XCTAssertEqual(calls, ["f=a", "f="], "\(type) \(handler)")
            XCTAssertEqual(storage, "", "\(type): the edit reached the storage")
        }
    }

    func testNoHandlerLeavesTheBindingAWritableBinding() throws {
        var storage = ""
        let source = SwiftUI.Binding<String>(get: { storage }, set: { storage = $0 })
        let c = try component(["type": "TextField", "text": "@{t}"])
        let control = UserEditBinding.text(source, component: c, id: "x", data: [:])
        control.wrappedValue = "typed"
        XCTAssertEqual(storage, "typed")
    }

    /// A handler that takes only the value (`(String) -> Void`) is called too —
    /// DynamicEventHelper.callWithValue's second shape.
    func testAValueOnlyHandlerIsCalled() throws {
        var got: [String] = []
        var storage = ""
        let source = SwiftUI.Binding<String>(get: { storage }, set: { storage = $0 })
        let c = try component(["type": "TextField", "text": "@{t}", "onTextChange": "@{h}"])
        let data: [String: Any] = ["h": { (v: String) in got.append(v) }]
        UserEditBinding.text(source, component: c, id: "x", data: data).wrappedValue = "v"
        drain()
        XCTAssertEqual(got, ["v"])
    }
}
#endif // DEBUG
