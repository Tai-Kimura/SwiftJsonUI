import XCTest
@testable import SwiftJsonUI

/// Type names are their SSoT spellings, case-sensitive (jsonui-cli 1.9.0).
/// TypeSynonyms looks a synonym and a declared alias section up as written: a
/// spelling in another case is not one. caseOnlyMatch is where what names an
/// unknown type finds the spelling it offers ("did you mean").
final class TypeSynonymsCaseTests: XCTestCase {
    func testASynonymIsFoundAsWrittenAndNotInAnotherCase() {
        XCTAssertEqual(TypeSynonyms.drawnAs("HStack"), "View")
        XCTAssertEqual(TypeSynonyms.drawnAs("hstack"), "hstack")
        XCTAssertNotNil(TypeSynonyms.canonicalize(["type": "HStack"]))
        XCTAssertNil(TypeSynonyms.canonicalize(["type": "hstack"]))
    }

    #if DEBUG
    func testAnAliasSectionIsFoundAsWrittenAndNotInAnotherCase() throws {
        let (alias, canonical) = try XCTUnwrap(JsonUIComponentAliases.canonical.sorted { $0.key < $1.key }.first)
        XCTAssertNotEqual(alias.lowercased(), alias, "control: the spelling has an upper-case letter")
        XCTAssertEqual(TypeSynonyms.drawnType(alias), canonical)
        XCTAssertEqual(TypeSynonyms.drawnType(alias.lowercased()), alias.lowercased())
    }
    #endif

    func testCaseOnlyMatchOffersTheDeclaredSpelling() throws {
        XCTAssertEqual(TypeSynonyms.caseOnlyMatch("switch", known: ["Label", "Switch"]), "Switch")
        XCTAssertEqual(TypeSynonyms.caseOnlyMatch("SELECTBOX", known: ["SelectBox"]), "SelectBox")
        XCTAssertEqual(TypeSynonyms.caseOnlyMatch("hstack"), "HStack")
        let alias = try XCTUnwrap(JsonUIComponentAliases.canonical.keys.sorted().first)
        XCTAssertEqual(TypeSynonyms.caseOnlyMatch(alias.uppercased()), alias)
    }

    func testCaseOnlyMatchOffersNothingForASpellingAsWrittenOrOneNoCaseMatches() {
        XCTAssertNil(TypeSynonyms.caseOnlyMatch("Switch", known: ["Switch"]))
        XCTAssertNil(TypeSynonyms.caseOnlyMatch("HStack"))
        XCTAssertNil(TypeSynonyms.caseOnlyMatch("Nope", known: ["Label"]))
    }
}
