//
//  SpacerConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Spacer
//

import SwiftUI

public struct SpacerConverter {
    
    /// Convert DynamicComponent to SwiftUI Spacer
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        return AnyView(
            Spacer()
                .frame(
                    width: component.width,
                    height: component.height,
                    alignment: component.alignment ?? .center
                )
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}