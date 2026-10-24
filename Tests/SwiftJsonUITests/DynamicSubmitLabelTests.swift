//
//  DynamicSubmitLabelTests.swift
//  SwiftJsonUITests
//
//  The return key of a TextField / TextView drawn by Dynamic is the one sjui
//  codegen gives: `returnKeyType` declared → that submit label; not declared
//  → no `.submitLabel` at all (the system's key). Dynamic put `.done` on an
//  id'd TextField that declared nothing (FocusableTextField's default), left
//  a declared label off an id'd secure field, and never read `returnKeyType`
//  on TextView (ticket 2026-10-24-sjui-dynamic-return-key-defaults-to-done).
//
//  The arm reads the drawn UIKit control's returnKeyType, so a label that is
//  resolved but not applied (or applied and then overridden by an inner
//  default) is seen as what the keyboard shows.
//

import XCTest
import SwiftUI
import UIKit
@testable import SwiftJsonUI

#if DEBUG
final class DynamicSubmitLabelTests: XCTestCase {

    private final class Model: ObservableObject {
        @Published var text = ""
    }

    private struct Host: View {
        @ObservedObject var model: Model
        let build: ([String: Any]) -> AnyView
        var body: some View {
            build(["t": $model.text as Any])
        }
    }

    private func allSubviews(_ view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap { allSubviews($0) }
    }

    /// Named so a failure prints the keys, not "[UIReturnKeyType]".
    private func name(_ k: UIReturnKeyType) -> String {
        switch k {
        case .default: return "default"
        case .go: return "go"
        case .google: return "google"
        case .join: return "join"
        case .next: return "next"
        case .route: return "route"
        case .search: return "search"
        case .send: return "send"
        case .yahoo: return "yahoo"
        case .done: return "done"
        case .emergencyCall: return "emergencyCall"
        case .continue: return "continue"
        @unknown default: return "raw\(k.rawValue)"
        }
    }

    /// The returnKeyType of every UITextField / UITextView drawn by `json`.
    private func drawnReturnKeys(
        _ json: [String: Any],
        convert: @escaping (DynamicComponent, [String: Any]) -> AnyView
    ) throws -> [String] {
        let c = try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: json))
        let host = UIHostingController(rootView: Host(model: Model(), build: { convert(c, $0) }))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        return allSubviews(host.view).compactMap { v in
            if let f = v as? UITextField { return name(f.returnKeyType) }
            if let t = v as? UITextView { return name(t.returnKeyType) }
            return nil
        }
    }

    private func field(_ extra: [String: Any]) -> [String: Any] {
        ["type": "TextField", "text": "@{t}", "hint": "h"].merging(extra) { $1 }
    }

    private func view(_ extra: [String: Any]) -> [String: Any] {
        ["type": "TextView", "text": "@{t}"].merging(extra) { $1 }
    }

    // MARK: - TextField

    /// The reported shape: an id'd field (FocusableTextField) that declares
    /// no returnKeyType showed ✓ (.done); codegen emits no .submitLabel.
    func testIdTextFieldWithoutReturnKeyTypeKeepsTheSystemKey() throws {
        XCTAssertEqual(try drawnReturnKeys(field(["id": "f"]), convert: TextFieldConverter.convert), ["default"])
    }

    func testIdTextFieldTakesTheDeclaredReturnKeyType() throws {
        XCTAssertEqual(
            try drawnReturnKeys(field(["id": "f", "returnKeyType": "Search"]), convert: TextFieldConverter.convert),
            ["search"]
        )
    }

    /// Codegen puts .submitLabel on the SecureField too; FocusableTextField's
    /// secure branch had none, so the declared key was dropped.
    func testIdSecureTextFieldTakesTheDeclaredReturnKeyType() throws {
        XCTAssertEqual(
            try drawnReturnKeys(
                field(["id": "f", "input": "password", "returnKeyType": "Send"]),
                convert: TextFieldConverter.convert
            ),
            ["send"]
        )
    }

    func testIdSecureTextFieldWithoutReturnKeyTypeKeepsTheSystemKey() throws {
        XCTAssertEqual(
            try drawnReturnKeys(field(["id": "f", "input": "password"]), convert: TextFieldConverter.convert),
            ["default"]
        )
    }

    /// Control: the id-less path (applyAllModifiers) already matched codegen
    /// both ways.
    func testIdlessTextFieldMatchesCodegenBothWays() throws {
        XCTAssertEqual(try drawnReturnKeys(field([:]), convert: TextFieldConverter.convert), ["default"])
        XCTAssertEqual(
            try drawnReturnKeys(field(["returnKeyType": "Go"]), convert: TextFieldConverter.convert),
            ["go"]
        )
    }

    // MARK: - TextView

    func testTextViewWithoutReturnKeyTypeKeepsTheSystemKey() throws {
        XCTAssertEqual(try drawnReturnKeys(view(["id": "v"]), convert: TextViewConverter.convert), ["default"])
    }

    /// Codegen emits .submitLabel on the TextEditor (textview_converter.rb);
    /// Dynamic did not read returnKeyType at all.
    func testTextViewTakesTheDeclaredReturnKeyType() throws {
        XCTAssertEqual(
            try drawnReturnKeys(view(["id": "v", "returnKeyType": "Send"]), convert: TextViewConverter.convert),
            ["send"]
        )
    }

    /// TextView's vocabulary is codegen's TextView table, not TextField's:
    /// Continue / Join / Route are not in it and fall to `.return`.
    func testTextViewMapsWordsOutsideItsTableToReturn() throws {
        XCTAssertEqual(
            try drawnReturnKeys(view(["id": "v", "returnKeyType": "Join"]), convert: TextViewConverter.convert),
            ["default"]
        )
    }
}
#endif
