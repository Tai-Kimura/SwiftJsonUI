//
//  StyleProcessorTests.swift
//  SwiftJsonUI
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class StyleProcessorTests: XCTestCase {

    override func setUp() {
        super.setUp()
        StyleProcessor.clearCache()
    }

    override func tearDown() {
        StyleProcessor.clearCache()
        super.tearDown()
    }

    func testProcessStylesWithoutStyle() {
        let json: [String: Any] = [
            "type": "Label",
            "text": "Hello"
        ]

        let result = StyleProcessor.processStyles(json)

        XCTAssertEqual(result["type"] as? String, "Label")
        XCTAssertEqual(result["text"] as? String, "Hello")
        XCTAssertNil(result["style"])
    }

    func testProcessStylesWithChild() {
        let json: [String: Any] = [
            "type": "View",
            "child": [
                [
                    "type": "Label",
                    "text": "Child"
                ]
            ]
        ]

        let result = StyleProcessor.processStyles(json)

        XCTAssertNotNil(result["child"])
        if let child = result["child"] as? [[String: Any]] {
            XCTAssertEqual(child.count, 1)
            XCTAssertEqual(child[0]["type"] as? String, "Label")
        } else {
            XCTFail("Child should be an array")
        }
    }

    func testProcessStylesWithChildren() {
        let json: [String: Any] = [
            "type": "TabView",
            "children": [
                ["type": "Label", "text": "Tab 1"],
                ["type": "Label", "text": "Tab 2"]
            ]
        ]

        let result = StyleProcessor.processStyles(json)

        XCTAssertNotNil(result["children"])
        if let children = result["children"] as? [[String: Any]] {
            XCTAssertEqual(children.count, 2)
            XCTAssertEqual(children[0]["text"] as? String, "Tab 1")
            XCTAssertEqual(children[1]["text"] as? String, "Tab 2")
        } else {
            XCTFail("Children should be an array")
        }
    }

    func testProcessStylesWithSingleChild() {
        let json: [String: Any] = [
            "type": "View",
            "child": [
                "type": "Label",
                "text": "Single"
            ]
        ]

        let result = StyleProcessor.processStyles(json)

        XCTAssertNotNil(result["child"])
    }

    func testClearCache() {
        StyleProcessor.clearCache()

        // Should not throw
        XCTAssertNoThrow(StyleProcessor.clearCache())
    }

    func testClearCacheForSpecificStyle() {
        StyleProcessor.clearCache(for: "testStyle")

        // Should not throw
        XCTAssertNoThrow(StyleProcessor.clearCache(for: "testStyle"))
    }

    func testProcessStylesRecursively() {
        let json: [String: Any] = [
            "type": "View",
            "child": [
                [
                    "type": "View",
                    "child": [
                        [
                            "type": "Label",
                            "text": "Nested"
                        ]
                    ]
                ]
            ]
        ]

        let result = StyleProcessor.processStyles(json)

        XCTAssertNotNil(result["child"])
        if let child = result["child"] as? [[String: Any]],
           let nestedChild = child[0]["child"] as? [[String: Any]] {
            XCTAssertEqual(nestedChild[0]["text"] as? String, "Nested")
        } else {
            XCTFail("Nested children should be processed")
        }
    }

    func testProcessStylesPreservesOtherAttributes() {
        let json: [String: Any] = [
            "type": "Label",
            "text": "Hello",
            "fontSize": 16,
            "fontColor": "#FF0000",
            "background": "#00FF00"
        ]

        let result = StyleProcessor.processStyles(json)

        XCTAssertEqual(result["type"] as? String, "Label")
        XCTAssertEqual(result["text"] as? String, "Hello")
        XCTAssertEqual(result["fontSize"] as? Int, 16)
        XCTAssertEqual(result["fontColor"] as? String, "#FF0000")
        XCTAssertEqual(result["background"] as? String, "#00FF00")
    }

    func testProcessStylesWithEmptyChild() {
        let json: [String: Any] = [
            "type": "View",
            "child": []
        ]

        let result = StyleProcessor.processStyles(json)

        if let child = result["child"] as? [[String: Any]] {
            XCTAssertEqual(child.count, 0)
        } else {
            XCTFail("Child should be an empty array")
        }
    }

    func testProcessStylesWithEmptyChildren() {
        let json: [String: Any] = [
            "type": "TabView",
            "children": []
        ]

        let result = StyleProcessor.processStyles(json)

        if let children = result["children"] as? [[String: Any]] {
            XCTAssertEqual(children.count, 0)
        } else {
            XCTFail("Children should be an empty array")
        }
    }
}
#endif
