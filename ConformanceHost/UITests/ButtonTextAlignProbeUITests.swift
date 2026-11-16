//
//  ButtonTextAlignProbeUITests.swift
//  ConformanceHostUITests
//
//  A Button's text is placed across it by textAlign (ButtonTextAlignProbeView):
//  Left at the start and Right at the end of a 200pt and a matchParent
//  button; Center, none and a gravity left in the middle. Read from the
//  button's pixels: the dark (text) columns' margins. The Dynamic half
//  always; the generated half in the codegen host only. NOT opt-in.
//

import XCTest

final class ButtonTextAlignProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    /// The columns (in points) left and right of the dark pixels of an
    /// element's screenshot, and its width; nil when it has none.
    private func inkMargins(_ element: XCUIElement) -> (left: CGFloat, right: CGFloat, width: CGFloat)? {
        guard let cg = element.screenshot().image.cgImage else { return nil }
        let w = cg.width, h = cg.height
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        var first = -1, last = -1
        for x in 0..<w {
            var ink = false
            for y in 0..<h {
                let i = (y * w + x) * 4
                if Int(pixels[i]) + Int(pixels[i + 1]) + Int(pixels[i + 2]) < 200 { ink = true; break }
            }
            if ink { if first < 0 { first = x }; last = x }
        }
        guard first >= 0 else { return nil }
        let scale = CGFloat(w) / element.frame.width
        return (CGFloat(first) / scale, CGFloat(w - 1 - last) / scale, element.frame.width)
    }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["bt_ready"].waitForExistence(timeout: 15), "probe did not start")
        var lines: [String] = []
        for (row, want) in [
            ("w200_left", "start"),
            ("w200_right", "end"),
            ("mw_left", "start"),
            ("mw_right", "end"),
            ("w200_center", "centre"),
            ("w200_none", "centre"),
            ("w200_gravity_left", "centre")
        ] {
            let button = app.buttons.matching(identifier: "\(p)_bt_\(row)_button").firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 5), "\(p)_bt_\(row) is not drawn")
            guard let m = inkMargins(button) else { XCTFail("\(p)_bt_\(row): no text drawn"); continue }
            lines.append("\(p)_bt_\(row): button \(Int(m.width))pt, text \(String(format: "%.1f", m.left)) from the start, \(String(format: "%.1f", m.right)) from the end")
            XCTAssertGreaterThan(m.width, 150, "\(p)_bt_\(row): the button is not wide")
            switch want {
            case "start": XCTAssertLessThan(m.left, 6, "\(p)_bt_\(row): the text is not at the start")
            case "end": XCTAssertLessThan(m.right, 6, "\(p)_bt_\(row): the text is not at the end")
            default: XCTAssertEqual(m.left, m.right, accuracy: 3, "\(p)_bt_\(row): the text is not in the middle")
            }
        }
        lines.forEach { print("BTP \($0)") }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "button_text_align_\(p)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testAButtonsTextIsPlacedByTextAlignDynamic() throws {
        run(prefix: "dyn", argument: "-buttonTextAlignProbe")
    }

    func testAButtonsTextIsPlacedByTextAlignGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(prefix: "cg", argument: "-buttonTextAlignProbeCodegen")
    }
}
