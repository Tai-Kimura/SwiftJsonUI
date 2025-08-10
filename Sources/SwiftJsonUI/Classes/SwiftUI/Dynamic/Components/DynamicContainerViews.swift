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
        if let child = component.child {
            Logger.debug("[DynamicViewContainer] Processing child field...")
            // child is AnyCodable, can be single component or array
            if let singleComponent = child.asDynamicComponent {
                Logger.debug("[DynamicViewContainer] Found single component: \(singleComponent.type)")
                return [singleComponent]
            } else if let componentArray = child.asDynamicComponentArray {
                Logger.debug("[DynamicViewContainer] Found component array with \(componentArray.count) items")
                return componentArray
            } else {
                Logger.debug("[DynamicViewContainer] child field exists but couldn't decode as component")
            }
        }
        
        if let children = component.children {
            Logger.debug("[DynamicViewContainer] Found children array with \(children.count) items")
            return children
        }
        
        Logger.debug("[DynamicViewContainer] No children found")
        return []
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
            VStack(spacing: 0) {
                ForEach(Array(getChildren().enumerated()), id: \.offset) { _, child in
                    DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                }
            }
        }
    }
    
    private func getChildren() -> [DynamicComponent] {
        if let child = component.child {
            Logger.debug("[DynamicViewContainer] Processing child field...")
            // child is AnyCodable, can be single component or array
            if let singleComponent = child.asDynamicComponent {
                Logger.debug("[DynamicViewContainer] Found single component: \(singleComponent.type)")
                return [singleComponent]
            } else if let componentArray = child.asDynamicComponentArray {
                Logger.debug("[DynamicViewContainer] Found component array with \(componentArray.count) items")
                return componentArray
            } else {
                Logger.debug("[DynamicViewContainer] child field exists but couldn't decode as component")
            }
        }
        
        if let children = component.children {
            Logger.debug("[DynamicViewContainer] Found children array with \(children.count) items")
            return children
        }
        
        Logger.debug("[DynamicViewContainer] No children found")
        return []
    }
}