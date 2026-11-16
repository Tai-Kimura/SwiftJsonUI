//
//  LabelVerticalProbeUITests.swift
//  ConformanceHostUITests
//
//  A Label's text in a box taller than it sits at the vertical its gravity
//  names, else at the centre (LabelVerticalProbeView). Read from the row's
//  pixels: the band of dark (text) pixels, its top and bottom margin.
//  Changed rows: mw_top / ww_top at the top and mw_bottom at the bottom (they
//  were centred); w200_left / w200_right centred (they were at the top);
//  w200_bottom at the bottom and w200_cv centred (Dynamic: at the top);
//  fill_none and minh_none centred (they were at the top). Controls: mw_none
//  centred, w200_top at the top, w200_center_tac centred. The Dynamic half
//  always; the generated half in the codegen host only. NOT opt-in.
//

import XCTest

final class LabelVerticalProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    /// The rows (in points) above and below the dark pixels of an element's
    /// screenshot, and its height; nil when it has none.
    private func inkMargins(_ element: XCUIElement) -> (top: CGFloat, bottom: CGFloat, height: CGFloat)? {
        guard let cg = element.screenshot().image.cgImage else { return nil }
        let w = cg.width, h = cg.height
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        var first = -1, last = -1
        for y in 0..<h {
            var ink = false
            for x in 0..<w {
                let i = (y * w + x) * 4
                if Int(pixels[i]) + Int(pixels[i + 1]) + Int(pixels[i + 2]) < 200 { ink = true; break }
            }
            if ink { if first < 0 { first = y }; last = y }
        }
        guard first >= 0 else { return nil }
        let scale = CGFloat(h) / element.frame.height
        return (CGFloat(first) / scale, CGFloat(h - 1 - last) / scale, element.frame.height)
    }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["lv_ready"].waitForExistence(timeout: 15), "probe did not start")
        var lines: [String] = []
        for (row, want) in [
            ("mw_top", "top"),
            ("mw_bottom", "bottom"),
            ("ww_top", "top"),
            ("w200_left", "center"),
            ("w200_right", "center"),
            ("w200_bottom", "bottom"),
            ("w200_cv", "center"),
            ("fill_none", "center"),
            ("minh_none", "center"),
            ("mw_none", "center"),
            ("w200_top", "top"),
            ("w200_center_tac", "center")
        ] {
            let box = app.descendants(matching: .any).matching(identifier: "\(p)_lv_\(row)").firstMatch
            XCTAssertTrue(box.waitForExistence(timeout: 5), "\(p)_lv_\(row) is not drawn")
            guard let m = inkMargins(box) else { XCTFail("\(p)_lv_\(row): no text drawn"); continue }
            lines.append("\(p)_lv_\(row): row \(Int(m.height))pt, text \(String(format: "%.1f", m.top)) from the top, \(String(format: "%.1f", m.bottom)) from the bottom")
            XCTAssertGreaterThan(m.height, 40, "\(p)_lv_\(row): the row is not taller than its text")
            switch want {
            case "top": XCTAssertLessThan(m.top, 8, "\(p)_lv_\(row): the text is not at the top")
            case "bottom": XCTAssertLessThan(m.bottom, 8, "\(p)_lv_\(row): the text is not at the bottom")
            default: XCTAssertEqual(m.top, m.bottom, accuracy: 3, "\(p)_lv_\(row): the text is not centred vertically")
            }
        }
        lines.forEach { print("LVP \($0)") }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "label_vertical_\(p)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testALabelsTextSitsAtItsGravitysVerticalElseTheCentreDynamic() throws {
        run(prefix: "dyn", argument: "-labelVerticalProbe")
    }

    func testALabelsTextSitsAtItsGravitysVerticalElseTheCentreGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(prefix: "cg", argument: "-labelVerticalProbeCodegen")
    }
}
