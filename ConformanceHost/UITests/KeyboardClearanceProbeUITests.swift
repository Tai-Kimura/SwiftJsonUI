//
//  KeyboardClearanceProbeUITests.swift
//  ConformanceHostUITests
//
//  Opt-in: TEST_RUNNER_KEYBOARD_CLEARANCE_PROBE=1 in the xcodebuild process
//  environment, with the `test` action.
//
//  Measures the clearance a focused field keeps from the ScrollView's
//  visible bottom while the keyboard is up, for the two shapes
//  KeyboardClearanceProbeView builds (footer / bare) and for two padding
//  values, so the number FOLLOWS the configuration rather than merely being
//  non-zero. Reported 2026-09-22: the clearance was 0 — negative for a
//  decorated field — whatever `additionalPadding` said, because nothing in
//  the library applied it (see AdvancedKeyboardAvoidingScrollView).
//
//  The measured field is the TextField's own frame (the text area SwiftUI
//  aligns), not its decorated container; the container's own overhang is
//  what the padding has to cover on the reporting screen.
//

import XCTest

final class KeyboardClearanceProbeUITests: XCTestCase {

    private struct Reading {
        let shape: String
        let padding: Double
        let fieldBottom: Double
        let edge: Double
        var clearance: Double { edge - fieldBottom }
    }

    /// Reads (field bottom, edge) every 0.25 s until the field has held its
    /// place for 1 s (within 0.5 pt), at most `settleBudget`. A fixed
    /// `sleep(2)` read wherever the field was at 2 s: on the CI runner (Xcode
    /// 26.3, iOS 26.2; run 38322592393, the first time this probe ran in CI)
    /// four of eight readings were short of the padding — one by all of it —
    /// with the keyboard and the footer in the same place every time. Read
    /// once it holds still, a short value is the field's resting place (the
    /// library's), not a moment of its travel. Returns the readings, the time
    /// it held from, and whether it held within the budget.
    private func settle(field: XCUIElement, edge: () -> Double) -> (fieldBottom: Double, edge: Double, series: [String], heldAt: Double?) {
        let interval: useconds_t = 250_000
        let start = Date()
        var series: [String] = []
        var heldSince: Date?
        var last: Double?
        while Date().timeIntervalSince(start) < settleBudget {
            let bottom = field.frame.maxY
            let e = edge()
            let t = Date().timeIntervalSince(start)
            series.append(String(format: "%.2f:%.1f", t, e - bottom))
            if let l = last, abs(bottom - l) <= 0.5 {
                if heldSince == nil { heldSince = Date() }
                if Date().timeIntervalSince(heldSince!) >= 1 {
                    return (bottom, e, series, heldSince!.timeIntervalSince(start))
                }
            } else {
                heldSince = nil
            }
            last = bottom
            usleep(interval)
        }
        return (field.frame.maxY, edge(), series, nil)
    }

    /// Long enough for a slow runner's scroll; far from the 1 s it must hold.
    private let settleBudget: TimeInterval = 15

    private var runtime: String {
        ProcessInfo.processInfo.environment["SIMULATOR_RUNTIME_VERSION"] ?? "unknown"
    }

    private func measure(shape: String, padding: Double) throws -> Reading {
        let app = XCUIApplication()
        app.launchArguments = ["-keyboardClearanceProbe", shape, "-keyboardClearancePadding", String(padding)]
        app.launch()
        let field = app.textFields["probe_field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10), "probe did not start")
        field.tap()
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 10),
            "no software keyboard — on a simulator with a hardware keyboard attached the probe cannot measure")
        // The visible bottom. Footer shape: the ScrollView's frame ends at
        // the footer's top (SwiftUI shrinks the frame to the safe area the
        // footer leaves). Bare shape: the frame does NOT shrink — the
        // keyboard becomes an inset inside it — and XCUITest's keyboard
        // element starts 45pt below the edge the scroll view actually
        // stops at (the QuickType bar is keyboard for the safe area, not
        // for the element's frame). So the bare shape is measured against
        // the keyboard element and read RELATIVELY: the field must sit
        // `padding + B` above it with B the same for every padding.
        let footer = app.otherElements["probe_footer"]
        if shape == "footer" { XCTAssertTrue(footer.exists, "footer missing") }
        let held = settle(field: field) { shape == "footer" ? footer.frame.minY : keyboard.frame.minY }
        print("KEYBOARD_CLEARANCE_SERIES runtime=\(runtime) shape=\(shape) padding=\(padding) heldAt=\(held.heldAt.map { String(format: "%.2f", $0) } ?? "never") \(held.series.joined(separator: " "))")
        XCTAssertNotNil(held.heldAt, "\(shape) \(padding): the field did not hold still within \(settleBudget) s")
        let edge = held.edge
        if shape == "footer" {
            XCTAssertEqual(app.scrollViews.firstMatch.frame.maxY, edge, accuracy: 1,
                "the scroll view ends at the footer's top")
        }
        let r = Reading(shape: shape, padding: padding, fieldBottom: held.fieldBottom, edge: edge)
        print("KEYBOARD_CLEARANCE runtime=\(runtime) shape=\(shape) padding=\(padding) fieldBottom=\(r.fieldBottom) edge=\(edge) clearance=\(r.clearance)")
        app.terminate()
        return r
    }

    func testAFocusedFieldKeepsTheConfiguredClearanceFromTheVisibleBottom() throws {
        guard ProcessInfo.processInfo.environment["KEYBOARD_CLEARANCE_PROBE"] == "1" else {
            throw XCTSkip("keyboard clearance probe: set TEST_RUNNER_KEYBOARD_CLEARANCE_PROBE=1 to run")
        }
        // Footer: the clearance IS the configured padding, within a few
        // points of layout rounding (measured 19.7 / 59.7).
        let f20 = try measure(shape: "footer", padding: 20)
        let f60 = try measure(shape: "footer", padding: 60)
        XCTAssertEqual(f20.clearance, 20, accuracy: 4, "footer: clearance at padding 20")
        XCTAssertEqual(f60.clearance, 60, accuracy: 4, "footer: clearance at padding 60")

        // Bare: padding + B above the keyboard element, B constant (the
        // QuickType bar; 45 measured on iOS 26.5, not asserted as a number).
        let b20 = try measure(shape: "bare", padding: 20)
        let b60 = try measure(shape: "bare", padding: 60)
        let bar20 = b20.clearance - 20
        let bar60 = b60.clearance - 60
        print("KEYBOARD_CLEARANCE bare: bar=\(bar20) / \(bar60)")
        XCTAssertGreaterThanOrEqual(bar20, 0, "bare: the field must clear the keyboard by at least the padding")
        XCTAssertEqual(bar20, bar60, accuracy: 4, "bare: the clearance must follow the padding one-for-one")
        XCTAssertEqual(b20.fieldBottom - b60.fieldBottom, 40, accuracy: 4, "bare: 40 more padding moves the field 40 up")
    }
}
