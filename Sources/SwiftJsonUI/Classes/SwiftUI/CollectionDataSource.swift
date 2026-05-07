import SwiftUI

/// Section data for collection views (SwiftUI)
public struct CollectionDataSection {
    /// Header view name and its data
    public var header: (viewName: String, data: [String: Any])?

    /// Cell view name and array of data for cells
    public var cells: (viewName: String, data: [[String: Any]])?

    /// Footer view name and its data
    public var footer: (viewName: String, data: [String: Any])?

    /// Primary key for each cell dictionary. Combined with `autoChangeTrackingId`
    /// to enable auto `cellId` generation.
    public var cellIdProperty: String?

    /// When true (and `cellIdProperty` is set), `setCells` / `reconfigured`
    /// enrich each cell with a `"cellId"` = `"<primary>_<hash>"` entry.
    public var autoChangeTrackingId: Bool = false

    public init(
        header: (viewName: String, data: [String: Any])? = nil,
        cells: (viewName: String, data: [[String: Any]])? = nil,
        footer: (viewName: String, data: [String: Any])? = nil,
        cellIdProperty: String? = nil,
        autoChangeTrackingId: Bool = false
    ) {
        self.header = header
        self.cells = cells
        self.footer = footer
        self.cellIdProperty = cellIdProperty
        self.autoChangeTrackingId = autoChangeTrackingId
    }

    /// Set cells with view name and array of data
    public mutating func setCells(viewName: String, data: [[String: Any]]) {
        let payload = Self.enrichIfNeeded(
            data,
            cellIdProperty: cellIdProperty,
            autoChangeTrackingId: autoChangeTrackingId
        )
        cells = (viewName: viewName, data: payload)
    }

    /// Add a single cell data to existing cells
    public mutating func addCellData(_ data: [String: Any]) {
        if var cellsData = cells {
            cellsData.data.append(data)
            if autoChangeTrackingId, cellIdProperty != nil {
                cellsData.data = Self.enrichIfNeeded(
                    cellsData.data,
                    cellIdProperty: cellIdProperty,
                    autoChangeTrackingId: autoChangeTrackingId
                )
            }
            cells = cellsData
        }
    }

    /// Set header with view name and data
    public mutating func setHeader(viewName: String, data: [String: Any]) {
        header = (viewName: viewName, data: data)
    }

    /// Set footer with view name and data
    public mutating func setFooter(viewName: String, data: [String: Any]) {
        footer = (viewName: viewName, data: data)
    }

    /// Returns a copy with `cellIdProperty` / `autoChangeTrackingId` applied and
    /// the existing cells re-enriched. Idempotent: applying twice produces the
    /// same `cellId` values because `"cellId"` is excluded from the hash.
    public func reconfigured(
        cellIdProperty: String?,
        autoChangeTrackingId: Bool
    ) -> CollectionDataSection {
        var copy = self
        copy.cellIdProperty = cellIdProperty
        copy.autoChangeTrackingId = autoChangeTrackingId

        if let existing = copy.cells {
            let enriched = Self.enrichIfNeeded(
                existing.data,
                cellIdProperty: cellIdProperty,
                autoChangeTrackingId: autoChangeTrackingId
            )
            copy.cells = (viewName: existing.viewName, data: enriched)
        }
        return copy
    }

    private static func enrichIfNeeded(
        _ data: [[String: Any]],
        cellIdProperty: String?,
        autoChangeTrackingId: Bool
    ) -> [[String: Any]] {
        guard autoChangeTrackingId, let key = cellIdProperty, !key.isEmpty else {
            return data
        }
        let mapped = data.enumerated().map { index, d -> [String: Any] in
            var enriched = d
            enriched["cellId"] = CellIdGenerator.autoId(
                from: d, primaryKey: key, fallbackIndex: index
            )
            return enriched
        }
        return CellIdGenerator.dedupe(mapped)
    }
}

/// Collection data source configuration for SwiftJsonUI
public struct CollectionDataSource {
    /// Array of sections
    public var sections: [CollectionDataSection]

    public init(sections: [CollectionDataSection] = []) {
        self.sections = sections
    }

    public init() {
        self.sections = []
    }

    /// Add a new section
    public mutating func addSection(_ section: CollectionDataSection) {
        sections.append(section)
    }

    /// Propagates `cellIdProperty` / `autoChangeTrackingId` to every section
    /// and re-enriches their cells. Used by the static SwiftUI converter
    /// inside the body so spec attributes take effect without VM changes.
    public func reconfigured(
        cellIdProperty: String?,
        autoChangeTrackingId: Bool
    ) -> CollectionDataSource {
        var copy = self
        copy.sections = copy.sections.map {
            $0.reconfigured(
                cellIdProperty: cellIdProperty,
                autoChangeTrackingId: autoChangeTrackingId
            )
        }
        return copy
    }
}
