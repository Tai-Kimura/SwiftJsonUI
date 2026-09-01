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

    /// Is the missing cancel a dead end, or only a missing label?
    ///
    /// A popover is supposed to be dismissable by tapping outside it, and if
    /// that works the user is not trapped — the defect is "the only visible
    /// choice is the destructive one", not "there is no way out". Those are
    /// different severities and a consumer deciding how long it can wait for
    /// a fix needs the difference measured, not assumed.
    ///
    /// The destructive tap counter is what separates "closed" from "closed
    /// after doing the thing".
    func testWhetherTappingOutsideEscapesWithoutFiring() {
        let app = launch()
        let sizeClass = app.staticTexts["probe_size_class"].label

        XCTAssertTrue(app.buttons["probe_open_dialog"].waitForExistence(timeout: 10))
        app.buttons["probe_open_dialog"].tap()
        XCTAssertTrue(app.buttons["probe_destructive"].waitForExistence(timeout: 5),
                      "nothing was presented")

        // THE COORDINATE TAP WAS THE INSTRUMENT'S DEFECT. A raw
        // app.coordinate tap dismissed nothing in any arm — not even a
        // medium sheet, which outside-taps are documented to dismiss — so
        // "did not close" was unreadable. The hierarchy names the real
        // target: presentation puts a full-screen Other element labelled
        // 'dismiss popup' (identifier PopoverDismissRegion) behind the
        // popover, and that ELEMENT is what an outside tap means. Falling
        // back to the coordinate keeps the compact arm honest, where the
        // region may not exist.
        let dismissRegion = app.otherElements["PopoverDismissRegion"]
        let usedRegion = dismissRegion.exists
        if usedRegion {
            dismissRegion.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.02)).tap()
        }

        // `waitForExistence` returns immediately when the element is already
        // there, so this is "still present after the tap", not a 3s wait.
        let closed = !app.buttons["probe_destructive"]
            .waitForExistence(timeout: 3)
        let firedAfterOutsideTap =
            app.staticTexts["probe_destructive_fired"].label

        // POSITIVE CONTROL, IN THE SAME RUN. "did not close" and "this test
        // cannot see a close" produce the same false, so something that must
        // close it is tried next. Without this the first measurement is
        // unreadable — and it came back false on BOTH size classes, including
        // the one where a cancel button is drawn and the sheet is expected to
        // dismiss, which is exactly the shape of an instrument that never
        // detects a dismissal at all.
        var controlClosed = true
        if !closed {
            app.buttons["probe_destructive"].tap()
            controlClosed = !app.buttons["probe_destructive"]
                .waitForExistence(timeout: 3)
        }

        print("PROBE-ESCAPE size_class=\(sizeClass) "
              + "via_dismiss_region=\(usedRegion) "
              + "closed_on_outside_tap=\(closed) "
              + "destructive_fired=\(firedAfterOutsideTap) "
              + "CONTROL_closed_on_button_tap=\(controlClosed)")

        XCTAssertTrue(controlClosed,
                      "control failed: the dialog did not close even when a "
                      + "button in it was tapped, so this test cannot "
                      + "distinguish 'does not dismiss' from 'cannot see a "
                      + "dismissal' — the outside-tap result means nothing")

        // Asserted, because a dismissal that ran the destructive action would
        // be a far worse finding than the one being investigated, and must
        // not be reported as a print line someone may skim past.
        XCTAssertEqual(firedAfterOutsideTap, "0",
                       "tapping outside fired the destructive action")
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
