//
//  DirectionStartEdgeTests.swift
//  SwiftJsonUITests
//
//  A reversed stack starts at the edge its direction starts from:
//  `bottomToTop` puts the first child at the BOTTOM of the column, and
//  `rightToLeft` at the RIGHT of the row (user ruling 2026-10-05,
//  attribute_semantics stackDirection). Dynamic reversed the children and
//  laid them from the top / left, so in a 200 column of 40s the first child
//  sat below the content's top, nowhere near the bottom edge (conformance
//  host pixels, View/direction__bottomtotop and __righttoleft; ticket
//  sjui-a-reversed-stack-starts-at-the-top-not-at-its-start-edge).
//
//  The first child is red, the second blue; each is looked for in a drawing
//  of the container at the origin.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class DirectionStartEdgeTests: XCTestCase {

    private func layout(orientation: String, direction: String, gravity: String = "") -> String {
        return """
        { "type": "View", "id": "root", "width": "matchParent", "height": "matchParent",
          "child": [
            { "type": "View", "id": "stack", "orientation": "\(orientation)", "direction": "\(direction)",
              \(gravity)"width": 200, "height": 200, "background": "#FFFFFF",
              "child": [
                { "type": "View", "id": "box_a", "width": 40, "height": 40, "background": "#FF0000" },
                { "type": "View", "id": "box_b", "width": 40, "height": 40, "background": "#0000FF" }
              ] }
          ] }
        """
    }

    @MainActor
    func testBottomToTopStartsAtTheBottom() throws {
        let image = try draw(layout(orientation: "vertical", direction: "bottomToTop"))
        XCTAssertEqual(span(image, rgb: (255, 0, 0), vertical: true), 160..<200, "the first child is not at the bottom")
        XCTAssertEqual(span(image, rgb: (0, 0, 255), vertical: true), 120..<160, "the second child is not above it")
    }

    @MainActor
    func testRightToLeftStartsAtTheRight() throws {
        let image = try draw(layout(orientation: "horizontal", direction: "rightToLeft"))
        XCTAssertEqual(span(image, rgb: (255, 0, 0), vertical: false), 160..<200, "the first child is not at the right")
        XCTAssertEqual(span(image, rgb: (0, 0, 255), vertical: false), 120..<160, "the second child is not left of it")
    }

    /// A gravity naming the main axis still decides it.
    @MainActor
    func testAGravityOnTheMainAxisStillDecides() throws {
        let image = try draw(layout(orientation: "vertical", direction: "bottomToTop", gravity: #""gravity": "top", "#))
        XCTAssertEqual(span(image, rgb: (255, 0, 0), vertical: true), 40..<80, "top gravity: the first child is under the second")
        XCTAssertEqual(span(image, rgb: (0, 0, 255), vertical: true), 0..<40)
    }

    @MainActor
    private func draw(_ json: String) throws -> CGImage {
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        let host = UIHostingController(rootView: DynamicComponentBuilder(component: component, data: [:], viewId: nil)
            .frame(width: 390, height: 500, alignment: .topLeading)
            .background(Color.white))
        // The window's safe area would push the drawing down (31 measured).
        if #available(iOS 16.4, *) { host.safeAreaRegions = [] }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 500))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: host.view.bounds, format: format).image { context in
            host.view.layer.render(in: context.cgContext)
        }
        window.isHidden = true
        return try XCTUnwrap(image.cgImage)
    }

    /// The rows (vertical) or columns holding a pixel within ±2 of the RGB.
    private func span(_ image: CGImage, rgb: (Int, Int, Int), vertical: Bool) -> Range<Int>? {
        let width = image.width, height = image.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let ctx = CGContext(data: &buffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        var hits: [Int] = []
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                if abs(Int(buffer[i]) - rgb.0) <= 2 && abs(Int(buffer[i + 1]) - rgb.1) <= 2 && abs(Int(buffer[i + 2]) - rgb.2) <= 2 {
                    hits.append(vertical ? y : x)
                }
            }
        }
        guard let lo = hits.min(), let hi = hits.max() else { return nil }
        return lo..<(hi + 1)
    }
}
#endif // DEBUG
