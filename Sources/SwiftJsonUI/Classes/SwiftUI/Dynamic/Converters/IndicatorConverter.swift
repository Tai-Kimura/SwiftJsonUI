//
//  IndicatorConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Activity Indicator (ProgressView)
//

import SwiftUI
#if DEBUG


public struct IndicatorConverter {
    
    /// Convert DynamicComponent to SwiftUI ProgressView (Activity Indicator)
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        
        // Check if we should hide when stopped
        let hidesWhenStopped = component.hidesWhenStopped ?? true
        
        // Check if the indicator is animating (default true unless explicitly stopped)
        let isAnimating = component.isOn ?? true
        
        if !isAnimating && hidesWhenStopped {
            // Hide the indicator when not animating
            return AnyView(
                EmptyView()
                    .modifier(CommonModifiers(component: component, viewModel: viewModel))
            )
        }
        
        return AnyView(
            ProgressView()
                .progressViewStyle(getIndicatorStyle(component))
                .scaleEffect(getScale(component))
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
    
    private static func getIndicatorStyle(_ component: DynamicComponent) -> some ProgressViewStyle {
        switch component.indicatorStyle?.lowercased() {
        case "large":
            return CircularProgressViewStyle(tint: getIndicatorColor(component))
        default:
            return CircularProgressViewStyle(tint: getIndicatorColor(component))
        }
    }
    
    private static func getScale(_ component: DynamicComponent) -> CGFloat {
        switch component.indicatorStyle?.lowercased() {
        case "large":
            return 1.5
        case "small":
            return 0.8
        default:
            return 1.0
        }
    }
    
    private static func getIndicatorColor(_ component: DynamicComponent) -> Color {
        // Use color, tintColor, fontColor, or iconColor in that order
        if let colorHex = component.color ?? component.tintColor ?? component.tint ?? component.fontColor ?? component.iconColor {
            return DynamicHelpers.colorFromHex(colorHex) ?? .primary
        }
        return .primary
    }
}
#endif // DEBUG
