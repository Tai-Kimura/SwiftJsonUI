import XCTest
@testable import SwiftJsonUI

/// TypeSynonyms reads the vendored copy of jsonui-cli's type_synonyms.json
/// from the package's resource bundle (CI compares the copy with the pinned
/// jsonui-cli ref). The expected entries are read from the same file with
/// JSONSerialization, a second reader, not written out here.
final class TypeSynonymsTests: XCTestCase {
    override func tearDown() {
        TypeSynonyms.warningHandler = nil
        TypeSynonyms.reset()
        super.tearDown()
    }

    func testEveryEntryOfTheVendoredFileIsRead() throws {
        let url = try XCTUnwrap(TypeSynonyms.resourceURL, "type_synonyms.json is not in the package's bundle")
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let synonyms = try XCTUnwrap(root["synonyms"] as? [String: [String: Any]])
        XCTAssertGreaterThanOrEqual(synonyms.count, 40)
        XCTAssertEqual(Set(synonyms.keys.map { $0.lowercased() }), Set(TypeSynonyms.entries.keys))
        for (spelling, value) in synonyms {
            let entry = try XCTUnwrap(TypeSynonyms.entries[spelling.lowercased()])
            XCTAssertEqual(entry.canonical, value["canonical"] as? String, spelling)
            XCTAssertEqual(entry.renderAs, value["render_as"] as? String, spelling)
        }
    }

    func testASynonymIsDrawnAsItsTargetWhateverItsCase() {
        XCTAssertEqual(TypeSynonyms.drawnAs("ProgressBar"), "Progress")
        XCTAssertEqual(TypeSynonyms.drawnAs("progressbar"), "Progress")
        // render_as: drawn by the converter it names, not the canonical one
        XCTAssertEqual(TypeSynonyms.drawnAs("CircleImageView"), "CircleImage")
        XCTAssertEqual(TypeSynonyms.drawnAs("Label"), "Label")
        XCTAssertEqual(TypeSynonyms.drawnAs("ProbeCustomType"), "ProbeCustomType")
    }

    func testASynonymNodeGetsTheAttributesItsSpellingMeans() throws {
        let drawn = try XCTUnwrap(TypeSynonyms.canonicalize(["type": "HStack", "id": "h"]))
        XCTAssertEqual(drawn["type"] as? String, "View")
        XCTAssertEqual(drawn["orientation"] as? String, "horizontal")
        XCTAssertEqual(drawn["id"] as? String, "h")
        XCTAssertEqual(TypeSynonyms.canonicalize(["type": "column"])?["orientation"] as? String, "vertical")
        // ZStack / Box mean a View without orientation: nothing is added
        XCTAssertNil(TypeSynonyms.canonicalize(["type": "ZStack"])?["orientation"])
        XCTAssertEqual(TypeSynonyms.canonicalize(["type": "CircleImageView"])?["type"] as? String, "CircleImage")
    }

    func testTheNodesOwnValueWinsAndAWarningNamesBoth() throws {
        var warnings: [String] = []
        TypeSynonyms.warningHandler = { warnings.append($0) }
        let drawn = try XCTUnwrap(TypeSynonyms.canonicalize(["type": "Row", "orientation": "vertical"]))
        XCTAssertEqual(drawn["type"] as? String, "View")
        XCTAssertEqual(drawn["orientation"] as? String, "vertical")
        XCTAssertEqual(warnings.count, 1)
        let w = try XCTUnwrap(warnings.first)
        XCTAssertTrue(w.contains("Row") && w.contains("horizontal") && w.contains("vertical"), w)
    }

    func testATypeThatIsNotASynonymIsNotRewritten() {
        XCTAssertNil(TypeSynonyms.canonicalize(["type": "View", "orientation": "vertical"]))
        XCTAssertNil(TypeSynonyms.canonicalize(["type": "Triangle"]))
    }

    func testAMalformedTableThrows() {
        XCTAssertThrowsError(try TypeSynonyms.parse(Data(#"{"nothing": {}}"#.utf8)))
        XCTAssertThrowsError(try TypeSynonyms.parse(Data(#"{"synonyms": {"X": {}}}"#.utf8)))
    }
}
