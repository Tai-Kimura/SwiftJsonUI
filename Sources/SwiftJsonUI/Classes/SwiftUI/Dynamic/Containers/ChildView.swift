//
//  ChildView.swift
//  SwiftJsonUI
//
//  Child view wrapper that applies visibility using VisibilityWrapper
//

import SwiftUI

// MARK: - Child View with Visibility
public struct ChildView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    let viewId: String?
    
    public init(component: DynamicComponent, viewModel: DynamicViewModel, viewId: String? = nil) {
        self.component = component
        self.viewModel = viewModel
        self.viewId = viewId
    }
    
    public var body: some View {
        // Handle both visibility and hidden properties
        let visibility: String? = {
            if component.hidden == true {
                return "gone"
            }
            return component.visibility
        }()
        
        // Use SwiftJsonUI's VisibilityWrapper
        VisibilityWrapper(visibility) {
            DynamicComponentBuilder(component: component, viewModel: viewModel, viewId: viewId)
        }
    }
}