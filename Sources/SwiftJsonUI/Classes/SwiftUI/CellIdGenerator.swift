import SwiftUI

/// Conform types that must be excluded from cellId hashing (e.g. `AnyView`).
public protocol CellIdHashIgnorable {}

extension AnyView: CellIdHashIgnorable {}

/// Mirrors `CollectionDataSection.reconfigured` on the flat `[[String: Any]]`
/// array the static SwiftUI converter hands to ForEach. The generator emits
/// `cellsData.reconfigured(...)` without knowing whether it holds a section
/// or the unwrapped data array; this extension makes both call sites work.
public extension Array where Element == [String: Any] {
    func reconfigured(
        cellIdProperty: String?,
        autoChangeTrackingId: Bool
    ) -> [[String: Any]] {
        CellIdGenerator.enrichCellIds(
            self,
            cellIdProperty: cellIdProperty,
            autoChangeTrackingId: autoChangeTrackingId
        )
    }
}

/// Generates stable cell identifiers for `Collection` components.
///
/// Produces `"<primary>_<base36Hash>"`. The hash covers every entry in the
/// dictionary except `primaryKey` and the reserved `"cellId"` key, so the
/// output is idempotent: calling `autoId` repeatedly (Mode A + Mode B
/// re-application) yields the same string.
///
/// The hash is session-stable only. `Swift.Hasher` uses a launch-scoped seed,
/// so identifiers must not be persisted or compared across processes.
public enum CellIdGenerator {
    public static func autoId(
        from data: [String: Any],
        primaryKey: String,
        fallbackIndex: Int
    ) -> String {
        let primary: String
        if let value = data[primaryKey] {
            primary = String(describing: value)
        } else {
            primary = "\(fallbackIndex)"
        }

        var hasher = Hasher()
        for key in data.keys.sorted() where key != primaryKey && key != "cellId" {
            hasher.combine(key)
            combine(hasher: &hasher, value: data[key]!)
        }
        let raw = Int64(hasher.finalize())
        let encoded = String(UInt64(bitPattern: raw), radix: 36)
        return "\(primary)_\(encoded)"
    }

    private static func combine(hasher: inout Hasher, value: Any) {
        switch value {
        case let v as String: hasher.combine(v)
        case let v as Int: hasher.combine(v)
        case let v as Int64: hasher.combine(v)
        case let v as Double: hasher.combine(v)
        case let v as Bool: hasher.combine(v)
        case let v as [Any]:
            for item in v { combine(hasher: &hasher, value: item) }
        case let v as [String: Any]:
            for key in v.keys.sorted() {
                hasher.combine(key)
                combine(hasher: &hasher, value: v[key]!)
            }
        default:
            if !isIgnorable(value) {
                hasher.combine(String(describing: value))
            }
        }
    }

    private static func isIgnorable(_ value: Any) -> Bool {
        if value is CellIdHashIgnorable { return true }
        let name = String(describing: type(of: value))
        return name.contains("->")
    }

    /// Public counterpart to `Array<[String: Any]>.reconfigured`. Returns the
    /// input unchanged unless `autoChangeTrackingId` is true and
    /// `cellIdProperty` is a non-empty key.
    public static func enrichCellIds(
        _ cells: [[String: Any]],
        cellIdProperty: String?,
        autoChangeTrackingId: Bool
    ) -> [[String: Any]] {
        guard autoChangeTrackingId, let key = cellIdProperty, !key.isEmpty else {
            return cells
        }
        let mapped = cells.enumerated().map { index, d -> [String: Any] in
            var enriched = d
            enriched["cellId"] = autoId(from: d, primaryKey: key, fallbackIndex: index)
            return enriched
        }
        return dedupe(mapped)
    }

    static func dedupe(_ cells: [[String: Any]]) -> [[String: Any]] {
        var seen: [String: Int] = [:]
        var duplicates: [String] = []
        let result = cells.map { d -> [String: Any] in
            guard let id = d["cellId"] as? String else { return d }
            let count = (seen[id] ?? 0) + 1
            seen[id] = count
            guard count > 1 else { return d }
            duplicates.append(id)
            var copy = d
            copy["cellId"] = "\(id)#\(count)"
            return copy
        }
        if !duplicates.isEmpty {
            Logger.log("[CellIdGenerator] Duplicate cellIds detected: \(duplicates). Consider adding a unique field to cellIdProperty.")
        }
        return result
    }
}
