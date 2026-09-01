//
//  ConfirmationDialogProbeUITests.swift
//  ConformanceHostUITests
//
//  Records what a `.confirmationDialog` and an `.alert` actually draw, in
//  whatever size class the running device reports. See
//  ConfirmationDialogProbeView for why this is being measured rather than
//  reasoned about.
//
//  This test does not fail when the cancel is missing. A missing cancel is
//  the finding, not a defect in the host — so the run PRINTS the counts and
//  asserts only the things that would mean the probe itself did not work:
//  that the dialog opened at all, and that the control arm behaved.
//

import XCTest

final class ConfirmationDialogProbeUITests: XCTestCase {

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-confirmationDialogProbe"]
        app.launch()
        return app
    }

    /// A dialog's buttons are not children of the app's main window in every
    /// idiom — a popover puts them in their own hierarchy — so both are
    /// searched, and the search is by identifier rather than by label so a
    /// localized cancel cannot be missed.
    private func present(_ app: XCUIApplication, opening identifier: String)
        -> (destructive: Bool, cancel: Bool) {
        XCTAssertTrue(app.buttons[identifier].waitForExistence(timeout: 10),
                      "probe did not launch: \(identifier) never appeared")
        app.buttons[identifier].tap()

        let destructive = app.buttons["probe_destructive"]
        XCTAssertTrue(destructive.waitForExistence(timeout: 5),
                      "nothing was presented for \(identifier)")
        // Settle: the cancel, if it is drawn at all, is drawn with the rest.
        let cancel = app.buttons["probe_cancel"]
        _ = cancel.waitForExistence(timeout: 2)
        return (destructive.exists, cancel.exists)
    }

    func testWhatEachPresentationDraws() {
        let app = launch()
        let sizeClass = app.staticTexts["probe_size_class"].label

        let dialog = present(app, opening: "probe_open_dialog")
        // Dismiss before the second arm: a presented dialog swallows taps.
        if dialog.cancel {
            app.buttons["probe_cancel"].tap()
        } else {
            app.tap()
        }

        let alert = present(app, opening: "probe_open_alert")

        print("""
        PROBE-RESULT size_class=\(sizeClass) \
        dialog_destructive=\(dialog.destructive) dialog_cancel=\(dialog.cancel) \
        alert_destructive=\(alert.destructive) alert_cancel=\(alert.cancel)
        """)

        // The only assertions are about the instrument. `.alert` draws every
        // button in both idioms, so an alert arm that lost its cancel means
        // this test is measuring something other than what it claims.
        XCTAssertTrue(alert.destructive,
                      "control arm broken: .alert lost its destructive button")
        XCTAssertTrue(alert.cancel,
                      "control arm broken: .alert lost its cancel button — "
                      + "the probe is not measuring presentation")
    }
}
