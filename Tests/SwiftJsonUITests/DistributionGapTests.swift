//
//  DistributionGapTests.swift
//  SwiftJsonUITests
//
//  The ios gap collapse (5th-round collapsedPairs): equalSpacing and
//  equalCentering shared one spacer structure (edge 1 / between 1), so the
//  two distributions rendered the same picture. E's construction table —
//  canon in attribute_semantics.json — makes them distinct mechanically:
//
//    equalSpacing   = Spacer(minLength: 0) BETWEEN children only
//                     (first/last child flush at the edges)
//    equalCentering = 1 at each edge + 2 between (edge:gap = 1:2,
//                     so the child CENTERS are equally spaced)
//
//  Rendered with two 40pt children in a fixed 300pt row (free space 220):
//    equalSpacing:   red 0-40,   blue 260-300  (one 220pt gap)
//    equalCentering: 4 spacers × 55 → red 55-95, blue 205-245
//
//  The samples sit at `rowY`, inside the 40pt row, NOT at the vertical middle
//  of the 200pt container. They used to sit at y=100 because an omitted
//  gravity dropped the frame's alignment argument and SwiftUI centred the row
//  — which is precisely the deviation `gravityDefaults` names ("a platform
//  centering by default is the deviant"). With the omitted case resolving to
//  top | start the row sits at the top, so the sample row moves with it. This
//  file is about the HORIZONTAL gap construction; the y coordinate was never
//  its subject.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class DistributionGapTests: XCTestCase {

    /// Inside the 40pt row, which an omitted gravity now pins to the top.
    private let rowY = 20

    @MainActor
    private func render(_ distribution: String) throws -> (CGImage, Int, Int) {
        let layout = """
        {
          "type": "View", "id": "target", "width": 300, "height": 200,
          "background": "#DDDDDD", "orientation": "horizontal",
          "distribution": "\(distribution)",
          "child": [
            { "type": "View", "id": "box_a", "width": 40, "height": 40, "background": "#FF0000" },
            { "type": "View", "id": "box_b", "width": 40, "height": 40, "background": "#0000FF" }
          ]
        }
        """
        let component = try JSONDecoder().decode(
            DynamicComponent.self, from: layout.data(using: .utf8)!
        )
        let view = DynamicComponentBuilder(component: component, data: [:], viewId: nil)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(width: 300, height: 200)
        guard let cg = renderer.cgImage else {
            throw XCTSkip("render produced no image")
        }
        return (cg, cg.width, cg.height)
    }

    private func color(_ image: CGImage, _ x: Int, _ y: Int) -> (Int, Int, Int) {
        let w = image.width, h = image.height
        var buf = [UInt8](repeating: 0, count: w * h * 4)
        let ctx = CGContext(
            data: &buf, width: w, height: h, bitsPerComponent: 8,
            bytesPerRow: w * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        let i = (y * w + x) * 4
        return (Int(buf[i]), Int(buf[i + 1]), Int(buf[i + 2]))
    }

    private func isRed(_ c: (Int, Int, Int)) -> Bool { c.0 > 180 && c.1 < 80 && c.2 < 80 }
    private func isBlue(_ c: (Int, Int, Int)) -> Bool { c.2 > 180 && c.0 < 80 && c.1 < 80 }
    private func isBackground(_ c: (Int, Int, Int)) -> Bool {
        abs(c.0 - 221) <= 3 && abs(c.1 - 221) <= 3 && abs(c.2 - 221) <= 3
    }

    @MainActor
    func testEqualSpacingIsFlushAtTheEdges() throws {
        let (image, _, _) = try render("equalSpacing")
        XCTAssertTrue(isRed(color(image, 5, rowY)),
                      "equalSpacing pins the first child to the leading edge")
        XCTAssertTrue(isBlue(color(image, 295, rowY)),
                      "…and the last child to the trailing edge")
        XCTAssertTrue(isBackground(color(image, 150, rowY)),
                      "the single gap sits between them")
    }

    @MainActor
    func testEqualCenteringGivesTheEdgesHalfAGap() throws {
        let (image, _, _) = try render("equalCentering")
        XCTAssertTrue(isBackground(color(image, 5, rowY)),
                      "equalCentering leaves a half-gap at the leading edge")
        // The 1:2 ratio puts the first child at exactly 55-95 — a uniform
        // 3-spacer structure (edge 1 / between 1 / edge 1, the shape a
        // partial reversion produces) lands it at 73-113 instead, so pin
        // BOTH sides of the 55 boundary, not just a point inside the box.
        XCTAssertTrue(isBackground(color(image, 50, rowY)),
                      "background up to the 55pt edge spacer")
        XCTAssertTrue(isRed(color(image, 60, rowY)),
                      "first child starts at 55: edge gets ONE spacer of the four")
        XCTAssertTrue(isBlue(color(image, 240, rowY)),
                      "second child ends at 245, mirroring")
        XCTAssertTrue(isBackground(color(image, 250, rowY)),
                      "background after 245")
        XCTAssertTrue(isBackground(color(image, 295, rowY)),
                      "…and a half-gap at the trailing edge")
    }
}
#endif // DEBUG
