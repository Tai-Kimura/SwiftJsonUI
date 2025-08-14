//
//  ImageViewConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Image view
//

import SwiftUI

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
                        .modifier(CommonModifiers(component: component, viewModel: viewModel))
                )
            } else {
                return AnyView(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .frame(width: component.width, height: component.height)
                        .modifier(CommonModifiers(component: component, viewModel: viewModel))
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
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
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