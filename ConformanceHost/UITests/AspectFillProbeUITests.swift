//
//  AspectFillProbeUITests.swift
//  ConformanceHostUITests
//
//  An image stays inside its frame, whatever its contentMode
//  (AspectFillProbeView). Two measures per case:
//  - the frame is its declared size and the label after it starts where the
//    frame ends: the image did not grow its frame (the ticket's iPad pane
//    squeezed to ~100pt);
//  - the pixel just outside the frame (below a box, right of a spine) is not
//    one of the sample's four colours: nothing was drawn over the neighbour
//    (the ticket's spine texture covering the page).
//  The Dynamic half always; the generated half in the codegen host only.
//  NOT opt-in.
//

import XCTest
import UIKit

final class AspectFillProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    // conformance_sample's four quadrants
    private let sampleColours: [(Int, Int, Int)] = [(220, 60, 60), (60, 160, 220), (60, 200, 120), (240, 200, 60)]

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func pixel(_ image: UIImage, atPoint p: CGPoint) -> (Int, Int, Int)? {
        guard let cg = image.cgImage else { return nil }
        let scale = CGFloat(cg.width) / image.size.width
        let x = Int(p.x * scale), y = Int(p.y * scale)
        guard x >= 0, y >= 0, x < cg.width, y < cg.height,
              let data = cg.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else { return nil }
        let bpp = cg.bitsPerPixel / 8
        let o = y * cg.bytesPerRow + x * bpp
        let first = cg.bitmapInfo.rawValue & CGBitmapInfo.byteOrderMask.rawValue == CGBitmapInfo.byteOrder32Little.rawValue
        return first ? (Int(bytes[o + 2]), Int(bytes[o + 1]), Int(bytes[o])) : (Int(bytes[o]), Int(bytes[o + 1]), Int(bytes[o + 2]))
    }

    private func isSample(_ c: (Int, Int, Int)?) -> Bool {
        guard let c else { return false }
        return sampleColours.contains { abs($0.0 - c.0) + abs($0.1 - c.1) + abs($0.2 - c.2) < 60 }
    }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["af_ready"].waitForExistence(timeout: 15), "probe did not start")
        let shot = app.screenshot()
        // (case, declared frame, the neighbour is below — else to the right)
        let cases: [(String, CGSize, Bool)] = [
            ("img_fill", CGSize(width: 120, height: 60), true), ("img_fit", CGSize(width: 120, height: 60), true),
            ("img_center", CGSize(width: 120, height: 60), true), ("net_fill", CGSize(width: 120, height: 60), true),
            ("circle_fill", CGSize(width: 120, height: 60), true),
            ("spine_fill", CGSize(width: 16, height: 60), false), ("spine_center", CGSize(width: 16, height: 60), false),
            ("grow", CGSize(width: 100, height: 160), false)
        ]
        var lines: [String] = []
        for (key, size, below) in cases {
            // The marker gives the frame's declared top and start; the frame's
            // own element reports the union with what its child draws.
            let top = element(app, "\(p)_af_\(key)_top").frame
            let after = element(app, "\(p)_af_\(key)_after").frame
            let image = element(app, "\(p)_af_\(key)_img").frame
            let start = CGPoint(x: top.minX, y: top.maxY)
            // How far the neighbour sits from the frame's start: the frame's
            // laid-out size along the axis the neighbour follows.
            let laidOut = below ? after.minY - start.y : after.minX - start.x
            // A pixel in empty space just past the declared frame: below a box
            // (right of the "after" label's text), right of a spine (below its label).
            let probe = below ? CGPoint(x: start.x + size.width - 6, y: start.y + size.height + 12)
                              : CGPoint(x: start.x + size.width + 4, y: start.y + size.height - 8)
            let outside = pixel(shot.image, atPoint: probe)
            lines.append("\(p)_af_\(key): laid out \(Int(laidOut)) (declared \(Int(below ? size.height : size.width))) " +
                         "image element \(Int(image.width))x\(Int(image.height)) outside-pixel \(outside.map { "\($0)" } ?? "nil") sample=\(isSample(outside))")
            XCTAssertEqual(laidOut, below ? size.height : size.width, accuracy: 2, "\(p)_af_\(key): the image grew its frame")
            XCTAssertFalse(isSample(outside), "\(p)_af_\(key): the image is drawn outside its frame")
        }
        lines.forEach { print("AFP \($0)") }
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = "aspect_fill_\(p)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testAnImageStaysInsideItsFrameDynamic() throws {
        run(prefix: "dyn", argument: "-aspectFillProbe")
    }

    func testAnImageStaysInsideItsFrameGenerated() throws {
        try XCTSkipUnless(codegenHost, "the generated half runs in the codegen host")
        run(prefix: "cg", argument: "-aspectFillProbeCodegen")
    }
}
