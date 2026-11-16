//
//  RelativeParentPaddingTests.swift
//  SwiftJsonUITests
//
//  A RelativePositionContainer that fills its parent and has a padding must
//  stay the parent's size and lay its children inside the padding: a
//  matchParent child is the container less its margins and the padding, on
//  both axes. The container reported its proposal PLUS the padding, so it
//  came out wider (and taller) than its parent by the padding twice; a
//  matchParent child then got the full width back and only moved by the
//  padding — with padding 40 its right edge was past the screen (ticket
//  sjui-relative-matchparent-width-ignores-parent-padding-without-
//  horizontal-constraint).
//
//  Frames are read in the window's coordinates from GeometryReader. Both
//  routes: the codegen shape (RelativePositionContainer with parentPadding,
//  as sjui_tools emits it) and Dynamic (a View with `padding` whose child has
//  a relative attribute, which Dynamic lays out through the same container).
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
@available(iOS 16.0, *)
final class RelativeParentPaddingTests: XCTestCase {

    private let width: CGFloat = 375
    private let height: CGFloat = 600
    private let margin: CGFloat = 24

    private enum Horizontal: String, CaseIterable {
        case none, left, leftAndRight, centerHorizontal
        var constraints: [RelativePositionConstraint] {
            switch self {
            case .none: return []
            case .left: return [RelativePositionConstraint(type: .parentLeft, targetId: "")]
            case .leftAndRight: return [RelativePositionConstraint(type: .parentLeft, targetId: ""), RelativePositionConstraint(type: .parentRight, targetId: "")]
            case .centerHorizontal: return [RelativePositionConstraint(type: .parentCenterHorizontal, targetId: "")]
            }
        }
    }

    /// matchParent width, fixed height, at the top; the container fills the
    /// host. Every horizontal case must give the same frame: left at
    /// padding + margin, width = container − 2·margin − 2·padding. The
    /// container itself is the host's width.
    @MainActor
    func testMatchParentChildIsInsideThePaddingHorizontally() throws {
        var wrong: [String] = []
        for padding in [CGFloat(0), 16, 40] {
            for horizontal in Horizontal.allCases {
                let child = FrameBox(), container = FrameBox()
                let config = RelativeChildConfig(
                    id: "bar", view: AnyView(Color.black.background(FrameReader(box: child))),
                    constraints: [RelativePositionConstraint(type: .parentTop, targetId: "")] + horizontal.constraints,
                    margins: EdgeInsets(top: 0, leading: margin, bottom: 0, trailing: margin),
                    widthMode: .matchParent, heightMode: .fixed(20))
                let relative = RelativePositionContainer(
                    children: [config], parentPadding: EdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding),
                    containerWidthMode: .matchParent, containerHeightMode: .matchParent)
                host(AnyView(relative.background(FrameReader(box: container))))
                let wantMinX = padding + margin, wantWidth = width - 2 * margin - 2 * padding
                let got = child.frame
                let ok = abs(got.minX - wantMinX) < 0.5 && abs(got.width - wantWidth) < 0.5 && abs(container.frame.width - width) < 0.5
                print("RELATIVE_PADDING h padding=\(Int(padding)) \(horizontal.rawValue): child minX=\(got.minX) width=\(got.width) maxX=\(got.maxX) container=\(container.frame.width) \(ok ? "ok" : "WRONG")")
                if !ok { wrong.append("padding \(Int(padding)) \(horizontal.rawValue): child x \(got.minX)…\(got.maxX) (want \(wantMinX)…\(wantMinX + wantWidth)), container \(container.frame.width) (want \(width))") }
            }
        }
        XCTAssertEqual(wrong, [], wrong.joined(separator: "\n"))
    }

    /// The same on the vertical axis: a child at the parent's bottom ends at
    /// the container's height less the padding and its margin, and the
    /// container is the host's height.
    @MainActor
    func testMatchParentContainerKeepsItsHeightAndTheBottomInsideThePadding() throws {
        var wrong: [String] = []
        for padding in [CGFloat(0), 16, 40] {
            let child = FrameBox(), container = FrameBox()
            let config = RelativeChildConfig(
                id: "bar", view: AnyView(Color.black.background(FrameReader(box: child))),
                constraints: [RelativePositionConstraint(type: .parentBottom, targetId: "")],
                margins: EdgeInsets(top: 0, leading: margin, bottom: 10, trailing: margin),
                widthMode: .matchParent, heightMode: .fixed(20))
            let relative = RelativePositionContainer(
                children: [config], parentPadding: EdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding),
                containerWidthMode: .matchParent, containerHeightMode: .matchParent)
            host(AnyView(relative.background(FrameReader(box: container))))
            let wantMaxY = height - padding - 10
            let ok = abs(child.frame.maxY - wantMaxY) < 0.5 && abs(container.frame.height - height) < 0.5
            print("RELATIVE_PADDING v padding=\(Int(padding)): child maxY=\(child.frame.maxY) container=\(container.frame.height) \(ok ? "ok" : "WRONG")")
            if !ok { wrong.append("padding \(Int(padding)): child bottom \(child.frame.maxY) (want \(wantMaxY)), container \(container.frame.height) (want \(height))") }
        }
        XCTAssertEqual(wrong, [], wrong.joined(separator: "\n"))
    }

    /// A filling-width, wrapContent-height container with padding measures its
    /// height with the text at the width it will be placed with — the
    /// container less the padding and the margins — so it holds every line.
    /// Measured at the width plus the padding, the text was one line short.
    @MainActor
    func testWrapContentHeightHoldsTheTextAtThePaddedWidth() throws {
        let padding: CGFloat = 40
        let text = "Orders placed before noon ship the same day.\nReturns are accepted within thirty days.\nItems marked as final sale cannot be returned, exchanged or refunded as store credit at any location.\nThank you for shopping with us."
        func label() -> some View { Text(text).font(.system(size: 10)).lineSpacing(4).multilineTextAlignment(.center) }
        let container = FrameBox()
        let config = RelativeChildConfig(
            id: "notice", view: AnyView(label()),
            constraints: [RelativePositionConstraint(type: .parentTop, targetId: "")],
            margins: EdgeInsets(top: 0, leading: margin, bottom: 0, trailing: margin),
            widthMode: .matchParent, heightMode: .wrapContent)
        let relative = RelativePositionContainer(
            children: [config], parentPadding: EdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding),
            containerWidthMode: .matchParent, containerHeightMode: .wrapContent)
        host(AnyView(VStack(spacing: 0) { relative.background(FrameReader(box: container)); Spacer(minLength: 0) }))
        let placed = width - 2 * margin - 2 * padding
        let needed = UIHostingController(rootView: label()).sizeThatFits(in: CGSize(width: placed, height: CGFloat.greatestFiniteMagnitude)).height
        let atWider = UIHostingController(rootView: label()).sizeThatFits(in: CGSize(width: placed + 2 * padding, height: CGFloat.greatestFiniteMagnitude)).height
        XCTAssertGreaterThan(needed, atWider, "the text must wrap into more lines at the padded width (else this case proves nothing)")
        XCTAssertGreaterThanOrEqual(container.frame.height, needed + 2 * padding - 0.5,
            "the container is \(container.frame.height)pt; the text needs \(needed)pt at \(placed)pt plus the padding")
    }

    /// A wrapContent container keeps adding its padding around the children
    /// (the control: that side was right and must stay so).
    @MainActor
    func testWrapContentContainerStillGrowsByItsPadding() throws {
        for padding in [CGFloat(0), 16, 40] {
            let container = FrameBox()
            let config = RelativeChildConfig(
                id: "dot", view: AnyView(Color.black.frame(width: 50, height: 30)),
                constraints: [RelativePositionConstraint(type: .parentTop, targetId: "")],
                widthMode: .fixed(50), heightMode: .fixed(30))
            let relative = RelativePositionContainer(
                children: [config], parentPadding: EdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding))
            host(AnyView(VStack(alignment: .leading, spacing: 0) { relative.background(FrameReader(box: container)); Spacer(minLength: 0) }))
            XCTAssertEqual(container.frame.width, 50 + 2 * padding, accuracy: 0.5, "padding \(padding): wrapContent width")
            XCTAssertEqual(container.frame.height, 30 + 2 * padding, accuracy: 0.5, "padding \(padding): wrapContent height")
        }
    }

    /// Dynamic: a View with `padding` filling the screen, its child a
    /// matchParent View with margins and a relative attribute (alignTop), so
    /// Dynamic routes the parent through RelativePositionContainer. The
    /// child's blue background is located in the rendered pixels.
    @MainActor
    func testDynamicMatchParentChildIsInsideThePadding() throws {
        var wrong: [String] = []
        for padding in [0, 16, 40] {
            let json = ##"{ "type": "View", "id": "root", "width": "matchParent", "height": "matchParent", "padding": \##(padding), "background": "#FFFFFF", "child": [ { "type": "View", "id": "bar", "width": "matchParent", "height": 20, "leftMargin": 24, "rightMargin": 24, "alignTop": true, "background": "#0000FF" } ] }"##
            let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
            let (minX, maxX) = try blueSpan(of: AnyView(DynamicComponentBuilder(component: component, data: [:], viewId: nil)))
            let wantMin = CGFloat(padding) + margin, wantMax = width - CGFloat(padding) - margin
            print("RELATIVE_PADDING dynamic padding=\(padding): blue x \(minX)…\(maxX) want \(wantMin)…\(wantMax)")
            if abs(minX - wantMin) > 1 || abs(maxX - wantMax) > 1 {
                wrong.append("padding \(padding): blue x \(minX)…\(maxX), want \(wantMin)…\(wantMax)")
            }
        }
        XCTAssertEqual(wrong, [], wrong.joined(separator: "\n"))
    }

    // MARK: hosting

    @MainActor
    private func host(_ content: AnyView) {
        let host = UIHostingController(rootView: content.frame(width: width, height: height, alignment: .topLeading))
        if #available(iOS 16.4, *) { host.safeAreaRegions = [] }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        window.isHidden = true
    }

    /// The first and last column (in points) holding pure blue on the row
    /// 10pt below the top padding band.
    @MainActor
    private func blueSpan(of content: AnyView) throws -> (CGFloat, CGFloat) {
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
        var first: Int?, last: Int?
        for y in 0..<min(h, 120) {
            for x in 0..<w {
                let i = (y * w + x) * 4
                if buffer[i] < 10 && buffer[i + 1] < 10 && buffer[i + 2] > 245 {
                    first = min(first ?? x, x); last = max(last ?? x, x)
                }
            }
        }
        return (CGFloat(first ?? -1), CGFloat((last ?? -2) + 1))
    }
}

@available(iOS 16.0, *)
private final class FrameBox { var frame: CGRect = .zero }

@available(iOS 16.0, *)
private struct FrameReader: View {
    let box: FrameBox
    var body: some View {
        GeometryReader { proxy in
            Color.clear.onAppear { box.frame = proxy.frame(in: .global) }
        }
    }
}
#endif // DEBUG
