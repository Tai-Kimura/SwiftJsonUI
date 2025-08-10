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
            let _ = Logger.debug("[DynamicViewContainer] Processing child field...")
            let _ = Logger.debug("[DynamicViewContainer] child value type: \(type(of: child.value))")
            
            // Check if value is array of DynamicComponent directly
            if let componentArray = child.asDynamicComponentArray {
                let _ = Logger.debug("[DynamicViewContainer] Found component array with \(componentArray.count) items")
                for (index, comp) in componentArray.enumerated() {
                    let _ = Logger.debug("[DynamicViewContainer]   Item \(index): type=\(comp.type)")
                }
                return componentArray
            }
            // Check if value is array of AnyCodable (which may contain DynamicComponents and/or data objects)
            else if let anyCodableArray = child.value as? [AnyCodable] {
                let _ = Logger.debug("[DynamicViewContainer] Found array of AnyCodable, extracting components...")
                var components: [DynamicComponent] = []
                for (index, item) in anyCodableArray.enumerated() {
                    if let comp = item.value as? DynamicComponent {
                        components.append(comp)
                        let _ = Logger.debug("[DynamicViewContainer]   Item \(index): Component with type=\(comp.type)")
                    } else if let dict = item.value as? [String: AnyCodable],
                              dict["data"] != nil {
                        // This is a data binding definition, skip it
                        let _ = Logger.debug("[DynamicViewContainer]   Item \(index): Data binding definition (skipped)")
                    } else {
                        let _ = Logger.debug("[DynamicViewContainer]   Item \(index): Unknown type (skipped)")
                    }
                }
                if !components.isEmpty {
                    let _ = Logger.debug("[DynamicViewContainer] Extracted \(components.count) components from AnyCodable array")
                    return components
                }
            }
            // Check if single component
            else if let singleComponent = child.asDynamicComponent {
                let _ = Logger.debug("[DynamicViewContainer] Found single component: \(singleComponent.type)")
                return [singleComponent]
            } else {
                let _ = Logger.debug("[DynamicViewContainer] child field exists but couldn't decode as component")
                let _ = Logger.debug("[DynamicViewContainer] child.value: \(child.value)")
            }
        }
        
        if let children = component.children {
            let _ = Logger.debug("[DynamicViewContainer] Found children array with \(children.count) items")
            return children
        }
        
        let _ = Logger.debug("[DynamicViewContainer] No children found")
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
            let _ = Logger.debug("[DynamicViewContainer] Processing child field...")
            let _ = Logger.debug("[DynamicViewContainer] child value type: \(type(of: child.value))")
            
            // Check if value is array of DynamicComponent directly
            if let componentArray = child.asDynamicComponentArray {
                let _ = Logger.debug("[DynamicViewContainer] Found component array with \(componentArray.count) items")
                for (index, comp) in componentArray.enumerated() {
                    let _ = Logger.debug("[DynamicViewContainer]   Item \(index): type=\(comp.type)")
                }
                return componentArray
            }
            // Check if value is array of AnyCodable (which may contain DynamicComponents and/or data objects)
            else if let anyCodableArray = child.value as? [AnyCodable] {
                let _ = Logger.debug("[DynamicViewContainer] Found array of AnyCodable, extracting components...")
                var components: [DynamicComponent] = []
                for (index, item) in anyCodableArray.enumerated() {
                    if let comp = item.value as? DynamicComponent {
                        components.append(comp)
                        let _ = Logger.debug("[DynamicViewContainer]   Item \(index): Component with type=\(comp.type)")
                    } else if let dict = item.value as? [String: AnyCodable],
                              dict["data"] != nil {
                        // This is a data binding definition, skip it
                        let _ = Logger.debug("[DynamicViewContainer]   Item \(index): Data binding definition (skipped)")
                    } else {
                        let _ = Logger.debug("[DynamicViewContainer]   Item \(index): Unknown type (skipped)")
                    }
                }
                if !components.isEmpty {
                    let _ = Logger.debug("[DynamicViewContainer] Extracted \(components.count) components from AnyCodable array")
                    return components
                }
            }
            // Check if single component
            else if let singleComponent = child.asDynamicComponent {
                let _ = Logger.debug("[DynamicViewContainer] Found single component: \(singleComponent.type)")
                return [singleComponent]
            } else {
                let _ = Logger.debug("[DynamicViewContainer] child field exists but couldn't decode as component")
                let _ = Logger.debug("[DynamicViewContainer] child.value: \(child.value)")
            }
        }
        
        if let children = component.children {
            let _ = Logger.debug("[DynamicViewContainer] Found children array with \(children.count) items")
            return children
        }
        
        let _ = Logger.debug("[DynamicViewContainer] No children found")
        return []
    }
}