//
//  DynamicHandlersAreCalledTests.swift
//  SwiftJsonUITests
//
//  A TextField's onSubmit and its focus handlers (onFocus / onBeginEditing,
//  onBlur / onEndEditing), and a Collection's onItemAppear / a pager's
//  onValueChange, are called on Dynamic as the closure the data holds asks —
//  the binding form or the bare name, with the viewId when the closure takes
//  one. Until 10.29.2 Dynamic never called the TextField's five (no
//  onSubmitAction, no focus wiring), and the Collection's two only when the
//  closure was `(Int) -> Void`: measured on the iOS simulator by support
//  lane 2, while the generated code called them all (ticket
//  sjui-dynamic-textfield-and-collection-handlers-are-not-called).
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class DynamicHandlersAreCalledTests: XCTestCase {

    private func component(_ json: [String: Any]) throws -> DynamicComponent {
        try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: json))
    }

    // MARK: - TextField onSubmit

    func testOnSubmitIsCalledInTheBindingFormAndBare() throws {
        for secure in [false, true] {
            for value in ["@{h}", "h"] {
                var calls = 0
                let c = try component(["type": "TextField", "id": "f", "text": "@{t}", "secure": secure, "onSubmit": value])
                let submit = TextFieldConverter.submitAction(component: c, data: ["h": { calls += 1 } as () -> Void])
                submit?()
                XCTAssertEqual(calls, 1, "secure \(secure): \(value)")
            }
        }
    }

    func testOnSubmitHandsTheViewIdToAHandlerThatTakesOne() throws {
        var got: String?
        let c = try component(["type": "TextField", "id": "f", "onSubmit": "@{h}"])
        TextFieldConverter.submitAction(component: c, data: ["h": { (id: String) in got = id } as (String) -> Void])?()
        XCTAssertEqual(got, "f")
    }

    func testNoSubmitActionWithoutAHandler() throws {
        for value: Any in ["", "@{}"] {
            let c = try component(["type": "TextField", "id": "f", "onSubmit": value])
            XCTAssertNil(TextFieldConverter.submitAction(component: c, data: [:]), "\(value)")
        }
        XCTAssertNil(TextFieldConverter.submitAction(component: try component(["type": "TextField"]), data: [:]))
    }

    // MARK: - TextField focus

    func testFocusHandlersAreCalledOnGainAndLossInDeclarationOrder() throws {
        for (focus, blur) in [("@{a}", "@{b}"), ("a", "b")] {
            var log: [String] = []
            let data: [String: Any] = [
                "a": { log.append("a") } as () -> Void, "b": { log.append("b") } as () -> Void,
                "c": { log.append("c") } as () -> Void, "d": { log.append("d") } as () -> Void
            ]
            let c = try component(["type": "TextField", "onFocus": focus, "onBeginEditing": "c",
                                   "onBlur": blur, "onEndEditing": "@{d}"])
            let change = try XCTUnwrap(TextFieldConverter.focusChangeAction(component: c, data: data))
            change(true)
            change(false)
            XCTAssertEqual(log, ["a", "c", "b", "d"], "\(focus) / \(blur)")
        }
    }

    func testNoFocusActionWithoutAFocusHandler() throws {
        XCTAssertNil(TextFieldConverter.focusChangeAction(component: try component(["type": "TextField", "id": "f"]), data: [:]))
    }

    // MARK: - Collection

    private func pager(_ extra: [String: Any]) throws -> DynamicComponent {
        var json: [String: Any] = ["type": "Collection", "id": "pager", "items": "@{rows}",
                                   "layout": "horizontal", "paging": true]
        json.merge(extra) { _, new in new }
        return try component(json)
    }

    func testIndexHandlersAreCalledInEveryShapeTheDataHolds() throws {
        for (key, resolve) in [
            ("onItemAppear", { CollectionConverter.itemAppearCallback(component: $0, data: $1) }),
            ("onValueChange", { CollectionConverter.pageChangeCallback(component: $0, data: $1) })
        ] as [(String, (DynamicComponent, [String: Any]) -> ((Int) -> Void)?)] {
            for value in ["@{h}", "h"] {
                let c = try pager([key: value])
                var calls = 0
                resolve(c, ["h": { calls += 1 } as () -> Void])?(2)
                XCTAssertEqual(calls, 1, "() -> Void, \(key): \(value)")

                var index: Int?
                resolve(c, ["h": { (i: Int) in index = i } as (Int) -> Void])?(2)
                XCTAssertEqual(index, 2, "(Int) -> Void, \(key): \(value)")

                var pair: (String, Int)?
                resolve(c, ["h": { (id: String, i: Int) in pair = (id, i) } as (String, Int) -> Void])?(3)
                XCTAssertEqual(pair?.0, "pager", "(String, Int) -> Void, \(key): \(value)")
                XCTAssertEqual(pair?.1, 3, "(String, Int) -> Void, \(key): \(value)")

                XCTAssertNil(resolve(c, [:]), "no handler, \(key): \(value)")
            }
        }
    }
}
#endif
