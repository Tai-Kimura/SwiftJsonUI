//
//  HorizontalScrollCrossAxisTests.swift
//  SwiftJsonUITests
//
//  A horizontal ScrollView starts its content at the top of its cross axis.
//  SwiftUI centres content of any other height on a horizontal scroll's cross
//  axis: the conformance content (600 high in a 200-high ScrollView) drew at
//  y -200, where the declaration (attribute_semantics gravityDefaults:
//  top|start on every container) and web put it at y 0 (frame-parity,
//  2026-10-05; ticket sjui-horizontal-scrollview-centres-its-content-on-the-cross-axis).
//
//  Both routes draw through AdvancedKeyboardAvoidingScrollView: Dynamic's
//  ScrollView container and the sjui codegen's emit. Each is drawn here and
//  the content's top stripe is looked for at the top of the viewport —
//  centred, the stripe sits 200 above it and is not on the canvas at all.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class HorizontalScrollCrossAxisTests: XCTestCase {

    // A 600-high content whose top 20 is blue; the rest is red.
    private let layout = """
    {
      "type": "View", "id": "root", "width": "matchParent", "height": "matchParent",
      "child": [
        { "type": "ScrollView", "id": "target", "width": 200, "height": 200,
          "background": "#DDDDDD", "horizontalScroll": true,
          "child": [
            { "type": "View", "id": "content", "orientation": "vertical", "width": 150, "height": 600,
              "background": "#FF0000",
              "child": [ { "type": "View", "id": "stripe", "width": 150, "height": 20, "background": "#0000FF" } ] }
          ] }
      ]
    }
    """

    @MainActor
    func testDynamicHorizontalScrollStartsItsContentAtTheTop() throws {
        let component = try JSONDecoder().decode(DynamicComponent.self, from: layout.data(using: .utf8)!)
        try assertStripeAtTheTop(AnyView(DynamicComponentBuilder(component: component, data: [:], viewId: nil)),
                                 route: "Dynamic")
    }

    /// The shape scrollview_converter.rb emits for a horizontal ScrollView.
    @MainActor
    func testCodegenHorizontalScrollStartsItsContentAtTheTop() throws {
        let view = AdvancedKeyboardAvoidingScrollView(.horizontal, showsIndicators: true) {
            VStack(spacing: 0) {
                Rectangle().fill(Color(red: 0, green: 0, blue: 1)).frame(width: 150, height: 20)
                Rectangle().fill(Color(red: 1, green: 0, blue: 0)).frame(width: 150, height: 580)
            }
            .frame(width: 150, height: 600)
        }
        .frame(width: 200, height: 200)
        try assertStripeAtTheTop(AnyView(view), route: "codegen")
    }

    @MainActor
    private func assertStripeAtTheTop(_ content: AnyView, route: String) throws {
        // ImageRenderer draws no ScrollView content (measured: not one red
        // pixel), and drawHierarchy draws nothing in this app-less test
        // process; the hosted view's layer tree, rendered, has both.
        let host = UIHostingController(rootView: content
            .frame(width: 390, height: 500, alignment: .topLeading)
            .background(Color.white))
        // The window's safe area would push the drawing down (31 measured).
        if #available(iOS 16.4, *) { host.safeAreaRegions = [] }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 500))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: host.view.bounds, format: format).image { context in
            host.view.layer.render(in: context.cgContext)
        }
        window.isHidden = true
        guard let cg = image.cgImage else {
            XCTFail("\(route): render produced no image")
            return
        }
        let red = rows(cg, rgb: (255, 0, 0))
        let blue = rows(cg, rgb: (0, 0, 255))
        XCTAssertFalse(red.isEmpty, "\(route): the content did not draw at all — the measurement would say nothing")
        XCTAssertEqual(blue.first, 0, "\(route): the content's top stripe is at rows \(blue.first.map(String.init) ?? "none"), want 0")
        XCTAssertEqual(blue.count, 20, "\(route): the stripe shows \(blue.count) rows, want 20")
    }

    /// The rows (y) holding at least one pixel within ±2 of the RGB.
    private func rows(_ image: CGImage, rgb: (Int, Int, Int)) -> [Int] {
        let width = image.width, height = image.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let ctx = CGContext(data: &buffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        var found: [Int] = []
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                if abs(Int(buffer[i]) - rgb.0) <= 2 && abs(Int(buffer[i + 1]) - rgb.1) <= 2 && abs(Int(buffer[i + 2]) - rgb.2) <= 2 {
                    found.append(y)
                    break
                }
            }
        }
        return found
    }
}
#endif // DEBUG
