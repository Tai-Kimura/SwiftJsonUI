//
//  VerticalScrollShortContentTests.swift
//  SwiftJsonUITests
//
//  A vertical ScrollView starts a content shorter than its viewport at the
//  top (attribute_semantics gravityDefaults: top|start on every container).
//  AdvancedKeyboardAvoidingScrollView — which Dynamic's ScrollView container
//  and the sjui codegen emit both draw through — lays the content in a frame
//  of at least the viewport's height, whose default alignment is the centre:
//  a short content that did not stretch itself drew in the vertical middle.
//  A consumer's book page put its first line ~74pt down (iPhone 17 Pro,
//  iOS 27, once its footer grew; ticket
//  sjui-vertical-scrollview-centres-a-short-content).
//
//  The arm is the short content that does not stretch (no Spacer): the
//  consumer's trigger — the footer growing after the first layout — did not
//  reproduce in a test host (measured: the stretching content stayed at 20).
//  The tall content is the control: it fills the viewport, so the alignment
//  cannot move it, before or after.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class VerticalScrollShortContentTests: XCTestCase {

    private func stripe(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color(red: 0, green: 0, blue: 1)).frame(width: 150, height: 20)
            Rectangle().fill(Color(red: 1, green: 0, blue: 0)).frame(width: 150, height: height - 20)
        }
        .frame(width: 150, height: height)
    }

    /// The shape a codegen ScrollView takes when its child does not stretch.
    @MainActor
    func testAShortContentStartsAtTheTop() throws {
        let view = AdvancedKeyboardAvoidingScrollView(.vertical, showsIndicators: true) { stripe(height: 80) }
            .frame(width: 200, height: 200)
        try assertStripe(AnyView(view), at: 0, route: "short")
    }

    /// Dynamic: a ScrollView whose one child has a fixed height. Green before
    /// and after (measured): the Dynamic container stretches what it lays in
    /// the frame, so this is not an arm — it pins that Dynamic stays at the top.
    @MainActor
    func testDynamicShortContentIsAtTheTop() throws {
        let json = ##"""
        { "type": "View", "id": "root", "width": "matchParent", "height": "matchParent",
          "child": [ { "type": "ScrollView", "id": "target", "width": 200, "height": 200, "background": "#DDDDDD",
            "child": [ { "type": "View", "id": "content", "orientation": "vertical", "width": 150, "height": 80, "background": "#FF0000",
              "child": [ { "type": "View", "id": "stripe", "width": 150, "height": 20, "background": "#0000FF" } ] } ] } ] }
        """##
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        try assertStripe(AnyView(DynamicComponentBuilder(component: component, data: [:], viewId: nil)), at: 0, route: "Dynamic")
    }

    /// Control: a content taller than the viewport is at the top either way.
    @MainActor
    func testATallContentIsAtTheTopEitherWay() throws {
        let view = AdvancedKeyboardAvoidingScrollView(.vertical, showsIndicators: true) { stripe(height: 600) }
            .frame(width: 200, height: 200)
        try assertStripe(AnyView(view), at: 0, route: "tall")
    }

    @MainActor
    private func assertStripe(_ content: AnyView, at expected: Int, route: String) throws {
        // ImageRenderer draws no ScrollView content, and drawHierarchy draws
        // nothing in this app-less test process; the hosted view's layer
        // tree, rendered, has both.
        let host = UIHostingController(rootView: content
            .frame(width: 390, height: 500, alignment: .topLeading)
            .background(Color.white))
        if #available(iOS 16.4, *) { host.safeAreaRegions = [] }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 500))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: host.view.bounds, format: format).image { context in
            host.view.layer.render(in: context.cgContext)
        }
        window.isHidden = true
        let cg = try XCTUnwrap(image.cgImage)
        let width = cg.width, height = cg.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let ctx = CGContext(data: &buffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        var blue: [Int] = []
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                if abs(Int(buffer[i])) <= 2 && abs(Int(buffer[i + 1])) <= 2 && abs(Int(buffer[i + 2]) - 255) <= 2 { blue.append(y); break }
            }
        }
        XCTAssertEqual(blue.first, expected, "\(route): the content's top stripe is at \(blue.first.map(String.init) ?? "none"), want \(expected)")
        XCTAssertEqual(blue.count, 20, "\(route): the stripe shows \(blue.count) rows, want 20")
    }
}
#endif // DEBUG
