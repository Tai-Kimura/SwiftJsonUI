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
        } else if let defaultImage = component.defaultImage {
            image = Image(defaultImage)
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
        var result: AnyView
        if DynamicDecodingHelper.isStretchContentMode(component.contentMode) {
            result = AnyView(renderedImage.resizable())
        } else if let alignment = DynamicDecodingHelper.positionalContentAlignment(component.contentMode) {
            // Positional: unscaled image, aligned in the declared frame,
            // cropped — mirrors image_converter.rb.
            if let w = component.width, w.isFinite,
               let h = component.height, h.isFinite {
                result = AnyView(
                    renderedImage
                        .frame(width: w, height: h, alignment: alignment)
                        .clipped()
                )
            } else {
                result = AnyView(renderedImage)
            }
        } else {
            let contentMode = DynamicHelpers.getContentMode(from: component)
            result = AnyView(renderedImage.resizable().aspectRatio(contentMode: contentMode))
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
        if component.canTap == true, let onClick = component.onClick {
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
