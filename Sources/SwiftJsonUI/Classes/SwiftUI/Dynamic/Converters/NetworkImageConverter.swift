//
//  NetworkImageConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftJsonUI NetworkImage
//

import SwiftUI

// Dynamic mode network image converter
// Generated code equivalent: sjui_tools/lib/swiftui/views/network_image_converter.rb
public struct NetworkImageConverter {
    
    /// Convert DynamicComponent to SwiftJsonUI NetworkImage (for type: "NetworkImage")
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        
        let contentMode = DynamicHelpers.getNetworkImageContentMode(from: component)
        let renderingMode = DynamicHelpers.getRenderingMode(from: component)
        
        return AnyView(
            NetworkImage(
                url: component.src,
                placeholder: component.placeholder,
                defaultImage: component.defaultImage,
                errorImage: component.errorImage,
                loadingImage: component.loadingImage,
                contentMode: contentMode,
                renderingMode: renderingMode,
                headers: component.headers ?? [:]
            )
            .frame(width: component.width, height: component.height)
            .padding(DynamicHelpers.getPadding(from: component))  // Internal padding
            .background(DynamicHelpers.colorFromHex(component.background) ?? .clear)
            .cornerRadius(component.cornerRadius ?? 0)
            .modifier(NetworkImageModifiers(component: component, viewModel: viewModel))  // External margins only
        )
    }
    
}

// MARK: - NetworkImage Modifiers (margins only, no padding/background/cornerRadius)
// Generated code equivalent: sjui_tools/lib/swiftui/views/network_image_converter.rb:72-73 (apply_margins)
struct NetworkImageModifiers: ViewModifier {
    let component: DynamicComponent
    let viewModel: DynamicViewModel
    
    func body(content: Content) -> some View {
        content
            // Apply margins only (padding/background/cornerRadius are handled by NetworkImageConverter)
            .padding(DynamicHelpers.getMargins(from: component))
            .opacity(DynamicHelpers.getOpacity(from: component))
            .opacity(DynamicHelpers.isHidden(component) ? 0 : 1)
    }
}