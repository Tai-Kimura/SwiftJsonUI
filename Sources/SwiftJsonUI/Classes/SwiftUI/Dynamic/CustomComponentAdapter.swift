//
//  CustomComponentAdapter.swift
//  SwiftJsonUI
//
//  Protocol for registering custom component builders in Dynamic mode
//

import SwiftUI

#if DEBUG

/// Protocol for adapters that can build custom components in Dynamic mode
public protocol CustomComponentAdapter {
    /// The component type this adapter handles (e.g., "TestComponent", "CustomButton")
    var componentType: String { get }
    
    /// Build the SwiftUI view for the given component
    /// - Parameters:
    ///   - component: The dynamic component data
    ///   - viewModel: The view model for data binding
    ///   - viewId: Optional view identifier
    ///   - parentOrientation: The parent container's orientation
    /// - Returns: A SwiftUI view
    func buildView(
        component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String?,
        parentOrientation: String?
    ) -> AnyView
}

/// Registry for custom component adapters
public class CustomComponentRegistry {
    /// Shared singleton instance
    public static let shared = CustomComponentRegistry()
    
    /// Dictionary of registered adapters keyed by component type
    private var adapters: [String: CustomComponentAdapter] = [:]
    
    private init() {}
    
    /// Register a custom component adapter
    /// - Parameter adapter: The adapter to register
    public func register(_ adapter: CustomComponentAdapter) {
        let key = adapter.componentType.lowercased()
        adapters[key] = adapter
        print("📦 Registered custom adapter for type: \(adapter.componentType)")
    }
    
    /// Register multiple adapters at once
    /// - Parameter adapters: Array of adapters to register
    public func registerAll(_ adapters: [CustomComponentAdapter]) {
        adapters.forEach { register($0) }
    }
    
    /// Get an adapter for the given component type
    /// - Parameter type: The component type to look up
    /// - Returns: The registered adapter if found, nil otherwise
    public func adapter(for type: String) -> CustomComponentAdapter? {
        return adapters[type.lowercased()]
    }
    
    /// Remove all registered adapters
    public func reset() {
        adapters.removeAll()
    }
}

#endif // DEBUG