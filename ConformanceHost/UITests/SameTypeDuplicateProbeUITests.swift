//
//  SameTypeDuplicateProbeUITests.swift
//  ConformanceHostUITests
//
//  Opt-in: TEST_RUNNER_SAME_TYPE_PROBE=1 in the xcodebuild process
//  environment (the prefix is stripped before the runner sees it), and the
//  `test` action — `test-without-building` ignores TEST_RUNNER_*.
//
//  Closes the half of the 1.9.5 -> 1.9.6 equivalence that reading the source
//  cannot: with several same-typed elements under one identifier, 1.9.5
//  takes the first of a TYPE-FILTERED enumeration and 1.9.6+ takes the first
//  winner in the UNFILTERED `.any` enumeration. Whether those two
//  enumerations agree is an internal property of XCTest, so it is measured.
//
//  ⚠️ `UITests/Vendor/` is gitignored: a result from this file means nothing
//  unless reported with the vendored driver's tag and SHA. Run it against
//  1.9.5, 1.9.6 and 1.9.7 — 1.9.5's answer is being MEASURED, not assumed
//  correct, so the baseline is a reading rather than a premise.
//
//  Reading a failure:
//    * self-checks fail          -> the fixture stopped isolating the axis
//    * only the resolution fails -> the versions disagree; the printed
//                                   DUP2_PROBE_RESULT names which element
//                                   this version picked
//

import XCTest

final class SameTypeDuplicateProbeUITests: XCTestCase {

    private let sharedIdentifier = "same_type_target"
    private let expectedMatches = 4
    /// The eight-candidate bound. Asserted to be OUT of play here so a
    /// failure cannot be confused with fixture 1's axis.
    private let bound = 8

    private func result(_ app: XCUIApplication) -> String {
        app.staticTexts["same_type_probe_result"].label
    }

    func testAllVersionsResolveTheSameOfSeveralSameTypedMatches() throws {
        guard ProcessInfo.processInfo.environment["SAME_TYPE_PROBE"] == "1" else {
            throw XCTSkip("same-type duplicate probe: run with the guard lifted, as the other probes are")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-sameTypeDuplicateProbe"]
        app.launch()
        XCTAssertTrue(
            app.staticTexts["same_type_probe_result"].waitForExistence(timeout: 10),
            "probe did not start")

        let matches = app.descendants(matching: .any).matching(identifier: sharedIdentifier)
        let total = matches.count

        // ---- self-checks: is this arm still isolating the same-type axis? ----
        XCTAssertEqual(
            total, expectedMatches,
            "FIXTURE: expected \(expectedMatches) elements sharing '\(sharedIdentifier)', found \(total)")
        XCTAssertLessThanOrEqual(
            total, bound,
            "FIXTURE: \(total) matches exceeds the bound of \(bound) — a failure would be ambiguous "
            + "between this axis and fixture 1's")

        var types: [UInt] = []
        var frames: [CGRect] = []
        for index in 0..<total {
            let element = matches.element(boundBy: index)
            types.append(element.elementType.rawValue)
            frames.append(element.frame)
        }
        print("DUP2_PROBE_TYPES total=\(total) types=\(types)")
        print("DUP2_PROBE_FRAMES \(frames)")

        // All one type: with no rank differences, only enumeration order can
        // decide the winner, which is the question being asked.
        XCTAssertTrue(
            types.allSatisfy { $0 == XCUIElement.ElementType.button.rawValue },
            "FIXTURE: expected every match to be .button so type cannot decide the winner; got \(types)")
        // Identity must be observable, or "which one" is unanswerable.
        XCTAssertEqual(
            Set(frames.map { "\($0)" }).count, total,
            "FIXTURE: matches do not occupy distinct frames, so the resolved one cannot be identified")

        // ---- the measurement ----
        app.buttons["same_type_probe_reset"].tap()
        XCTAssertEqual(result(app), "tapped: none", "reset did not take")

        let executor = XCUITestActionExecutor(platform: "ios")
        try executor.execute(step: TestStep(action: "tap", id: sharedIdentifier), in: app)

        let fired = result(app)
        print("DUP2_PROBE_RESULT \(fired)")

        // Both rules reduce to "the first interactive element in tree order",
        // so every version should land on index 0. Stated before running; a
        // failure on ANY version — 1.9.5 included — is the finding.
        XCTAssertEqual(
            fired, "tapped: btn0",
            "RESOLUTION: this driver picked \(fired) rather than the first match in tree order. "
            + "If versions disagree here, 1.9.6's single-query rewrite is NOT equivalent to 1.9.5 "
            + "for same-typed duplicates, and 1.9.7 does not fix it either")
    }
}
