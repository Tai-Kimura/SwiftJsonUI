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
    ///   - data: The data dictionary for variable resolution
    ///   - viewId: Optional view identifier
    ///   - parentOrientation: The parent container's orientation
    /// - Returns: A SwiftUI view
    func buildView(
        component: DynamicComponent,
        data: [String: Any],
        viewId: String?,
        parentOrientation: String?
    ) -> AnyView

    /// False for a leaf — a component scaffolded with `sjui g converter <Name>
    /// --no-container`, which has no content slot. A layout that gives it
    /// children then draws an error naming the component and the children
    /// instead of the component, as `jui build` refuses that layout in
    /// codegen. Defaults to true, so an adapter that does not say is drawn as
    /// before.
    var acceptsChildren: Bool { get }
}

extension CustomComponentAdapter {
    public var acceptsChildren: Bool { true }
}

/// What a leaf given children is told, in Dynamic as in the build.
public enum LeafChildren {
    /// The message for `component` drawn by `adapter`, or nil when there is
    /// nothing to refuse: the adapter takes children, or the layout gives
    /// none. Data-only entries (`{"data": [...]}`) are not children.
    public static func rejection(for adapter: CustomComponentAdapter, component: DynamicComponent) -> String? {
        guard !adapter.acceptsChildren else { return nil }
        let key = component.child != nil ? "child" : "children"
        let dropped = (component.childComponents ?? []).enumerated().compactMap { index, child -> String? in
            guard child.isValid || child.include != nil else { return nil }
            return "\(key)[\(index)]" + (child.id.map { " (id=\($0))" } ?? "")
        }
        guard !dropped.isEmpty else { return nil }
        let node = component.id.map { " (id=\($0))" } ?? ""
        // The same sentence as the wrapper kjui writes for an Android leaf:
        // jsonui-cli shared/core/leaf_children_vectors.json binds the two.
        return "'\(adapter.componentType)'\(node) takes no children — it is declared a leaf, so "
            + dropped.joined(separator: ", ") + (dropped.count == 1 ? " is" : " are") + " not drawn."
            + " Remove the children, or regenerate the component with --container."
    }
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