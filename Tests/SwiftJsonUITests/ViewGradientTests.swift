//
//  ViewGradientTests.swift
//  SwiftJsonUITests
//
//  `View.gradient` is DECLARED as an array of colours; the dynamic container
//  accepted only a dictionary, so the declared spelling cast to nil and drew
//  nothing — `View/gradient__static` plus every `gradientDirection__*` row
//  measured inert on ios for that single reason (51-E2 §2).
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class ViewGradientTests: XCTestCase {

    private func view(_ dict: [String: Any]) -> DynamicComponent {
        var d: [String: Any] = ["type": "View", "width": 100, "height": 100]
        d.merge(dict) { _, new in new }
        let data = try! JSONSerialization.data(withJSONObject: d)
        return try! JSONDecoder().decode(DynamicComponent.self, from: data)
    }

    // The declared shape has to survive decode as an array — the cast that
    // used to drop it was `as? [String: Any]`.
    func testDeclaredArrayFormReachesTheTypedTable() {
        let c = view(["gradient": ["#FF0000", "#0000FF"]])
        let colors = c.typedAttributes(ViewAttributes.self).gradient?.compactMap { $0 as? String }
        XCTAssertEqual(colors, ["#FF0000", "#0000FF"])
    }

    // The wider legacy dictionary the tool also emits still arrives, through
    // the raw passthrough rather than the typed field.
    func testLegacyDictionaryFormStillArrives() {
        let c = view(["gradient": ["colors": ["#FF0000", "#0000FF"], "startPoint": "leading"]])
        XCTAssertNotNil(c.rawData["gradient"] as? [String: Any])
    }

    // gradientDirection was read by nothing. All eight declared spellings must
    // resolve, including the three the SSoT folds by alias.
    func testEveryDeclaredDirectionSpellingResolves() {
        // The generated enum's rawValue IS the canonical declared spelling,
        // so the aliases fold onto the capitalised canonical name.
        let expected: [String: String] = [
            "Vertical": "Vertical", "TopToBottom": "Vertical",
            "Horizontal": "Horizontal", "LeftToRight": "Horizontal",
            "Oblique": "Oblique", "Diagonal": "Oblique",
            "RightToLeft": "RightToLeft", "BottomToTop": "BottomToTop"
        ]
        for (declared, canonical) in expected {
            let c = view(["gradient": ["#FF0000", "#0000FF"], "gradientDirection": declared])
            XCTAssertEqual(
                c.enumString(ViewAttributes.self, \.gradientDirection), canonical,
                "\(declared) must fold to \(canonical)"
            )
        }
    }

    // RightToLeft and BottomToTop are canonical values, not aliases — they are
    // the two the codegen has no case arm for, so they must not quietly become
    // Vertical here either.
    func testRightToLeftAndBottomToTopAreNotVertical() {
        for spelling in ["RightToLeft", "BottomToTop"] {
            let c = view(["gradient": ["#FF0000"], "gradientDirection": spelling])
            XCTAssertNotEqual(c.enumString(ViewAttributes.self, \.gradientDirection), "Vertical")
        }
    }
}
#endif
