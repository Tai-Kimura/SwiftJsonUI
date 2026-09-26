import XCTest
@testable import SwiftJsonUI

#if DEBUG
/// The sentence Dynamic names an unknown type with is jsonui-cli's, byte for
/// byte: the rows of unknown_component_type_vectors.json's `case_only`
/// section are the Ruby validator's own words for every known type written
/// in another case (written by jsonui-cli's UnknownTypeCaseRows, copied here
/// byte for byte and compared by CI). The candidate is TypeSynonyms
/// .caseOnlyMatch over the declared types, the synonyms and the alias
/// sections — the one search every path asks (4f's ruling); the builder
/// searched the declared types alone.
final class TypeNameCaseVectorsTests: XCTestCase {
    private struct Section: Decodable {
        struct Row: Decodable { let written: String; let expect: String }
        let known: [String]
        let not_drawn: [String: [String]]
        let rows: [Row]
    }

    private func section() throws -> Section {
        struct File: Decodable { let case_only: Section }
        return try JSONDecoder().decode(File.self, from: TestFixtures.loadJSON(named: "unknown_component_type_vectors")).case_only
    }

    /// The types this runtime does not draw are the declaration's
    /// (component_metadata.json `swift_dynamic: false`, which the table
    /// carries): exactly the SSoT's sections the builder has no case for,
    /// both ways — a moved declaration or a moved case reddens this.
    func testTheTypesItDoesNotDrawAreTheDeclarations() throws {
        let table = try section()
        let notDrawn = Set(table.not_drawn["swift_dynamic"] ?? [])
        let sections = Set(table.known).subtracting(TypeSynonyms.entries.keys).subtracting(JsonUIComponentAliases.canonical.keys)
        let uncased = sections.subtracting(DynamicComponentBuilder.declaredTypes)
        XCTAssertFalse(notDrawn.isEmpty, "the table names what this runtime does not draw")
        XCTAssertEqual(notDrawn, uncased, "declared not drawn (swift_dynamic: false) vs sections with no case")
        XCTAssertTrue(uncased.isSubset(of: notDrawn) && notDrawn.isSubset(of: uncased))
    }

    /// Every row but those offering a type this runtime does not draw: the
    /// same sentence, byte for byte. Those rows are the validator's words, not
    /// this runtime's — it does not offer what it cannot draw.
    func testItSaysTheValidatorsSentenceForEveryKnownTypeInAnotherCase() throws {
        let table = try section()
        let notDrawn = table.not_drawn["swift_dynamic"] ?? []
        var compared = 0
        var excluded = 0
        var offeredBeyondDeclared = 0
        for row in table.rows {
            if notDrawn.contains(where: { $0.caseInsensitiveCompare(row.written) == .orderedSame }) {
                excluded += 1
                XCTAssertTrue(notDrawn.contains { row.expect.contains("'\($0)'") }, row.written)
                continue
            }
            let candidate = DynamicComponentBuilder.spellingCandidate(for: row.written)
            XCTAssertEqual(TypeNameSpelling.sentence(written: row.written, declared: candidate), row.expect, row.written)
            compared += 1
            if let candidate, !DynamicComponentBuilder.declaredTypes.contains(candidate) { offeredBeyondDeclared += 1 }
        }
        XCTAssertGreaterThan(compared, 200)
        XCTAssertGreaterThan(excluded, 0, "the declared exclusions are in the table")
        // The rows a search of the declared types alone would miss: a
        // synonym or an alias section in another case (the control for the
        // search's pool).
        XCTAssertGreaterThan(offeredBeyondDeclared, 100)
    }
}
#endif
