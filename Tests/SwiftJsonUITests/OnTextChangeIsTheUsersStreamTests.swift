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

    /// Spins until `condition` holds or `timeout` passes, and returns the
    /// time it took. A fixed spin was not enough on a slow runner: on the
    /// Xcode 16.4 / iOS 18 CI leg the editor wrote "12a" into the binding
    /// late, the test's next insertText came before the deferred call ran,
    /// and the two edits coalesced into one call (run 39010897386: calls
    /// ["12a34567"] where ["12a", "1234567"] was asserted) — the semantics
    /// working as designed, the test not waiting for the first edit. Waiting
    /// for the outcome keeps the arm a discriminator: a deferred call that
    /// the guard dropped wrongly never arrives, and the wait ends red.
    @discardableResult
    private func settle(
        _ host: UIViewController, timeout: TimeInterval = 10, until condition: () -> Bool
    ) -> TimeInterval {
        let start = Date()
        while !condition() && Date().timeIntervalSince(start) < timeout {
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        return Date().timeIntervalSince(start)
    }

    /// Runs the main queue until everything queued so far has run: a marker
    /// queued behind it, waited for, three times (a block may queue
    /// another). Not a fixed sleep, so a slow runner (the Xcode 16.4 leg)
    /// cannot read "not run yet" as "not called".
    private func drain() {
        for _ in 0..<3 {
            var done = false
            DispatchQueue.main.async { done = true }
            let start = Date()
            while !done && Date().timeIntervalSince(start) < 10 {
                RunLoop.main.run(until: Date().addingTimeInterval(0.01))
            }
            XCTAssertTrue(done, "the main queue did not empty in 10 s")
        }
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
        settle(host) { !calls.isEmpty }
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
        // Each step waits for its own call before the next, as a person's
        // keystrokes are far apart; without that, steps coalesce by design.
        input.setMarkedText("か", selectedRange: NSRange(location: 1, length: 0))
        let t1 = settle(host) { calls.count == 1 }
        input.setMarkedText("かん", selectedRange: NSRange(location: 2, length: 0))
        let t2 = settle(host) { calls.count == 2 }
        input.setMarkedText("漢", selectedRange: NSRange(location: 1, length: 0))
        let t3 = settle(host) { calls.count == 3 }
        input.unmarkText()
        spin(host)
        print("MEASURED marked-text calls=\(calls) model=\(model.text) drawn=\(input.text ?? "") waited=\([t1, t2, t3])")
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
        let t1 = settle(host) { calls.count == 1 && input.text == "12" }
        spin(host) // and nothing more arrives: the write-back does not fire
        print("MEASURED narrow after 'a': calls=\(calls) model=\(model.text) drawn=\(input.text ?? "") waited=\(t1)")
        XCTAssertEqual(calls, ["12a"], "the edit's own call arrived, once")
        XCTAssertEqual(model.text, "12")
        XCTAssertEqual(input.text, "12", "the editor shows the value the handler wrote back")
        input.insertText("34567")
        let t2 = settle(host) { calls.count == 2 && input.text == "123456" }
        spin(host)
        print("MEASURED narrow after '34567': calls=\(calls) model=\(model.text) drawn=\(input.text ?? "") waited=\(t2)")
        XCTAssertEqual(model.text, "123456")
        XCTAssertEqual(input.text, "123456")
        XCTAssertEqual(calls, ["12a", "1234567"], "one call per edit; the write-back did not fire again")
    }

    /// Dynamic, drawn: the two bursts typed into a TextView, with a handler
    /// that records only (a write-back would make the value move again).
    func testDrawnBurstsCallOnceOrNotAtAll() throws {
        let model = Model()
        model.text = "x"
        var calls: [String] = []
        let (window, host, input) = try drawFocusedTextView(model) { _, v in calls.append(v) }
        defer { window.isHidden = true }
        try assertDrawnBursts(input, host: host, calls: { calls.count })
        print("MEASURED drawn bursts: calls=\(calls) model=\(model.text)")
        XCTAssertEqual(calls, ["xa"])
    }

    // MARK: - the codegen shape, drawn

    /// What sjui codegen emits for a TextView over `@{noteText}` with
    /// `onTextChange: @{onNoteTextChange}`, copied verbatim from
    /// jsonui-cli's TextViewConverter output (fix/ontextchange-coalesce-by-
    /// generation): the generation lives in the main thread's dictionary,
    /// keyed by the view's type and the field, not in the view. Here
    /// so the generated `$data.x` binding — a
    /// `@SwiftUI.Binding var data` in the generated view — runs on every
    /// simulator leg this suite runs on: the guard reads
    /// `$data.noteText.wrappedValue` when the deferred call runs, and has
    /// to see the edit's own write there. A transcription, not the
    /// generator: the jsonui-cli spec pins the generator's text.
    private struct CodegenData {
        var noteText = "12"
        var onNoteTextChange: ((String, String) -> Void)?
    }

    private final class CodegenModel: ObservableObject {
        @Published var data = CodegenData()
    }

    private struct CodegenShape: View {
        @SwiftUI.Binding var data: CodegenData
        var body: some View {
            TextEditor(
                text: SwiftUI.Binding(get: { $data.noteText.wrappedValue }, set: { newValue in let key = "sjui.userEdit.\(Self.self).memo"; let edit = (Thread.main.threadDictionary[key] as? NSMutableDictionary) ?? NSMutableDictionary(); Thread.main.threadDictionary[key] = edit; let before = $data.noteText.wrappedValue; let changed = before != newValue; $data.noteText.wrappedValue = newValue; if changed { if edit["start"] == nil { edit["start"] = before }; let number = (edit["number"] as? Int ?? 0) + 1; edit["number"] = number; DispatchQueue.main.async { guard edit["number"] as? Int == number else { return }; let start = edit["start"] as? String; edit["start"] = nil; guard $data.noteText.wrappedValue == newValue, newValue != start else { return }; data.onNoteTextChange?("memo", newValue) } } })
            )
        }
    }

    private struct CodegenHost: View {
        @ObservedObject var model: CodegenModel
        var body: some View { CodegenShape(data: $model.data) }
    }

    /// The codegen shape with a narrowing write-back handler: each edit's
    /// own call arrives (once), the editor follows the narrowed value, and a
    /// later programmatic change does not call it.
    func testTheCodegenShapeCallsOncePerEditAndFollowsTheWriteBack() throws {
        let model = CodegenModel()
        var calls: [String] = []
        model.data.onNoteTextChange = { [unowned model] id, v in
            calls.append("\(id)=\(v)")
            model.data.noteText = String(v.filter(\.isNumber).prefix(6))
        }
        let host = UIHostingController(rootView: CodegenHost(model: model))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        spin(host)
        let input = try XCTUnwrap(allSubviews(host.view).first { $0 is UITextView } as? UITextView)
        XCTAssertTrue(input.becomeFirstResponder(), "control: the editor took focus")
        spin(host)
        input.selectedRange = NSRange(location: (input.text ?? "").utf16.count, length: 0)

        input.insertText("a")
        let t1 = settle(host) { calls.count == 1 && input.text == "12" }
        spin(host)
        input.insertText("34567")
        let t2 = settle(host) { calls.count == 2 && input.text == "123456" }
        spin(host)
        print("MEASURED codegen shape: calls=\(calls) data=\(model.data.noteText) drawn=\(input.text ?? "") waited=\([t1, t2])")
        XCTAssertEqual(calls, ["memo=12a", "memo=1234567"], "one call per edit, with the edit's value")
        XCTAssertEqual(model.data.noteText, "123456")
        XCTAssertEqual(input.text, "123456", "the editor follows the write-back")

        model.data.noteText = "from the view model"
        spin(host)
        drain()
        XCTAssertEqual(calls.count, 2, "a programmatic change does not call it")

        // The two bursts of ticket sjui-ontextchange-deferred-guard-can-
        // double-call-or-call-without-net-change, typed in one turn each.
        try assertDrawnBursts(input, host: host, calls: { calls.count })
    }

    /// Types the two bursts into a drawn editor that holds `X` at its end —
    /// "y" then delete (back where it began: no call), then "a", delete,
    /// "a" (one call) — and checks the call count after each.
    private func assertDrawnBursts(
        _ input: UITextView, host: UIViewController, calls: () -> Int,
        file: StaticString = #filePath, line: UInt = #line
    ) throws {
        let before = calls()
        input.selectedRange = NSRange(location: (input.text ?? "").utf16.count, length: 0)
        let start = input.text ?? ""
        input.insertText("y")
        input.deleteBackward()
        spin(host)
        drain()
        XCTAssertEqual(input.text, start, "control: the editor is back where it began", file: file, line: line)
        XCTAssertEqual(calls(), before, "a burst that ends where it began calls nothing", file: file, line: line)

        input.insertText("a")
        input.deleteBackward()
        input.insertText("a")
        settle(host) { calls() == before + 1 }
        spin(host)
        drain()
        XCTAssertEqual(calls(), before + 1, "a value that comes back within a burst is called once", file: file, line: line)
    }

    // MARK: - the binding the control writes through: the user's edit fires

    func testSettingTheControlsBindingCallsTheHandlerWithTheViewIdAndTheValue() throws {
        for (type, handler) in [("TextField", "@{h}"), ("TextField", "h"), ("TextView", "@{h}")] {
            var storage = "seed"
            var calls: [String] = []
            let source = SwiftUI.Binding<String>(get: { storage }, set: { storage = $0 })
            let c = try component(["type": type, "id": "f", "text": "@{t}", "onTextChange": handler])
            let data: [String: Any] = ["t": source, "h": { (id: String, v: String) in calls.append("\(id)=\(v)") }]
            let control = UserEditBinding.text(source, generation: UserEditGeneration(), component: c, id: LayoutPath.viewId(of: c), data: data)

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

    // MARK: - a deferred call a later edit overtook is dropped
    //
    // Ticket sjui-ontextchange-deferred-handler-replays-stale-value: 10.30.1
    // handed each deferred call its own edit's value, and a handler that
    // writes it back (`data.x = v`, the common shape) replayed intermediate
    // values over later edits.

    /// A field over storage, with the handler shape most screens use:
    /// store what it is handed.
    private final class Field {
        var storage = "string"
        var calls: [String] = []
        var staleWrites = 0
        var control: SwiftUI.Binding<String>!
        let generation = UserEditGeneration()
        init(_ seed: String = "string") throws {
            storage = seed
            let source = SwiftUI.Binding<String>(get: { self.storage }, set: { self.storage = $0 })
            let c = try XCTUnwrap(JSONLayoutLoader.decodeComponent(
                from: ["type": "TextView", "id": "note", "text": "@{t}", "onTextChange": "@{h}"]
            ))
            let handler: (String, String) -> Void = { [unowned self] _, v in
                self.calls.append(v)
                if v != self.storage { self.staleWrites += 1 }
                self.storage = v
            }
            control = UserEditBinding.text(source, generation: generation, component: c, id: "note", data: ["t": source, "h": handler])
        }
        /// A delete key, as the field applies it: from what the field holds.
        func delete() { control.wrappedValue = String(control.wrappedValue.dropLast()) }
    }

    /// Six deletes in one turn (the runner's `clear`): one call, with the
    /// last value; the value stays where the edits left it.
    func testABurstOfEditsIsOneCallWithTheLatestValue() throws {
        let field = try Field()
        for _ in 0..<6 { field.delete() }
        drain()
        XCTAssertEqual(field.storage, "")
        XCTAssertEqual(field.calls, [""], "intermediate values coalesce")
        XCTAssertEqual(field.staleWrites, 0)
    }

    /// A key event landing between two queued calls — the shape that lost
    /// edits on a consumer (queue: A "strin", key, B "stri"). Three deletes
    /// leave "str"; replaying A's "strin" made the next delete start from it
    /// and left "stri".
    func testAKeyBetweenTwoQueuedCallsIsNotUndone() throws {
        let field = try Field()
        field.delete()
        DispatchQueue.main.async { field.delete() }
        field.delete()
        drain()
        XCTAssertEqual(field.storage, "str", "no delete lost")
        XCTAssertEqual(field.calls, ["str"])
        XCTAssertEqual(field.staleWrites, 0, "no handler wrote back a value the field had left")
    }

    /// "x" -> "xy" -> "x" in one turn: the burst ends where it began, so
    /// there is no call (Android compares with the data and does not call;
    /// 10.30.2 called with "x").
    func testABurstThatEndsWhereItBeganCallsNothing() throws {
        let field = try Field("x")
        field.control.wrappedValue = "xy"
        field.control.wrappedValue = "x"
        drain()
        XCTAssertEqual(field.storage, "x")
        XCTAssertEqual(field.calls, [], "no net change, no call")
    }

    /// "" -> "a" -> "" -> "a" in one turn: one call. 10.30.2 called twice —
    /// the first call's "a" matched the current value by chance.
    func testAValueThatComesBackInABurstIsCalledOnce() throws {
        let field = try Field("")
        field.control.wrappedValue = "a"
        field.control.wrappedValue = ""
        field.control.wrappedValue = "a"
        drain()
        XCTAssertEqual(field.storage, "a")
        XCTAssertEqual(field.calls, ["a"], "only the last edit of the burst calls")
    }

    /// Edits in separate turns are separate bursts: each calls; and a burst
    /// after a call starts from the value that call left.
    func testEditsInSeparateTurnsEachCall() throws {
        let field = try Field("")
        field.control.wrappedValue = "a"
        drain()
        field.control.wrappedValue = "ab"
        drain()
        field.control.wrappedValue = "abc"
        field.control.wrappedValue = "ab"
        drain()
        XCTAssertEqual(field.calls, ["a", "ab"], "the third burst ended where it began")
    }

    /// A programmatic change while a call is queued: the call is stale, and
    /// the view model's value stands.
    func testAProgrammaticChangeWhileACallIsQueuedStands() throws {
        let field = try Field()
        field.delete()
        field.storage = "from the view model"
        drain()
        XCTAssertEqual(field.storage, "from the view model")
        XCTAssertEqual(field.calls, [])
    }

    /// Drawn: clear (six deleteBackward in one turn) then type, with the
    /// write-back handler — what the consumer's UI test does.
    func testClearThenTypeIntoADrawnTextViewKeepsTheTypedText() throws {
        let model = Model()
        model.text = "string"
        var calls: [String] = []
        let (window, host, input) = try drawFocusedTextView(model) { _, v in
            calls.append(v)
            model.text = v
        }
        defer { window.isHidden = true }
        input.selectedRange = NSRange(location: (input.text ?? "").utf16.count, length: 0)
        for _ in 0..<6 { input.deleteBackward() }
        input.insertText("UITEST NOTE")
        settle(host) { calls.last == "UITEST NOTE" }
        spin(host)
        XCTAssertEqual(model.text, "UITEST NOTE")
        XCTAssertEqual(input.text, "UITEST NOTE")
        XCTAssertEqual(calls.last, "UITEST NOTE")
    }

    func testNoHandlerLeavesTheBindingAWritableBinding() throws {
        var storage = ""
        let source = SwiftUI.Binding<String>(get: { storage }, set: { storage = $0 })
        let c = try component(["type": "TextField", "text": "@{t}"])
        let control = UserEditBinding.text(source, generation: UserEditGeneration(), component: c, id: "x", data: [:])
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
        UserEditBinding.text(source, generation: UserEditGeneration(), component: c, id: "x", data: data).wrappedValue = "v"
        drain()
        XCTAssertEqual(got, ["v"])
    }
}
#endif // DEBUG
