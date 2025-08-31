//
//  ImageViewConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Image view
//

import SwiftUI
#if DEBUG


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
                        .aspectRatio(contentMode: DynamicHelpers.getContentMode(from: component))
                        .frame(width: component.width, height: component.height)
                        .padding(DynamicHelpers.getPadding(from: component))  // Internal padding
                        .background(DynamicHelpers.getColor(component.background) ?? .clear)
                        .cornerRadius(component.cornerRadius ?? 0)
                        .modifier(ImageModifiers(component: component, viewModel: viewModel))  // External margins only
                )
            } else {
                return AnyView(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .frame(width: component.width, height: component.height)
                        .padding(DynamicHelpers.getPadding(from: component))  // Internal padding
                        .background(DynamicHelpers.getColor(component.background) ?? .clear)
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
                .renderingMode(DynamicHelpers.getRenderingMode(from: component))
                .resizable()
                .aspectRatio(contentMode: DynamicHelpers.getContentMode(from: component))
                .foregroundColor(getImageColor(component))
                .padding(DynamicHelpers.getPadding(from: component))  // Apply padding first
                .frame(width: component.width, height: component.height)  // Then frame
                .background(DynamicHelpers.getColor(component.background) ?? .clear)
                .cornerRadius(component.cornerRadius ?? 0)
                .modifier(ImageModifiers(component: component, viewModel: viewModel))  // External margins only
        )
    }
    
    private static func getImageColor(_ component: DynamicComponent) -> Color? {
        // Use iconColor or fontColor for tinting
        let colorHex = component.iconColor ?? component.fontColor
        return DynamicHelpers.getColor(colorHex)
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
            .padding(DynamicHelpers.getMargins(from: component))
            .opacity(DynamicHelpers.getOpacity(from: component))
            .opacity(DynamicHelpers.isHidden(component) ? 0 : 1)
    }
}
#endif // DEBUG
