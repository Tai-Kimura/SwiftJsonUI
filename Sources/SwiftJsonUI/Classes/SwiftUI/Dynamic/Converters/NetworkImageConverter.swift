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

    /// The image URL, canonical spelling first. `url` is the DECLARED alias
    /// of `src` (attribute_definitions.json), and the layer contract keeps
    /// alias fallbacks in consumers for L0 (raw) layouts — L1 normalization
    /// rewrites them upstream (JsonUINormalization). Nothing here read the
    /// alias, so a raw layout that wrote `url:` handed the view NO url at
    /// all: the loader never started, and the idle branch drew `Color.clear`
    /// — 49-B measured both NetworkImage fixtures as 100% blank on the
    /// dynamic face while codegen (which reads url || source || src) drew
    /// the declared images.
    ///
    /// `srcName` stays out: it is declared on Image, not NetworkImage, and
    /// network_image_converter.rb does not read it either.
    ///
    /// Internal so the test pins the read itself.
    static func declaredURL(_ component: DynamicComponent, data: [String: Any]) -> String? {
        let src = component.string(NetworkImageAttributes.self, \.src)
            ?? component.string(NetworkImageAttributes.self, \.url)
        guard let src = src else { return nil }
        if let inner = DynamicBindingResolver.inner(of: src) {
            // Canonical string value context (Binding<String> unwraps
            // at the value layer; dot-path / `??` default resolve)
            return DynamicBindingResolver.resolveString(expression: inner, data: data)
        }
        return src
    }

    /// Convert DynamicComponent to SwiftUI NetworkImage
    /// Matches network_image_converter.rb convert method exactly
    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        // --- 1. Build NetworkImage ---

        // URL with binding support
        let urlString = declaredURL(component, data: data)

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
