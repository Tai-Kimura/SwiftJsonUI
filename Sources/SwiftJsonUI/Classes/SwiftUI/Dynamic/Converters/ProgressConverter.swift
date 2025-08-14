//
//  ProgressConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI ProgressView
//

import SwiftUI

public struct ProgressConverter {
    
    /// Convert DynamicComponent to SwiftUI ProgressView
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let progress = component.progress ?? component.value ?? 0.0
        let isCircular = component.type?.lowercased().contains("circular") ?? false
        
        if progress > 0 {
            // Determinate progress
            if isCircular {
                return AnyView(
                    ProgressView(value: progress, total: 1.0) {
                        if let text = component.text {
                            Text(text)
                                .font(getFont(component))
                                .foregroundColor(getTextColor(component))
                        }
                    }
                    .progressViewStyle(CircularProgressViewStyle())
                    .modifier(CommonModifiers(component: component, viewModel: viewModel))
                )
            } else {
                return AnyView(
                    ProgressView(value: progress, total: 1.0) {
                        if let text = component.text {
                            Text(text)
                                .font(getFont(component))
                                .foregroundColor(getTextColor(component))
                        }
                    }
                    .progressViewStyle(LinearProgressViewStyle())
                    .modifier(CommonModifiers(component: component, viewModel: viewModel))
                )
            }
        } else {
            // Indeterminate progress
            if isCircular {
                return AnyView(
                    ProgressView {
                        if let text = component.text {
                            Text(text)
                                .font(getFont(component))
                                .foregroundColor(getTextColor(component))
                        }
                    }
                    .progressViewStyle(CircularProgressViewStyle())
                    .modifier(CommonModifiers(component: component, viewModel: viewModel))
                )
            } else {
                return AnyView(
                    ProgressView {
                        if let text = component.text {
                            Text(text)
                                .font(getFont(component))
                                .foregroundColor(getTextColor(component))
                        }
                    }
                    .progressViewStyle(LinearProgressViewStyle())
                    .modifier(CommonModifiers(component: component, viewModel: viewModel))
                )
            }
        }
    }
    
    private static func getFont(_ component: DynamicComponent) -> Font {
        let size = component.fontSize ?? 14
        return .system(size: size)
    }
    
    private static func getTextColor(_ component: DynamicComponent) -> Color {
        if let colorHex = component.fontColor {
            return DynamicHelpers.colorFromHex(colorHex) ?? .primary
        }
        return .primary
    }
}