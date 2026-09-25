//
//  NetworkImageConverter.swift
//  SwiftJsonUI
//
//  Dynamic mode equivalent of network_image_converter.rb
//  Creates NetworkImage matching tool-generated code exactly.
//
//  Modifier order (matches network_image_converter.rb):
//    1. NetworkImage(...) creation
//    2. what VoiceOver reads (ImageAccessibilityModifier)
//    3. the standard chain (applyStandardModifiers) — padding, frame, background,
//       …, events, accessibilityIdentifier, in the order every other Dynamic
//       component runs
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

        // --- 2. What VoiceOver reads ---
        // The alt, nothing (decorative), or — for an image that operates a
        // control with no alt — the asset name as before. Innermost, right
        // after the image itself: codegen emits it there (before `.padding`),
        // so the standard chain's traits and identifier land on top of it.
        result = AnyView(result.modifier(ImageAccessibilityModifier(component: component, data: data)))

        // --- 3. The standard chain ---
        // Every stage codegen emits for an image, through the same chain every
        // other Dynamic component runs: network_image_converter.rb reaches them through
        // apply_modifiers (modifier_bag.rb), not a list of its own. This chain
        // used to be hand-picked (frameSize, padding, background, cornerRadius,
        // border, margins, opacity, hidden), and each stage it left out was
        // simply not drawn: the border until it was restored on its own, the
        // events until the fix before this one, and shadow, offset, zIndex,
        // min / max frame, tint and safeAreaInsetPositions until now (measured
        // by `dump` against a View through this chain). Padding now sits
        // INSIDE the frame, as codegen puts it (`.padding` before `.frame`);
        // the hand-picked chain framed first and padded outside.
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }
}
#endif // DEBUG
