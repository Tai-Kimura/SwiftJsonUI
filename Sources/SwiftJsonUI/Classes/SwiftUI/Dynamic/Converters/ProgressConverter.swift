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
        // Try to get progress value from data dictionary first
        var progress = component.progress ?? component.value ?? 0.0
        
        if let componentId = component.id {
            // Try to find a matching progress property in data dictionary
            // Common patterns: progress1Value, progress1_value, etc.
            let possibleKeys = [
                "\(componentId)Value",
                "\(componentId)_value",
                componentId
            ]
            
            for key in possibleKeys {
                if let dataValue = viewModel.data[key] as? Double {
                    progress = dataValue
                    break
                }
            }
        }
        
        let isCircular = component.type?.lowercased().contains("circular") ?? false
        
        if progress > 0 {
            // Determinate progress
            if isCircular {
                return AnyView(
                    ProgressView(value: progress, total: 1.0) {
                        if let text = component.text {
                            Text(viewModel.processText(text))
                                .font(getFont(component))
                                .foregroundColor(getTextColor(component))
                        }
                    }
                    .progressViewStyle(CircularProgressViewStyle(tint: getTintColor(component)))
                    .modifier(CommonModifiers(component: component, viewModel: viewModel))
                )
            } else {
                return AnyView(
                    ProgressView(value: progress, total: 1.0) {
                        if let text = component.text {
                            Text(viewModel.processText(text))
                                .font(getFont(component))
                                .foregroundColor(getTextColor(component))
                        }
                    }
                    .progressViewStyle(LinearProgressViewStyle(tint: getTintColor(component)))
                    .modifier(CommonModifiers(component: component, viewModel: viewModel))
                )
            }
        } else {
            // Indeterminate progress
            if isCircular {
                return AnyView(
                    ProgressView {
                        if let text = component.text {
                            Text(viewModel.processText(text) ?? text)
                                .font(getFont(component))
                                .foregroundColor(getTextColor(component))
                        }
                    }
                    .progressViewStyle(CircularProgressViewStyle(tint: getTintColor(component)))
                    .modifier(CommonModifiers(component: component, viewModel: viewModel))
                )
            } else {
                return AnyView(
                    ProgressView {
                        if let text = component.text {
                            Text(viewModel.processText(text) ?? text)
                                .font(getFont(component))
                                .foregroundColor(getTextColor(component))
                        }
                    }
                    .progressViewStyle(LinearProgressViewStyle(tint: getTintColor(component)))
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
    
    private static func getTintColor(_ component: DynamicComponent) -> Color? {
        if let tintColor = component.tintColor ?? component.tint {
            return DynamicHelpers.colorFromHex(tintColor)
        }
        return nil
    }
}