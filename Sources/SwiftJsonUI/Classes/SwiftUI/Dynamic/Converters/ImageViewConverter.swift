//
//  ImageViewConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Image view
//

import SwiftUI

// Dynamic mode image converter
// Generated code equivalent: sjui_tools/lib/swiftui/views/image_converter.rb
public struct ImageViewConverter {
    
    /// Convert DynamicComponent to SwiftUI Image view (for type: "Image")
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        
        guard let imageName = component.src ?? component.text else {
            // Use placeholder if available, otherwise show default
            if let placeholder = component.placeholder {
                return AnyView(
                    Image(placeholder)
                        .resizable()
                        .aspectRatio(contentMode: getContentMode(component))
                        .frame(width: component.width, height: component.height)
                        .padding(getImagePadding(component))  // Internal padding
                        .background(DynamicHelpers.colorFromHex(component.background) ?? .clear)
                        .cornerRadius(component.cornerRadius ?? 0)
                        .modifier(ImageModifiers(component: component, viewModel: viewModel))  // External margins only
                )
            } else {
                return AnyView(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .frame(width: component.width, height: component.height)
                        .padding(getImagePadding(component))  // Internal padding
                        .background(DynamicHelpers.colorFromHex(component.background) ?? .clear)
                        .cornerRadius(component.cornerRadius ?? 0)
                        .modifier(ImageModifiers(component: component, viewModel: viewModel))  // External margins only
                )
            }
        }
        
        // Local image or SF Symbol
        let image: Image
        
        // Check if it's an SF Symbol (usually doesn't contain file extensions)
        if !imageName.contains(".") && !imageName.contains("/") {
            image = Image(systemName: imageName)
        } else {
            image = Image(imageName)
        }
        
        return AnyView(
            image
                .renderingMode(getRenderingMode(component))
                .resizable()
                .aspectRatio(contentMode: getContentMode(component))
                .frame(width: component.width, height: component.height)
                .foregroundColor(getImageColor(component))
                .padding(getImagePadding(component))  // Internal padding
                .background(DynamicHelpers.colorFromHex(component.background) ?? .clear)
                .cornerRadius(component.cornerRadius ?? 0)
                .modifier(ImageModifiers(component: component, viewModel: viewModel))  // External margins only
        )
    }
    
    private static func getImagePadding(_ component: DynamicComponent) -> EdgeInsets {
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
    
    private static func getContentMode(_ component: DynamicComponent) -> ContentMode {
        guard let mode = component.contentMode else { return .fit }
        
        switch mode.lowercased() {
        case "fill", "scaleaspectfill", "aspectfill":
            return .fill
        case "fit", "scaleaspectfit", "aspectfit":
            return .fit
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
    
    private static func getImageColor(_ component: DynamicComponent) -> Color? {
        // Use iconColor or fontColor for tinting
        let colorHex = component.iconColor ?? component.fontColor
        return DynamicHelpers.colorFromHex(colorHex)
    }
}

// MARK: - Image Modifiers (margins only, no padding/background/cornerRadius)  
// Generated code equivalent: sjui_tools/lib/swiftui/views/image_converter.rb:94-95 (apply_margins)
struct ImageModifiers: ViewModifier {
    let component: DynamicComponent
    let viewModel: DynamicViewModel
    
    func body(content: Content) -> some View {
        content
            // Apply margins only (padding/background/cornerRadius are handled by ImageViewConverter)
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