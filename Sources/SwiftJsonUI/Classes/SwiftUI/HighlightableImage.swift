//
//  HighlightableImage.swift
//  SwiftJsonUI
//
//  `highlightSrc` — the image shown while the view is pressed.
//
//  UIKit gets this for free: UIImageView has `highlightedImage` and
//  SJUIImageView sets it (SJUIImageView.swift:84). SwiftUI has no such
//  property, so the swap has to be driven by a press gesture. The pressed
//  flag is local `@State` rather than screen state — it is transient view
//  state, the same call image_converter.rb makes when it generates this.
//

import SwiftUI

/// Swaps `image` for `highlightImage` while pressed.
///
/// The highlighted image REPLACES the base one rather than layering over it,
/// which is what `highlightedImage` does in UIKit — so a highlight asset with
/// transparency does not show the base image through it.
public struct HighlightableImage<Base: View, Highlight: View>: View {
    private let base: Base
    private let highlight: Highlight

    @State private var isPressed = false

    public init(@ViewBuilder base: () -> Base, @ViewBuilder highlight: () -> Highlight) {
        self.base = base()
        self.highlight = highlight()
    }

    public var body: some View {
        base
            .opacity(isPressed ? 0 : 1)
            .overlay {
                highlight.opacity(isPressed ? 1 : 0)
            }
            // minimumDistance 0 makes this fire on touch-down rather than
            // after a drag threshold, which is what "while pressed" means.
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed { isPressed = true }
                    }
                    .onEnded { _ in isPressed = false }
            )
    }
}
