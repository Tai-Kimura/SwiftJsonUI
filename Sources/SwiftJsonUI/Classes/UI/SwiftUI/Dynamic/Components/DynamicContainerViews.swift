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
        let children = getChildren()
        
        switch children.count {
        case 0:
            EmptyView()
        case 1:
            DynamicComponentBuilder(component: children[0], viewModel: viewModel, viewId: viewId)
        default:
            multipleChildrenView(children: children)
        }
    }
    
    private func getChildren() -> [DynamicComponent] {
        if let childArray = component.child?.asArray {
            return childArray
        } else if let children = component.children {
            return children
        } else {
            return []
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
    
    private func getChildren() -> [DynamicComponent] {
        if let childArray = component.child?.asArray {
            return childArray
        } else if let children = component.children {
            return children
        } else {
            return []
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
            VStack(spacing: 0) {
                ForEach(Array(getChildren().enumerated()), id: \.offset) { _, child in
                    DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                }
            }
        }
    }
}