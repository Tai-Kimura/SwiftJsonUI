//
//  DuplicateIdentifierProbeUITests.swift
//  ConformanceHostUITests
//
//  The only discriminator for the 1.9.6 interactive-search regression.
//  Opt-in like the other probes: DUPLICATE_ID_PROBE=1.
//
//  1.9.5 searched per interactive TYPE across the whole hierarchy, so a
//  control was found wherever it sat. 1.9.6 slices `min(total, 8)` off a
//  single `.any` query BEFORE looking for an interactive type, so a control
//  at index >= 8 is never considered. Neither consumer corpus reaches nine
//  matches on one identifier, so no consumer suite can see this — green
//  there is not evidence, and that is why this probe exists.
//
//  ⚠️ `UITests/Vendor/` is gitignored: which driver this ran against is NOT
//  recorded by git. A red or green from this file is meaningless unless it
//  is reported together with the vendored driver's tag and SHA.
//
//  Reading a failure:
//
//    * self-checks (count / exactly one interactive / index >= 8 / type)
//      fail  -> THE FIXTURE broke. The arm no longer reaches the defect and
//               says nothing about the driver.
//    * only the resolution assert fails -> THE DRIVER. Under 1.9.6 the
//      expected wrong answer is `row0`: the interactive search misses and
//      the hittable fallback returns the first of the eight candidates.
//

import XCTest

final class DuplicateIdentifierProbeUITests: XCTestCase {

    private let sharedIdentifier = "dup_target"
    private let expectedMatches = 12
    /// The bound 1.9.6 applies to the interactive search.
    private let bound = 8

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-duplicateIdentifierProbe"]
        app.launch()
        XCTAssertTrue(
            app.staticTexts["dup_probe_result"].waitForExistence(timeout: 10),
            "probe did not start")
        return app
    }

    private func result(_ app: XCUIApplication) -> String {
        app.staticTexts["dup_probe_result"].label
    }

    func testDriverResolvesAnInteractiveElementPastTheBound() throws {
        guard ProcessInfo.processInfo.environment["DUPLICATE_ID_PROBE"] == "1" else {
            throw XCTSkip("duplicate-identifier probe: run with the guard lifted, as the other probes are")
        }
        let app = launch()

        let matches = app.descendants(matching: .any).matching(identifier: sharedIdentifier)
        let total = matches.count

        // ---- fixture self-checks: does this arm still reach the defect? ----
        // Asserted rather than assumed, because every one of these is a
        // property of SwiftUI's tree that a future OS could change, and a
        // silently-invalid arm would report green against a broken driver.

        XCTAssertEqual(
            total, expectedMatches,
            "FIXTURE: expected \(expectedMatches) elements sharing '\(sharedIdentifier)', found \(total)")

        var buttonIndices: [Int] = []
        var observedTypes: [UInt] = []
        for index in 0..<total {
            let type = matches.element(boundBy: index).elementType
            observedTypes.append(type.rawValue)
            if type == .button { buttonIndices.append(index) }
        }
        print("DUP_PROBE_TYPES total=\(total) types=\(observedTypes) buttonIndices=\(buttonIndices)")

        XCTAssertEqual(
            buttonIndices.count, 1,
            "FIXTURE: expected exactly one interactive row, found \(buttonIndices.count) at \(buttonIndices) "
            + "— more than one and the winner may be within the bound, which cannot fail")
        guard let interactiveIndex = buttonIndices.first else { return }

        XCTAssertGreaterThanOrEqual(
            interactiveIndex, bound,
            "FIXTURE: the interactive row is at index \(interactiveIndex), INSIDE the bound of \(bound) "
            + "— 1.9.6 would find it, so this arm cannot detect the regression")

        let interactive = matches.element(boundBy: interactiveIndex)
        let interactiveFrame = interactive.frame
        let firstFrame = matches.element(boundBy: 0).frame
        print("DUP_PROBE_RESOLUTION_TARGETS interactiveIndex=\(interactiveIndex) "
              + "interactiveFrame=\(interactiveFrame) index0Frame=\(firstFrame)")

        // The two possible resolutions must be geometrically distinct, or
        // "the right one fired" could not be told from "the wrong one did".
        XCTAssertNotEqual(
            interactiveFrame, firstFrame,
            "FIXTURE: the interactive row and index 0 occupy the same frame — the arm cannot discriminate")

        // ---- the measurement ----
        app.buttons["dup_probe_reset"].tap()
        XCTAssertEqual(result(app), "tapped: none", "reset did not take")

        let executor = XCUITestActionExecutor(platform: "ios")
        try executor.execute(step: TestStep(action: "tap", id: sharedIdentifier), in: app)

        let fired = result(app)
        print("DUP_PROBE_RESULT \(fired)")

        // Every row reports its own index, so a wrong resolution names the
        // element the driver picked instead of leaving silence.
        XCTAssertEqual(
            fired, "tapped: row\(interactiveIndex)",
            "DRIVER: tap on '\(sharedIdentifier)' resolved to the wrong element "
            + "(expected the interactive row at index \(interactiveIndex)); "
            + "'tapped: row0' is the 1.9.6 signature — interactive search bounded at \(bound), "
            + "hittable fallback returning the first candidate")

        // elementType and frame of what actually received the tap, which is
        // what the ticket asks to assert rather than a bare pass.
        XCTAssertEqual(interactive.elementType, .button, "DRIVER/FIXTURE: resolved element is not a button")
        XCTAssertTrue(
            interactive.isHittable,
            "the interactive row must be hittable at its own frame for this result to mean what it says")
    }
}
