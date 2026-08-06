//
//  DynamicRelativeMarginTests.swift
//  SwiftJsonUITests
//
//  Margins double-applied on the relative-positioning path (49-B, the
//  parity "align" family — 10 fixtures, one mechanism):
//  RelativePositioningContainer places each slot using the child's FULL
//  individual margins (RelativePositionConverter.buildMargins), and
//  DynamicComponentBuilder's margin pass padded the same margins again.
//  Inside the fixed, centre-anchored slot the padding shifts the content by
//  (leading−trailing)/2 — margins (120, 0) drew the anchor at (+60, +60).
//
//  Repro is 49-B's, verbatim: decode the alignBottomView__static layout →
//  DynamicComponentBuilder at 390×500 → ImageRenderer → scan for #CCCCCC.
//  Correct picture: the 200×200 target (bottom-aligned to the anchor)
//  covers the anchor completely — ZERO #CCCCCC pixels. The broken picture
//  leaks a ~50×50 #CCCCCC block around (180,180)-(230,230), outside the
//  target's cover.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class DynamicRelativeMarginTests: XCTestCase {

    // The alignBottomView__static conformance layout (fixtures are
    // @generated in the tool repo; this is the same tree inlined).
    private let layout = """
    {
      "type": "View", "id": "root", "width": "matchParent", "height": "matchParent",
      "child": [
        { "type": "View", "id": "anchor", "width": 50, "height": 50,
          "background": "#CCCCCC", "topMargin": 120, "leftMargin": 120 },
        { "type": "View", "id": "target", "width": 200, "height": 200,
          "background": "#DDDDDD", "alignBottomView": "anchor",
          "child": [
            { "type": "View", "id": "box_a", "width": 40, "height": 40, "background": "#FF0000" }
          ] }
      ]
    }
    """

    @MainActor
    func testRelativeChildMarginsAreNotAppliedTwice() throws {
        let component = try JSONDecoder().decode(
            DynamicComponent.self, from: layout.data(using: .utf8)!
        )
        let view = DynamicComponentBuilder(component: component, data: [:], viewId: nil)
            .frame(width: 390, height: 500)
            .background(Color.white)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(width: 390, height: 500)
        guard let cg = renderer.cgImage else {
            XCTFail("render produced no image")
            return
        }

        let counts = pixelCounts(cg, colors: [
            "anchor": (204, 204, 204),   // #CCCCCC
            "target": (221, 221, 221),   // #DDDDDD
        ])

        XCTAssertGreaterThan(
            counts["target"] ?? 0, 10_000,
            "the target must actually render (a blank picture must not pass)"
        )
        XCTAssertEqual(
            counts["anchor"] ?? 0, 0,
            "the anchor belongs at (120,120) under the target's cover — visible " +
            "#CCCCCC means its margins moved it twice (the (+60,+60) drift)"
        )
    }

    /// Count pixels within ±2 of each reference RGB.
    private func pixelCounts(
        _ image: CGImage, colors: [String: (Int, Int, Int)]
    ) -> [String: Int] {
        let width = image.width, height = image.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let ctx = CGContext(
            data: &buffer, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        var counts: [String: Int] = [:]
        for i in stride(from: 0, to: buffer.count, by: 4) {
            let r = Int(buffer[i]), g = Int(buffer[i + 1]), b = Int(buffer[i + 2])
            for (name, ref) in colors where
                abs(r - ref.0) <= 2 && abs(g - ref.1) <= 2 && abs(b - ref.2) <= 2 {
                counts[name, default: 0] += 1
            }
        }
        return counts
    }
}
#endif // DEBUG
