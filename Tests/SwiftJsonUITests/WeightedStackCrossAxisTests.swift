//
//  WeightedStackCrossAxisTests.swift
//  SwiftJsonUITests
//
//  A weighted stack's CROSS axis: a horizontal one whose height is wrapContent (or not declared) is as tall as its
//  tallest child, as Android's Row is; a vertical one is as wide as its widest child. With unequal weights the stack
//  is the Layout-protocol path (WeightedHStackLayout / WeightedVStackLayout), and it took the height (width) its
//  parent proposed instead: a 3:2 row of 56pt buttons in a card's column grew to the column's remaining height
//  (ticket sjui-weighted-hstack-wrap-content-takes-proposed-height). Equal weights take the native HStack / VStack,
//  which already wrapped, and are measured beside it as the reference.
//
//  Both routes: Dynamic (the JSON) and the codegen shape (what sjui_tools 2.5.32 emits for the same JSON,
//  transcribed: the children's frames, the stack's frame with its gravity alignment, the declared height's frame).
//  The stack's box is read from the rendered pixels: everything that is not the white page.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
@available(iOS 17.0, *)
final class WeightedStackCrossAxisTests: XCTestCase {

    private let pageWidth: CGFloat = 375
    private let pageHeight: CGFloat = 700

    // MARK: cases

    /// One declaration of the stack, and the box Android draws for it (KotlinJsonUI: Row / Column with
    /// `wrapContentHeight` / `fillMaxHeight` / `height(N)`, the weighted children `Modifier.weight`).
    private struct Case {
        let name: String
        let stack: String          // the stack's own attributes, JSON
        let children: [Child]
        let horizontal: Bool
        let want: CGRect           // the stack's box on the page
    }

    private struct Child {
        let weight: Double
        let cross: Cross           // height of a row's child, width of a column's child
        var gone = false
        var json: String {
            let size = horizontal ? "height" : "width"
            let crossValue: String
            switch cross {
            case .points(let p): crossValue = "\(Int(p))"
            case .matchParent: crossValue = "\"matchParent\""
            }
            let main = horizontal ? "\"width\": 0, " : "\"height\": 0, "
            return ##"{"type": "View", \##(main)"\##(size)": \##(crossValue), "weight": \##(weight), "background": "#FF0000""##
                + (gone ? ##", "visibility": "gone""## : "") + "}"
        }
        var horizontal = true
    }

    private enum Cross { case points(CGFloat), matchParent }

    private func row(_ name: String, _ stack: String, _ children: [Child], want height: CGFloat, y: CGFloat = 0) -> Case {
        Case(name: name, stack: stack, children: children, horizontal: true,
             want: CGRect(x: 0, y: y, width: pageWidth, height: height))
    }

    private func column(_ name: String, _ stack: String, _ children: [Child], want width: CGFloat) -> Case {
        Case(name: name, stack: stack, children: children.map { var c = $0; c.horizontal = false; return c },
             horizontal: false, want: CGRect(x: 0, y: 0, width: width, height: pageHeight))
    }

    private var cases: [Case] {
        let a = Child(weight: 3, cross: .points(56)), b = Child(weight: 2, cross: .points(40))
        let fill = Child(weight: 2, cross: .matchParent)
        var gone = Child(weight: 2, cross: .points(80)); gone.gone = true
        let a1 = Child(weight: 1, cross: .points(56)), b1 = Child(weight: 1, cross: .points(40))
        let ca = Child(weight: 3, cross: .points(120)), cb = Child(weight: 2, cross: .points(80))
        return [
            // the reported shape: unequal weights, wrapContent / not declared
            row("3:2 wrapContent", ##""height": "wrapContent""##, [a, b], want: 56),
            row("3:2 height not declared", "", [a, b], want: 56),
            row("3:2 wrapContent, a matchParent child", ##""height": "wrapContent""##, [a, fill], want: pageHeight),
            row("3:2 wrapContent, a gone child", ##""height": "wrapContent""##, [a, gone], want: 56),
            // decided heights keep the proposal
            row("3:2 matchParent", ##""height": "matchParent""##, [a, b], want: pageHeight),
            row("3:2 height 120", ##""height": 120"##, [a, b], want: 120),
            // the native path, for reference
            row("1:1 wrapContent", ##""height": "wrapContent""##, [a1, b1], want: 56),
            row("1:1 height not declared", "", [a1, b1], want: 56),
            // the vertical stack's width
            column("3:2 column wrapContent width", ##""width": "wrapContent", "height": "matchParent""##, [ca, cb], want: 120),
            column("3:2 column width not declared", ##""height": "matchParent""##, [ca, cb], want: 120),
            column("3:2 column matchParent width", ##""width": "matchParent", "height": "matchParent""##, [ca, cb], want: pageWidth),
            column("3:2 column width 200", ##""width": 200, "height": "matchParent""##, [ca, cb], want: 200),
            column("1:1 column wrapContent width", ##""width": "wrapContent", "height": "matchParent""##,
                   [Child(weight: 1, cross: .points(120)), Child(weight: 1, cross: .points(80))], want: 120),
        ]
    }

    // MARK: Dynamic

    @MainActor
    func testDynamicWeightedStackCrossAxisIsItsChildrenUnlessDecided() throws {
        var wrong: [String] = []
        for c in cases {
            let orientation = c.horizontal ? "horizontal" : "vertical"
            let stackWidth = c.horizontal ? ##""width": "matchParent", "## : ""
            let stack = ##"{"type": "View", "orientation": "\##(orientation)", \##(stackWidth)"background": "#0000FF""##
                + (c.stack.isEmpty ? "" : ", " + c.stack)
                + ##", "child": [\##(c.children.map(\.json).joined(separator: ", "))]}"##
            let page = c.horizontal
                ? ##"{"type": "View", "orientation": "vertical", "width": "matchParent", "height": "matchParent", "child": [\##(stack)]}"##
                : ##"{"type": "View", "orientation": "horizontal", "width": "matchParent", "height": "matchParent", "child": [\##(stack)]}"##
            let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(page.utf8))
            let got = try inkBox(of: AnyView(DynamicComponentBuilder(component: component, data: [:], viewId: nil)))
            record(&wrong, "dynamic", c, got)
        }
        XCTAssertEqual(wrong, [], wrong.joined(separator: "\n"))
    }

    // MARK: codegen

    @MainActor
    func testCodegenWeightedStackCrossAxisIsItsChildrenUnlessDecided() throws {
        var wrong: [String] = []
        for c in cases {
            let got = try inkBox(of: codegen(c))
            record(&wrong, "codegen", c, got)
        }
        XCTAssertEqual(wrong, [], wrong.joined(separator: "\n"))
    }

    /// sjui_tools' emission for the case, transcribed: a child is `Rectangle().fill(...)` with
    /// `.frame(maxWidth: .infinity)` (a weighted child of a row) and its declared cross size as a min/ideal/max frame
    /// (`.frame(maxHeight: .infinity)` for matchParent); a gone child is not emitted. The stack carries
    /// `hasMatchParentCrossAxis: true` only for a matchParent height, then `.frame(maxWidth: .infinity, alignment:
    /// .topLeading)`, the declared cross size's frame, and its background.
    @MainActor
    private func codegen(_ c: Case) -> AnyView {
        let children: [(view: AnyView, weight: CGFloat)] = c.children.filter { !$0.gone }.map { child in
            var v = AnyView(Rectangle().fill(Color(red: 1, green: 0, blue: 0)))
            switch (c.horizontal, child.cross) {
            case (true, .points(let p)):
                v = AnyView(v.frame(maxWidth: .infinity).frame(minHeight: p, idealHeight: p, maxHeight: p))
            case (true, .matchParent):
                v = AnyView(v.frame(maxWidth: .infinity).frame(maxHeight: .infinity))
            case (false, .points(let p)):
                v = AnyView(v.frame(maxHeight: .infinity).frame(minWidth: p, idealWidth: p, maxWidth: p))
            case (false, .matchParent):
                v = AnyView(v.frame(maxHeight: .infinity).frame(maxWidth: .infinity))
            }
            return (view: v, weight: CGFloat(child.weight))
        }
        let blue = Color(red: 0, green: 0, blue: 1)
        if c.horizontal {
            let match = c.stack.contains("matchParent")
            var stack = AnyView(WeightedHStack(alignment: .top, spacing: 0, children: children, hasMatchParentCrossAxis: match)
                .frame(maxWidth: .infinity, maxHeight: match ? .infinity : nil, alignment: .topLeading))
            if let h = fixed(c.stack, "height") {
                stack = AnyView(stack.frame(minHeight: h, idealHeight: h, maxHeight: h, alignment: .topLeading))
            }
            return AnyView(VStack(alignment: .leading, spacing: 0) {
                stack.background(blue)
                Spacer(minLength: 0)
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading))
        }
        let matchWidth = c.stack.contains(##""width": "matchParent""##)
        var stack = AnyView(WeightedVStack(alignment: .leading, spacing: 0, children: children)
            .frame(maxWidth: matchWidth ? .infinity : nil, maxHeight: .infinity, alignment: .topLeading))
        if let w = fixed(c.stack, "width") {
            stack = AnyView(stack.frame(minWidth: w, idealWidth: w, maxWidth: w, alignment: .topLeading))
        }
        return AnyView(HStack(alignment: .top, spacing: 0) {
            stack.background(blue)
            Spacer(minLength: 0)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading))
    }

    /// A weighted child that wraps is measured at the width it is drawn at: the row is as tall as the text set in
    /// its 3/5 share, not as one line of it (the Layout path proposed `width: nil` when it measured the cross axis).
    @MainActor
    func testAWrappingWeightedChildIsMeasuredAtItsShare() throws {
        let words = String(repeating: "weighted stack wraps ", count: 12)
        let text = { Text(words).font(.system(size: 17)).foregroundColor(.black) }
        let share = pageWidth * 3 / 5
        let alone = try inkBox(of: AnyView(VStack(spacing: 0) {
            Rectangle().fill(Color(red: 0, green: 0, blue: 1)).frame(width: share)
                .overlay(alignment: .topLeading) { text().frame(width: share, alignment: .leading).fixedSize(horizontal: false, vertical: true) }
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)))
        let row = try inkBox(of: AnyView(VStack(alignment: .leading, spacing: 0) {
            WeightedHStack(alignment: .top, spacing: 0, children: [
                (view: AnyView(text().frame(maxWidth: .infinity, alignment: .leading)), weight: 3),
                (view: AnyView(Color.clear.frame(maxWidth: .infinity).frame(height: 10)), weight: 2),
            ])
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(Color(red: 0, green: 0, blue: 1))
            Spacer(minLength: 0)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)))
        print("WEIGHTED_CROSS wrapping text: row \(row) alone \(alone)")
        XCTAssertGreaterThan(alone.height, 40, "the text wraps to several lines in its share")
        XCTAssertEqual(row.height, alone.height, accuracy: 1, "the row is as tall as its text set at its share")
    }

    private func fixed(_ json: String, _ key: String) -> CGFloat? {
        guard let r = json.range(of: ##""\##(key)": (\d+)"##, options: .regularExpression) else { return nil }
        return CGFloat(Int(json[r].split(separator: " ").last!)!)
    }

    private func record(_ wrong: inout [String], _ route: String, _ c: Case, _ got: CGRect) {
        let ok = abs(got.minX - c.want.minX) < 1 && abs(got.minY - c.want.minY) < 1
            && abs(got.width - c.want.width) < 1 && abs(got.height - c.want.height) < 1
        print("WEIGHTED_CROSS \(route) \(c.name): \(got) want \(c.want) \(ok ? "ok" : "WRONG")")
        if !ok { wrong.append("\(route) \(c.name): stack \(got), want \(c.want)") }
    }

    // MARK: hosting

    /// The box (in points) of every pixel that is not the white page.
    @MainActor
    private func inkBox(of content: AnyView) throws -> CGRect {
        let host = UIHostingController(rootView: content.frame(width: pageWidth, height: pageHeight, alignment: .topLeading)
            .background(Color.white))
        host.safeAreaRegions = []
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
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
                if !(buffer[i] > 245 && buffer[i + 1] > 245 && buffer[i + 2] > 245) {
                    minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
                }
            }
        }
        guard maxX >= 0 else { return .null }
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }
}
#endif // DEBUG
