//
//  ImageViewConverter.swift
//  SwiftJsonUI
//
//  Dynamic mode equivalent of image_converter.rb
//  Creates Image view matching tool-generated code exactly.
//
//  Modifier order (matches image_converter.rb):
//    1. Image(...) creation
//    2. .resizable()
//    3. .aspectRatio(contentMode:)
//    4. .clipShape(Circle()) for CircleImage
//    5. .onTapGesture (canTap + onClick)
//    6. apply_frame_size
//    7. apply_padding
//    8. .background
//    9. .cornerRadius
//   10. apply_margins
//   11. .opacity / .hidden
//   12. accessibilityIdentifier
//

import SwiftUI
#if DEBUG

public struct ImageViewConverter {

    /// Convert DynamicComponent to SwiftUI Image
    /// Matches image_converter.rb convert method exactly
    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        // --- 1. Image creation ---
        // srcName takes priority (direct asset name)
        // --- 1 & 2. Image creation + .resizable() ---
        let image: Image
        if let srcName = component.typedAttributes(ImageAttributes.self)
            .srcName?.rawRepresentation as? String {
            // srcName is string|binding: the raw representation of a bound
            // spelling IS the literal "@{expr}", which matches no asset and
            // rendered nothing. Resolve it the same way `src` and
            // `highlightSrc` already do.
            image = Image(DynamicHelpers.processText(srcName, data: data))
        } else if let src = component.string(ImageAttributes.self, \.src) {
            let processedSrc = DynamicHelpers.processText(src, data: data)
            // systemIcon reinterprets `src` as an SF Symbol name rather than
            // an asset name — a different Image initializer, decided here
            // (mirrors image_converter.rb).
            if component.systemIcon == true {
                image = Image(systemName: processedSrc)
            } else {
                image = Image(processedSrc)
            }
        } else if let fallback = component.defaultImage
            ?? component.errorImage ?? component.loadingImage {
            // Fallback imagery when no src resolves. A static Image never
            // loads over the network, so errorImage/loadingImage cannot mean
            // in-flight states here — they join the chain behind defaultImage
            // (image_converter.rb:36-43 makes the same call). Better an
            // intended asset than the photo glyph.
            image = Image(fallback)
        } else {
            image = Image(systemName: "photo")
        }

        // --- 3. .renderingMode + .aspectRatio(contentMode:) ---
        // renderingMode is an Image-level modifier: template tints via
        // .foregroundColor/tint, original suppresses tinting (mirrors
        // image_converter.rb, which emits it before .resizable()).
        let renderedImage: Image
        if let renderingMode = DynamicHelpers.getRenderingMode(from: component) {
            renderedImage = image.renderingMode(renderingMode)
        } else {
            renderedImage = image
        }
        // fill/scaleToFill are the stretch (canonical image.fill = stretch,
        // shared/core/attribute_semantics.json): resizable WITHOUT an
        // aspectRatio modifier fills the frame on both axes — the same
        // branch image_converter.rb emits.
        // contentMode is string|binding. The hand-decoded slot holds the
        // layout spelling, so `@{mode}` matched no branch and fell through to
        // the `.fit` default — the bound face could not select any mode at
        // all, least of all the stretch, which is spelled as the ABSENCE of
        // `.aspectRatio` and so cannot be chosen by a ternary. That absence
        // is why this goes through Image.imageContentMode rather than
        // branching here (image_converter.rb names the same seam).
        //
        // Read through `enumString`, NOT `rawRepresentation as? String`:
        // `contentMode` is `AttrValue<AttrEnum<ContentMode>>`, so the
        // `.value` case carries an `AttrEnum`, not a String, and the cast
        // returned nil for EVERY literal spelling while a binding — whose
        // rawRepresentation IS the `"@{expr}"` string — kept working. That is
        // the inverse of the usual failure and is why the bound fixture
        // stayed active while all fifteen literal ones went inert (run 4).
        let contentModeIntent = Self.contentModeIntent(for: component, data: data)
        let declaredSize: (width: CGFloat, height: CGFloat)? = {
            guard let w = component.declaredWidth, w.isFinite,
                  let h = component.declaredHeight, h.isFinite else { return nil }
            return (w, h)
        }()
        var result = AnyView(
            renderedImage.imageContentMode(contentModeIntent, size: declaredSize)
        )

        // --- 3b. highlightSrc (pressed-state image) ---
        // `DynamicComponent` has decoded this all along and nothing read it.
        // The swap goes on before clipShape/frame so both images are cropped
        // and sized identically — image_converter.rb emits it in the same slot.
        if let highlightSrc = component.typedAttributes(ImageAttributes.self)
            .highlightSrc?.rawRepresentation as? String {
            let resolved = DynamicHelpers.processText(highlightSrc, data: data)
            let highlightImage = component.systemIcon == true
                ? Image(systemName: resolved)
                : Image(resolved)
            let base = result
            result = AnyView(
                HighlightableImage(
                    base: { base },
                    highlight: {
                        highlightImage
                            .resizable()
                            .aspectRatio(contentMode: DynamicHelpers.getContentMode(from: component))
                    }
                )
            )
        }

        // --- 4. .clipShape(Circle()) for CircleImage ---
        if component.type?.lowercased() == "circleimage" {
            result = AnyView(result.clipShape(Circle()))
        }

        // --- 5. .onTapGesture (canTap + onClick) ---
        // `canTap` is boolean|binding — the hand-decoded slot is nil for a
        // binding, so `canTap: "@{isTappable}"` made the image untappable.
        let canTap = DynamicHelpers.resolveBool(
            component.typedAttributes(CommonAttributes.self).canTap,
            legacy: nil,
            data: data
        ) ?? false
        if canTap, let onClick = component.commonAny(\.onClick) {
            let propName = DynamicEventHelper.extractPropertyName(from: onClick) ?? onClick
            if let closure = data[propName] as? () -> Void {
                result = AnyView(result.onTapGesture { closure() })
            }
        }

        // --- 6. apply_frame_size ---
        result = DynamicModifierHelper.applyFrameSize(result, component: component, data: data)

        // --- 7. apply_padding ---
        result = DynamicModifierHelper.applyPadding(result, component: component, data: data)

        // --- 8. background ---
        result = DynamicModifierHelper.applyBackground(result, component: component, data: data)

        // --- 9. cornerRadius ---
        result = DynamicModifierHelper.applyCornerRadius(result, component: component, data: data)

        // --- 10. margins ---
        result = DynamicModifierHelper.applyMargins(result, component: component, data: data)

        // --- 11. opacity / hidden ---
        result = DynamicModifierHelper.applyOpacity(result, component: component, data: data)
        result = DynamicModifierHelper.applyHidden(result, component: component, data: data)

        // --- 12. accessibilityIdentifier ---
        result = DynamicModifierHelper.applyAccessibilityId(result, component: component)

        return result
    }

    /// The resolved `contentMode`.
    ///
    /// Internal rather than inlined so the READ has a unit test: the AnyView
    /// it lands on cannot be inspected, and the defect this replaces lived in
    /// the read, not in the mapping. A test that exercises
    /// `ImageContentModeIntent.from` directly stays green while the converter
    /// feeds it nil — which is exactly what happened before run 4.
    ///
    /// `enumString`, NOT `rawRepresentation as? String`: `contentMode` is
    /// `AttrValue<AttrEnum<ContentMode>>`, so `.value` carries an `AttrEnum`
    /// and the String cast is nil for EVERY literal spelling, while a
    /// binding — whose rawRepresentation IS `"@{expr}"` — keeps working.
    /// All fifteen literal fixtures went inert on ios; the bound one did not.
    static func contentModeIntent(
        for component: DynamicComponent,
        data: [String: Any]
    ) -> ImageContentModeIntent {
        let spelling = DynamicHelpers.processText(
            component.enumString(ImageAttributes.self, \.contentMode, data: data),
            data: data
        )
        return ImageContentModeIntent.from(spelling)
    }

}
#endif // DEBUG
