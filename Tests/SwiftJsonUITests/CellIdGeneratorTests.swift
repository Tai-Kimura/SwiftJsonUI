import XCTest
import SwiftUI
@testable import SwiftJsonUI

final class CellIdGeneratorTests: XCTestCase {

    func testSameDataProducesSameId() {
        let data: [String: Any] = ["id": 1, "name": "Alice", "active": true]
        let a = CellIdGenerator.autoId(from: data, primaryKey: "id", fallbackIndex: 0)
        let b = CellIdGenerator.autoId(from: data, primaryKey: "id", fallbackIndex: 0)
        XCTAssertEqual(a, b)
        XCTAssertTrue(a.hasPrefix("1_"))
    }

    func testOtherFieldChangesHashButKeepsPrimary() {
        let a: [String: Any] = ["id": 1, "name": "Alice"]
        let b: [String: Any] = ["id": 1, "name": "Bob"]
        let idA = CellIdGenerator.autoId(from: a, primaryKey: "id", fallbackIndex: 0)
        let idB = CellIdGenerator.autoId(from: b, primaryKey: "id", fallbackIndex: 0)
        XCTAssertTrue(idA.hasPrefix("1_"))
        XCTAssertTrue(idB.hasPrefix("1_"))
        XCTAssertNotEqual(idA, idB)
    }

    func testClosureValuesAreIgnored() {
        let handler1: () -> Void = { print("one") }
        let handler2: () -> Void = { print("two") }
        let a: [String: Any] = ["id": 1, "name": "Alice", "onTap": handler1]
        let b: [String: Any] = ["id": 1, "name": "Alice", "onTap": handler2]
        let idA = CellIdGenerator.autoId(from: a, primaryKey: "id", fallbackIndex: 0)
        let idB = CellIdGenerator.autoId(from: b, primaryKey: "id", fallbackIndex: 0)
        XCTAssertEqual(idA, idB)
    }

    func testCellIdHashIgnorableValuesAreIgnored() {
        let viewA = AnyView(Text("A"))
        let viewB = AnyView(Text("B"))
        let a: [String: Any] = ["id": 1, "name": "Alice", "view": viewA]
        let b: [String: Any] = ["id": 1, "name": "Alice", "view": viewB]
        let idA = CellIdGenerator.autoId(from: a, primaryKey: "id", fallbackIndex: 0)
        let idB = CellIdGenerator.autoId(from: b, primaryKey: "id", fallbackIndex: 0)
        XCTAssertEqual(idA, idB)
    }

    func testMissingPrimaryFallsBackToIndex() {
        let data: [String: Any] = ["name": "Alice"]
        let id = CellIdGenerator.autoId(from: data, primaryKey: "id", fallbackIndex: 7)
        XCTAssertTrue(id.hasPrefix("7_"))
    }

    func testCellIdPropertyEqualsCellIdPreservesPrimary() {
        let data: [String: Any] = ["cellId": "bar_42", "name": "Alice", "available": true]
        let id = CellIdGenerator.autoId(from: data, primaryKey: "cellId", fallbackIndex: 0)
        XCTAssertTrue(id.hasPrefix("bar_42_"))

        // Changing another field changes the suffix but not the prefix.
        let data2: [String: Any] = ["cellId": "bar_42", "name": "Alice", "available": false]
        let id2 = CellIdGenerator.autoId(from: data2, primaryKey: "cellId", fallbackIndex: 0)
        XCTAssertTrue(id2.hasPrefix("bar_42_"))
        XCTAssertNotEqual(id, id2)
    }

    func testCellIdKeyIsExcludedFromHashWhenPrimaryIsDifferent() {
        // primary = "id", with stray cellId entry — should NOT be included.
        let a: [String: Any] = ["id": 1, "name": "Alice", "cellId": "stale_a"]
        let b: [String: Any] = ["id": 1, "name": "Alice", "cellId": "stale_b"]
        let idA = CellIdGenerator.autoId(from: a, primaryKey: "id", fallbackIndex: 0)
        let idB = CellIdGenerator.autoId(from: b, primaryKey: "id", fallbackIndex: 0)
        XCTAssertEqual(idA, idB)
    }

    func testNestedArrayAndDictHashStable() {
        let data: [String: Any] = [
            "id": 1,
            "tags": ["new", "featured"],
            "meta": ["score": 42, "owner": "x"]
        ]
        let a = CellIdGenerator.autoId(from: data, primaryKey: "id", fallbackIndex: 0)
        let b = CellIdGenerator.autoId(from: data, primaryKey: "id", fallbackIndex: 0)
        XCTAssertEqual(a, b)
    }

    func testBase36SuffixWithinExpectedLength() {
        let data: [String: Any] = ["id": 1, "name": "Alice"]
        let id = CellIdGenerator.autoId(from: data, primaryKey: "id", fallbackIndex: 0)
        let parts = id.split(separator: "_", maxSplits: 1, omittingEmptySubsequences: false)
        XCTAssertEqual(parts.count, 2)
        XCTAssertLessThanOrEqual(parts[1].count, 13)
    }

    func testIdempotentAcrossRepeatedApplication() {
        // Mode A + Mode B overlap: first enrich, then enrich again.
        var section = CollectionDataSection(cellIdProperty: "id", autoChangeTrackingId: true)
        section.setCells(viewName: "CellView", data: [
            ["id": 1, "name": "Alice"],
            ["id": 2, "name": "Bob"]
        ])
        let once = section.cells?.data.map { $0["cellId"] as? String }
        let twice = section.reconfigured(cellIdProperty: "id", autoChangeTrackingId: true)
            .cells?.data.map { $0["cellId"] as? String }
        XCTAssertEqual(once, twice)
    }

    func testDedupeAddsSuffixForDuplicates() {
        // Two identical dicts except for cellId enrichment; same primary+fields
        // should produce the same combined id before dedupe, then suffixes.
        var section = CollectionDataSection(cellIdProperty: "id", autoChangeTrackingId: true)
        section.setCells(viewName: "CellView", data: [
            ["id": 1, "name": "Alice"],
            ["id": 1, "name": "Alice"]
        ])
        let ids = section.cells?.data.compactMap { $0["cellId"] as? String } ?? []
        XCTAssertEqual(ids.count, 2)
        XCTAssertNotEqual(ids[0], ids[1])
        XCTAssertTrue(ids[1].contains("#2"))
    }

    func testReconfiguredEnrichesExistingSection() {
        // VM set cells without flags; converter will call reconfigured in body.
        var section = CollectionDataSection()
        section.setCells(viewName: "CellView", data: [
            ["id": 1, "name": "Alice"],
            ["id": 2, "name": "Bob"]
        ])
        XCTAssertNil(section.cells?.data[0]["cellId"])

        let applied = section.reconfigured(cellIdProperty: "id", autoChangeTrackingId: true)
        XCTAssertNotNil(applied.cells?.data[0]["cellId"])
        let id0 = applied.cells?.data[0]["cellId"] as? String
        XCTAssertTrue(id0?.hasPrefix("1_") ?? false)
    }

    func testReconfiguredLeavesPrimaryKeyDataIntact() {
        // cellIdProperty: "id" — data["id"] must NOT be overwritten.
        var section = CollectionDataSection()
        section.setCells(viewName: "CellView", data: [
            ["id": 1, "name": "Alice"]
        ])
        let applied = section.reconfigured(cellIdProperty: "id", autoChangeTrackingId: true)
        XCTAssertEqual(applied.cells?.data[0]["id"] as? Int, 1)
        XCTAssertNotNil(applied.cells?.data[0]["cellId"])
    }

    func testDataSourceReconfiguredPropagatesToAllSections() {
        var dataSource = CollectionDataSource()
        var s1 = CollectionDataSection()
        s1.setCells(viewName: "A", data: [["id": 1]])
        var s2 = CollectionDataSection()
        s2.setCells(viewName: "B", data: [["id": 2]])
        dataSource.addSection(s1)
        dataSource.addSection(s2)

        let applied = dataSource.reconfigured(cellIdProperty: "id", autoChangeTrackingId: true)
        XCTAssertNotNil(applied.sections[0].cells?.data[0]["cellId"])
        XCTAssertNotNil(applied.sections[1].cells?.data[0]["cellId"])
    }

    func testAutoChangeTrackingIdWithoutCellIdPropertyIsNoop() {
        // autoChangeTrackingId=true but no primary key → no enrichment.
        var section = CollectionDataSection(autoChangeTrackingId: true)
        section.setCells(viewName: "CellView", data: [["id": 1]])
        XCTAssertNil(section.cells?.data[0]["cellId"])
    }

    // MARK: - Array<[String: Any]> extension

    func testArrayReconfiguredEnrichesCellIds() {
        // The static converter emits `cellsData.reconfigured(...)` where
        // cellsData is `[[String: Any]]`. The Array extension must match
        // CollectionDataSection.reconfigured's enrichment semantics.
        let cellsData: [[String: Any]] = [
            ["id": 1, "name": "Alice"],
            ["id": 2, "name": "Bob"]
        ]
        let enriched = cellsData.reconfigured(cellIdProperty: "id", autoChangeTrackingId: true)
        XCTAssertEqual(enriched.count, 2)
        XCTAssertTrue((enriched[0]["cellId"] as? String)?.hasPrefix("1_") ?? false)
        XCTAssertTrue((enriched[1]["cellId"] as? String)?.hasPrefix("2_") ?? false)
    }

    func testArrayReconfiguredIsNoopWhenAutoTrackingDisabled() {
        let cellsData: [[String: Any]] = [["id": 1]]
        let result = cellsData.reconfigured(cellIdProperty: "id", autoChangeTrackingId: false)
        XCTAssertNil(result[0]["cellId"])
    }

    func testArrayReconfiguredIsIdempotent() {
        let cellsData: [[String: Any]] = [["id": 1, "name": "Alice"]]
        let once = cellsData.reconfigured(cellIdProperty: "id", autoChangeTrackingId: true)
        let twice = once.reconfigured(cellIdProperty: "id", autoChangeTrackingId: true)
        XCTAssertEqual(
            once[0]["cellId"] as? String,
            twice[0]["cellId"] as? String
        )
    }
}
