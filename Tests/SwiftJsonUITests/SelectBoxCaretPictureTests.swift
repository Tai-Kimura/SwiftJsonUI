//
//  SelectBoxCaretPictureTests.swift
//
//  caretAttributes.tintColor paints the default chevron only; the app's own
//  picture (`src`) keeps its own colours (the requester's ruling 2026-11-14,
//  the three faces alike; ticket kjui-date-selectbox-caret-attributes-not-
//  emitted). SelectBoxView drew a template asset in tintColor, or gray without
//  one. The list box and the date box draw the one caretGlyph.
//

import XCTest
import SwiftUI
import UIKit
@testable import SwiftJsonUI

@MainActor
final class SelectBoxCaretPictureTests: XCTestCase {
    private var savedPicture: ((String) -> Image)!

    override func setUp() {
        super.setUp()
        savedPicture = SelectBoxView.caretPicture
        // A red square marked as a template, as an asset catalog's template image is.
        let red = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24)).image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 24, height: 24))
        }.withRenderingMode(.alwaysTemplate)
        SelectBoxView.caretPicture = { _ in Image(uiImage: red) }
    }

    override func tearDown() {
        SelectBoxView.caretPicture = savedPicture
        super.tearDown()
    }

    /// The pixels near (r, g, b) in the caret drawn alone, 24 x 24 at scale 1.
    private func count(_ caret: SelectBoxView.CaretAttributes, r: CGFloat, g: CGFloat, b: CGFloat) throws -> Int {
        let renderer = ImageRenderer(content: SelectBoxView.caretGlyph(caret).frame(width: 24, height: 24))
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.uiImage?.cgImage)
        let w = image.width, h = image.height
        var bytes = [UInt8](repeating: 0, count: w * h * 4)
        let ctx = try XCTUnwrap(CGContext(data: &bytes, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        var n = 0
        for i in stride(from: 0, to: bytes.count, by: 4) where bytes[i + 3] > 200 {
            let pr = CGFloat(bytes[i]) / 255, pg = CGFloat(bytes[i + 1]) / 255, pb = CGFloat(bytes[i + 2]) / 255
            if abs(pr - r) < 0.15 && abs(pg - g) < 0.15 && abs(pb - b) < 0.15 { n += 1 }
        }
        return n
    }

    /// (2) A template picture without tintColor keeps its red; it was painted gray.
    func testTheAppsPictureKeepsItsColoursWithoutATint() throws {
        let caret = SelectBoxView.CaretAttributes(src: "calendar", width: 24, height: 24)
        XCTAssertGreaterThan(try count(caret, r: 1, g: 0, b: 0), 400, "the picture is drawn in its own red")
    }

    /// (2) ... and with one: tintColor does not paint the picture.
    func testTintColorDoesNotPaintTheAppsPicture() throws {
        let caret = SelectBoxView.CaretAttributes(src: "calendar", width: 24, height: 24, tintColor: Color(red: 0, green: 0.8, blue: 0))
        XCTAssertGreaterThan(try count(caret, r: 1, g: 0, b: 0), 400, "the picture keeps its red")
        XCTAssertEqual(try count(caret, r: 0, g: 0.8, b: 0), 0, "no pixel in the tint")
    }

    /// (1) tintColor paints the default chevron (it did, and stays so: the rule's other half).
    func testTintColorPaintsTheDefaultChevron() throws {
        let caret = SelectBoxView.CaretAttributes(width: 24, height: 24, tintColor: Color(red: 0, green: 0.8, blue: 0))
        XCTAssertGreaterThan(try count(caret, r: 0, g: 0.8, b: 0), 5, "the chevron is drawn in the tint")
    }
}
