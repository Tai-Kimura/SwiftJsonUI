//
//  DynamicScrollViewContainer.swift
//  SwiftJsonUI
//
//  ScrollView container for dynamic layouts
//

import SwiftUI

// MARK: - ScrollView Container
public struct DynamicScrollViewContainer: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    let viewId: String?
    
    public init(component: DynamicComponent, viewModel: DynamicViewModel, viewId: String? = nil) {
        self.component = component
        self.viewModel = viewModel
        self.viewId = viewId
    }
    
    @ViewBuilder
    public var body: some View {
        let _ = print("📜 DynamicScrollViewContainer: id=\(component.id ?? "no-id"), childCount=\(component.child?.count ?? 0), width=\(component.width ?? -999), height=\(component.height ?? -999)")
        
        // ScrollView's padding should be applied to its content
        // Create custom modifiers that skip padding for ScrollView itself
        let customModifiers = ModifierOverrides(
            skipPadding: true  // Don't apply padding to ScrollView itself
        )
        
        AdvancedKeyboardAvoidingScrollView {
            // ScrollView should have exactly one child
            if let children = component.child, let firstChild = children.first {
                // Apply ScrollView's padding to the child content
                DynamicComponentBuilder(component: firstChild, viewModel: viewModel, viewId: viewId)
                    .padding(DynamicHelpers.getPadding(from: component))
            }
        }
        .modifier(CommonModifiers(component: component, viewModel: viewModel, customModifiers: customModifiers))
    }
}