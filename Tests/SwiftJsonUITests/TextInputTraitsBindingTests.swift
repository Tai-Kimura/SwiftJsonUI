//
//  TextInputTraitsBindingTests.swift
//  SwiftJsonUITests
//
//  TextField / TextView keyboard and length attributes take a binding
//  (jsonui-cli 2.5.61). Before, the Dynamic path read `input` and
//  `returnKeyType` from hand-written String slots, so "@{x}" was taken as
//  the spelling and drew the default keyboard; `maxLength`,
//  `autocapitalizationType` and `autocorrectionType` were not read at all,
//  written or bound.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class TextInputTraitsBindingTests: XCTestCase {

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: json.data(using: .utf8)!)
    }

    // MARK: - input / returnKeyType

    func testBoundInputResolvesToTheDataValue() throws {
        let c = try component(#"{ "type": "TextField", "input": "@{keyboard}" }"#)
        XCTAssertEqual(TextFieldConverter.inputSpelling(c, data: ["keyboard": "number"]), "number")
        XCTAssertEqual(
            DynamicHelpers.keyboardType(forInput: TextFieldConverter.inputSpelling(c, data: ["keyboard": "number"])),
            .numberPad
        )
        XCTAssertEqual(
            DynamicHelpers.keyboardType(forInput: TextFieldConverter.inputSpelling(c, data: ["keyboard": "alphabet"])),
            .asciiCapable
        )
    }

    func testUnresolvedOrUnknownInputDrawsTheDefault() throws {
        let c = try component(#"{ "type": "TextField", "input": "@{keyboard}" }"#)
        XCTAssertNil(TextFieldConverter.inputSpelling(c, data: [:]))
        XCTAssertEqual(DynamicHelpers.keyboardType(forInput: TextFieldConverter.inputSpelling(c, data: [:])), .default)
        XCTAssertEqual(
            DynamicHelpers.keyboardType(forInput: TextFieldConverter.inputSpelling(c, data: ["keyboard": "nothing"])),
            .default
        )
    }

    func testLiteralInputStillReads() throws {
        let c = try component(#"{ "type": "TextField", "input": "email" }"#)
        XCTAssertEqual(DynamicHelpers.keyboardType(forInput: TextFieldConverter.inputSpelling(c, data: [:])), .emailAddress)
    }

    func testBoundReturnKeyTypeResolves() throws {
        let c = try component(#"{ "type": "TextField", "returnKeyType": "@{submit}" }"#)
        XCTAssertEqual(c.enumString(TextFieldAttributes.self, \.returnKeyType, data: ["submit": "Next"]), "Next")
    }

    func testBoundTextViewKeyboardAttributesResolve() throws {
        let c = try component(#"{ "type": "TextView", "input": "@{a}", "keyboardType": "@{b}", "returnKeyType": "@{c}" }"#)
        let data: [String: Any] = ["a": "email", "b": "phone", "c": "Search"]
        XCTAssertEqual(c.enumString(TextViewAttributes.self, \.input, data: data), "email")
        XCTAssertEqual(c.enumString(TextViewAttributes.self, \.keyboardType, data: data), "phone")
        XCTAssertEqual(c.enumString(TextViewAttributes.self, \.returnKeyType, data: data), "Search")
    }

    func testBoundTextViewEditableResolves() throws {
        let c = try component(#"{ "type": "TextView", "editable": "@{on}" }"#)
        XCTAssertEqual(
            DynamicHelpers.resolveBool(c.typedAttributes(TextViewAttributes.self).editable, legacy: nil, data: ["on": false]),
            false
        )
    }

    // MARK: - maxLength

    func testMaxLengthWrittenOrBound() throws {
        let written = try component(#"{ "type": "TextField", "maxLength": 4 }"#)
        XCTAssertEqual(TextFieldConverter.maxLengthLimit(written, data: [:]), 4)
        let bound = try component(#"{ "type": "TextField", "maxLength": "@{limit}" }"#)
        XCTAssertEqual(TextFieldConverter.maxLengthLimit(bound, data: ["limit": 6]), 6)
    }

    func testZeroUnsetAndUnresolvedAreNoLimit() throws {
        XCTAssertNil(TextFieldConverter.maxLengthLimit(try component(#"{ "type": "TextField", "maxLength": 0 }"#), data: [:]))
        XCTAssertNil(TextFieldConverter.maxLengthLimit(try component(#"{ "type": "TextField" }"#), data: [:]))
        let bound = try component(#"{ "type": "TextField", "maxLength": "@{limit}" }"#)
        XCTAssertNil(TextFieldConverter.maxLengthLimit(bound, data: [:]))
        XCTAssertNil(TextFieldConverter.maxLengthLimit(bound, data: ["limit": 0]))
    }

    func testAnEditIsCutToTheLimitWhenWritten() throws {
        var stored = "ab"
        let source = SwiftUI.Binding(get: { stored }, set: { stored = $0 })
        let c = try component(#"{ "type": "TextField", "maxLength": "@{limit}" }"#)
        let limited = TextFieldConverter.limitingLength(source, component: c, data: ["limit": 3])
        limited.wrappedValue = "abcdef"
        XCTAssertEqual(stored, "abc")
        limited.wrappedValue = "xy"
        XCTAssertEqual(stored, "xy")
    }

    func testAShrunkLimitDoesNotCutTheTextByItself() throws {
        var stored = "abcdef"
        let source = SwiftUI.Binding(get: { stored }, set: { stored = $0 })
        let c = try component(#"{ "type": "TextField", "maxLength": "@{limit}" }"#)
        let limited = TextFieldConverter.limitingLength(source, component: c, data: ["limit": 2])
        XCTAssertEqual(limited.wrappedValue, "abcdef")
        limited.wrappedValue = "abcdefg"
        XCTAssertEqual(stored, "ab")
    }

    // MARK: - autocapitalizationType / autocorrectionType

    func testAutocapitalizationSpellings() throws {
        XCTAssertEqual(TextFieldConverter.autocapitalizationName("none"), "never")
        XCTAssertEqual(TextFieldConverter.autocapitalizationName("words"), "words")
        XCTAssertEqual(TextFieldConverter.autocapitalizationName("allCharacters"), "characters")
        XCTAssertNil(TextFieldConverter.autocapitalizationName("nothing"))
        XCTAssertNil(TextFieldConverter.autocapitalization(nil))
        XCTAssertNotNil(TextFieldConverter.autocapitalization("sentences"))
        let c = try component(#"{ "type": "TextField", "autocapitalizationType": "@{caps}" }"#)
        XCTAssertEqual(c.enumString(TextFieldAttributes.self, \.autocapitalizationType, data: ["caps": "sentences"]), "sentences")
    }

    func testAutocorrectionSpellings() throws {
        XCTAssertEqual(TextFieldConverter.autocorrectionDisabled("no"), true)
        XCTAssertEqual(TextFieldConverter.autocorrectionDisabled("off"), true)
        XCTAssertEqual(TextFieldConverter.autocorrectionDisabled("yes"), false)
        XCTAssertNil(TextFieldConverter.autocorrectionDisabled("default"))
        XCTAssertNil(TextFieldConverter.autocorrectionDisabled(nil))
        let c = try component(#"{ "type": "TextField", "autocorrectionType": "@{fix}" }"#)
        XCTAssertEqual(c.enumString(TextFieldAttributes.self, \.autocorrectionType, data: ["fix": "no"]), "no")
    }
}
#endif // DEBUG
