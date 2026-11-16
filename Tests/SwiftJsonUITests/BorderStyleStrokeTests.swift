//
//  BorderStyleStrokeTests.swift
//  SwiftJsonUITests
//
//  `common.borderStyle` (solid / dashed / dotted) — #18.
//
//  ios was the one platform that drew every border solid: the Dynamic
//  overlay stroked with `lineWidth:` and never read the attribute, while
//  base_view_converter.rb#stroke_style_argument had been emitting the dash
//  patterns all along. The contract recorded the fixture inert on ios only.
//
//  The dash numbers are the generator's, taken from Compose's
//  DashedBorderModifier.kt, so the assertions below are pinning THREE
//  implementations to one set of constants — changing them here without
//  changing the generator re-opens the split.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class BorderStyleStrokeTests: XCTestCase {

    func testDashedUsesTheGeneratorsPattern() {
        let style = DynamicModifierHelper.strokeStyle(.known(.dashed), borderWidth: 2)
        XCTAssertEqual(style.lineWidth, 2)
        XCTAssertEqual(style.dash, [6, 3], "base_view_converter.rb: dash: [6, 3]")
    }

    func testDottedScalesWithBorderWidthAndRoundsTheCap() {
        let style = DynamicModifierHelper.strokeStyle(.known(.dotted), borderWidth: 4)
        XCTAssertEqual(style.lineWidth, 4)
        XCTAssertEqual(style.dash, [4, 8], "dash: [width, width * 2]")
        XCTAssertEqual(style.lineCap, .round)
    }

    func testSolidAndUndeclaredAreAPlainStroke() {
        for declared in [AttrEnum<CommonAttributes.BorderStyle>.known(.solid), nil] {
            let style = DynamicModifierHelper.strokeStyle(declared, borderWidth: 3)
            XCTAssertEqual(style.lineWidth, 3)
            XCTAssertTrue(style.dash.isEmpty, "solid must not dash")
        }
    }

    /// An undeclared spelling is `.unknown` (open enum), not a parse failure.
    /// It must render as a plain stroke rather than dropping the border.
    func testUnknownSpellingFallsBackToPlain() {
        let style = DynamicModifierHelper.strokeStyle(.unknown("groovy"), borderWidth: 1)
        XCTAssertEqual(style.lineWidth, 1)
        XCTAssertTrue(style.dash.isEmpty)
    }

    /// `borderStyle` alone summons no border — style decorates a border the
    /// width/color pair requests (shared/core/attribute_semantics.json).
    /// This is why the plain `common/borderStyle__dashed` fixture is
    /// CORRECTLY inert and only the `_with_border` variant can measure it.
    func testStyleAloneDrawsNothing() throws {
        let component = try JSONDecoder().decode(
            DynamicComponent.self,
            from: #"{ "type": "View", "id": "target", "borderStyle": "dashed" }"#.data(using: .utf8)!
        )
        let common = component.typedAttributes(CommonAttributes.self)
        XCTAssertNotNil(common.borderStyle, "declared")
        XCTAssertNil(common.borderWidth, "…but no border to decorate")
        XCTAssertNil(component.commonString(\.borderColor))
    }
}
#endif
