//
//  SJUIModelTests.swift
//  SwiftJsonUI
//

import XCTest
@testable import SwiftJsonUI

final class SJUIModelTests: XCTestCase {

    func testSJUIModelInitialization() {
        let json = JSON(["key": "value", "number": 42])
        let model = SJUIModel(json: json)

        XCTAssertNotNil(model._json)
        XCTAssertEqual(model._json["key"].string, "value")
        XCTAssertEqual(model._json["number"].int, 42)
    }

    func testSelectedDefaultValue() {
        let json = JSON([:])
        let model = SJUIModel(json: json)

        XCTAssertFalse(model.selected)
    }

    func testSelectedCanBeSet() {
        let json = JSON([:])
        let model = SJUIModel(json: json)

        model.selected = true
        XCTAssertTrue(model.selected)

        model.selected = false
        XCTAssertFalse(model.selected)
    }

    func testValueForUndefinedKey() {
        let json = JSON([:])
        let model = SJUIModel(json: json)

        let value = model.value(forUndefinedKey: "nonexistent")
        XCTAssertNil(value)
    }

    func testModelWithComplexJSON() {
        let json = JSON([
            "string": "test",
            "int": 100,
            "double": 3.14,
            "bool": true,
            "array": [1, 2, 3],
            "object": ["nested": "value"]
        ])

        let model = SJUIModel(json: json)

        XCTAssertEqual(model._json["string"].string, "test")
        XCTAssertEqual(model._json["int"].int, 100)
        XCTAssertEqual(model._json["double"].double, 3.14)
        XCTAssertEqual(model._json["bool"].bool, true)
        XCTAssertEqual(model._json["array"].array?.count, 3)
        XCTAssertEqual(model._json["object"]["nested"].string, "value")
    }

    func testModelWithEmptyJSON() {
        let json = JSON([:])
        let model = SJUIModel(json: json)

        XCTAssertNotNil(model._json)
        XCTAssertFalse(model.selected)
    }

    func testModelWithNullJSON() {
        let json = JSON(NSNull())
        let model = SJUIModel(json: json)

        XCTAssertNotNil(model._json)
        XCTAssertTrue(model._json.isEmpty)
    }

    func testModelIsNSObject() {
        let json = JSON([:])
        let model = SJUIModel(json: json)

        XCTAssertTrue(model is NSObject)
    }

    func testModelCanBeSubclassed() {
        class CustomModel: SJUIModel {
            var customProperty: String = "custom"
        }

        let json = JSON(["test": "value"])
        let customModel = CustomModel(json: json)

        XCTAssertEqual(customModel.customProperty, "custom")
        XCTAssertEqual(customModel._json["test"].string, "value")
    }
}
