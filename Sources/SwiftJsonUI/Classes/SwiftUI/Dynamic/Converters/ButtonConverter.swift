//
//  ButtonConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Button view
//

import SwiftUI

public struct ButtonConverter {
    
    /// Convert DynamicComponent to SwiftUI Button view
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let text = component.text ?? ""
        
        return AnyView(
            Button(action: {
                handleButtonAction(component: component, viewModel: viewModel)
            }) {
                Text(text)
                    .font(DynamicHelpers.fontFromComponent(component))
                    .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .white)
                    .frame(maxWidth: component.width == .infinity ? .infinity : nil)
                    .padding(getButtonPadding(component))
            }
            .buttonStyle(getDynamicButtonStyle(component))
            .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
    
    private static func handleButtonAction(component: DynamicComponent, viewModel: DynamicViewModel) {
        // Handle onClick action
        if let action = component.onClick {
            viewModel.handleAction(action)
        }
        
        // Handle action property
        if let action = component.action {
            viewModel.handleAction(action)
        }
    }
    
    
    private static func getButtonPadding(_ component: DynamicComponent) -> EdgeInsets {
        // Default button padding if not specified
        let defaultPadding: CGFloat = 12
        
        let top = component.paddingTop ?? component.topPadding ?? component.padding?.value as? CGFloat ?? defaultPadding
        let leading = component.paddingLeft ?? component.leftPadding ?? component.padding?.value as? CGFloat ?? defaultPadding * 2
        let bottom = component.paddingBottom ?? component.bottomPadding ?? component.padding?.value as? CGFloat ?? defaultPadding
        let trailing = component.paddingRight ?? component.rightPadding ?? component.padding?.value as? CGFloat ?? defaultPadding * 2
        
        return EdgeInsets(
            top: top,
            leading: leading,
            bottom: bottom,
            trailing: trailing
        )
    }
    
    private static func getDynamicButtonStyle(_ component: DynamicComponent) -> some ButtonStyle {
        DynamicButtonStyle(
            backgroundColor: DynamicHelpers.colorFromHex(component.background) ?? .blue,
            cornerRadius: component.cornerRadius ?? 8
        )
    }
}

// MARK: - Custom Button Style
struct DynamicButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(backgroundColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}