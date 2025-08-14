//
//  RelativePositioningContainer.swift
//  SwiftJsonUI
//
//  Relative positioning container using SwiftJsonUI's RelativePositionContainer
//

import SwiftUI

// MARK: - Relative Positioning Container
public struct RelativePositioningContainer: View {
    let children: [DynamicComponent]
    @ObservedObject var viewModel: DynamicViewModel
    let viewId: String?
    
    public init(
        children: [DynamicComponent],
        viewModel: DynamicViewModel,
        viewId: String? = nil
    ) {
        self.children = children
        self.viewModel = viewModel
        self.viewId = viewId
    }
    
    public var body: some View {
        // Convert DynamicComponents to RelativeChildConfigs
        let childConfigs = children.enumerated().map { index, child in
            RelativePositionConverter.convert(
                component: child,
                index: index,
                viewBuilder: { component in
                    AnyView(ChildView(component: component, viewModel: viewModel, viewId: viewId))
                }
            )
        }
        
        // Use SwiftJsonUI's RelativePositionContainer
        RelativePositionContainer(
            children: childConfigs,
            alignment: .topLeading,
            backgroundColor: nil
        )
    }
}