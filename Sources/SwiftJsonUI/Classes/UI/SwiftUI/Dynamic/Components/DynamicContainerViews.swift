//
//  DynamicContainerViews.swift
//  SwiftJsonUI
//
//  Dynamic container components
//

import SwiftUI

struct DynamicViewContainer: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    let viewId: String?
    
    init(component: DynamicComponent, viewModel: DynamicViewModel, viewId: String? = nil) {
        self.component = component
        self.viewModel = viewModel
        self.viewId = viewId
    }
    
    @ViewBuilder
    var body: some View {
        let children: [DynamicComponent] = component.child?.asArray ?? component.children ?? []
        
        switch children.count {
        case 0:
            EmptyView()
        case 1:
            DynamicComponentBuilder(component: children[0], viewModel: viewModel, viewId: viewId)
        default:
            multipleChildrenView(children: children)
        }
    }
    
    @ViewBuilder
    private func multipleChildrenView(children: [DynamicComponent]) -> some View {
        let orientation = component.orientation ?? "vertical"
        if orientation == "horizontal" {
            HStack(spacing: 0) {
                ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                    DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                }
            }
        } else {
            VStack(spacing: 0) {
                ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                    DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                }
            }
        }
    }
}

struct DynamicScrollViewContainer: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    let viewId: String?
    
    init(component: DynamicComponent, viewModel: DynamicViewModel, viewId: String? = nil) {
        self.component = component
        self.viewModel = viewModel
        self.viewId = viewId
    }
    
    @ViewBuilder
    var body: some View {
        ScrollView {
            let children: [DynamicComponent] = component.child?.asArray ?? component.children ?? []
            VStack(spacing: 0) {
                ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                    DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                }
            }
        }
    }
}