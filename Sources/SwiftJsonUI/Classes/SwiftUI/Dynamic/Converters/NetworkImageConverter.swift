//
//  NetworkImageConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftJsonUI NetworkImage
//

import SwiftUI

public struct NetworkImageConverter {
    
    /// Convert DynamicComponent to SwiftJsonUI NetworkImage (for type: "NetworkImage")
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        
        let contentMode = getContentMode(component)
        let renderingMode = getRenderingMode(component)
        
        return AnyView(
            NetworkImage(
                url: component.src,
                placeholder: component.placeholder,
                contentMode: contentMode,
                renderingMode: renderingMode,
                headers: component.headers ?? [:]
            )
            .frame(width: component.width, height: component.height)
            .padding(getNetworkImagePadding(component))  // Internal padding
            .background(DynamicHelpers.colorFromHex(component.background) ?? .clear)
            .cornerRadius(component.cornerRadius ?? 0)
            .modifier(NetworkImageModifiers(component: component, viewModel: viewModel))  // External margins only
        )
    }
    
    private static func getNetworkImagePadding(_ component: DynamicComponent) -> EdgeInsets {
        // Get padding value from AnyCodable
        var paddingValue: CGFloat? = nil
        if let padding = component.padding {
            if let intValue = padding.value as? Int {
                paddingValue = CGFloat(intValue)
            } else if let doubleValue = padding.value as? Double {
                paddingValue = CGFloat(doubleValue)
            } else if let floatValue = padding.value as? CGFloat {
                paddingValue = floatValue
            }
        }
        
        // If padding is specified, use it for all sides
        if let padding = paddingValue {
            return EdgeInsets(
                top: component.paddingTop ?? component.topPadding ?? padding,
                leading: component.paddingLeft ?? component.leftPadding ?? padding,
                bottom: component.paddingBottom ?? component.bottomPadding ?? padding,
                trailing: component.paddingRight ?? component.rightPadding ?? padding
            )
        }
        
        // Use individual padding properties or default to 0
        return EdgeInsets(
            top: component.paddingTop ?? component.topPadding ?? 0,
            leading: component.paddingLeft ?? component.leftPadding ?? 0,
            bottom: component.paddingBottom ?? component.bottomPadding ?? 0,
            trailing: component.paddingRight ?? component.rightPadding ?? 0
        )
    }
    
    private static func getContentMode(_ component: DynamicComponent) -> NetworkImage.ContentMode {
        guard let mode = component.contentMode else { return .fit }
        
        switch mode.lowercased() {
        case "fill", "scaleaspectfill", "aspectfill":
            return .fill
        case "fit", "scaleaspectfit", "aspectfit":
            return .fit
        case "center":
            return .center
        default:
            return .fit
        }
    }
    
    private static func getRenderingMode(_ component: DynamicComponent) -> Image.TemplateRenderingMode? {
        guard let mode = component.renderingMode else { return nil }
        
        switch mode.lowercased() {
        case "template":
            return .template
        case "original":
            return .original
        default:
            return nil
        }
    }
}

// MARK: - NetworkImage Modifiers (margins only, no padding/background/cornerRadius)
struct NetworkImageModifiers: ViewModifier {
    let component: DynamicComponent
    let viewModel: DynamicViewModel
    
    func body(content: Content) -> some View {
        content
            // Apply margins only (padding/background/cornerRadius are handled by NetworkImageConverter)
            .padding(getMargins())
            .opacity(getOpacity())
            .opacity(isHidden() ? 0 : 1)
    }
    
    private func getMargins() -> EdgeInsets {
        // Use margin properties for outer spacing
        let top = component.topMargin ?? 0
        let leading = component.leftMargin ?? 0
        let bottom = component.bottomMargin ?? 0
        let trailing = component.rightMargin ?? 0
        
        return EdgeInsets(
            top: top,
            leading: leading,
            bottom: bottom,
            trailing: trailing
        )
    }
    
    private func getOpacity() -> Double {
        if let opacity = component.opacity {
            return Double(opacity)
        }
        if let alpha = component.alpha {
            return Double(alpha)
        }
        return 1.0
    }
    
    private func isHidden() -> Bool {
        return component.hidden == true || component.visibility == "gone"
    }
}