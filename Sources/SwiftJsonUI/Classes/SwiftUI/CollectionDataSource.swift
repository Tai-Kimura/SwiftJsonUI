import SwiftUI

/// Section data for collection views (SwiftUI)
public class CollectionDataSection {
    /// Header view name and its data
    public var header: (viewName: String, data: [String: Any])?
    
    /// Cell view name and array of data for cells
    public var cells: (viewName: String, data: [[String: Any]])?
    
    /// Footer view name and its data
    public var footer: (viewName: String, data: [String: Any])?
    
    public init(
        header: (viewName: String, data: [String: Any])? = nil,
        cells: (viewName: String, data: [[String: Any]])? = nil,
        footer: (viewName: String, data: [String: Any])? = nil
    ) {
        self.header = header
        self.cells = cells
        self.footer = footer
    }
    
    /// Set cells with view name and array of data
    public func setCells(viewName: String, data: [[String: Any]]) {
        cells = (viewName: viewName, data: data)
    }
    
    /// Add a single cell data to existing cells
    public func addCellData(_ data: [String: Any]) {
        if var cellsData = cells {
            cellsData.data.append(data)
            cells = cellsData
        }
    }
    
    /// Set header with view name and data
    public func setHeader(viewName: String, data: [String: Any]) {
        header = (viewName: viewName, data: data)
    }
    
    /// Set footer with view name and data
    public func setFooter(viewName: String, data: [String: Any]) {
        footer = (viewName: viewName, data: data)
    }
}

/// Collection data source configuration for SwiftJsonUI
public class CollectionDataSource {
    /// Array of sections
    public var sections: [CollectionDataSection]
    
    public init(sections: [CollectionDataSection] = []) {
        self.sections = sections
    }
    
    public init() {
        self.sections = []
    }
    
    /// Add a new section
    public func addSection(_ section: CollectionDataSection) {
        sections.append(section)
    }
    
    /// Create and add a new section with builder pattern
    @discardableResult
    public func addSection() -> CollectionDataSection {
        let section = CollectionDataSection()
        sections.append(section)
        return section
    }
}