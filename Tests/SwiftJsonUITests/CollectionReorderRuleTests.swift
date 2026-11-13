//
//  CollectionReorderRuleTests.swift
//  SwiftJsonUITests
//
//  The reorder rule (ticket jui-collection-drag-to-reorder) as written in the ruling and in jsonui-cli's
//  shared/core/reorder_rule.py: centre crossing, locked rows as walls, a release off the rows cancels, onMove's
//  destination and iOS 27's ReorderDifference turned into the index after the move, the edge band's auto-scroll, and
//  the accessibility moves a row offers.
//

import XCTest
@testable import SwiftJsonUI

final class CollectionReorderRuleTests: XCTestCase {
    typealias Rule = CollectionReorderRule

    /// Six rows 56 tall with 4 between: tops 0, 60, 120, …; centres 28, 88, 148, 208, 268, 328.
    private let rows: [Rule.RowSpan] = (0..<6).map { Rule.RowSpan(top: CGFloat($0) * 60, bottom: CGFloat($0) * 60 + 56) }

    func testARowPassesEveryCentreItsOwnCentreCrossed() {
        XCTAssertEqual(Rule.target(from: 0, dy: 0, rows: rows, locked: []), 0)
        XCTAssertEqual(Rule.target(from: 0, dy: 59, rows: rows, locked: []), 0, "28 + 59 = 87 is short of row 1's 88")
        XCTAssertEqual(Rule.target(from: 0, dy: 60, rows: rows, locked: []), 0, "exactly on the centre is not past it")
        XCTAssertEqual(Rule.target(from: 0, dy: 61, rows: rows, locked: []), 1)
        XCTAssertEqual(Rule.target(from: 0, dy: 185, rows: rows, locked: []), 3)
        XCTAssertEqual(Rule.target(from: 0, dy: 5000, rows: rows, locked: []), 5, "past the last row is the last row")
        XCTAssertEqual(Rule.target(from: 4, dy: -121, rows: rows, locked: []), 2)
        XCTAssertEqual(Rule.target(from: 4, dy: -5000, rows: rows, locked: []), 0)
    }

    func testALockedRowIsAWall() {
        XCTAssertEqual(Rule.target(from: 0, dy: 5000, rows: rows, locked: [3]), 2, "stops in front of the locked row")
        XCTAssertEqual(Rule.target(from: 5, dy: -5000, rows: rows, locked: [3]), 4)
        XCTAssertEqual(Rule.target(from: 0, dy: 5000, rows: rows, locked: [1]), 0)
    }

    func testLettingGoInsideTheContainerCommitsAndOutsideCancels() {
        // a container from -40 (a 40pt header) to 396 (a 40pt footer after the last row's 356)
        XCTAssertTrue(Rule.releaseCommits(fingerY: 200, containerTop: -40, containerBottom: 396))
        XCTAssertTrue(Rule.releaseCommits(fingerY: 380, containerTop: -40, containerBottom: 396), "over the footer")
        XCTAssertTrue(Rule.releaseCommits(fingerY: -20, containerTop: -40, containerBottom: 396), "over the header")
        XCTAssertFalse(Rule.releaseCommits(fingerY: 397, containerTop: -40, containerBottom: 396), "below the container")
        XCTAssertFalse(Rule.releaseCommits(fingerY: -41, containerTop: -40, containerBottom: 396), "above the container")
    }

    func testOverTheHeaderOrFooterARowLandsFirstOrLast() {
        // the row's centre over the footer is past the last row's centre; over the header, before the first row's
        XCTAssertEqual(Rule.target(from: 1, dy: 380 - 88, rows: rows, locked: []), 5)
        XCTAssertEqual(Rule.target(from: 4, dy: -20 - 268, rows: rows, locked: []), 0)
        XCTAssertEqual(Rule.target(from: 4, dy: -20 - 268, rows: rows, locked: [1]), 2, "short of a locked row")
    }

    func testOnlyARealMoveIsReported() {
        XCTAssertFalse(Rule.shouldReport(from: 2, to: 2))
        XCTAssertTrue(Rule.shouldReport(from: 2, to: 3))
    }

    func testOnMovesDestinationIsTheIndexBeforeTheRowIsTakenOut() {
        XCTAssertEqual(Rule.toIndex(fromOnMove: 0, destination: 4), 3, "A to after D in ABCDEF: A is then at 3")
        XCTAssertEqual(Rule.toIndex(fromOnMove: 4, destination: 1), 1)
        XCTAssertEqual(Rule.toIndex(fromOnMove: 2, destination: 2), 2)
        XCTAssertEqual(Rule.toIndex(fromOnMove: 2, destination: 3), 2, "in front of the next row is no move")
    }

    func testReorderDifferenceNamesTheRowInFront() {
        XCTAssertEqual(Rule.toIndex(from: 0, beforeIndex: 4, count: 6), 3, "A before E in ABCDEF: BCDAEF")
        XCTAssertEqual(Rule.toIndex(from: 4, beforeIndex: 1, count: 6), 1)
        XCTAssertEqual(Rule.toIndex(from: 0, beforeIndex: nil, count: 6), 5, ".end")
    }

    func testAMoveAcrossALockedRowIsRefused() {
        XCTAssertTrue(Rule.crossesLocked(from: 0, to: 4, locked: [2]))
        XCTAssertTrue(Rule.crossesLocked(from: 4, to: 0, locked: [2]))
        XCTAssertFalse(Rule.crossesLocked(from: 0, to: 1, locked: [2]))
        XCTAssertTrue(Rule.crossesLocked(from: 2, to: 3, locked: [2]), "a locked row does not move")
        XCTAssertFalse(Rule.crossesLocked(from: 3, to: 3, locked: [2]))
    }

    func testAMoveFromAnywhereEndsShortOfALockedRow() {
        XCTAssertEqual(Rule.clampedTo(from: 0, to: 4, locked: [2]), 1)
        XCTAssertEqual(Rule.clampedTo(from: 5, to: 0, locked: [2]), 3)
        XCTAssertEqual(Rule.clampedTo(from: 0, to: 1, locked: [2]), 1)
        XCTAssertNil(Rule.clampedTo(from: 2, to: 4, locked: [2]), "a locked row does not move")
        XCTAssertEqual(Rule.clampedTo(from: 0, to: 5, locked: [1]), 0, "a wall right beside it: no move")
    }

    func testAutoScrollGrowsWithTheDepthIntoTheBand() {
        // a viewport from 100 to 700
        XCTAssertEqual(Rule.autoScrollVelocity(fingerY: 400, viewportTop: 100, viewportBottom: 700), 0)
        XCTAssertEqual(Rule.autoScrollVelocity(fingerY: 148, viewportTop: 100, viewportBottom: 700), 0, "the band's inner edge")
        XCTAssertEqual(Rule.autoScrollVelocity(fingerY: 124, viewportTop: 100, viewportBottom: 700), -400, accuracy: 0.001)
        XCTAssertEqual(Rule.autoScrollVelocity(fingerY: 100, viewportTop: 100, viewportBottom: 700), -800)
        XCTAssertEqual(Rule.autoScrollVelocity(fingerY: 60, viewportTop: 100, viewportBottom: 700), -800, "capped past the edge")
        XCTAssertEqual(Rule.autoScrollVelocity(fingerY: 676, viewportTop: 100, viewportBottom: 700), 400, accuracy: 0.001)
        XCTAssertEqual(Rule.autoScrollVelocity(fingerY: 700, viewportTop: 100, viewportBottom: 700), 800)
    }

    func testInAShortViewportTheNearerEdgeWins() {
        // 100 tall: both bands overlap
        XCTAssertLessThan(Rule.autoScrollVelocity(fingerY: 130, viewportTop: 100, viewportBottom: 200), 0)
        XCTAssertGreaterThan(Rule.autoScrollVelocity(fingerY: 170, viewportTop: 100, viewportBottom: 200), 0)
    }

    func testTheAccessibilityMovesARowOffers() {
        XCTAssertTrue(Rule.accessibilityMoves(index: 0, count: 6, locked: []) == (false, true))
        XCTAssertTrue(Rule.accessibilityMoves(index: 5, count: 6, locked: []) == (true, false))
        XCTAssertTrue(Rule.accessibilityMoves(index: 2, count: 6, locked: []) == (true, true))
        XCTAssertTrue(Rule.accessibilityMoves(index: 2, count: 6, locked: [1]) == (false, true), "the row above is locked")
        XCTAssertTrue(Rule.accessibilityMoves(index: 2, count: 6, locked: [2]) == (false, false), "a locked row")
    }
}
