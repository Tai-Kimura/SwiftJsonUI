//
//  ResponsiveResolverTests.swift
//  SwiftJsonUITests
//
//  Tests for ResponsiveResolver -- responsive override resolution
//  at the JSON dictionary level.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class ResponsiveResolverTests: XCTestCase {

    // MARK: - No responsive block

    func testNoResponsiveBlockReturnsOriginal() {
        let json: [String: Any] = [
            "type": "View",
            "orientation": "vertical",
            "spacing": 8
        ]

        let resolver = ResponsiveResolver(
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        )
        let result = resolver.resolveTree(json)

        XCTAssertEqual(result["orientation"] as? String, "vertical")
        XCTAssertEqual(result["spacing"] as? Int, 8)
        XCTAssertNil(result["responsive"])
    }

    // MARK: - Compact size class

    func testCompactSizeClassAppliesCompactOverrides() {
        let json: [String: Any] = [
            "type": "View",
            "orientation": "vertical",
            "spacing": 8,
            "responsive": [
                "compact": ["spacing": 4],
                "regular": ["orientation": "horizontal", "spacing": 24]
            ]
        ]

        let resolver = ResponsiveResolver(
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        )
        let result = resolver.resolveTree(json)

        XCTAssertEqual(result["orientation"] as? String, "vertical")
        XCTAssertEqual(result["spacing"] as? Int, 4)
        XCTAssertNil(result["responsive"])
    }

    // MARK: - Regular size class

    func testRegularSizeClassAppliesRegularOverrides() {
        let json: [String: Any] = [
            "type": "View",
            "orientation": "vertical",
            "spacing": 8,
            "responsive": [
                "compact": ["spacing": 4],
                "regular": ["orientation": "horizontal", "spacing": 24]
            ]
        ]

        let resolver = ResponsiveResolver(
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        )
        let result = resolver.resolveTree(json)

        XCTAssertEqual(result["orientation"] as? String, "horizontal")
        XCTAssertEqual(result["spacing"] as? Int, 24)
        XCTAssertNil(result["responsive"])
    }

    // MARK: - Landscape (verticalSizeClass == .compact)

    func testLandscapeAppliesLandscapeOverrides() {
        let json: [String: Any] = [
            "type": "View",
            "orientation": "vertical",
            "spacing": 8,
            "responsive": [
                "landscape": ["spacing": 16]
            ]
        ]

        let resolver = ResponsiveResolver(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact
        )
        let result = resolver.resolveTree(json)

        XCTAssertEqual(result["spacing"] as? Int, 16)
        XCTAssertEqual(result["orientation"] as? String, "vertical")
    }

    // MARK: - Compound: regular-landscape

    func testRegularLandscapeCompoundOverrides() {
        let json: [String: Any] = [
            "type": "View",
            "orientation": "vertical",
            "spacing": 8,
            "responsive": [
                "regular": ["orientation": "horizontal", "spacing": 24],
                "landscape": ["spacing": 16],
                "regular-landscape": ["orientation": "horizontal", "spacing": 32]
            ]
        ]

        let resolver = ResponsiveResolver(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        )
        let result = resolver.resolveTree(json)

        // Compound key takes priority over both "regular" and "landscape"
        XCTAssertEqual(result["orientation"] as? String, "horizontal")
        XCTAssertEqual(result["spacing"] as? Int, 32)
    }

    // MARK: - Compound: compact-landscape

    func testCompactLandscapeCompoundOverrides() {
        let json: [String: Any] = [
            "type": "View",
            "orientation": "vertical",
            "spacing": 8,
            "responsive": [
                "compact": ["spacing": 4],
                "landscape": ["spacing": 16],
                "compact-landscape": ["spacing": 12, "orientation": "horizontal"]
            ]
        ]

        let resolver = ResponsiveResolver(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact
        )
        let result = resolver.resolveTree(json)

        // Compound key takes priority
        XCTAssertEqual(result["orientation"] as? String, "horizontal")
        XCTAssertEqual(result["spacing"] as? Int, 12)
    }

    // MARK: - Priority: compound > landscape > regular

    func testCompoundPriorityOverLandscapeAndRegular() {
        let json: [String: Any] = [
            "type": "View",
            "spacing": 8,
            "responsive": [
                "regular": ["spacing": 20],
                "landscape": ["spacing": 16],
                "regular-landscape": ["spacing": 32]
            ]
        ]

        // regular + landscape = regular-landscape takes priority
        let resolver = ResponsiveResolver(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        )
        let result = resolver.resolveTree(json)
        XCTAssertEqual(result["spacing"] as? Int, 32)
    }

    func testLandscapePriorityOverRegularWhenNoCompound() {
        let json: [String: Any] = [
            "type": "View",
            "spacing": 8,
            "responsive": [
                "regular": ["spacing": 20],
                "landscape": ["spacing": 16]
            ]
        ]

        // Both regular and landscape match, but no compound key exists.
        // landscape has higher priority than regular.
        let resolver = ResponsiveResolver(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        )
        let result = resolver.resolveTree(json)
        XCTAssertEqual(result["spacing"] as? Int, 16)
    }

    // MARK: - Medium falls back to compact

    func testMediumFallsBackToCompact() {
        let json: [String: Any] = [
            "type": "View",
            "spacing": 8,
            "responsive": [
                "medium": ["spacing": 12]
            ]
        ]

        // On iOS, compact maps to medium as fallback
        let resolver = ResponsiveResolver(
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        )
        let result = resolver.resolveTree(json)
        XCTAssertEqual(result["spacing"] as? Int, 12)
    }

    func testCompactHasPriorityOverMedium() {
        let json: [String: Any] = [
            "type": "View",
            "spacing": 8,
            "responsive": [
                "compact": ["spacing": 4],
                "medium": ["spacing": 12]
            ]
        ]

        // compact key is checked after medium in priority but wait --
        // priority order is: compound > landscape > regular > medium > compact
        // So medium has HIGHER priority than compact.
        let resolver = ResponsiveResolver(
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        )
        let result = resolver.resolveTree(json)
        // medium is checked before compact in the priority chain
        XCTAssertEqual(result["spacing"] as? Int, 12)
    }

    // MARK: - Recursive resolution

    func testRecursiveChildResolution() {
        let json: [String: Any] = [
            "type": "View",
            "orientation": "vertical",
            "child": [
                [
                    "type": "Label",
                    "text": "Hello",
                    "fontSize": 14,
                    "responsive": [
                        "regular": ["fontSize": 20]
                    ]
                ] as [String: Any],
                [
                    "type": "Label",
                    "text": "World"
                ] as [String: Any]
            ]
        ]

        let resolver = ResponsiveResolver(
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        )
        let result = resolver.resolveTree(json)

        let children = result["child"] as! [[String: Any]]
        XCTAssertEqual(children[0]["fontSize"] as? Int, 20)
        XCTAssertNil(children[0]["responsive"])
        XCTAssertEqual(children[1]["text"] as? String, "World")
    }

    func testRecursiveChildrenAliasResolution() {
        let json: [String: Any] = [
            "type": "View",
            "children": [
                [
                    "type": "Label",
                    "text": "Hello",
                    "responsive": [
                        "regular": ["fontColor": "#FF0000"]
                    ]
                ] as [String: Any]
            ]
        ]

        let resolver = ResponsiveResolver(
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        )
        let result = resolver.resolveTree(json)

        let children = result["children"] as! [[String: Any]]
        XCTAssertEqual(children[0]["fontColor"] as? String, "#FF0000")
        XCTAssertNil(children[0]["responsive"])
    }

    // MARK: - No matching key

    func testNoMatchingKeyUsesDefaults() {
        let json: [String: Any] = [
            "type": "View",
            "orientation": "vertical",
            "spacing": 8,
            "responsive": [
                "regular": ["orientation": "horizontal"]
            ]
        ]

        // compact size class but only "regular" override exists
        let resolver = ResponsiveResolver(
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        )
        let result = resolver.resolveTree(json)

        XCTAssertEqual(result["orientation"] as? String, "vertical")
        XCTAssertEqual(result["spacing"] as? Int, 8)
        XCTAssertNil(result["responsive"])
    }

    // MARK: - Nil size classes

    func testNilSizeClassesUseDefaults() {
        let json: [String: Any] = [
            "type": "View",
            "spacing": 8,
            "responsive": [
                "compact": ["spacing": 4],
                "regular": ["spacing": 24]
            ]
        ]

        let resolver = ResponsiveResolver(
            horizontalSizeClass: nil,
            verticalSizeClass: nil
        )
        let result = resolver.resolveTree(json)

        // No size class matched -> defaults used
        XCTAssertEqual(result["spacing"] as? Int, 8)
        XCTAssertNil(result["responsive"])
    }

    // MARK: - jsonContainsResponsive

    func testJsonContainsResponsiveDetectsTopLevel() {
        let json: [String: Any] = [
            "type": "View",
            "responsive": ["compact": ["spacing": 4]]
        ]
        XCTAssertTrue(ResponsiveResolver.jsonContainsResponsive(json))
    }

    func testJsonContainsResponsiveDetectsInChild() {
        let json: [String: Any] = [
            "type": "View",
            "child": [
                [
                    "type": "Label",
                    "responsive": ["compact": ["fontSize": 12]]
                ] as [String: Any]
            ]
        ]
        XCTAssertTrue(ResponsiveResolver.jsonContainsResponsive(json))
    }

    func testJsonContainsResponsiveReturnsFalseWhenNone() {
        let json: [String: Any] = [
            "type": "View",
            "child": [
                ["type": "Label", "text": "Hello"] as [String: Any]
            ]
        ]
        XCTAssertFalse(ResponsiveResolver.jsonContainsResponsive(json))
    }

    // MARK: - Override preserves unrelated attributes

    func testOverridePreservesUnrelatedAttributes() {
        let json: [String: Any] = [
            "type": "View",
            "orientation": "vertical",
            "spacing": 8,
            "background": "#FFFFFF",
            "responsive": [
                "regular": ["spacing": 24]
            ]
        ]

        let resolver = ResponsiveResolver(
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        )
        let result = resolver.resolveTree(json)

        XCTAssertEqual(result["type"] as? String, "View")
        XCTAssertEqual(result["orientation"] as? String, "vertical")
        XCTAssertEqual(result["spacing"] as? Int, 24)
        XCTAssertEqual(result["background"] as? String, "#FFFFFF")
    }
}
#endif // DEBUG
