//
//  CollectionReorderVectorTests.swift
//  SwiftJsonUITests
//
//  The reorder rule's vectors (jsonui-cli shared/core/reorder_vectors.json, vendored byte-identical in Fixtures and
//  checked against JSONUI_CLI_MANIFEST_REF by ci.yml), run against the library's own reading of it
//  (CollectionReorderRule). The same file is read by KotlinJsonUI and rjui; jui_tools tests it against the reference
//  implementation, shared/core/reorder_rule.py.
//

import XCTest
@testable import SwiftJsonUI

final class CollectionReorderVectorTests: XCTestCase {
    typealias Rule = CollectionReorderRule

    private var vectors: [String: Any] = [:]

    override func setUpWithError() throws {
        let data = try TestFixtures.loadJSON(named: "reorder_vectors")
        vectors = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func cases(_ key: String) throws -> [[String: Any]] {
        let list = try XCTUnwrap(vectors[key] as? [[String: Any]], "\(key) is missing")
        XCTAssertFalse(list.isEmpty, "\(key) has no case")
        return list
    }

    private func num(_ value: Any?) -> CGFloat { CGFloat((value as? NSNumber)?.doubleValue ?? 0) }
    private func locked(_ c: [String: Any]) -> Set<Int> { Set((c["locked"] as? [Int]) ?? []) }
    private func fixed(_ c: [String: Any]) -> Set<Int> { Set((c["fixed"] as? [Int]) ?? []) }

    /// Rows laid one after another from `top` (each span includes the spacing after it, as the vectors say).
    private func spans(_ heights: [CGFloat], from top: CGFloat = 0) -> [Rule.RowSpan] {
        var y = top
        return heights.map { h in defer { y += h }; return Rule.RowSpan(top: y, bottom: y + h) }
    }

    func testDrag() throws {
        for c in try cases("drag") {
            let heights = (c["heights"] as? [NSNumber] ?? []).map { CGFloat($0.doubleValue) }
            let from = c["from"] as! Int
            guard let to = c["to"] as? Int else {
                XCTAssertFalse(Rule.canPickUp(from, locked: locked(c), fixed: fixed(c)), "\(c["name"] ?? ""): not picked up")
                continue
            }
            XCTAssertTrue(Rule.canPickUp(from, locked: locked(c), fixed: fixed(c)), "\(c["name"] ?? "")")
            XCTAssertEqual(Rule.target(from: from, dy: num(c["dy"]), rows: spans(heights), locked: locked(c)), to, "\(c["name"] ?? "")")
        }
    }

    func testDrop() throws {
        for c in try cases("drop") {
            let rows = c["rows"] as! [String]
            let from = c["from"] as! Int, to = c["to"] as! Int
            let valid = Rule.isValidMove(from: from, to: to, count: rows.count, locked: locked(c), fixed: fixed(c))
            if c["refused"] != nil {
                XCTAssertFalse(valid, "\(c["name"] ?? ""): refused (\(c["refused"] ?? ""))")
            } else {
                XCTAssertTrue(valid, "\(c["name"] ?? "")")
                var order = rows
                order.insert(order.remove(at: from), at: to)
                XCTAssertEqual(order, c["order"] as? [String], "\(c["name"] ?? "")")
            }
        }
    }

    func testIOSOnMove() throws {
        for c in try cases("iosOnMove") {
            let from = c["from"] as! Int
            let to = Rule.toIndex(fromOnMove: from, destination: c["destination"] as! Int)
            XCTAssertEqual(to, c["to"] as? Int, "from \(from) destination \(c["destination"] ?? "")")
        }
    }

    /// The library's drag: the finger, from the container's top, is header + the row's top + grabAt + dy; inside the
    /// container the drag's target (clamped short of a locked row) is the move, outside it is cancelled.
    func testRelease() throws {
        for c in try cases("release") {
            let header = num(c["header"]), footer = num(c["footer"])
            let heights = (c["heights"] as? [NSNumber] ?? []).map { CGFloat($0.doubleValue) }
            let rows = spans(heights, from: header)
            let from = c["from"] as! Int, dy = num(c["dy"])
            let finger = rows[from].top + num(c["grabAt"]) + dy
            let bottom = header + heights.reduce(0, +) + footer
            let commits = Rule.releaseCommits(fingerY: finger, containerTop: 0, containerBottom: bottom)
            let name = "\(c["name"] ?? "")"
            if c["cancelled"] as? Bool == true {
                XCTAssertFalse(commits, name)
            } else if c["to"] == nil || c["to"] is NSNull {
                // Inside the container, but the row is not picked up (locked or fixed).
                XCTAssertTrue(commits, name)
                XCTAssertFalse(Rule.canPickUp(from, locked: locked(c), fixed: fixed(c)), name)
                XCTAssertNil(Rule.clampedTo(from: from, to: from, locked: locked(c), fixed: fixed(c)), name)
            } else {
                XCTAssertTrue(commits, name)
                XCTAssertEqual(Rule.target(from: from, dy: dy, rows: rows, locked: locked(c)), c["to"] as? Int, name)
            }
        }
    }

    func testAutoScroll() throws {
        for c in try cases("autoScroll") {
            let got = Rule.autoScrollVelocity(fingerY: num(c["fingerY"]), viewportTop: 0, viewportBottom: num(c["viewport"]))
            XCTAssertEqual(got, num(c["speed"]), accuracy: 0.001, "\(c["name"] ?? "")")
        }
    }

    func testAccessibility() throws {
        for c in try cases("a11y") {
            let moves = Rule.accessibilityMoves(index: c["from"] as! Int, count: c["rows"] as! Int, locked: locked(c),
                                                fixed: fixed(c))
            let offered = (c["action"] as? String) == "up" ? moves.up : moves.down
            let name = "\(c["name"] ?? "")"
            if let to = c["to"] as? Int {
                XCTAssertTrue(offered, name)
                XCTAssertEqual((c["from"] as! Int) + ((c["action"] as? String) == "up" ? -1 : 1), to, name)
            } else {
                XCTAssertFalse(offered, name)
            }
        }
    }

    /// The one place iOS 27's own reorderContainer reads the rule differently is written down, not hidden.
    func testTheKnownDifferenceIsIOS27sCentre() throws {
        let known = try XCTUnwrap(vectors["knownDifferences"] as? [[String: Any]])
        XCTAssertEqual(known.count, 1)
        XCTAssertTrue("\(known[0])".contains("27"))
    }
}
