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
