//
//  LabelRangeColorTests.swift
//  SwiftJsonUITests
//
//  A tappable range of a Label draws the colour its declaration gives it:
//  the declared fontColor wins over the link colour the platform would give
//  a link (4f ruling, jsonui-cli 1.9.0). SwiftUI draws a `.link` run in the
//  view's tint, over its foregroundColor; each case below reads the ink the
//  range is drawn in, with a control drawn without a handler.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class LabelRangeColorTests: XCTestCase {

    private let text = "Terms of Service and the rest"
    private let declared = (r: 0xFF, g: 0xC3, b: 0x64)

    /// The most frequent non-white colour in the first 120 × 40 points (the range), as RRGGBB.
    @MainActor
    private func ink<V: View>(_ view: V) throws -> String {
        let renderer = ImageRenderer(content: view.frame(width: 320, height: 40, alignment: .topLeading).background(Color.white))
        renderer.scale = 1
        guard let cg = renderer.cgImage else { throw XCTSkip("render produced no image") }
        var buf = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
        let ctx = CGContext(data: &buf, width: cg.width, height: cg.height, bitsPerComponent: 8,
                            bytesPerRow: cg.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
        var counts: [Int: Int] = [:]
        for y in 0..<min(40, cg.height) {
            for x in 0..<min(120, cg.width) {
                let i = (y * cg.width + x) * 4
                let rgb = (Int(buf[i]) << 16) | (Int(buf[i + 1]) << 8) | Int(buf[i + 2])
                if rgb != 0xFFFFFF { counts[rgb, default: 0] += 1 }
            }
        }
        guard let top = counts.max(by: { $0.value < $1.value })?.key else { return "none" }
        return String(format: "%06X", top)
    }

    private func range(_ onClick: (() -> Void)?) -> [PartialAttribute] {
        [PartialAttribute(textPattern: "Terms of Service",
                          fontColor: Color(red: 1, green: 0xC3 / 255.0, blue: 0x64 / 255.0),
                          onClick: onClick)]
    }

    @MainActor
    func testATappableRangeDrawsItsDeclaredColour() throws {
        let control = try ink(PartialAttributedText(text, partialAttributes: range(nil)))
        let tappable = try ink(PartialAttributedText(text, partialAttributes: range({})))
        let tinted = try ink(PartialAttributedText(text, partialAttributes: range({})).tint(.purple))
        // The measurement's own control: a link run with no colour of its own
        // takes the tint, so this renderer does draw link styling.
        let bare = [PartialAttribute(textPattern: "Terms of Service", onClick: {})]
        let plain = try ink(PartialAttributedText(text, partialAttributes: [PartialAttribute(textPattern: "Terms of Service")]).tint(.purple))
        let linkTinted = try ink(PartialAttributedText(text, partialAttributes: bare).tint(.purple))
        XCTAssertNotEqual(linkTinted, plain, "control: a bare link draws as plain text here (\(linkTinted)) — the renderer shows no link styling")
        XCTAssertEqual(control, "FFC364", "control: a range with no handler draws its fontColor")
        XCTAssertEqual(tappable, control, "a range with a handler draws otherwise than its declaration")
        XCTAssertEqual(tinted, control, "a range with a handler takes the view's tint")
    }
}
#endif
