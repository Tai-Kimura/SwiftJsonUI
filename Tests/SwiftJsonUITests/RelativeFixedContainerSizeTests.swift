//
//  RelativeFixedContainerSizeTests.swift
//  SwiftJsonUITests
//
//  A RelativePositionContainer of a fixed size is that size, padding
//  included, and its parent-relative constraints resolve against it. It took
//  the proposal only when it filled (matchParent) and was otherwise measured
//  from its children: a container 120 high reported the child's 40, sat at
//  the top of its frame, and alignBottom / centerVertical resolved inside a
//  box as tall as the child — the child stayed at the top. A fixed width did
//  the same to alignRight (ticket swiftjsonui-relative-container-ignores-
//  fixed-container-size).
//
//  Both routes: the codegen shape (the container with containerWidthMode /
//  containerHeightMode .fixed and the frames sjui_tools puts after it) and
//  Dynamic (a View with a numeric width / height whose child has a relative
//  attribute). The blue child's box is read from the rendered pixels.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
@available(iOS 16.0, *)
final class RelativeFixedContainerSizeTests: XCTestCase {

    private let width: CGFloat = 375
    private let height: CGFloat = 600
    private let box: CGFloat = 40

    private struct Case {
        let name: String
        let constraints: [RelativePositionConstraint]
        let json: String
        /// The child's origin in a container of width w, height h and padding p.
        let want: (CGFloat, CGFloat, CGFloat) -> CGPoint
    }

    private var cases: [Case] {
        let b = box
        return [
            Case(name: "alignBottom alignRight",
                 constraints: [.init(type: .parentBottom, targetId: ""), .init(type: .parentRight, targetId: "")],
                 json: #""alignBottom": true, "alignRight": true"#,
                 want: { w, h, p in CGPoint(x: w - p - b, y: h - p - b) }),
            // alignLeft too: an axis with no constraint at all is placed
            // without the padding, whatever the container's size (its own
            // ticket, swiftjsonui-relative-unconstrained-axis-ignores-parent-
            // padding).
            Case(name: "centerVertical alignLeft",
                 constraints: [.init(type: .parentCenterVertical, targetId: ""), .init(type: .parentLeft, targetId: "")],
                 json: #""centerVertical": true, "alignLeft": true"#,
                 want: { _, h, p in CGPoint(x: p, y: (h - b) / 2) }),
            Case(name: "centerHorizontal alignBottom",
                 constraints: [.init(type: .parentCenterHorizontal, targetId: ""), .init(type: .parentBottom, targetId: "")],
                 json: #""centerHorizontal": true, "alignBottom": true"#,
                 want: { w, h, p in CGPoint(x: (w - b) / 2, y: h - p - b) }),
        ]
    }

    @MainActor
    func testTheCodegenShapeLaysTheChildInsideTheFixedSize() throws {
        var wrong: [String] = []
        for (w, h) in [(CGFloat(300), CGFloat(120)), (CGFloat(200), CGFloat(200))] {
            for padding in [CGFloat(0), 10] {
                for c in cases {
                    let config = RelativeChildConfig(
                        id: "blue", view: AnyView(Color(red: 0, green: 0, blue: 1).frame(width: box, height: box)),
                        constraints: c.constraints, margins: .init(), widthMode: .fixed(box), heightMode: .fixed(box))
                    let relative = RelativePositionContainer(
                        children: [config], parentPadding: EdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding),
                        containerWidthMode: .fixed(w), containerHeightMode: .fixed(h))
                        .frame(minWidth: w, idealWidth: w, maxWidth: w, alignment: .topLeading)
                        .frame(minHeight: h, idealHeight: h, maxHeight: h, alignment: .topLeading)
                    let got = try blueBox(of: AnyView(relative))
                    let want = c.want(w, h, padding)
                    let ok = abs(got.minX - want.x) < 1 && abs(got.minY - want.y) < 1
                    print("RELATIVE_FIXED codegen \(Int(w))x\(Int(h)) padding=\(Int(padding)) \(c.name): \(got) want \(want) \(ok ? "ok" : "WRONG")")
                    if !ok { wrong.append("codegen \(Int(w))x\(Int(h)) padding \(Int(padding)) \(c.name): child at \(got.origin), want \(want)") }
                }
            }
        }
        XCTAssertEqual(wrong, [], wrong.joined(separator: "\n"))
    }

    @MainActor
    func testDynamicLaysTheChildInsideTheFixedSize() throws {
        var wrong: [String] = []
        for (w, h) in [(CGFloat(300), CGFloat(120)), (CGFloat(200), CGFloat(200))] {
            for padding in [CGFloat(0), 10] {
                for c in cases {
                    let json = ##"{"type": "View", "width": \##(Int(w)), "height": \##(Int(h)), "paddings": [\##(Int(padding))], "child": [{"type": "View", "id": "blue", "width": 40, "height": 40, "background": "#0000FF", \##(c.json)}]}"##
                    let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
                    let got = try blueBox(of: AnyView(DynamicComponentBuilder(component: component, data: [:], viewId: nil)))
                    let want = c.want(w, h, padding)
                    let ok = abs(got.minX - want.x) < 1 && abs(got.minY - want.y) < 1
                    print("RELATIVE_FIXED dynamic \(Int(w))x\(Int(h)) padding=\(Int(padding)) \(c.name): \(got) want \(want) \(ok ? "ok" : "WRONG")")
                    if !ok { wrong.append("dynamic \(Int(w))x\(Int(h)) padding \(Int(padding)) \(c.name): child at \(got.origin), want \(want)") }
                }
            }
        }
        XCTAssertEqual(wrong, [], wrong.joined(separator: "\n"))
    }

    /// A fixed container still is its size when a child fills it: the child
    /// takes the fixed box less the padding, not the proposal.
    @MainActor
    func testAMatchParentChildFillsTheFixedBoxLessThePadding() throws {
        let config = RelativeChildConfig(
            id: "blue", view: AnyView(Color(red: 0, green: 0, blue: 1)),
            constraints: [], margins: .init(), widthMode: .matchParent, heightMode: .matchParent)
        let relative = RelativePositionContainer(
            children: [config], parentPadding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10),
            containerWidthMode: .fixed(300), containerHeightMode: .fixed(120))
            .frame(minWidth: 300, idealWidth: 300, maxWidth: 300, alignment: .topLeading)
            .frame(minHeight: 120, idealHeight: 120, maxHeight: 120, alignment: .topLeading)
        let got = try blueBox(of: AnyView(relative))
        XCTAssertEqual(got, CGRect(x: 10, y: 10, width: 280, height: 100), "matchParent child in a fixed 300 x 120 with padding 10")
    }

    // MARK: hosting

    /// The box (in points) of the pure blue pixels.
    @MainActor
    private func blueBox(of content: AnyView) throws -> CGRect {
        let host = UIHostingController(rootView: content.frame(width: width, height: height, alignment: .topLeading).background(Color.white))
        if #available(iOS 16.4, *) { host.safeAreaRegions = [] }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
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
        let w = cg.width, h = cg.height
        var buffer = [UInt8](repeating: 0, count: w * h * 4)
        let ctx = CGContext(data: &buffer, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        var minX = Int.max, minY = Int.max, maxX = -1, maxY = -1
        for y in 0..<h {
            for x in 0..<w {
                let i = (y * w + x) * 4
                if buffer[i] < 10 && buffer[i + 1] < 10 && buffer[i + 2] > 245 {
                    minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
                }
            }
        }
        guard maxX >= 0 else { return .null }
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }
}
#endif // DEBUG
