//
//  LeafGravityProbeUITests.swift
//  ConformanceHostUITests
//
//  A leaf's partial gravity fixes only its own axis (LeafGravityProbeView):
//  a TextField's text centred vertically in a 44pt frame with gravity left,
//  on a frame that sizes one axis and on one that sizes both; a Button's
//  (gravity left or center) and a Label's as before, centred. Read from
//  the row's pixels: the band of dark (text) pixels, top and bottom margin.
//  The Dynamic half always; the generated half in the codegen host only.
//  NOT opt-in.
//

import XCTest

final class LeafGravityProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    /// The rows (in points) above and below the dark pixels of an element's
    /// screenshot, and its height; nil when it has none.
    private func inkMargins(_ element: XCUIElement) -> (top: CGFloat, bottom: CGFloat, height: CGFloat)? {
        let image = element.screenshot().image
        guard let cg = image.cgImage else { return nil }
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
        XCTAssertTrue(app.staticTexts["lg_ready"].waitForExistence(timeout: 15), "probe did not start")
        var lines: [String] = []
        // every row: the text centred vertically
        for row in ["tf_mw_h_left", "tf_w_h_left", "btn_mw_h_left", "btn_w_h_left", "btn_mw_h_center", "label_mw_h_left"] {
            let box = app.descendants(matching: .any).matching(identifier: "\(p)_lg_\(row)").firstMatch
            XCTAssertTrue(box.waitForExistence(timeout: 5), "\(p)_lg_\(row) is not drawn")
            guard let m = inkMargins(box) else { XCTFail("\(p)_lg_\(row): no text drawn"); continue }
            lines.append("\(p)_lg_\(row): row \(Int(m.height))pt, text \(String(format: "%.1f", m.top)) from the top, \(String(format: "%.1f", m.bottom)) from the bottom")
            XCTAssertEqual(m.height, 44, accuracy: 2, "\(p)_lg_\(row): the row is not the leaf's 44pt")
            XCTAssertEqual(m.top, m.bottom, accuracy: 3, "\(p)_lg_\(row): the text is not centred vertically")
        }
        lines.forEach { print("LGP \($0)") }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "leaf_gravity_\(p)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testALeafsPartialGravityKeepsTheOtherAxisCentredDynamic() throws {
        run(prefix: "dyn", argument: "-leafGravityProbe")
    }

    func testALeafsPartialGravityKeepsTheOtherAxisCentredGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(prefix: "cg", argument: "-leafGravityProbeCodegen")
    }
}
