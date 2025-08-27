import SwiftUI

/// Section data for collection views (SwiftUI)
public class CollectionDataSection {
    /// Header view name and its data
    public var header: (viewName: String, data: Any)?
    
    /// Array of cell views and their data
    public var cells: [(viewName: String, data: Any)]
    
    /// Footer view name and its data
    public var footer: (viewName: String, data: Any)?
    
    public init(
        header: (viewName: String, data: Any)? = nil,
        cells: [(viewName: String, data: Any)] = [],
        footer: (viewName: String, data: Any)? = nil
    ) {
        self.header = header
        self.cells = cells
        self.footer = footer
    }
    
    /// Add a cell with view name and data
    public func addCell(viewName: String, data: Any) {
        cells.append((viewName: viewName, data: data))
    }
    
    /// Set header with view name and data
    public func setHeader(viewName: String, data: Any) {
        header = (viewName: viewName, data: data)
    }
    
    /// Set footer with view name and data
    public func setFooter(viewName: String, data: Any) {
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
    
    // MARK: - Legacy API for backward compatibility
    
    /// Header classes mapped to their data arrays (deprecated - use sections instead)
    private var headerClasses: [String: [Any]] = [:]
    
    /// Footer classes mapped to their data arrays (deprecated - use sections instead)
    private var footerClasses: [String: [Any]] = [:]
    
    /// Cell classes mapped to their data arrays (deprecated - use sections instead)
    private var cellClasses: [String: [Any]] = [:]
    
    /// Legacy: Set cell data for a specific class name
    /// This creates a single section with all the cells
    public func setCellData(for className: String, data: [Any]) {
        cellClasses[className] = data
        rebuildSectionsFromLegacyData()
    }
    
    /// Legacy: Set header data for a specific class name
    public func setHeaderData(for className: String, data: [Any]) {
        headerClasses[className] = data
        rebuildSectionsFromLegacyData()
    }
    
    /// Legacy: Set footer data for a specific class name
    public func setFooterData(for className: String, data: [Any]) {
        footerClasses[className] = data
        rebuildSectionsFromLegacyData()
    }
    
    /// Rebuild sections from legacy API data
    private func rebuildSectionsFromLegacyData() {
        // Clear existing sections if using legacy API
        if !cellClasses.isEmpty || !headerClasses.isEmpty || !footerClasses.isEmpty {
            sections.removeAll()
            
            // Create a single section with all legacy data
            let section = CollectionDataSection()
            
            // Add first header if exists
            if let firstHeader = headerClasses.first {
                if let firstData = firstHeader.value.first {
                    section.setHeader(componentName: firstHeader.key, data: firstData)
                }
            }
            
            // Add all cells from all cell classes
            for (className, dataArray) in cellClasses {
                for data in dataArray {
                    section.addCell(componentName: className, data: data)
                }
            }
            
            // Add first footer if exists
            if let firstFooter = footerClasses.first {
                if let firstData = firstFooter.value.first {
                    section.setFooter(componentName: firstFooter.key, data: firstData)
                }
            }
            
            if !section.cells.isEmpty || section.header != nil || section.footer != nil {
                sections.append(section)
            }
        }
    }
    
    /// Legacy: Get cell data for a specific class name with type casting
    public func getCellData<T>(for className: String) -> [T] {
        guard !sections.isEmpty else {
            // Fallback to legacy data
            guard let data = cellClasses[className] else { return [] }
            return data.compactMap { $0 as? T }
        }
        
        // Collect all cells with matching component name from all sections
        var result: [T] = []
        for section in sections {
            for cell in section.cells where cell.componentName == className {
                if let typedData = cell.data as? T {
                    result.append(typedData)
                }
            }
        }
        return result
    }
    
    /// Legacy: Get header data for a specific class name with type casting
    public func getHeaderData<T>(for className: String) -> [T] {
        guard !sections.isEmpty else {
            guard let data = headerClasses[className] else { return [] }
            return data.compactMap { $0 as? T }
        }
        
        // Collect all headers with matching component name from all sections
        var result: [T] = []
        for section in sections {
            if let header = section.header,
               header.componentName == className,
               let typedData = header.data as? T {
                result.append(typedData)
            }
        }
        return result
    }
    
    /// Legacy: Get footer data for a specific class name with type casting
    public func getFooterData<T>(for className: String) -> [T] {
        guard !sections.isEmpty else {
            guard let data = footerClasses[className] else { return [] }
            return data.compactMap { $0 as? T }
        }
        
        // Collect all footers with matching component name from all sections
        var result: [T] = []
        for section in sections {
            if let footer = section.footer,
               footer.componentName == className,
               let typedData = footer.data as? T {
                result.append(typedData)
            }
        }
        return result
    }
    
    /// Legacy: Get cell data for a specific class name without type casting
    public func getCellData(for className: String) -> [Any] {
        guard !sections.isEmpty else {
            return cellClasses[className] ?? []
        }
        
        // Collect all cells with matching component name from all sections
        var result: [Any] = []
        for section in sections {
            for cell in section.cells where cell.componentName == className {
                result.append(cell.data)
            }
        }
        return result
    }
    
    /// Legacy: Get header data for a specific class name without type casting
    public func getHeaderData(for className: String) -> [Any] {
        guard !sections.isEmpty else {
            return headerClasses[className] ?? []
        }
        
        // Collect all headers with matching component name
        var result: [Any] = []
        for section in sections {
            if let header = section.header, header.componentName == className {
                result.append(header.data)
            }
        }
        return result
    }
    
    /// Legacy: Get footer data for a specific class name without type casting
    public func getFooterData(for className: String) -> [Any] {
        guard !sections.isEmpty else {
            return footerClasses[className] ?? []
        }
        
        // Collect all footers with matching component name
        var result: [Any] = []
        for section in sections {
            if let footer = section.footer, footer.componentName == className {
                result.append(footer.data)
            }
        }
        return result
}

/// Protocol for views that can receive collection item data
public protocol CollectionDataReceiver {
    associatedtype DataType
    var data: DataType { get set }
}

/// Extension to help with collection data binding
public extension View {
    /// Set collection item data to the view's environment
    func collectionItemData(_ data: Any) -> some View {
        self.environment(\.collectionItemData, data)
    }
}

/// Environment key for passing collection item data
private struct CollectionItemDataKey: EnvironmentKey {
    static let defaultValue: Any? = nil
}

public extension EnvironmentValues {
    var collectionItemData: Any? {
        get { self[CollectionItemDataKey.self] }
        set { self[CollectionItemDataKey.self] = newValue }
    }
}