//
//  NetworkImageConverter.swift
//  SwiftJsonUI
//
//  Dynamic mode equivalent of network_image_converter.rb
//  Creates NetworkImage matching tool-generated code exactly.
//
//  Modifier order (matches network_image_converter.rb):
//    1. NetworkImage(...) creation
//    2. apply_frame_size (width/height)
//    3. apply_padding (paddings/paddingTop etc.)
//    4. .background
//    5. .cornerRadius
//    6. apply_margins
//    7. .opacity / .hidden
//    8. accessibilityIdentifier
//

import SwiftUI
#if DEBUG

public struct NetworkImageConverter {

    /// Convert DynamicComponent to SwiftUI NetworkImage
    /// Matches network_image_converter.rb convert method exactly
    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        // --- 1. Build NetworkImage ---

        // URL with binding support
        let urlString: String? = {
            // `srcName` is declared on Image, not on NetworkImage, and
            // network_image_converter.rb does not read it either — this
            // fallback was reaching for an attribute the component does not
            // have.
            let src = component.string(NetworkImageAttributes.self, \.src)
            guard let src = src else { return nil }
            if let inner = DynamicBindingResolver.inner(of: src) {
                // Canonical string value context (Binding<String> unwraps
                // at the value layer; dot-path / `??` default resolve)
                return DynamicBindingResolver.resolveString(expression: inner, data: data)
            }
            return src
        }()

        // contentMode
        let contentMode = DynamicHelpers.getNetworkImageContentMode(from: component)

        // renderingMode
        let renderingMode = DynamicHelpers.getRenderingMode(from: component)

        // placeholder / defaultImage
        //
        // `hint` is the canonical spelling and `placeholder` its alias — all
        // three converters read hint first (sjui network_image_converter.rb:29,
        // rjui :157, kjui likewise). This read them the other way round, so
        // the canonical spelling was the one that got dropped.
        let placeholder = component.typedAttributes(NetworkImageAttributes.self).hint
            ?? component.placeholder
            ?? component.defaultImage

        // headers
        let headers = component.headers ?? [:]

        var result = AnyView(
            NetworkImage(
                url: urlString,
                placeholder: placeholder,
                defaultImage: component.defaultImage,
                errorImage: component.errorImage,
                loadingImage: component.loadingImage,
                contentMode: contentMode,
                renderingMode: renderingMode,
                headers: headers
            )
        )

        // --- 2. apply_frame_size (width/height) ---
        result = DynamicModifierHelper.applyFrameSize(result, component: component, data: data)

        // --- 3. apply_padding (paddings/paddingTop etc.) ---
        result = DynamicModifierHelper.applyPadding(result, component: component, data: data)

        // --- 4. .background ---
        result = DynamicModifierHelper.applyBackground(result, component: component, data: data)

        // --- 5. .cornerRadius ---
        result = DynamicModifierHelper.applyCornerRadius(result, component: component, data: data)

        // --- 6. apply_margins ---
        result = DynamicModifierHelper.applyMargins(result, component: component, data: data)

        // --- 7. .opacity / .hidden ---
        result = DynamicModifierHelper.applyOpacity(result, component: component, data: data)
        result = DynamicModifierHelper.applyHidden(result, component: component, data: data)

        // --- 8. accessibilityIdentifier ---
        result = DynamicModifierHelper.applyAccessibilityId(result, component: component)

        return result
    }
}
#endif // DEBUG
