//
//  ResponsiveResolverVectorTests.swift
//  SwiftJsonUITests
//
//  Which key of a responsive block wins — the rule every codegen draws
//  (jsonui-cli shared/core/responsive_resolver.rb build_branches) — held on
//  the Dynamic resolver. The cases are jsonui-cli
//  shared/core/responsive_resolution_vectors.json, copied byte-identical into
//  Fixtures/ (CI compares the copy with the file at the pinned jsonui-cli ref).
//
//  - one key wins, alone: no other key's overrides stack on it;
//  - medium-landscape is read (sjui-dynamic-responsive-ignores-medium-landscape);
//  - minWidth:N holds at width >= N, maxWidth:N at width < N; the smallest
//    maxWidth that holds wins, else the largest minWidth
//    (jui-responsive-width-threshold-conditions) — N-1 / N / N+1 and a
//    fractional width are cases.
//
//  env.sizeClass is a width bucket; on iOS compact and medium are both
//  horizontalSizeClass .compact, and the vectors give the iOS answer as
//  `ios_winner` where it differs.
//

import XCTest
import SwiftUI
import Combine
@testable import SwiftJsonUI

#if DEBUG
final class ResponsiveResolverVectorTests: XCTestCase {

    private struct Vectors: Decodable {
        struct Env: Decodable {
            let sizeClass: String?
            let landscape: Bool?
            let width: Double?
        }
        struct Case: Decodable {
            let name: String
            let keys: [String]
            let env: Env
            let winner: String?
            let ios_winner: String?
        }
        struct Condition: Decodable {
            let kind: String
            let value: Int
        }
        struct KeyCase: Decodable {
            let key: String
            let condition: Condition?
        }
        let cases: [Case]
        let key_cases: [KeyCase]
    }

    private func vectors() throws -> Vectors {
        try JSONDecoder().decode(Vectors.self, from: TestFixtures.loadJSON(named: "responsive_resolution_vectors"))
    }

    func testEveryCaseDrawsItsWinnerAlone() throws {
        let vectors = try vectors()
        XCTAssertGreaterThanOrEqual(vectors.cases.count, 20)
        for c in vectors.cases {
            var responsive: [String: Any] = [:]
            for key in c.keys { responsive[key] = ["tag": key] }
            let json: [String: Any] = ["type": "View", "tag": "base", "responsive": responsive]
            let horizontal: UserInterfaceSizeClass? = c.env.sizeClass.map { $0 == "regular" ? .regular : .compact }
            let vertical: UserInterfaceSizeClass? = c.env.landscape.map { $0 ? .compact : .regular }
            let resolver = ResponsiveResolver(horizontalSizeClass: horizontal, verticalSizeClass: vertical,
                                              windowWidth: c.env.width.map { CGFloat($0) })
            let expected = c.ios_winner ?? c.winner
            XCTAssertEqual(resolver.resolveTree(json)["tag"] as? String, expected ?? "base", c.name)
        }
    }

    func testEveryKeyCaseParsesAsItSays() throws {
        let vectors = try vectors()
        XCTAssertGreaterThanOrEqual(vectors.key_cases.count, 15)
        for c in vectors.key_cases {
            let parsed = ResponsiveResolver.WidthCondition(c.key)
            XCTAssertEqual(parsed.map { $0.kind == .min ? "min" : "max" }, c.condition?.kind, c.key)
            XCTAssertEqual(parsed?.value, c.condition?.value, c.key)
        }
    }

    func testWidthConditionsHoldNothingWithoutAWidth() {
        let json: [String: Any] = ["type": "View", "tag": "base", "responsive": ["minWidth:0": ["tag": "min"]]]
        let resolver = ResponsiveResolver(horizontalSizeClass: .regular, verticalSizeClass: .regular, windowWidth: nil)
        XCTAssertEqual(resolver.resolveTree(json)["tag"] as? String, "base")
    }

    /// DynamicView tracks its window's width (a probe behind the view) only
    /// for a tree with a width condition; a probe on every DynamicView — every
    /// Collection cell — changed the cell's accessibility frame.
    func testOnlyATreeWithAWidthConditionTracksTheWindow() {
        let sizeClassesOnly: [String: Any] = ["type": "View", "responsive": ["regular": ["spacing": 4]],
                                              "child": [["type": "Label", "responsive": ["landscape": ["fontSize": 20]]]]]
        XCTAssertFalse(ResponsiveResolver.jsonContainsWidthConditions(sizeClassesOnly))
        XCTAssertFalse(ResponsiveResolver.jsonContainsWidthConditions(["type": "View"]))
        let nested: [String: Any] = ["type": "View", "child": [["type": "View", "children": [
            ["type": "Label", "responsive": ["maxWidth:700": ["fontSize": 12]]]]]]]
        XCTAssertTrue(ResponsiveResolver.jsonContainsWidthConditions(nested))
        let inATab: [String: Any] = ["type": "TabView", "tabs": [["child": [["type": "View", "responsive": ["minWidth:0": [:]]]]]]]
        XCTAssertTrue(ResponsiveResolver.jsonContainsWidthConditions(inATab))
        XCTAssertFalse(ResponsiveResolver.jsonContainsWidthConditions(["type": "View", "responsive": ["minWidth:7.5": [:]]]))
    }

    // MARK: - SJUIWindowWidth

    @MainActor
    func testTheWidthPublishesAChangeAndIgnoresAnUnknownOne() {
        let width = SJUIWindowWidth()
        var published: [CGFloat] = []
        let subscription = width.$measured.dropFirst().sink { published.append($0) }
        width.update(700)
        width.update(700)    // the same width: no change
        width.update(nil)    // no scene: keep what was measured
        width.update(0)      // a zero geometry: keep what was measured
        width.update(699.5)
        XCTAssertEqual(published, [700, 699.5])
        // No scene in the test host: the value is the last one measured.
        XCTAssertNil(SJUIWindowWidth.activeScene())
        XCTAssertEqual(width.value, 699.5)
        subscription.cancel()
    }

    @MainActor
    func testTheFirstWidthIsReadWhenTheObjectIsMade() {
        // The test host's scene (or none): whatever SJUIWindowMetrics reads,
        // the object starts there rather than at 0-then-measured.
        let expected = SJUIWindowWidth.width(of: SJUIWindowWidth.activeScene()) ?? SJUIWindowMetrics.bounds().width
        XCTAssertEqual(SJUIWindowWidth().value, expected)
    }
}
#endif
