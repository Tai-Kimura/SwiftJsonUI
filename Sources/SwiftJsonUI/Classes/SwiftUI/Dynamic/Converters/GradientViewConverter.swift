//
//  GradientViewConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI View with Gradient Background
//

import SwiftUI

public struct GradientViewConverter {
    
    /// Convert DynamicComponent to SwiftUI View with Gradient Background
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
        
        // Apply gradient background
        return AnyView(
            content
                .background(getGradient(component))
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
    
    private static func getGradient(_ component: DynamicComponent) -> LinearGradient {
        // Get colors from data array (expecting hex strings)
        let colorHexes: [String] = component.data?.compactMap { item in
            if let dict = item.value as? [String: Any] {
                if let color = dict["color"] as? String {
                    return color
                }
                // Try to get first string value
                return dict.values.first { $0 is String } as? String
            }
            return nil
        } ?? []
        
        // Convert hex strings to Colors
        let colors = colorHexes.compactMap { hex in
            DynamicHelpers.colorFromHex(hex)
        }
        
        // If no colors, use default gradient
        let finalColors = colors.isEmpty ? [Color.blue, Color.purple] : colors
        
        // Determine gradient direction
        let startPoint: UnitPoint
        let endPoint: UnitPoint
        
        // Check for explicit start/end points in data
        if let firstItem = component.data?.first,
           let firstPoint = firstItem.value as? [String: Any],
           let startXStr = firstPoint["startX"] as? String,
           let startYStr = firstPoint["startY"] as? String,
           let endXStr = firstPoint["endX"] as? String,
           let endYStr = firstPoint["endY"] as? String,
           let startX = Double(startXStr),
           let startY = Double(startYStr),
           let endX = Double(endXStr),
           let endY = Double(endYStr) {
            startPoint = UnitPoint(x: startX, y: startY)
            endPoint = UnitPoint(x: endX, y: endY)
        } else {
            // Default to vertical gradient
            startPoint = .top
            endPoint = .bottom
        }
        
        return LinearGradient(
            colors: finalColors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}