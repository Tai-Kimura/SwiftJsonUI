//
//  ButtonTextAlignmentTests.swift
//  SwiftJsonUITests
//
//  Where a Button's text sits across it (ButtonConverter.buttonTextAlignment):
//  textAlign by BUTTON's declared spelling, case and all (jsonui-cli
//  822e5efe). Button declares Left / Center / Right only, so any other
//  spelling — `left`, `LEFT`, `start`, `leading`, `end`, `trailing` — draws
//  the default, the centre, as sjui's button_text_alignment and kjui read it.
//  Until the fix the Dynamic read lowercased the value and also took start /
//  leading / end / trailing, and went through `textAlignSpelling()`, which
//  reads LabelAttributes first (Label declares the lower case). Ticket
//  sjui-button-textalign-read-case-insensitively.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class ButtonTextAlignmentTests: XCTestCase {

    private func button(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }

    func testDeclaredSpellingsPlaceTheText() throws {
        let cases: [(String, HorizontalAlignment)] = [
            (#"{"type":"Button","text":"Go","textAlign":"Left"}"#, .leading),
            (#"{"type":"Button","text":"Go","textAlign":"Right"}"#, .trailing),
            (#"{"type":"Button","text":"Go","textAlign":"Center"}"#, .center),
            (#"{"type":"Button","text":"Go"}"#, .center),
        ]
        for (json, expected) in cases {
            XCTAssertEqual(ButtonConverter.buttonTextAlignment(try button(json)), expected, json)
        }
    }

    func testUndeclaredSpellingsDrawTheCentre() throws {
        for spelling in ["left", "LEFT", "right", "start", "leading", "end", "trailing"] {
            let json = #"{"type":"Button","text":"Go","textAlign":"\#(spelling)"}"#
            XCTAssertEqual(
                ButtonConverter.buttonTextAlignment(try button(json)), .center,
                "\(spelling) is not a spelling Button declares"
            )
        }
    }
}
#endif
