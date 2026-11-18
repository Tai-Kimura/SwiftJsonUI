//
//  LabelAutoShrinkAndHighlightAlignTests.swift
//  SwiftJsonUITests
//
//  Two places the Dynamic Label drew otherwise than Android and web, with or
//  without partialAttributes:
//  - autoShrink forced one line (lineLimit 1), where it shrinks only until the
//    text fits its box (attribute_semantics autoShrink, web canon): a
//    wrapContent height wraps, a bounded one shrinks its lines.
//  - a selected Label's highlightAttributes.textAlign reached the lines but not
//    the frame, so one line stayed at the start of a fixed width.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

@MainActor
final class LabelAutoShrinkAndHighlightAlignTests: XCTestCase {
    private let long = "Sample text long enough to wrap onto several lines inside the two hundred point wide hosts"

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }

    private func height(_ c: DynamicComponent) -> CGFloat {
        let view = VStack(alignment: .leading, spacing: 0) { LabelConverter.convert(component: c, data: [:], parentOrientation: "vertical") }
        return UIHostingController(rootView: view).sizeThatFits(in: CGSize(width: 402, height: CGFloat.infinity)).height
    }

    func testAutoShrinkUnderAWrapContentHeightWraps() throws {
        let partial = ##","partialAttributes":[{"range":[0,3],"fontColor":"#FF0000"}]"##
        for extra in ["", partial] {
            let wrapped = try component(##"{"type":"Label","width":200,"height":"wrapContent","text":"\##(long)","autoShrink":true\##(extra)}"##)
            let plain = try component(##"{"type":"Label","width":200,"height":"wrapContent","text":"\##(long)"\##(extra)}"##)
            XCTAssertEqual(height(wrapped), height(plain), accuracy: 0.5, "the same lines as without autoShrink (\(extra.isEmpty ? "plain" : "partial"))")
            XCTAssertGreaterThan(height(wrapped), 60, "several lines")
        }
    }

    func testAutoShrinkKeepsTheLinesItDeclares() throws {
        let one = try component(##"{"type":"Label","width":200,"height":"wrapContent","text":"\##(long)","autoShrink":true,"lines":1}"##)
        XCTAssertLessThan(height(one), 21)
    }

    func testASelectedLabelIsPlacedByTheHighlightsTextAlign() throws {
        let hl = ##""highlightAttributes":{"font":"bold","textAlign":"Center"}"##
        let selected = try component(##"{"type":"Label","width":200,"text":"Sample","selected":true,\##(hl)}"##)
        XCTAssertEqual(DynamicModifierHelper.labelHorizontal(selected), .center)
        let bound = try component(##"{"type":"Label","width":200,"text":"Sample","selected":"@{isOn}",\##(hl)}"##)
        XCTAssertEqual(DynamicModifierHelper.labelHorizontal(bound, data: ["isOn": true]), .center)
        XCTAssertEqual(DynamicModifierHelper.labelHorizontal(bound, data: ["isOn": false]), .leading)
        let never = try component(##"{"type":"Label","width":200,"text":"Sample",\##(hl)}"##)
        XCTAssertEqual(DynamicModifierHelper.labelHorizontal(never), .leading)
        let own = try component(##"{"type":"Label","width":200,"text":"Sample","textAlign":"Right","selected":false,\##(hl)}"##)
        XCTAssertEqual(DynamicModifierHelper.labelHorizontal(own), .trailing, "not selected: the Label's own")
    }
}
