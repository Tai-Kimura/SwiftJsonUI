//
//  TintColorRenderTests.swift
//  SwiftJsonUITests
//
//  tintColor is the accent of the operable parts — a control's accent, a
//  link's colour, the cursor — never the text colour (jsonui-cli 1.9.0).
//  Label, Button, TextView and SelectBox did not draw it (their chains skip
//  applyStandardModifiers, where the tint stage lives); they apply `.tint`
//  now, as the sjui codegen does on the same components. What that changes on
//  screen is measured here: each type drawn with a red and a blue tint, and
//  the pixels that differ counted.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
@MainActor
final class TintColorRenderTests: XCTestCase {

    private func render(_ node: String, width: CGFloat, height: CGFloat) throws -> [UInt8] {
        let component = try JSONDecoder().decode(DynamicComponent.self, from: node.data(using: .utf8)!)
        let view = DynamicComponentBuilder(component: component, data: [:], viewId: nil)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(width: width, height: height)
        guard let image = renderer.cgImage else { throw XCTSkip("render produced no image") }
        let w = image.width, h = image.height
        var buffer = [UInt8](repeating: 0, count: w * h * 4)
        let context = CGContext(data: &buffer, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        return buffer
    }

    /// Pixels that differ between a red and a blue tint, and the reddish /
    /// bluish pixels in each (a pixel whose red or blue channel dominates).
    private func measure(_ type: String, _ body: String, width: CGFloat = 320, height: CGFloat = 80) throws -> (differ: Int, red: Int, blue: Int) {
        func node(_ tint: String?) -> String {
            let tintPart = tint.map { #", "tintColor": "\#($0)""# } ?? ""
            return #"{ "type": "\#(type)", "width": \#(Int(width)), "height": \#(Int(height))\#(tintPart)\#(body) }"#
        }
        let red = try render(node("#FF0000"), width: width, height: height)
        let blue = try render(node("#0000FF"), width: width, height: height)
        var differ = 0, reddish = 0, bluish = 0
        for i in stride(from: 0, to: min(red.count, blue.count), by: 4) {
            if red[i] != blue[i] || red[i + 1] != blue[i + 1] || red[i + 2] != blue[i + 2] { differ += 1 }
            if red[i] > 180 && red[i + 1] < 90 && red[i + 2] < 90 { reddish += 1 }
            if blue[i + 2] > 180 && blue[i] < 90 && blue[i + 1] < 90 { bluish += 1 }
        }
        print("[tint-measure] \(type): differing pixels \(differ), red-tint reddish \(reddish), blue-tint bluish \(bluish)")
        return (differ, reddish, bluish)
    }

    /// A Label's link takes the tint: its colour follows it.
    func testALabelsLinkTakesTheTint() throws {
        let m = try measure("Label", #", "text": "see https://example.com", "linkable": true, "fontSize": 18"#)
        XCTAssertGreaterThan(m.differ, 0, "the link is drawn in the tint")
        XCTAssertGreaterThan(m.red, 0)
        XCTAssertGreaterThan(m.blue, 0)
    }

    /// Control: a Label without links draws its text in the text colour — the
    /// tint changes nothing on it (tintColor is not the text colour).
    func testALabelWithoutLinksIsNotRecoloured() throws {
        let m = try measure("Label", #", "text": "plain text only", "fontSize": 18"#)
        XCTAssertEqual(m.differ, 0, "tintColor is not the text colour")
    }

    /// Button, TextView, SelectBox: measured and printed. Their text colours are
    /// explicit; what the tint reaches on them is recorded, not assumed.
    func testTheOtherThreeAreMeasured() throws {
        _ = try measure("Button", #", "text": "Go""#, width: 200, height: 50)
        _ = try measure("TextView", #", "text": "hello""#, width: 300, height: 100)
        _ = try measure("SelectBox", #", "items": ["a", "b"]"#, width: 300, height: 50)
    }
}
#endif
