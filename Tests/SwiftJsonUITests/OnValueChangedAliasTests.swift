//
//  OnValueChangedAliasTests.swift
//  SwiftJsonUITests
//
//  `onValueChanged` is the declared alias of `onValueChange`. From jsonui-cli
//  1.9.6 the SelectBox table folds it into its `onValueChange` instead of
//  carrying a field of its own, and DynamicComponent.onValueChangedSpelling
//  reads that field: SelectBox and Toggle answer the alias through it, as the
//  Switch table, which onValueChangeSpelling reads, does not fold it.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class OnValueChangedAliasTests: XCTestCase {

    private func component(_ json: [String: Any]) throws -> DynamicComponent {
        try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: json))
    }

    /// What the SelectBox and Toggle converters read for the handler.
    private func handler(_ json: [String: Any]) throws -> String? {
        let c = try component(json)
        return c.onValueChangeSpelling() ?? c.onValueChangedSpelling()
    }

    func testTheAliasIsAnsweredOnSelectBoxAndToggle() throws {
        for type in ["SelectBox", "Toggle"] {
            XCTAssertEqual(try handler(["type": type, "id": "x", "onValueChanged": "@{picked}"]), "@{picked}", type)
            XCTAssertEqual(try handler(["type": type, "id": "x", "onValueChange": "@{picked}"]), "@{picked}", type)
        }
    }

    func testNoHandlerIsNil() throws {
        XCTAssertNil(try handler(["type": "SelectBox", "id": "x"]))
    }
}
#endif
