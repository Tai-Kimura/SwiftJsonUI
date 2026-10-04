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
final class CellDataRefreshProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private func run(argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["cdr_ready"].waitForExistence(timeout: 15), "probe did not start")
        var stale: [String] = []
        for version in 0...2 {
            if version > 0 {
                app.buttons["cdr_bump"].tap()
                sleep(1)
            }
            for prefix in ["A", "K", "T", "N"] {
                for i in 0..<3 {
                    let want = "\(prefix)\(i) v\(version)"
                    let shown = app.staticTexts[want].waitForExistence(timeout: version == 0 ? 10 : 2)
                    print("[CellDataRefresh] \(argument) version \(version) \(["A": "cellIdProperty cellId", "K": "cellIdProperty key", "T": "cellIdProperty cellId + autoChangeTrackingId", "N": "no cellIdProperty"][prefix]!) cell \(i): \(want) \(shown ? "shown" : "NOT SHOWN")")
                    if !shown { stale.append(want) }
                }
            }
        }
        XCTAssertEqual(stale, [], "cells kept their old data after a data change with a fixed key: \(stale)")
    }

    func testDynamicCellsShowNewDataUnderAFixedKey() throws {
        try XCTSkipIf(codegenHost, "the Dynamic half runs in the Dynamic host")
        run(argument: "-cellDataRefreshProbe")
    }

    func testGeneratedCellsShowNewDataUnderAFixedKey() throws {
        try XCTSkipUnless(codegenHost, "the generated half runs in the codegen host")
        run(argument: "-cellDataRefreshProbeCodegen")
    }
}
