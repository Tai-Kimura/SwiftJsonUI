//
//  VerticalScrollStartEdgeTests.swift
//  SwiftJsonUITests
//
//  A vertical ScrollView starts its content at its leading edge.
//  The content stack is leading-aligned, but the frame that stretches it to
//  the ScrollView's width was centring it: a 150-wide child of a 200-wide
//  ScrollView drew at x 25, where the declaration (attribute_semantics
//  gravityDefaults: top|start on every container), Android and web put it at
//  x 0 (frame-parity, 2026-10-05: 25 ids on ScrollView fixtures, and 4 on a
//  flow Collection whose root is a ScrollView, at x 126 in the 402 canvas).
//
//  Both routes draw through AdvancedKeyboardAvoidingScrollView: Dynamic's
//  ScrollView container and the sjui codegen's emit
//  (scrollview_converter.rb). Each is drawn here and the content's left
//  column is looked for at the left of the viewport.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class VerticalScrollStartEdgeTests: XCTestCase {

    private let layout = """
    {
      "type": "View", "id": "root", "width": "matchParent", "height": "matchParent",
      "child": [
        { "type": "ScrollView", "id": "target", "width": 200, "height": 200, "background": "#DDDDDD",
          "child": [
            { "type": "View", "id": "content", "width": 150, "height": 600, "background": "#FF0000" },
            { "type": "View", "id": "content_b", "width": 150, "height": 80, "background": "#0000FF" }
          ] }
      ]
    }
    """

    @MainActor
    func testDynamicVerticalScrollStartsItsContentAtTheLeadingEdge() throws {
        let component = try JSONDecoder().decode(DynamicComponent.self, from: layout.data(using: .utf8)!)
        try assertContentAtTheLeadingEdge(AnyView(DynamicComponentBuilder(component: component, data: [:], viewId: nil)),
                                          route: "Dynamic")
    }

    /// The shape scrollview_converter.rb emits for a vertical ScrollView with
    /// more than one child.
    @MainActor
    func testCodegenVerticalScrollStartsItsContentAtTheLeadingEdge() throws {
        let view = AdvancedKeyboardAvoidingScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                Rectangle().fill(Color(red: 1, green: 0, blue: 0)).frame(width: 150, height: 600)
                Rectangle().fill(Color(red: 0, green: 0, blue: 1)).frame(width: 150, height: 80)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 200, height: 200)
        try assertContentAtTheLeadingEdge(AnyView(view), route: "codegen")
    }

    // MARK: - the ScrollView's own gravity, not the child's

    // common.gravity is the CONTENT gravity of the view that declares it: the
    // ScrollView's own places its content; a child's is the child's
    // content's and does not place the child. Read from the generators on
    // 2026-10-05, sjui codegen placed a single child by the child's gravity
    // and Dynamic read neither; web placed it by the ScrollView's.
    private func narrowChildLayout(scrollGravity: String?, childGravity: String?) -> String {
        let scroll = scrollGravity.map { ", \"gravity\": \"\($0)\"" } ?? ""
        let child = childGravity.map { ", \"gravity\": \"\($0)\"" } ?? ""
        return """
        {
          "type": "View", "id": "root", "width": "matchParent", "height": "matchParent",
          "child": [
            { "type": "ScrollView", "id": "target", "width": 200, "height": 200, "background": "#DDDDDD"\(scroll),
              "child": [ { "type": "View", "id": "box", "width": 40, "height": 40, "background": "#FF0000"\(child) } ] }
          ]
        }
        """
    }

    @MainActor
    func testDynamicScrollViewGravityCentresItsContent() throws {
        let component = try JSONDecoder().decode(DynamicComponent.self,
                                                 from: narrowChildLayout(scrollGravity: "centerHorizontal", childGravity: nil).data(using: .utf8)!)
        try assertContent(AnyView(DynamicComponentBuilder(component: component, data: [:], viewId: nil)),
                          route: "Dynamic", startsAt: 80, width: 40)
    }

    /// The shape scrollview_converter.rb emits for a vertical ScrollView with
    /// gravity centerHorizontal.
    @MainActor
    func testCodegenScrollViewGravityCentresItsContent() throws {
        let view = AdvancedKeyboardAvoidingScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .center, spacing: 0) {
                Rectangle().fill(Color(red: 1, green: 0, blue: 0)).frame(width: 40, height: 40)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(width: 200, height: 200)
        try assertContent(AnyView(view), route: "codegen", startsAt: 80, width: 40)
    }

    @MainActor
    func testDynamicChildGravityDoesNotPlaceTheChild() throws {
        let component = try JSONDecoder().decode(DynamicComponent.self,
                                                 from: narrowChildLayout(scrollGravity: nil, childGravity: "right").data(using: .utf8)!)
        try assertContent(AnyView(DynamicComponentBuilder(component: component, data: [:], viewId: nil)),
                          route: "Dynamic", startsAt: 0, width: 40)
    }

    @MainActor
    private func assertContentAtTheLeadingEdge(_ content: AnyView, route: String) throws {
        try assertContent(content, route: route, startsAt: 0, width: 150)
    }

    @MainActor
    private func assertContent(_ content: AnyView, route: String, startsAt: Int, width: Int) throws {
        // As HorizontalScrollCrossAxisTests: the hosted view's layer tree,
        // rendered, is what draws ScrollView content in this process.
        let host = UIHostingController(rootView: content
            .frame(width: 390, height: 500, alignment: .topLeading)
            .background(Color.white))
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
        let red = columns(cg, rgb: (255, 0, 0))
        XCTAssertFalse(red.isEmpty, "\(route): the content did not draw at all — the measurement would say nothing")
        XCTAssertEqual(red.first, startsAt, "\(route): the content starts at column \(red.first.map(String.init) ?? "none"), want \(startsAt)")
        XCTAssertEqual(red.count, width, "\(route): the content shows \(red.count) columns, want \(width)")
    }

    /// The columns (x) holding at least one pixel within ±2 of the RGB.
    private func columns(_ image: CGImage, rgb: (Int, Int, Int)) -> [Int] {
        let width = image.width, height = image.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let ctx = CGContext(data: &buffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        var found: [Int] = []
        for x in 0..<width {
            for y in 0..<height {
                let i = (y * width + x) * 4
                if abs(Int(buffer[i]) - rgb.0) <= 2 && abs(Int(buffer[i + 1]) - rgb.1) <= 2 && abs(Int(buffer[i + 2]) - rgb.2) <= 2 {
                    found.append(x)
                    break
                }
            }
        }
        return found
    }
}
#endif // DEBUG
