//
//  TabViewConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI TabView
//

import SwiftUI

public struct TabViewConverter {
    
    /// Convert DynamicComponent to SwiftUI TabView
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String? = nil
    ) -> AnyView {
        // Get tabs array from component
        let tabs = component.data ?? []
        let selectedIndex = component.selectedIndex ?? 0
        
        return AnyView(
            TabView(selection: .constant(selectedIndex)) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    let tab = tabs[index]
                    
                    // Create tab content
                    VStack {
                        // If tab has child components
                        if let child = component.child,
                           index < child.count {
                            ChildView(
                                component: child[index],
                                viewModel: viewModel,
                                viewId: viewId
                            )
                        } else {
                            // Default content for tab
                            Text(tab["content"] ?? "Tab \(index + 1)")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .tabItem {
                        Label(
                            tab["title"] ?? "Tab \(index + 1)",
                            systemImage: tab["icon"] ?? "circle"
                        )
                    }
                    .tag(index)
                }
            }
            .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}