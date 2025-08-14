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
            .modifier(CommonModifiers(component: component, viewModel: viewModel))
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