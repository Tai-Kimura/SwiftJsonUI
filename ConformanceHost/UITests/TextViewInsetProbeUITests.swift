//
//  TextViewInsetProbeUITests.swift
//  ConformanceHostUITests
//
//  A TextView's `padding` insets its text by the padding, beyond the
//  editor's own inset (8 top and bottom, 5 at the sides), on both paths, and
//  its id box stays the element's box (TextViewInsetProbeView). Read from the
//  screenshot: the dark text pixels inside the yellow box. With `padding: 8`
//  the text starts 3 further right (8 − 5) and at the same height (8 − 8) as
//  without. In the codegen host both halves run, and the generated text
//  starts where the Dynamic text does. NOT opt-in.
//

import XCTest

final class TextViewInsetProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// In points, relative to the yellow box: the yellow box and the top-left
    /// of the dark pixels inside it.
    private func read(_ rect: CGRect, _ image: CGImage, _ scale: CGFloat) -> (box: CGRect, text: CGPoint)? {
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let x0 = max(0, Int(rect.minX * scale)), x1 = min(width, Int(rect.maxX * scale))
        let y0 = max(0, Int(rect.minY * scale)), y1 = min(height, Int(rect.maxY * scale))
        var yb = (Int.max, Int.max, -1, -1), tx = (Int.max, Int.max)
        for y in y0..<y1 {
            for x in x0..<x1 {
                let i = (y * width + x) * 4
                let r = pixels[i], g = pixels[i + 1], b = pixels[i + 2]
                if r > 235 && g >= 205 && g <= 235 && b < 40 {
                    yb = (min(yb.0, x), min(yb.1, y), max(yb.2, x), max(yb.3, y))
                } else if r < 80 && g < 80 && b < 80 {
                    tx = (min(tx.0, x), min(tx.1, y))
                }
            }
        }
        guard yb.2 >= 0, tx.0 != Int.max else { return nil }
        let box = CGRect(x: CGFloat(yb.0) / scale, y: CGFloat(yb.1) / scale,
                         width: CGFloat(yb.2 - yb.0 + 1) / scale, height: CGFloat(yb.3 - yb.1 + 1) / scale)
        return (box, CGPoint(x: CGFloat(tx.0) / scale - box.minX, y: CGFloat(tx.1) / scale - box.minY))
    }

    private func measure(_ app: XCUIApplication, _ p: String, _ image: CGImage, _ scale: CGFloat) -> [String: CGPoint] {
        var out: [String: CGPoint] = [:]
        for v in ["pad", "nopad"] {
            let parent = element(app, "\(p)_tvi_p_\(v)")
            let tv = element(app, "\(p)_tvi_\(v)")
            XCTAssertTrue(tv.waitForExistence(timeout: 5), "\(p)_tvi_\(v) is not there")
            let rect = CGRect(x: parent.frame.minX, y: parent.frame.minY, width: 300, height: 80)
            guard let r = read(rect, image, scale) else { XCTFail("\(p)_tvi_\(v): nothing read"); continue }
            out[v] = r.text
            let idInBox = tv.frame.offsetBy(dx: -r.box.minX, dy: -r.box.minY)
            print(String(format: "TVI %@_tvi_%@: box (%.1f,%.1f) text at (%.2f,%.2f) id (%.1f,%.1f,%.1f,%.1f)",
                         p, v, r.box.width, r.box.height, r.text.x, r.text.y,
                         idInBox.minX, idInBox.minY, idInBox.width, idInBox.height))
            XCTAssertEqual(idInBox.width, r.box.width, accuracy: 0.5, "\(p)_tvi_\(v): id width \(idInBox.width), box \(r.box.width)")
            XCTAssertEqual(idInBox.minX, 0, accuracy: 0.5, "\(p)_tvi_\(v): id starts \(idInBox.minX) into the box")
        }
        if let a = out["pad"], let b = out["nopad"] {
            XCTAssertEqual(a.x - b.x, 3, accuracy: 0.5, "\(p): padding 8 moved the text \(a.x - b.x) across, not 8 − 5")
            XCTAssertEqual(a.y - b.y, 0, accuracy: 0.5, "\(p): padding 8 moved the text \(a.y - b.y) down, not 8 − 8")
        }
        return out
    }

    private func shot(_ argument: String) -> (XCUIApplication, CGImage, CGFloat)? {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["tvi_ready"].waitForExistence(timeout: 15), "probe did not start")
        guard let image = XCUIScreen.main.screenshot().image.cgImage else { XCTFail("no screenshot"); return nil }
        return (app, image, CGFloat(image.width) / app.frame.width)
    }

    func testPaddingInsetsTheTextDynamic() throws {
        guard let (app, image, scale) = shot("-textViewInsetProbe") else { return }
        _ = measure(app, "dyn", image, scale)
    }

    func testPaddingInsetsTheTextGeneratedAsDynamicDoes() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        guard let (dynApp, dynImage, dynScale) = shot("-textViewInsetProbe") else { return }
        let dyn = measure(dynApp, "dyn", dynImage, dynScale)
        dynApp.terminate()
        guard let (app, image, scale) = shot("-textViewInsetProbeCodegen") else { return }
        let cg = measure(app, "cg", image, scale)
        for v in ["pad", "nopad"] {
            guard let a = cg[v], let b = dyn[v] else { continue }
            XCTAssertEqual(a.x, b.x, accuracy: 0.5, "\(v): generated text at x \(a.x), Dynamic \(b.x)")
            XCTAssertEqual(a.y, b.y, accuracy: 0.5, "\(v): generated text at y \(a.y), Dynamic \(b.y)")
        }
    }
}
