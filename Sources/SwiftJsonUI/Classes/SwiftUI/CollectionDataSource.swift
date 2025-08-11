import SwiftUI

/// Collection data source configuration for SwiftJsonUI
public struct CollectionDataSource {
    /// Header classes mapped to their data arrays
    /// Key: class name, Value: array of data (can be model classes, dictionaries, etc.)
    public let headerClasses: [String: [Any]]
    
    /// Footer classes mapped to their data arrays
    /// Key: class name, Value: array of data (can be model classes, dictionaries, etc.)
    public let footerClasses: [String: [Any]]
    
    /// Cell classes mapped to their data arrays
    /// Key: class name, Value: array of data (can be model classes, dictionaries, etc.)
    public let cellClasses: [String: [Any]]
    
    public init(
        headerClasses: [String: [Any]] = [:],
        footerClasses: [String: [Any]] = [:],
        cellClasses: [String: [Any]] = [:]
    ) {
        self.headerClasses = headerClasses
        self.footerClasses = footerClasses
        self.cellClasses = cellClasses
    }
    
    /// Get cell data for a specific class name with type casting
    public func getCellData<T>(for className: String) -> [T] {
        guard let data = cellClasses[className] else { return [] }
        return data.compactMap { $0 as? T }
    }
    
    /// Get header data for a specific class name with type casting
    public func getHeaderData<T>(for className: String) -> [T] {
        guard let data = headerClasses[className] else { return [] }
        return data.compactMap { $0 as? T }
    }
    
    /// Get footer data for a specific class name with type casting
    public func getFooterData<T>(for className: String) -> [T] {
        guard let data = footerClasses[className] else { return [] }
        return data.compactMap { $0 as? T }
    }
    
    /// Get cell data for a specific class name without type casting
    public func getCellData(for className: String) -> [Any] {
        return cellClasses[className] ?? []
    }
    
    /// Get header data for a specific class name without type casting
    public func getHeaderData(for className: String) -> [Any] {
        return headerClasses[className] ?? []
    }
    
    /// Get footer data for a specific class name without type casting
    public func getFooterData(for className: String) -> [Any] {
        return footerClasses[className] ?? []
    }
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