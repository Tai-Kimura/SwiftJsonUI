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
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // child is always an array
                if let children = component.child {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        ChildView(component: child, viewModel: viewModel, viewId: viewId)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}