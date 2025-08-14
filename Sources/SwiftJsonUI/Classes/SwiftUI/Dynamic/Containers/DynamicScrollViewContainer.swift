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
        AdvancedKeyboardAvoidingScrollView {
            if let children = component.child {
                // Check if children need relative positioning
                let needsRelativePositioning = RelativePositionConverter.childrenNeedRelativePositioning(children)
                
                if needsRelativePositioning {
                    // Use RelativePositioningContainer for relative positioning
                    RelativePositioningContainer(children: children, viewModel: viewModel, viewId: viewId)
                } else if component.orientation == "horizontal" {
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                            DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                            DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .modifier(CommonModifiers(component: component, viewModel: viewModel))
    }
}