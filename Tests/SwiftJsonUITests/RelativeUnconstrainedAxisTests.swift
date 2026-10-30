//
//  RelativeUnconstrainedAxisTests.swift
//  SwiftJsonUITests
//
//  In a RelativePositionContainer, the axis no constraint places starts
//  inside the parent's padding and the child's own margin, as a constrained
//  axis does: a child with only alignBottom sits at padding + leftMargin from
//  the left, one with only alignRight at padding + topMargin from the top.
//  The default position was the container's bare corner, so such a child was
//  drawn at x 0 / y 0 whatever the padding and margin (ticket
//  swiftjsonui-relative-unconstrained-axis-ignores-parent-padding). A child
//  with no constraint at all was right only because sjui_tools gives it
//  parentTop / parentLeft. Every container size: matchParent, fixed, wrap.
//
//  Both routes: the codegen shape (the container as sjui_tools emits it) and
//  Dynamic. The blue child's box is read from the rendered pixels.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
@available(iOS 16.0, *)
final class RelativeUnconstrainedAxisTests: XCTestCase {

    private let width: CGFloat = 375
    private let height: CGFloat = 600
    private let box: CGFloat = 40

    private enum Free: String, CaseIterable { case x, y }
    private enum Size: String, CaseIterable { case matchParent, fixed, wrap }
    private let paddingAndMargin: [(CGFloat, CGFloat)] = [(10, 0), (0, 8), (10, 8)]

    /// The container's size for *size* (wrap: the child, its margin and the padding).
    private func containerSize(_ size: Size, free: Free, padding p: CGFloat, margin m: CGFloat) -> CGSize {
        switch size {
        case .matchParent: return CGSize(width: width, height: 80)
        case .fixed: return CGSize(width: 300, height: 80)
        case .wrap: return CGSize(width: box + 2 * p + (free == .x ? m : 0), height: box + 2 * p + (free == .y ? m : 0))
        }
    }

    /// The child's origin: the free axis at padding + margin, the constrained one at the far edge less the padding.
    private func want(_ c: CGSize, free: Free, padding p: CGFloat, margin m: CGFloat) -> CGPoint {
        free == .x ? CGPoint(x: p + m, y: c.height - p - box) : CGPoint(x: c.width - p - box, y: p + m)
    }

    @MainActor
    func testTheCodegenShapeStartsTheFreeAxisInsideThePaddingAndTheMargin() throws {
        var wrong: [String] = []
        for size in Size.allCases {
            for free in Free.allCases {
                for (p, m) in paddingAndMargin {
                    let c = containerSize(size, free: free, padding: p, margin: m)
                    let config = RelativeChildConfig(
                        id: "blue", view: AnyView(Color(red: 0, green: 0, blue: 1).frame(width: box, height: box)),
                        constraints: [.init(type: free == .x ? .parentBottom : .parentRight, targetId: "")],
                        margins: free == .x ? EdgeInsets(top: 0, leading: m, bottom: 0, trailing: 0) : EdgeInsets(top: m, leading: 0, bottom: 0, trailing: 0),
                        widthMode: .fixed(box), heightMode: .fixed(box))
                    let mode: (RelativeSizeMode, RelativeSizeMode) = {
                        switch size {
                        case .matchParent: return (.matchParent, .fixed(80))
                        case .fixed: return (.fixed(300), .fixed(80))
                        case .wrap: return (.wrapContent, .wrapContent)
                        }
                    }()
                    let relative = RelativePositionContainer(
                        children: [config], parentPadding: EdgeInsets(top: p, leading: p, bottom: p, trailing: p),
                        containerWidthMode: mode.0, containerHeightMode: mode.1)
                    let framed: AnyView = size == .wrap ? AnyView(relative) : AnyView(relative.frame(width: c.width, height: c.height, alignment: .topLeading))
                    let got = try blueBox(of: framed)
                    let w = want(c, free: free, padding: p, margin: m)
                    let ok = abs(got.minX - w.x) < 1 && abs(got.minY - w.y) < 1
                    print("RELATIVE_FREE_AXIS codegen \(size) free \(free) p\(Int(p)) m\(Int(m)): \(got) want \(w) \(ok ? "ok" : "WRONG")")
                    if !ok { wrong.append("codegen \(size) free \(free) padding \(Int(p)) margin \(Int(m)): child at \(got.origin), want \(w)") }
                }
            }
        }
        XCTAssertEqual(wrong, [], wrong.joined(separator: "\n"))
    }

    @MainActor
    func testDynamicStartsTheFreeAxisInsideThePaddingAndTheMargin() throws {
        var wrong: [String] = []
        for size in Size.allCases {
            for free in Free.allCases {
                for (p, m) in paddingAndMargin {
                    let c = containerSize(size, free: free, padding: p, margin: m)
                    let sizeJSON: String = {
                        switch size {
                        case .matchParent: return #""width": "matchParent", "height": 80, "#
                        case .fixed: return #""width": 300, "height": 80, "#
                        case .wrap: return ""
                        }
                    }()
                    let childAttrs = free == .x ? #""alignBottom": true, "leftMargin": \#(Int(m))"# : #""alignRight": true, "topMargin": \#(Int(m))"#
                    let json = ##"{"type": "View", \##(sizeJSON)"paddings": [\##(Int(p))], "child": [{"type": "View", "id": "blue", "width": 40, "height": 40, "background": "#0000FF", \##(childAttrs)}]}"##
                    let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
                    let got = try blueBox(of: AnyView(DynamicComponentBuilder(component: component, data: [:], viewId: nil)))
                    let w = want(c, free: free, padding: p, margin: m)
                    let ok = abs(got.minX - w.x) < 1 && abs(got.minY - w.y) < 1
                    print("RELATIVE_FREE_AXIS dynamic \(size) free \(free) p\(Int(p)) m\(Int(m)): \(got) want \(w) \(ok ? "ok" : "WRONG")")
                    if !ok { wrong.append("dynamic \(size) free \(free) padding \(Int(p)) margin \(Int(m)): child at \(got.origin), want \(w)") }
                }
            }
        }
        XCTAssertEqual(wrong, [], wrong.joined(separator: "\n"))
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
