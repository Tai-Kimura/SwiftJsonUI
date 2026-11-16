//
//  EmptyBackgroundProbeUITests.swift
//  ConformanceHostUITests
//
//  An empty View with a background paints its whole box, padding included
//  (EmptyBackgroundProbeView). The painted area is read from the screenshot —
//  the #FFDD00 pixels inside each parent — because no accessibility frame
//  names it. The padded View must paint what the unpadded control paints:
//  100 x 40. NOT opt-in.
//

import XCTest

final class EmptyBackgroundProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// The bounding box, in points, of the #FFDD00 pixels inside `rect` (points).
    private func yellowBox(in rect: CGRect, of image: CGImage, scale: CGFloat) -> CGRect? {
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let x0 = max(0, Int(rect.minX * scale)), x1 = min(width, Int(rect.maxX * scale))
        let y0 = max(0, Int(rect.minY * scale)), y1 = min(height, Int(rect.maxY * scale))
        var minX = Int.max, minY = Int.max, maxX = -1, maxY = -1
        for y in y0..<y1 {
            for x in x0..<x1 {
                let i = (y * width + x) * 4
                let r = pixels[i], g = pixels[i + 1], b = pixels[i + 2]
                if r > 235 && g >= 205 && g <= 235 && b < 40 {
                    minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
                }
            }
        }
        guard maxX >= 0 else { return nil }
        return CGRect(x: CGFloat(minX) / scale, y: CGFloat(minY) / scale,
                      width: CGFloat(maxX - minX + 1) / scale, height: CGFloat(maxY - minY + 1) / scale)
    }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["eb_ready"].waitForExistence(timeout: 15), "probe did not start")
        let screenshot = XCUIScreen.main.screenshot()
        guard let image = screenshot.image.cgImage else { return XCTFail("no screenshot image") }
        let scale = CGFloat(image.width) / app.frame.width
        var lines: [String] = []
        for v in ["nopad", "pad"] {
            let parent = element(app, "\(p)_eb_p_\(v)")
            XCTAssertTrue(parent.waitForExistence(timeout: 5), "\(p)_eb_p_\(v) is not there")
            // The parent's frame is the union of its 0.5pt anchor (its top-left)
            // and its child; widen to the fixed 300 x 60 it is declared as.
            let rect = CGRect(x: parent.frame.minX, y: parent.frame.minY, width: 300, height: 60)
            guard let box = yellowBox(in: rect, of: image, scale: scale) else {
                XCTFail("\(p)_eb_\(v): nothing painted"); continue
            }
            lines.append("\(p)_eb_\(v): painted \(box.width) x \(box.height)")
            XCTAssertEqual(box.width, 100, accuracy: 1, "\(p)_eb_\(v): painted \(box.width) wide")
            XCTAssertEqual(box.height, 40, accuracy: 1, "\(p)_eb_\(v): painted \(box.height) high")
        }
        lines.forEach { print("EBP \($0)") }
        let shot = XCTAttachment(screenshot: screenshot)
        shot.name = "empty_background_\(p)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testAnEmptyViewPaintsItsPaddingDynamic() throws {
        run(prefix: "dyn", argument: "-emptyBackgroundProbe")
    }

    func testAnEmptyViewPaintsItsPaddingGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(prefix: "cg", argument: "-emptyBackgroundProbeCodegen")
    }
}
