//
//  TabViewConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI TabView
//

import SwiftUI
#if DEBUG


public struct TabViewConverter {
    
    /// Convert DynamicComponent to SwiftUI TabView
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String? = nil
    ) -> AnyView {
        // Get tabs array from component
        let selectedIndex = component.selectedIndex ?? 0
        
        return AnyView(
            TabView(selection: .constant(selectedIndex)) {

            }
            .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}
#endif // DEBUG
