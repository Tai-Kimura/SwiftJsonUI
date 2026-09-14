//
//  DynamicKeyboardTypeTests.swift
//  SwiftJsonUITests
//
//  `input` and `keyboardType` on the Dynamic face.
//
//  🔻 THE SAME SHAPE AS `glass`, AND INVISIBLE TO THE SAME INSTRUMENT.
//  Three declared `input` spellings had no case in this face's table and fell
//  to `.default`, sitting next to the value that MEANS default — so the reader
//  looked like it read the attribute and did not. TextView had no table at
//  all. The conformance suite can never catch either: a soft keyboard is not
//  in the screenshot, so the picture is identical whether the attribute was
//  honoured or dropped. Nothing here can be left to a rendered comparison.
//
//  ⚠️ The two attributes are DIFFERENT VOCABULARIES with different answers for
//  the same word, and these arms pin that rather than smoothing it over: on
//  `input`, `number` is `.numberPad`; on `keyboardType`, `number` is
//  `.decimalPad`. Both are transcribed from the codegen face. An arm that
//  asserted one rule for both would be asserting something no face implements.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class DynamicKeyboardTypeTests: XCTestCase {

    private func textView(_ dict: [String: Any]) -> DynamicComponent {
        var raw = dict
        raw["type"] = "TextView"
        return try! JSONDecoder().decode(DynamicComponent.self,
                                         from: try! JSONSerialization.data(withJSONObject: raw))
    }

    // MARK: - input, the shared table

    /// 🔑 THE THREE THAT WERE MISSING. Each is a declared spelling whose
    /// answer is NOT `.default`, so each of these assertions fails if the row
    /// is removed again — which is exactly how they were absent before.
    func testTheThreeSpellingsThatUsedToFallThroughNowResolve() {
        XCTAssertEqual(DynamicHelpers.keyboardType(forInput: "signedDecimal"), .numbersAndPunctuation)
        XCTAssertEqual(DynamicHelpers.keyboardType(forInput: "alphabet"), .asciiCapable)
        XCTAssertEqual(DynamicHelpers.keyboardType(forInput: "allphabet"), .asciiCapable)
    }

    /// `signedDecimal` and `decimal` are different keyboards, and the reason
    /// is a key: `.decimalPad` has no minus. Asserting them unequal is what
    /// stops the plausible "simplification" of folding the new row into the
    /// decimal one — equality with `.decimalPad` would look right and be wrong.
    func testSignedDecimalIsNotTheDecimalPad() {
        XCTAssertNotEqual(DynamicHelpers.keyboardType(forInput: "signedDecimal"),
                          DynamicHelpers.keyboardType(forInput: "decimal"))
    }

    /// Every spelling the SSoT declares for `input` must be one the generated
    /// enum accepts. The list is checked AGAINST the vendored table rather
    /// than standing alone: if a spelling leaves the declaration, the
    /// re-vendor drops its case and `Input(rawValue:)` answers nil here.
    ///
    /// ⚠️ ASYMMETRIC, AND SAID OUT LOUD: this catches a spelling that
    /// DISAPPEARS from the declaration. It cannot catch one that is ADDED —
    /// the generated enums are not `CaseIterable`, so there is nothing to
    /// enumerate from. The added-value case is what left `signedDecimal`
    /// unhandled in the first place; the gate for that direction is the
    /// re-vendor diff being read, not this arm.
    func testEverySpellingThisArmNamesIsOneTheDeclarationStillHas() {
        for spelling in ["default", "alphabet", "allphabet", "email", "number",
                         "phone", "url", "password", "decimal", "signedDecimal",
                         "date", "time", "datetime"] {
            XCTAssertNotNil(TextFieldAttributes.Input(rawValue: spelling),
                            "\(spelling) is no longer declared — this arm's list is stale")
        }
    }

    /// The date family answers `.default` BY DECLARATION, not by falling
    /// through: attribute_definitions.json says UIKeyboardType has no member
    /// for it. Pinned so that a later "let's add a date keyboard" reads as a
    /// declaration change rather than a bug fix.
    func testTheDateFamilyIsDeclaredToDegradeToDefault() {
        for spelling in ["date", "time", "datetime"] {
            XCTAssertEqual(DynamicHelpers.keyboardType(forInput: spelling), .default)
        }
        // Control: the table is not answering `.default` to everything.
        XCTAssertNotEqual(DynamicHelpers.keyboardType(forInput: "email"), .default)
    }

    func testAnUnknownSpellingDegradesRatherThanCrashing() {
        XCTAssertEqual(DynamicHelpers.keyboardType(forInput: "no-such-input"), .default)
        XCTAssertEqual(DynamicHelpers.keyboardType(forInput: nil), .default)
    }

    // MARK: - keyboardType, TextView's own vocabulary

    /// The two tables disagree about the same word, and that disagreement is
    /// the codegen face's. Asserting it here is what stops one face being
    /// "tidied" into the other.
    func testTheTwoVocabulariesDisagreeExactlyWhereCodegenDoes() {
        XCTAssertEqual(DynamicHelpers.keyboardType(forInput: "number"), .numberPad)
        XCTAssertEqual(TextViewConverter.keyboardType(fromKeyboardTypeSpelling: "number"), .decimalPad)
        XCTAssertEqual(DynamicHelpers.keyboardType(forInput: "numeric"), .numberPad)
        XCTAssertEqual(TextViewConverter.keyboardType(fromKeyboardTypeSpelling: "numeric"), .phonePad)
    }

    /// The Ruby strips every non-letter before matching, so the declared
    /// camel/upper spellings have to arrive at the same row as their stripped
    /// forms. `URL` and `webURL` are the ones that would silently miss.
    func testTheDeclaredSpellingsSurviveTheSameNormalisation() {
        XCTAssertEqual(TextViewConverter.keyboardType(fromKeyboardTypeSpelling: "URL"), .URL)
        XCTAssertEqual(TextViewConverter.keyboardType(fromKeyboardTypeSpelling: "webURL"), .URL)
        XCTAssertEqual(TextViewConverter.keyboardType(fromKeyboardTypeSpelling: "namePhonePad"), .namePhonePad)
        XCTAssertEqual(TextViewConverter.keyboardType(fromKeyboardTypeSpelling: "emailAddress"), .emailAddress)
    }

    /// 🔻 A GAP REPRODUCED ON PURPOSE. `search`, `text` and
    /// `numbersAndPunctuation` are in the SSoT's declared list for
    /// `TextView.keyboardType` and have no row in the codegen table either, so
    /// they resolve to nil and emit no modifier — on BOTH faces. Closing it
    /// here alone would turn a shared gap into a divergence, which is the
    /// defect this whole train is about.
    ///
    /// ⚠️ THE CONTROL HERE IS NOT `KeyboardType(rawValue:)`, AND THE FIRST
    /// DRAFT'S WAS. The generated enum is NOT the declaration: `keyboardType`
    /// declares 20 spellings and the emitter keeps 10 — the canonical half of
    /// each alias pair — while `input` declares 13 and keeps all 13. So
    /// `KeyboardType(rawValue: "search")` is nil for a spelling that IS
    /// declared, and an arm built on it fails for a reason that has nothing
    /// to do with what it is asking. (Alias spellings still reach this
    /// function: AttrEnum passes an unmatched value through as `.unknown` and
    /// `enumString` hands back the raw string.)
    ///
    /// The control is therefore a spelling codegen DOES have a row for,
    /// printed in the same arm: if that one were nil the function is broken
    /// and the nils below would mean nothing.
    func testTheSpellingsCodegenHasNoRowForResolveToNilHereToo() {
        XCTAssertEqual(TextViewConverter.keyboardType(fromKeyboardTypeSpelling: "webSearch"), .webSearch,
                       "control: the function answers for a spelling that has a row")

        for spelling in ["search", "text", "numbersAndPunctuation"] {
            XCTAssertNil(TextViewConverter.keyboardType(fromKeyboardTypeSpelling: spelling),
                         "\(spelling) has no row in textview_converter.rb either — "
                         + "giving it one here alone would create a divergence")
        }
    }

    /// The asymmetry above, pinned so it is not rediscovered. `input` keeps
    /// every declared spelling in the generated enum; `keyboardType` keeps
    /// only the canonical ones. Any arm that treats the generated enum as the
    /// declaration is right for one and wrong for the other.
    func testTheGeneratedEnumMirrorsTheDeclarationForInputButNotForKeyboardType() {
        XCTAssertNotNil(TextFieldAttributes.Input(rawValue: "allphabet"),
                        "input keeps its declared alias as a case")
        XCTAssertNil(TextViewAttributes.KeyboardType(rawValue: "numberPad"),
                     "keyboardType folds its declared alias away — the enum is not the declaration")
        XCTAssertNotNil(TextViewAttributes.KeyboardType(rawValue: "number"),
                        "control: the canonical half of that same pair IS a case")
    }

}
#endif
