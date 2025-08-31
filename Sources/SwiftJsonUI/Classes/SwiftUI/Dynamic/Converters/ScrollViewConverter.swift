//
//  ScrollViewConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI ScrollView
//

import SwiftUI
#if DEBUG


public struct ScrollViewConverter {
    
    /// Convert DynamicComponent to SwiftUI ScrollView
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String? = nil
    ) -> AnyView {
        // Use existing DynamicScrollViewContainer
        return AnyView(
            DynamicScrollViewContainer(
                component: component,
                viewModel: viewModel,
                viewId: viewId
            )
        )
    }
}
#endif // DEBUG
