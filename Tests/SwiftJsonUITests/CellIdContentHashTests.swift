import XCTest
import SwiftUI
@testable import SwiftJsonUI

/// `CellIdGenerator.autoId` is a function of content, for every value a cell
/// dictionary can hold. Through 10.29.4 a value that was not a primitive, an
/// array or a `[String: Any]` was hashed by its `String(describing:)`, which
/// prints dictionaries inside it in per-instance order: a cell holding a
/// `CollectionDataSource` got a new id on every rebuild of equal content, so
/// its view was rebuilt and a ScrollView inside it jumped back to the top
/// (jsonui-cli ticket sjui-cellid-autoid-hash-is-nondeterministic-for-nested-
/// collection-data: 6 ids over 6 rebuilds on a consumer's book screen).
final class CellIdContentHashTests: XCTestCase {

    private func id(_ data: [String: Any]) -> String {
        CellIdGenerator.autoId(from: data, primaryKey: "id", fallbackIndex: 0)
    }

    /// A chip row as a consumer builds it: a fresh CollectionDataSource whose
    /// cell dictionaries get their keys in a different order every time.
    private func chips(_ labels: [String], order: Int) -> CollectionDataSource {
        let rows: [[String: Any]] = labels.enumerated().map { i, label in
            let pairs: [(String, Any)] = [("label", label), ("index", i), ("selected", i == 0), ("weight", 0.5)]
            var row: [String: Any] = [:]
            for pair in (order % 2 == 0 ? pairs : pairs.reversed()) { row[pair.0] = pair.1 }
            return row
        }
        var section = CollectionDataSection()
        section.setCells(viewName: "ChipCell", data: rows)
        return CollectionDataSource(sections: [section])
    }

    func testEqualCollectionDataSourceContentGivesOneIdAcrossRebuilds() {
        let labels = ["Red", "Green", "Blue", "Cyan", "Magenta", "Yellow"]
        let ids = Set((0..<50).map { order in
            id(["id": "item", "title": "Item", "chips": chips(labels, order: order)])
        })
        XCTAssertEqual(ids.count, 1, "equal content gave \(ids.count) ids over 50 rebuilds")
    }

    func testControlCollectionDataSourceContentChangeChangesTheId() {
        let a = id(["id": "item", "chips": chips(["Red", "Green"], order: 0)])
        let b = id(["id": "item", "chips": chips(["Red", "Blue"], order: 0)])
        XCTAssertNotEqual(a, b)
    }

    private struct Cursor { let index: Int; let label: String; let extra: [String: Any] }

    func testAStructHashesByItsFields() {
        let a = id(["id": 1, "cursor": Cursor(index: 2, label: "x", extra: ["b": 1, "a": "z"])])
        let b = id(["id": 1, "cursor": Cursor(index: 2, label: "x", extra: ["a": "z", "b": 1])])
        let c = id(["id": 1, "cursor": Cursor(index: 3, label: "x", extra: ["a": "z", "b": 1])])
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    func testADictionaryWithNonStringKeysHashesWhateverItsOrder() {
        var first: [Int: Any] = [:]
        for k in [5, 1, 9, 3] { first[k] = "v\(k)" }
        var second: [Int: Any] = [:]
        for k in [3, 9, 1, 5] { second[k] = "v\(k)" }
        XCTAssertEqual(id(["id": 1, "m": first]), id(["id": 1, "m": second]))
        second[9] = "changed"
        XCTAssertNotEqual(id(["id": 1, "m": first]), id(["id": 1, "m": second]))
    }

    func testHashableAndOptionalValuesHashByContent() {
        let date = Date(timeIntervalSince1970: 1_000)
        let uuid = UUID()
        let optional: Int? = 7
        let a = id(["id": 1, "f": Float(1.5), "g": CGFloat(2), "d": date, "u": uuid, "o": optional as Any])
        let b = id(["id": 1, "f": Float(1.5), "g": CGFloat(2), "d": date, "u": uuid, "o": optional as Any])
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, id(["id": 1, "f": Float(2.5), "g": CGFloat(2), "d": date, "u": uuid, "o": optional as Any]))
        XCTAssertNotEqual(a, id(["id": 1, "f": Float(1.5), "g": CGFloat(2), "d": date, "u": uuid, "o": (8 as Int?) as Any]))
    }
}
