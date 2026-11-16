//
//  RelativeWrappedLabelHeightTests.swift
//  SwiftJsonUITests
//
//  A wrapContent-height child of RelativePositionContainer must be as tall as
//  its content is at the width it is placed with. The layout measured that
//  height with no width (`sizeThatFits(.unspecified)`), so a Label narrowed
//  by its margins — or by a fixed width, or capped by the container — wrapped
//  into one more line than it was measured for, and the last line was cut
//  (ticket sjui-relative-position-wrapcontent-height-measured-unconstrained-
//  clips-wrapped-label).
//
//  The verdict is the number of text lines drawn, read from the pixels: the
//  same text laid out in a plain column of the placed width is the expected
//  count. Both routes are checked: the codegen shape (RelativePositionContainer
//  called directly, as sjui_tools emits it) and Dynamic (a Label with a
//  relative attribute, which Dynamic lays out through the same container).
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
@available(iOS 16.0, *)
final class RelativeWrappedLabelHeightTests: XCTestCase {

    /// Four paragraphs; the third is longer than one line at a phone width
    /// (327pt and 354pt), the others fit. And a Japanese twin.
    static let en = "Orders placed before noon ship the same day.\nReturns are accepted within thirty days.\nItems marked as final sale cannot be returned, exchanged or refunded as store credit at any location.\nThank you for shopping with us."
    static let ja = "正午までのご注文は当日に発送します。\n返品は三十日以内に承ります。\n最終セールの商品は、どの店舗でも返品・交換・ポイントでの返金を承ることができません。\nご利用ありがとうございます。"

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10))
            .lineSpacing(4)
            .multilineTextAlignment(.center)
            .foregroundColor(.black)
    }

    // MARK: codegen shape

    /// matchParent width with 24pt margins, wrapContent height, at the
    /// bottom of a matchParent container.
    @MainActor
    func testMatchParentWidthNarrowedByMarginsShowsEveryLine() throws {
        for (width, text, tag) in [(375.0, Self.en, "en 327"), (402.0, Self.en, "en 354"), (375.0, Self.ja, "ja 327")] {
            let child = RelativeChildConfig(
                id: "notice", view: AnyView(label(text)),
                constraints: [RelativePositionConstraint(type: .parentBottom, targetId: "")],
                margins: EdgeInsets(top: 0, leading: 24, bottom: 40, trailing: 24),
                widthMode: .matchParent, heightMode: .wrapContent)
            let relative = RelativePositionContainer(children: [child], containerWidthMode: .matchParent, containerHeightMode: .matchParent)
            let expected = try lines(of: AnyView(label(text).frame(width: width - 48).fixedSize(horizontal: false, vertical: true)), width: width)
            let got = try lines(of: AnyView(relative), width: width)
            XCTAssertGreaterThan(expected, 4, "\(tag): the control must wrap (else this case proves nothing)")
            XCTAssertEqual(got, expected, "\(tag): \(got) lines drawn in the relative container, \(expected) at the placed width")
        }
    }

    /// A fixed width narrower than the text, wrapContent height.
    @MainActor
    func testFixedWidthShowsEveryLine() throws {
        let child = RelativeChildConfig(
            id: "notice", view: AnyView(label(Self.en)),
            constraints: [RelativePositionConstraint(type: .parentTop, targetId: "")],
            margins: EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0),
            widthMode: .fixed(200), heightMode: .wrapContent)
        let relative = RelativePositionContainer(children: [child], containerWidthMode: .matchParent, containerHeightMode: .matchParent)
        let expected = try lines(of: AnyView(label(Self.en).frame(width: 200).fixedSize(horizontal: false, vertical: true)), width: 375)
        let got = try lines(of: AnyView(relative), width: 375)
        XCTAssertEqual(got, expected, "fixed 200: \(got) lines drawn, \(expected) at 200pt")
    }

    /// wrapContent width: a text wider than the container is capped at the
    /// room it has (as Android's wrap_content is) and wraps there.
    @MainActor
    func testWrapContentWidthIsCappedAndShowsEveryLine() throws {
        let child = RelativeChildConfig(
            id: "notice", view: AnyView(label(Self.en)),
            constraints: [RelativePositionConstraint(type: .parentCenterHorizontal, targetId: "")],
            margins: EdgeInsets(top: 20, leading: 24, bottom: 0, trailing: 24),
            widthMode: .wrapContent, heightMode: .wrapContent)
        let relative = RelativePositionContainer(children: [child], containerWidthMode: .matchParent, containerHeightMode: .matchParent)
        let expected = try lines(of: AnyView(label(Self.en).frame(width: 327).fixedSize(horizontal: false, vertical: true)), width: 375)
        let got = try lines(of: AnyView(relative), width: 375)
        XCTAssertEqual(got, expected, "wrapContent: \(got) lines drawn, \(expected) within 327pt")
    }

    /// A short wrapContent child keeps its natural width (it is not
    /// stretched to the room it has): the control for the cap above.
    @MainActor
    func testWrapContentWidthOfAShortChildStaysNatural() throws {
        let box = FrameBox()
        let child = RelativeChildConfig(
            id: "dot", view: AnyView(Color.black.frame(width: 30, height: 10).background(FrameReader(box: box))),
            constraints: [RelativePositionConstraint(type: .parentLeft, targetId: "")],
            widthMode: .wrapContent, heightMode: .wrapContent)
        let relative = RelativePositionContainer(children: [child], containerWidthMode: .matchParent, containerHeightMode: .matchParent)
        _ = try lines(of: AnyView(relative), width: 375)
        XCTAssertEqual(box.frame.width, 30, accuracy: 0.5)
    }

    /// The container's own wrapContent height (sizeThatFits) must hold the
    /// wrapped text too. Read from the container's frame, not from the lines
    /// drawn: a container measured too short still draws every line, past
    /// its own bottom (nothing clips it), and whatever comes next in the
    /// column overlaps them. Measured: the lines-drawn form of this arm
    /// stayed green with sizeThatFits measuring unconstrained.
    @MainActor
    func testWrapContentContainerIsTallEnoughForTheWrappedText() throws {
        let box = FrameBox()
        let child = RelativeChildConfig(
            id: "notice", view: AnyView(label(Self.en)),
            constraints: [RelativePositionConstraint(type: .parentTop, targetId: "")],
            margins: EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24),
            widthMode: .matchParent, heightMode: .wrapContent)
        let relative = RelativePositionContainer(children: [child], containerWidthMode: .matchParent, containerHeightMode: .wrapContent)
        let column = VStack(spacing: 0) { relative.background(FrameReader(box: box)); Spacer(minLength: 0) }
        _ = try lines(of: AnyView(column), width: 375)
        let needed = UIHostingController(rootView: label(Self.en)).sizeThatFits(in: CGSize(width: 327, height: CGFloat.greatestFiniteMagnitude)).height
        let oneLine = UIHostingController(rootView: label("Thank you for shopping with us.")).sizeThatFits(in: CGSize(width: 327, height: CGFloat.greatestFiniteMagnitude)).height
        XCTAssertGreaterThan(needed, oneLine * 4, "the text must wrap into a fifth line at 327pt (else this case proves nothing)")
        XCTAssertGreaterThanOrEqual(box.frame.height, needed - 0.5, "the wrapContent container is \(box.frame.height)pt tall; the text needs \(needed)pt at 327pt")
    }

    // MARK: termination (more measuring per layout must still finish)

    /// The layout now measures a child up to three times (unconstrained, at
    /// the capped width, at the placed width), and each measurement of a
    /// nested container measures its own children again: nesting multiplies.
    /// Containers 1 to 6 deep, the innermost a wrapping text: every depth
    /// lays out, shows every line, and the innermost text is measured a
    /// bounded number of times (printed per depth as RELATIVE_NEST).
    @MainActor
    func testNestedContainersFinishAndShowEveryLine() throws {
        for depth in 1...6 {
            let counter = Counter()
            var view = AnyView(CountingLayout(counter: counter) { label(Self.en) })
            for _ in 0..<depth {
                let child = RelativeChildConfig(
                    id: "level", view: view,
                    constraints: [RelativePositionConstraint(type: .parentTop, targetId: "")],
                    margins: EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4),
                    widthMode: .matchParent, heightMode: .wrapContent)
                view = AnyView(RelativePositionContainer(children: [child], containerWidthMode: .matchParent, containerHeightMode: .wrapContent))
            }
            let started = Date()
            let got = try lines(of: AnyView(VStack(spacing: 0) { view; Spacer(minLength: 0) }), width: 375)
            let seconds = Date().timeIntervalSince(started)
            let expected = try lines(of: AnyView(label(Self.en).frame(width: 375 - CGFloat(8 * depth)).fixedSize(horizontal: false, vertical: true)), width: 375)
            print("RELATIVE_NEST depth=\(depth) measured=\(counter.n) seconds=\(String(format: "%.2f", seconds)) lines=\(got)/\(expected)")
            XCTAssertEqual(got, expected, "depth \(depth): \(got) lines drawn, \(expected) expected")
            XCTAssertLessThan(seconds, 5, "depth \(depth) took \(seconds)s to lay out")
        }
    }

    /// Two children placed below each other (a cycle the constraint solver
    /// breaks by order), both wrapping: the layout finishes and draws both.
    @MainActor
    func testCircularConstraintsWithWrappingTextFinish() throws {
        let a = RelativeChildConfig(
            id: "a", view: AnyView(label(Self.en)),
            constraints: [RelativePositionConstraint(type: .below, targetId: "b")],
            margins: EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24),
            widthMode: .matchParent, heightMode: .wrapContent)
        let b = RelativeChildConfig(
            id: "b", view: AnyView(label(Self.ja)),
            constraints: [RelativePositionConstraint(type: .below, targetId: "a")],
            margins: EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24),
            widthMode: .matchParent, heightMode: .wrapContent)
        let relative = RelativePositionContainer(children: [a, b], containerWidthMode: .matchParent, containerHeightMode: .matchParent)
        let started = Date()
        let got = try lines(of: AnyView(relative), width: 375)
        XCTAssertLessThan(Date().timeIntervalSince(started), 5)
        XCTAssertGreaterThan(got, 0, "nothing drawn")
    }

    /// Laying the same view out twice puts every child in the same place:
    /// the measurement is a pure function of the proposal, not something
    /// that moves between passes.
    @MainActor
    func testLayingOutTwiceIsStable() throws {
        let box = FrameBox()
        let child = RelativeChildConfig(
            id: "notice", view: AnyView(label(Self.en).background(FrameReader(box: box))),
            constraints: [RelativePositionConstraint(type: .parentBottom, targetId: "")],
            margins: EdgeInsets(top: 0, leading: 24, bottom: 40, trailing: 24),
            widthMode: .matchParent, heightMode: .wrapContent)
        let relative = RelativePositionContainer(children: [child], containerWidthMode: .matchParent, containerHeightMode: .matchParent)
        _ = try lines(of: AnyView(relative), width: 375)
        let first = box.frame
        _ = try lines(of: AnyView(relative), width: 375)
        XCTAssertEqual(box.frame, first, "second layout moved the label: \(first) then \(box.frame)")
        XCTAssertGreaterThan(first.height, 0)
    }

    // MARK: Dynamic

    /// The same Label through Dynamic: a relative attribute makes
    /// Dynamic lay the parent out with RelativePositionContainer. The control
    /// is the same Label in a vertical column, where it showed every line.
    @MainActor
    func testDynamicLabelWithMarginsShowsEveryLine() throws {
        for (width, text, tag) in [(375.0, Self.en, "en 327"), (375.0, Self.ja, "ja 327")] {
            let escaped = text.replacingOccurrences(of: "\n", with: "\\n")
            let labelJSON = ##"{ "type": "Label", "id": "notice", "text": "\##(escaped)", "fontSize": 10, "fontColor": "#000000", "lineSpacing": 4, "textAlign": "center", "width": "matchParent", "height": "wrapContent", "leftMargin": 24, "rightMargin": 24, "bottomMargin": 40 RELATIVE }"##
            let relative = ##"{ "type": "View", "id": "root", "width": "matchParent", "height": "matchParent", "child": [ \##(labelJSON.replacingOccurrences(of: "RELATIVE", with: #", "alignBottom": true"#)) ] }"##
            let column = ##"{ "type": "View", "id": "root", "orientation": "vertical", "width": "matchParent", "height": "matchParent", "child": [ \##(labelJSON.replacingOccurrences(of: "RELATIVE", with: "")) ] }"##
            let expected = try lines(of: dynamic(column), width: width)
            let got = try lines(of: dynamic(relative), width: width)
            XCTAssertGreaterThan(expected, 4, "\(tag): the control must wrap (else this case proves nothing)")
            XCTAssertEqual(got, expected, "Dynamic \(tag): \(got) lines drawn with alignBottom, \(expected) in a vertical column")
        }
    }

    private func dynamic(_ json: String) throws -> AnyView {
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        return AnyView(DynamicComponentBuilder(component: component, data: [:], viewId: nil))
    }

    // MARK: measuring

    /// How many separate bands of dark pixels (text lines) the view draws,
    /// hosted at `width` x 600 on white.
    @MainActor
    private func lines(of content: AnyView, width: CGFloat) throws -> Int {
        let host = UIHostingController(rootView: content
            .frame(width: width, height: 600, alignment: .topLeading)
            .background(Color.white))
        if #available(iOS 16.4, *) { host.safeAreaRegions = [] }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 600))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
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
        var bands = 0
        var inBand = false
        for y in 0..<h {
            var ink = false
            for x in 0..<w {
                let i = (y * w + x) * 4
                if buffer[i] < 140 && buffer[i + 1] < 140 && buffer[i + 2] < 140 { ink = true; break }
            }
            if ink && !inBand { bands += 1 }
            inBand = ink
        }
        return bands
    }
}

@available(iOS 16.0, *)
private final class FrameBox { var frame: CGRect = .zero }

private final class Counter { var n = 0 }

/// Passes its one child through and counts how often it is measured.
@available(iOS 16.0, *)
private struct CountingLayout: Layout {
    let counter: Counter
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        counter.n += 1
        return subviews.first?.sizeThatFits(proposal) ?? .zero
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
    }
}

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
