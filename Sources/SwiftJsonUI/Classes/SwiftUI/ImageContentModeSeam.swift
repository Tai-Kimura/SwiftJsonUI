//
//  ImageContentModeSeam.swift
//  SwiftJsonUI
//
//  `contentMode` — including the one spelling that is the ABSENCE of a
//  modifier.
//
//  Canonically `fill` / `scaleToFill` is the STRETCH: `.resizable()` with NO
//  `.aspectRatio` at all, so the image fills both axes independently
//  (shared/core/attribute_semantics.json → image.fill). Absence is not
//  something a ternary can express, so a BOUND contentMode could not select
//  it — image_converter.rb says as much and names the fix: "closing that
//  needs the same kind of library seam clipToBounds needed". This is it.
//
//  Same shape as `View.clipToBounds(_:)`: the choice arrives as a parameter
//  and is resolved at render time, so `@{mode}` follows the data instead of
//  freezing at whatever the generator saw.
//

import SwiftUI

/// What a resolved `contentMode` asks for. The positional cases carry their
/// alignment because they draw the image UNSCALED and crop it, which needs a
/// definite frame the caller supplies.
public enum ImageContentModeIntent: Equatable {
    /// `fill` / `scaleToFill` — resizable with no aspectRatio. Fills both axes.
    case stretch
    /// `fit` / `AspectFit` — the whole image, letterboxed.
    case fit
    /// `AspectFill` — fills the frame, cropping the overflow.
    case aspectFill
    /// `top` / `bottom` / `left` / `right` / `center` — unscaled and aligned.
    case positional(Alignment)

    /// Resolves a declared spelling. Returns `.fit` for anything unrecognised,
    /// which is what both render paths already fall back to.
    public static func from(_ spelling: String?) -> ImageContentModeIntent {
        switch (spelling ?? "").lowercased() {
        case "fill", "scaletofill": return .stretch
        case "aspectfill": return .aspectFill
        case "top": return .positional(.top)
        case "bottom": return .positional(.bottom)
        case "left": return .positional(.leading)
        case "right": return .positional(.trailing)
        case "center": return .positional(.center)
        default: return .fit
        }
    }
}

public extension NetworkImage.ContentMode {
    /// Resolves a declared spelling at run time — the seam sjui codegen
    /// emits for a BOUND `NetworkImage.contentMode`, and the single table
    /// `DynamicDecodingHelper.toNetworkImageContentMode` delegates to.
    ///
    /// Exists because the compile-time map cannot see a `@{...}` value:
    /// the converter's `map_content_mode_enum` fell through to `.fit`,
    /// freezing the binding to a constant (C1/bound-frozen,
    /// NetworkImage.contentMode [ios]). `.fit` for anything unrecognised —
    /// the same default both render paths already used.
    static func from(_ spelling: String?) -> NetworkImage.ContentMode {
        switch spelling ?? "" {
        case "AspectFill", "aspectFill": return .fill
        case "AspectFit", "aspectFit": return .fit
        case "center", "Center": return .center
        case "top", "Top": return .top
        case "bottom", "Bottom": return .bottom
        case "left", "Left": return .left
        case "right", "Right": return .right
        case "fill", "Fill", "scaleToFill", "ScaleToFill", "scaletofill":
            // fill = stretch (canonical image.fill = stretch,
            // shared/core/attribute_semantics.json).
            return .stretch
        default: return .fit
        }
    }
}

public extension Image {
    /// Applies a content mode, including the stretch that is spelled as no
    /// modifier at all.
    ///
    /// - Parameters:
    ///   - size: the declared frame. Required by the positional cases, which
    ///     crop against it; without one they fall back to drawing unscaled.
    @ViewBuilder
    func imageContentMode(
        _ intent: ImageContentModeIntent,
        size: (width: CGFloat, height: CGFloat)? = nil
    ) -> some View {
        switch intent {
        case .stretch:
            // The whole point: resizable and NOTHING else.
            self.resizable()
        case .fit:
            self.resizable().aspectRatio(contentMode: .fit)
        case .aspectFill:
            self.resizable().aspectRatio(contentMode: .fill)
        case .positional(let alignment):
            if let size {
                self.frame(width: size.width, height: size.height, alignment: alignment)
                    .clipped()
            } else {
                self
            }
        }
    }
}
