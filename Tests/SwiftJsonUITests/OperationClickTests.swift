//
//  OperationClickTests.swift
//  SwiftJsonUITests
//
//  A control's declared onClick is called once, from the control's own
//  operation, after its own update — never from a plain tap around it; a
//  TextField / TextView does not call it (ticket
//  control-onclick-is-called-differently-on-every-path). The converters call
//  `DynamicEventHelper.operationClick` from the operation, through
//  `calling(_:after:)` where the operation is a binding's write; `applyOnClick`
//  attaches nothing to these types.
//
//  The operation itself is measured end to end by ConformanceHost
//  OnClickProbeUITests (opt-in); these pin the pieces it is made of.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class OperationClickTests: XCTestCase {

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: json.data(using: .utf8)!)
    }

    /// Every spelling of the ticket's nine types — and none of the types that
    /// keep their tap (a container's click sits on its own node, as kjui's).
    func testTheControlsAndTextFieldsHaveNoPlainTap() throws {
        for type in ["Switch", "Toggle", "CheckBox", "Check", "Checkbox", "Radio", "Segment", "Slider",
                     "SelectBox", "TextField", "EditText", "Input", "TextView"] {
            let c = try component(#"{ "type": ""# + type + #"", "onClick": "@{tap}" }"#)
            XCTAssertTrue(DynamicEventHelper.callsOnClickFromItsOperation(c), type)
        }
        for type in ["Button", "View", "Label", "Image", "TabView", "Collection", "ScrollView", "SafeAreaView", "IconLabel"] {
            let c = try component(#"{ "type": ""# + type + #"", "onClick": "@{tap}" }"#)
            XCTAssertFalse(DynamicEventHelper.callsOnClickFromItsOperation(c), type)
        }
    }

    func testTheCallRunsEveryHandlerInOrder() throws {
        var fired: [String] = []
        let data: [String: Any] = [
            "first": { fired.append("first") } as () -> Void,
            "second": { fired.append("second") } as () -> Void,
        ]
        let c = try component(#"{ "type": "Switch", "onclick": ["first", "second"] }"#)
        let click = try XCTUnwrap(DynamicEventHelper.operationClick(c, data: data))
        click()
        XCTAssertEqual(fired, ["first", "second"])
    }

    func testNoHandlerIsNoCall() throws {
        XCTAssertNil(DynamicEventHelper.operationClick(try component(#"{ "type": "Switch" }"#), data: [:]))
        XCTAssertNil(DynamicEventHelper.operationClick(try component(#"{ "type": "Switch", "onClick": "@{}" }"#), data: [:]))
    }

    /// canTap is the gate on the call: false, or a binding that resolves
    /// false when the call is made, calls nothing.
    func testCanTapGatesTheCall() throws {
        var calls = 0
        let tap = { calls += 1 } as () -> Void
        let shut = try component(#"{ "type": "Slider", "onClick": "@{tap}", "canTap": false }"#)
        DynamicEventHelper.operationClick(shut, data: ["tap": tap])?()
        XCTAssertEqual(calls, 0, "canTap: false")

        let bound = try component(#"{ "type": "Slider", "onClick": "@{tap}", "canTap": "@{gate}" }"#)
        DynamicEventHelper.operationClick(bound, data: ["tap": tap, "gate": false])?()
        XCTAssertEqual(calls, 0, "a bound gate that is false")
        DynamicEventHelper.operationClick(bound, data: ["tap": tap, "gate": true])?()
        XCTAssertEqual(calls, 1, "a bound gate that is true")

        var gate = false
        let live = SwiftUI.Binding(get: { gate }, set: { gate = $0 })
        let click = try XCTUnwrap(DynamicEventHelper.operationClick(bound, data: ["tap": tap, "gate": live]))
        click()
        XCTAssertEqual(calls, 1, "read when the call is made: still shut")
        gate = true
        click()
        XCTAssertEqual(calls, 2, "read when the call is made: open")
    }

    /// The control's write goes through first, then the call — and a read is
    /// not an operation.
    func testTheCallFollowsTheWrite() {
        var value = 0
        var seen: [Int] = []
        let base = SwiftUI.Binding(get: { value }, set: { value = $0 })
        let wrapped = DynamicEventHelper.calling({ seen.append(value) }, after: base)
        XCTAssertEqual(wrapped.wrappedValue, 0)
        XCTAssertEqual(seen, [], "reading calls nothing")
        wrapped.wrappedValue = 3
        XCTAssertEqual(seen, [3], "called once, after the value is written")
        value = 5
        XCTAssertEqual(wrapped.wrappedValue, 5, "the view model's change passes through")
        XCTAssertEqual(seen, [3], "and calls nothing")
    }
}
#endif
