//
//  RelativeFacingLinkAnchorMarginTests.swift
//  SwiftJsonUITests
//
//  A view placed with a FACING link (alignTopOfView / alignBottomOfView /
//  alignLeftOfView / alignRightOfView) meets the box the anchor DRAWS. The
//  layout holds the anchor at that box already (its own margin applied), and
//  the four facing links used to apply the anchor's margin a second time: with
//  the conformance anchor (topMargin / leftMargin 120) alignTopOfView put a
//  50-high target at y -50 where Android and web draw 70 (frame-parity,
//  support lane 1's iOS frames, 2026-10-05; ticket
//  sjui-relative-facing-link-measures-the-anchor-with-its-margin). Same shape
//  as KotlinJsonUI 2.43.4's fix.
//
//  The anchor here has a margin on ALL FOUR edges, so every facing link is at
//  a position that tells the two readings apart — the conformance anchor has
//  none on its bottom / right, where below / rightOf agree either way.
//
//  Two routes reach the one Layout: Dynamic (DynamicComponentBuilder) and the
//  container sjui_tools codegen emits (RelativePositionContainer of
//  RelativeChildConfig with margins and constraints). Both are drawn and
//  measured.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class RelativeFacingLinkAnchorMarginTests: XCTestCase {

    // Anchor 50 x 50 drawn at (120, 120): top / left margin 120, bottom /
    // right margin 30. Each target is 40 x 40 in its own colour.
    private static let colors: [String: (Int, Int, Int)] = [
        "anchor": (204, 204, 204),   // #CCCCCC
        "above": (255, 0, 0),        // #FF0000
        "below": (0, 0, 255),        // #0000FF
        "leftOf": (0, 170, 0),       // #00AA00
        "rightOf": (255, 170, 0),    // #FFAA00
    ]

    // Where each box belongs: the facing edge meets the anchor's drawn edge.
    // The pre-fix reading adds the anchor's margin on that side: above /
    // leftOf go off the canvas (-40...0), below / rightOf land 30 too far.
    private static let expected: [String: CGRect] = [
        "anchor": CGRect(x: 120, y: 120, width: 50, height: 50),
        "above": CGRect(x: 0, y: 80, width: 40, height: 40),
        "below": CGRect(x: 0, y: 170, width: 40, height: 40),
        "leftOf": CGRect(x: 80, y: 0, width: 40, height: 40),
        "rightOf": CGRect(x: 170, y: 0, width: 40, height: 40),
    ]

    private let layout = """
    {
      "type": "View", "id": "root", "width": "matchParent", "height": "matchParent",
      "child": [
        { "type": "View", "id": "anchor", "width": 50, "height": 50, "background": "#CCCCCC",
          "topMargin": 120, "leftMargin": 120, "bottomMargin": 30, "rightMargin": 30 },
        { "type": "View", "id": "t_above", "width": 40, "height": 40, "background": "#FF0000",
          "alignTopOfView": "anchor" },
        { "type": "View", "id": "t_below", "width": 40, "height": 40, "background": "#0000FF",
          "alignBottomOfView": "anchor" },
        { "type": "View", "id": "t_left", "width": 40, "height": 40, "background": "#00AA00",
          "alignLeftOfView": "anchor" },
        { "type": "View", "id": "t_right", "width": 40, "height": 40, "background": "#FFAA00",
          "alignRightOfView": "anchor" }
      ]
    }
    """

    @MainActor
    func testDynamicFacingLinksMeetTheAnchorsDrawnBox() throws {
        let component = try JSONDecoder().decode(
            DynamicComponent.self, from: layout.data(using: .utf8)!
        )
        let view = DynamicComponentBuilder(component: component, data: [:], viewId: nil)
        try assertBoxes(of: AnyView(view), route: "Dynamic")
    }

    /// The shape relative_positioning_helper.rb emits: margins on the config,
    /// the facing link as a RelativePositionConstraint, an unconstrained
    /// anchor given parentTop + parentLeft.
    @MainActor
    func testCodegenContainerFacingLinksMeetTheAnchorsDrawnBox() throws {
        func box(_ hex: Color) -> AnyView {
            AnyView(Rectangle().fill(hex).frame(width: 40, height: 40))
        }
        let children = [
            RelativeChildConfig(
                id: "anchor",
                view: AnyView(Rectangle().fill(Color(red: 0.8, green: 0.8, blue: 0.8)).frame(width: 50, height: 50)),
                constraints: [
                    RelativePositionConstraint(type: .parentTop, targetId: ""),
                    RelativePositionConstraint(type: .parentLeft, targetId: ""),
                ],
                margins: EdgeInsets(top: 120, leading: 120, bottom: 30, trailing: 30),
                widthMode: .fixed(50), heightMode: .fixed(50)
            ),
            RelativeChildConfig(
                id: "t_above", view: box(Color(red: 1, green: 0, blue: 0)),
                constraints: [RelativePositionConstraint(type: .above, targetId: "anchor")],
                widthMode: .fixed(40), heightMode: .fixed(40)
            ),
            RelativeChildConfig(
                id: "t_below", view: box(Color(red: 0, green: 0, blue: 1)),
                constraints: [RelativePositionConstraint(type: .below, targetId: "anchor")],
                widthMode: .fixed(40), heightMode: .fixed(40)
            ),
            RelativeChildConfig(
                id: "t_left", view: box(Color(red: 0, green: 170.0 / 255, blue: 0)),
                constraints: [RelativePositionConstraint(type: .leftOf, targetId: "anchor")],
                widthMode: .fixed(40), heightMode: .fixed(40)
            ),
            RelativeChildConfig(
                id: "t_right", view: box(Color(red: 1, green: 170.0 / 255, blue: 0)),
                constraints: [RelativePositionConstraint(type: .rightOf, targetId: "anchor")],
                widthMode: .fixed(40), heightMode: .fixed(40)
            ),
        ]
        let view = RelativePositionContainer(
            children: children,
            containerWidthMode: .matchParent,
            containerHeightMode: .matchParent
        )
        try assertBoxes(of: AnyView(view), route: "codegen container")
    }

    // MARK: - measurement

    @MainActor
    private func assertBoxes(of content: AnyView, route: String) throws {
        let view = content
            .frame(width: 390, height: 500, alignment: .topLeading)
            .background(Color.white)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(width: 390, height: 500)
        guard let cg = renderer.cgImage else {
            XCTFail("\(route): render produced no image")
            return
        }
        let boxes = boundingBoxes(cg, colors: Self.colors)
        for (name, want) in Self.expected.sorted(by: { $0.key < $1.key }) {
            guard let got = boxes[name] else {
                XCTFail("\(route): \(name) drew nothing on the canvas — want \(want)" +
                        (name == "above" || name == "leftOf"
                         ? " (off the canvas is where the anchor's margin, applied twice, puts it)"
                         : ""))
                continue
            }
            XCTAssertEqual(got, want, "\(route): \(name) at \(got), want \(want)")
        }
    }

    /// The bounding box of the pixels within ±2 of each reference RGB.
    private func boundingBoxes(
        _ image: CGImage, colors: [String: (Int, Int, Int)]
    ) -> [String: CGRect] {
        let width = image.width, height = image.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let ctx = CGContext(
            data: &buffer, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        var minX: [String: Int] = [:], minY: [String: Int] = [:]
        var maxX: [String: Int] = [:], maxY: [String: Int] = [:]
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                let r = Int(buffer[i]), g = Int(buffer[i + 1]), b = Int(buffer[i + 2])
                for (name, ref) in colors where
                    abs(r - ref.0) <= 2 && abs(g - ref.1) <= 2 && abs(b - ref.2) <= 2 {
                    minX[name] = min(minX[name] ?? x, x); maxX[name] = max(maxX[name] ?? x, x)
                    minY[name] = min(minY[name] ?? y, y); maxY[name] = max(maxY[name] ?? y, y)
                }
            }
        }
        var out: [String: CGRect] = [:]
        for name in minX.keys {
            out[name] = CGRect(
                x: minX[name]!, y: minY[name]!,
                width: maxX[name]! - minX[name]! + 1, height: maxY[name]! - minY[name]! + 1
            )
        }
        return out
    }
}
#endif // DEBUG
