import XCTest

/// CellDataRefreshProbeView: a cell whose key stays fixed while its data
/// changes shows the new data. Taps bump twice and reads every cell's title
/// in both Collections — cellIdProperty "cellId" (the consumer's shape) and
/// cellIdProperty "key" (no "cellId" in the data: the control) and
/// cellIdProperty "cellId" with autoChangeTrackingId (the enriched route) and
/// no cellIdProperty with no key in the data (the unkeyed route). Prints every
/// reading, so a red names which list kept which title.
///
/// Measured 2026-10-04 (iOS 26.5, Xcode 26.6), cells showing the new title
/// after bump: the generated half with jsonui-cli v1.9.10 — (A) 0 of 6,
/// (B) 6 of 6, (C) 6 of 6; with the cell call sites handing a rewritten
/// "cellId" (jsonui-cli ticket ios-cell-ignores-data-change-when-cellid-is-
/// fixed-android-updates) 6 of 6 on all three, and (A) 0 of 6 again with
/// that rewrite removed. The Dynamic half: 18 of 18 on (A) and (B) before the
/// change — DynamicView draws the data it is handed.
///
/// (D), no cellIdProperty and no key in the data, measured 2026-10-04 (the
/// same tools): 6 of 6 on the generated half with jsonui-cli v1.9.10 and with
/// v1.9.11, and 6 of 6 on the Dynamic half; (C) on the Dynamic half 6 of 6.
///
/// A red bump step reports what the tap met (TapDiagnosis): CI run
/// 37206310365 saw the second bump change none of the 12 cells, the control
/// lists included, and kept nothing that told an undelivered touch from a
/// drawing that did not answer (jsonui-cli ticket
/// ios-dynamic-interactive-fixture-tap-not-delivered-intermittently).
final class CellDataRefreshProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    /// The N of the probe's "version N" label, or nil when it cannot be read.
    private func shownVersion(_ app: XCUIApplication) -> Int? {
        let label = app.staticTexts["cdr_version"].label
        return Int(label.replacingOccurrences(of: "version ", with: ""))
    }

    private func run(argument: String, name: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["cdr_ready"].waitForExistence(timeout: 15), "probe did not start")
        var stale: [String] = []
        var diagnosis: [String] = []
        for version in 0...2 {
            let versionBefore = shownVersion(app)
            let bumpBefore = TapDiagnosis.elementState("cdr_bump", in: app)
            if version > 0 {
                app.buttons["cdr_bump"].tap()
                sleep(1)
            }
            var staleNow: [String] = []
            for prefix in ["A", "K", "T", "N"] {
                for i in 0..<3 {
                    let want = "\(prefix)\(i) v\(version)"
                    let shown = app.staticTexts[want].waitForExistence(timeout: version == 0 ? 10 : 2)
                    print("[CellDataRefresh] \(argument) version \(version) \(["A": "cellIdProperty cellId", "K": "cellIdProperty key", "T": "cellIdProperty cellId + autoChangeTrackingId", "N": "no cellIdProperty"][prefix]!) cell \(i): \(want) \(shown ? "shown" : "NOT SHOWN")")
                    if !shown { staleNow.append(want) }
                }
            }
            stale += staleNow
            // After a bump whose cells did not all change: what the tap met and
            // what it did (TapDiagnosis, the fixture runner's words). The
            // "version N" label separates the two readings of a red step — the
            // version went up and the cells stayed (the touch was delivered,
            // the drawing did not answer), or the version stayed (the touch did
            // not reach the app). bump is not idempotent, so the second tap is
            // judged by its OWN effect, the version going up again, and the
            // run stops there: the versions after it would not line up.
            if version > 0 && !staleNow.isEmpty {
                var detail = "bump to v\(version): version shown before \(versionBefore.map(String.init) ?? "?"), after \(shownVersion(app).map(String.init) ?? "?")"
                detail += "; cdr_bump before the tap: \(bumpBefore); now: \(TapDiagnosis.elementState("cdr_bump", in: app))"
                do {
                    detail += "; screenshot \(try TapDiagnosis.screenshot(named: "\(name)__post_tap_failure_v\(version)", app: app))"
                } catch {
                    detail += "; no screenshot (\(TapDiagnosis.shortError(error)))"
                }
                let beforeRetap = shownVersion(app)
                detail += "; " + TapDiagnosis.secondTap({ app.buttons["cdr_bump"].tap() }, effectShows: {
                    for _ in 0..<6 {
                        if let now = self.shownVersion(app), let was = beforeRetap, now > was { return nil }
                        usleep(500_000)
                    }
                    return "version stayed at \(self.shownVersion(app).map(String.init) ?? "?")"
                })
                print("[CellDataRefresh] \(argument) \(detail)")
                diagnosis.append(detail)
                break
            }
        }
        XCTAssertEqual(stale, [], "cells kept their old data after a data change with a fixed key: \(stale)\(diagnosis.isEmpty ? "" : " — " + diagnosis.joined(separator: " | "))")
    }

    func testDynamicCellsShowNewDataUnderAFixedKey() throws {
        try XCTSkipIf(codegenHost, "the Dynamic half runs in the Dynamic host")
        run(argument: "-cellDataRefreshProbe", name: "CellDataRefreshProbe_dynamic")
    }

    func testGeneratedCellsShowNewDataUnderAFixedKey() throws {
        try XCTSkipUnless(codegenHost, "the generated half runs in the codegen host")
        run(argument: "-cellDataRefreshProbeCodegen", name: "CellDataRefreshProbe_generated")
    }
}
