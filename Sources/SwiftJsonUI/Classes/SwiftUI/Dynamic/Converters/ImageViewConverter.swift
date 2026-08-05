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
//    5. .onAppear (onSrc callback)
//    6. .onTapGesture (canTap + onClick)
//    7. apply_frame_size
//    8. apply_padding
//    9. .background
//   10. .cornerRadius
//   11. apply_margins
//   12. .opacity / .hidden
//   13. accessibilityIdentifier
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
        if let srcName = component.srcName {
            image = Image(srcName)
        } else if let src = component.src {
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
        let contentModeSpelling = DynamicHelpers.processText(
            component.typedAttributes(ImageAttributes.self)
                .contentMode?.rawRepresentation as? String,
            data: data
        )
        let declaredSize: (width: CGFloat, height: CGFloat)? = {
            guard let w = component.width, w.isFinite,
                  let h = component.height, h.isFinite else { return nil }
            return (w, h)
        }()
        var result = AnyView(
            renderedImage.imageContentMode(
                ImageContentModeIntent.from(contentModeSpelling),
                size: declaredSize
            )
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

        // --- 5. .onAppear (onSrc callback) ---
        if let onSrc = component.rawAttribute("onSrc") as? String {
            let propName = DynamicEventHelper.extractPropertyName(from: onSrc) ?? onSrc
            if let closure = data[propName] as? () -> Void {
                result = AnyView(result.onAppear { closure() })
            }
        }

        // --- 6. .onTapGesture (canTap + onClick) ---
        // `canTap` is boolean|binding — the hand-decoded slot is nil for a
        // binding, so `canTap: "@{isTappable}"` made the image untappable.
        let canTap = DynamicHelpers.resolveBool(
            component.typedAttributes(CommonAttributes.self).canTap,
            legacy: component.canTap,
            data: data
        ) ?? false
        if canTap, let onClick = component.onClick {
            let propName = DynamicEventHelper.extractPropertyName(from: onClick) ?? onClick
            if let closure = data[propName] as? () -> Void {
                result = AnyView(result.onTapGesture { closure() })
            }
        }

        // --- 7. apply_frame_size ---
        result = DynamicModifierHelper.applyFrameSize(result, component: component, data: data)

        // --- 8. apply_padding ---
        result = DynamicModifierHelper.applyPadding(result, component: component, data: data)

        // --- 9. background ---
        result = DynamicModifierHelper.applyBackground(result, component: component, data: data)

        // --- 10. cornerRadius ---
        result = DynamicModifierHelper.applyCornerRadius(result, component: component, data: data)

        // --- 11. margins ---
        result = DynamicModifierHelper.applyMargins(result, component: component, data: data)

        // --- 12. opacity / hidden ---
        result = DynamicModifierHelper.applyOpacity(result, component: component, data: data)
        result = DynamicModifierHelper.applyHidden(result, component: component, data: data)

        // --- 13. accessibilityIdentifier ---
        result = DynamicModifierHelper.applyAccessibilityId(result, component: component)

        return result
    }
}
#endif // DEBUG
