//
//  ConfirmationDialogTextTests.swift
//  SwiftJsonUITests
//
//  The ONLY regression device this behaviour can have. D measured that the
//  conformance generator gives `confirmationDialog` a behavioural skip — a
//  dialog is not on the render surface, so no fixture can reach it — and that
//  SwiftJsonUI's own tests covered it zero times. The 10.14.2 fix (f8fc559)
//  that made title/message go through the string table therefore shipped with
//  nothing watching it.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class ConfirmationDialogTextTests: XCTestCase {

    private typealias Sut = DynamicModifierHelper

    // A plain sentence is not a key and must survive untouched.
    func testLiteralStringPassesThrough() {
        XCTAssertEqual(
            Sut.confirmationDialogText("Delete this item?", data: [:]),
            "Delete this item?"
        )
    }

    // The regression that f8fc559 fixed: a bound spelling was handed to the
    // localizer as the literal "@{dialogTitle}", so the dialog showed the
    // expression instead of the value.
    func testBoundSpellingResolvesFromData() {
        XCTAssertEqual(
            Sut.confirmationDialogText("@{dialogTitle}", data: ["dialogTitle": "Remove bottle?"]),
            "Remove bottle?"
        )
    }

    func testBoundSpellingResolvesThroughASwiftUIBinding() {
        let binding = SwiftUI.Binding<String>.constant("Remove bottle?")
        XCTAssertEqual(
            Sut.confirmationDialogText("@{dialogTitle}", data: ["dialogTitle": binding]),
            "Remove bottle?"
        )
    }

    // A key spelling reaches the string table rather than being rendered raw.
    // With no strings.json loaded the table answers the key itself, so this
    // pins the ROUTE, not a translation.
    func testKeySpellingReachesTheStringTable() {
        XCTAssertEqual(
            Sut.confirmationDialogText("bottler_title", data: [:]),
            "bottler_title".dynamicLocalized()
        )
    }

    // Absent and non-string declarations must not fabricate a title: the
    // builder distinguishes "no message" (one dialog overload) from
    // "empty message" (the other).
    func testAbsentDeclarationIsNil() {
        XCTAssertNil(Sut.confirmationDialogText(nil, data: [:]))
        XCTAssertNil(Sut.confirmationDialogText(42, data: [:]))
        XCTAssertNil(Sut.confirmationDialogText(["nested": "value"], data: [:]))
    }

    // An unresolvable binding must not leak the expression into the dialog.
    // Found by this test on the first run: the fallthrough handed
    // "@{missingKey}" to the localizer, which passes a non-key string through
    // unchanged, so the dialog printed the expression. The codegen cannot
    // produce that failure — it emits a typed `data.dialogTitle`.
    func testUnresolvedBindingDoesNotSurfaceTheExpression() {
        XCTAssertNil(Sut.confirmationDialogText("@{missingKey}", data: [:]))
    }

    // The declared-default form still resolves without the data entry.
    func testBindingWithADeclaredDefaultStillResolves() {
        let out = Sut.confirmationDialogText("@{missingKey ?? \"Fallback\"}", data: [:])
        XCTAssertEqual(out, "Fallback")
    }
}
#endif
