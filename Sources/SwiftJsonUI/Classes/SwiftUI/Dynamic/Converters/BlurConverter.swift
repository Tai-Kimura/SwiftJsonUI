//
//  BlurConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI View with Blur Effect
//

import SwiftUI

public struct BlurConverter {
    
    /// Convert DynamicComponent to SwiftUI View with Blur Effect
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String? = nil
    ) -> AnyView {
        // Create content
        let content: AnyView
        
        if let children = component.child, !children.isEmpty {
            if children.count == 1 {
                // Single child
                content = AnyView(
                    ChildView(component: children[0], viewModel: viewModel, viewId: viewId)
                )
            } else {
                // Multiple children
                content = AnyView(
                    VStack(spacing: 0) {
                        ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                            ChildView(component: child, viewModel: viewModel, viewId: viewId)
                        }
                    }
                )
            }
        } else {
            // No children - use clear color
            content = AnyView(Color.clear)
        }
        
        // Apply blur background
        return AnyView(
            content
                .background(.ultraThinMaterial)
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}