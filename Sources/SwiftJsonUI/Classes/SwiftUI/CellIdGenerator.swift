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

    /// Hashes `value` by its content, deterministically within a process, for
    /// every kind of value a cell dictionary can hold. Through 10.29.4 the
    /// fallback was `String(describing:)`, which prints the dictionaries
    /// inside a struct (a `CollectionDataSource`'s cells) in per-instance
    /// order: equal content hashed differently on each rebuild, so the cell
    /// was rebuilt and a ScrollView in it reset (jsonui-cli ticket
    /// sjui-cellid-autoid-hash-is-nondeterministic-for-nested-collection-
    /// data). The description is never hashed now.
    private static func combine(hasher: inout Hasher, value: Any, depth: Int = 0) {
        guard depth < maxDepth else {
            hasher.combine("<depth>")
            return
        }
        switch value {
        case let v as String: hasher.combine(v)
        case let v as Int: hasher.combine(v)
        case let v as Int64: hasher.combine(v)
        case let v as Double: hasher.combine(v)
        case let v as Bool: hasher.combine(v)
        case let v as [Any]:
            for item in v { combine(hasher: &hasher, value: item, depth: depth + 1) }
        case let v as [String: Any]:
            for key in v.keys.sorted() {
                hasher.combine(key)
                combine(hasher: &hasher, value: v[key]!, depth: depth + 1)
            }
        case let v as [AnyHashable: Any]:
            // Keys that are not Strings have no order to sort by: each entry
            // is hashed on its own and the results are summed, which does not
            // depend on the dictionary's iteration order.
            var sum = 0
            for (key, item) in v {
                var entry = Hasher()
                entry.combine(key)
                combine(hasher: &entry, value: item, depth: depth + 1)
                sum &+= entry.finalize()
            }
            hasher.combine(v.count)
            hasher.combine(sum)
        default:
            if isIgnorable(value) { return }
            let mirror = Mirror(reflecting: value)
            if mirror.displayStyle == .optional {
                if let wrapped = mirror.children.first?.value {
                    hasher.combine(true)
                    combine(hasher: &hasher, value: wrapped, depth: depth + 1)
                } else {
                    hasher.combine(false)
                }
            } else if let v = value as? AnyHashable {
                // Hashable values hash by their own content: Float, CGFloat,
                // Date, URL, UUID, Decimal, Set, Hashable enums and structs.
                hasher.combine(v)
            } else if !mirror.children.isEmpty {
                // Any other struct, enum payload, tuple or class (a
                // CollectionDataSource and its sections): its stored values,
                // in declaration order.
                hasher.combine(String(reflecting: type(of: value)))
                for child in mirror.children {
                    hasher.combine(child.label ?? "")
                    combine(hasher: &hasher, value: child.value, depth: depth + 1)
                }
            } else {
                // Neither Hashable nor made of stored values: there is no
                // content to read. The type stands for it — a change inside
                // such a value is not tracked, and the log says which type.
                let name = String(reflecting: type(of: value))
                hasher.combine(name)
                reportOpaque(name)
            }
        }
    }

    /// Deep enough for a nested CollectionDataSource; a reference cycle stops
    /// here instead of recursing forever.
    private static let maxDepth = 32

    private static var reportedOpaqueTypes = Set<String>()
    private static let reportLock = NSLock()

    private static func reportOpaque(_ name: String) {
        reportLock.lock()
        defer { reportLock.unlock() }
        guard reportedOpaqueTypes.insert(name).inserted else { return }
        Logger.log("[CellIdGenerator] \(name) has no content to hash (not Hashable, no stored values): a change inside it does not change the cell's id. Make it Hashable or conform it to CellIdHashIgnorable.")
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
