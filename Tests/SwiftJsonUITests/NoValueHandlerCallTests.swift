//
//  NoValueHandlerCallTests.swift
//  SwiftJsonUITests
//
//  A handler that takes no value — a tap, a control's or a Button's onClick,
//  a long press, onAppear / onDisappear, a Web's onLoadFailed — is called as
//  the closure the data holds asks (4f's ruling on
//  control-onclick-is-called-differently-on-every-path, 1.9.0): `(String)`
//  with the viewId (the id, else the drawn type and the position), `()` with
//  nothing. Every one of them went through `call`, which calls `() -> Void`
//  only. Here through a control's onClick (operationClick, a closure the
//  runtime hands the control); every port, on both iOS paths, in
//  ConformanceHost TapArityProbeUITests.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class NoValueHandlerCallTests: XCTestCase {

    private var calls: [String] = []

    private func data() -> [String: Any] {
        [
            "named": { (id: String) -> Void in self.calls.append("named(\(id))") },
            "bare": { () -> Void in self.calls.append("bare()") },
            "valued": { (value: Int) -> Void in self.calls.append("valued(\(value))") },
        ]
    }

    /// The second node of a layout the loader decoded (stamped): a Label
    /// first, then the Switch.
    private func switchNode(_ extra: String) throws -> DynamicComponent {
        let tree: [String: Any] = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(
            #"{"type":"View","child":[{"type":"Label","text":"a"},{"type":"Switch"\#(extra)}]}"#.utf8)) as? [String: Any])
        let root = try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: tree))
        return try XCTUnwrap(root.childComponents?.last)
    }

    private func click(_ component: DynamicComponent) -> [String] {
        calls = []
        DynamicEventHelper.operationClick(component, data: data())?()
        return calls
    }

    func testAStringHandlerIsHandedTheViewId() throws {
        XCTAssertEqual(click(try switchNode(#","onClick":"@{named}""#)), ["named(switch_0_1)"])
        XCTAssertEqual(click(try switchNode(#","id":"mine","onClick":"@{named}""#)), ["named(mine)"])
    }

    func testABareHandlerIsHandedNothing() throws {
        XCTAssertEqual(click(try switchNode(#","onClick":"@{bare}""#)), ["bare()"])
    }

    func testEveryHandlerOfTheArraySpellingInOrder() throws {
        XCTAssertEqual(click(try switchNode(#","onclick":["bare","named"]"#)), ["bare()", "named(switch_0_1)"])
    }

    func testAHandlerTakingAValueIsNotCalled() throws {
        XCTAssertEqual(click(try switchNode(#","onClick":"@{valued}""#)), [])
    }
}
#endif
