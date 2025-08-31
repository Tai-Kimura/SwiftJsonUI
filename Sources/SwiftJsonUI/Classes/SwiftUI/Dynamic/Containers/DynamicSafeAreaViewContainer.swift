//
//  DynamicSafeAreaViewContainer.swift
//  SwiftJsonUI
//
//  SafeAreaView container that respects safe area bounds
//

import SwiftUI
#if DEBUG


// MARK: - SafeAreaView Container
public struct DynamicSafeAreaViewContainer: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    let viewId: String?
    
    public init(component: DynamicComponent, viewModel: DynamicViewModel, viewId: String? = nil) {
        self.component = component
        self.viewModel = viewModel
        self.viewId = viewId
    }
    
    public var body: some View {
        // Use DynamicViewContainer for the actual content
        // The key difference is that SafeAreaView does NOT apply .ignoresSafeArea()
        DynamicViewContainer(component: component, viewModel: viewModel, viewId: viewId)
            .modifier(CommonModifiers(component: component, viewModel: viewModel))
            // SafeAreaView explicitly respects safe area - no .ignoresSafeArea() applied
    }
}
#endif // DEBUG
