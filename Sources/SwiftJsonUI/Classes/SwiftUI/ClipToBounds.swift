//
//  ClipToBounds.swift
//  SwiftJsonUI
//
//  `clipToBounds` — a conditional clip that removes the overflow from HIT
//  TESTING as well as from drawing.
//
//  SwiftUI has no conditional modifier, and the `View.if` helper that would
//  express one is module-internal, so generated code had no way to write
//  "clip only when this is true". Codegen worked around it by deciding at
//  build time, which silently made the bound form clip unconditionally (Ruby
//  truthiness: the string "@{x}" is truthy). This is the public seam both
//  render paths call instead.
//
//  Why not `.clipped()`: SwiftUI's clip modifiers clip DRAWING only — content
//  laid out beyond the bounds stays tappable, so a clipped overflow stole
//  taps from the sibling underneath it (canonical
//  attribute_semantics.offset.overflowHitTesting: "clipping removes the
//  overflow from hit testing as well as from drawing"; measured as the
//  common/clipToBounds__hit_overflow_true interactive failure on run
//  31234163967 — android and web already honor it). UIKit's hitTest IS
//  bounds-restricted, so the clip rides a UIKit container: a
//  UIHostingConfiguration content view (no view controller required, iOS 16+)
//  inside a clipsToBounds container. Points outside the bounds never reach
//  the hosted subtree; drawing clips at the same edge.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public extension View {
    /// Clips to bounds when `enabled`, and leaves the view untouched
    /// otherwise.
    ///
    /// Taking the flag as a parameter rather than branching at the call site
    /// is what lets a *bound* `clipToBounds` work: the value is resolved at
    /// render time, so `@{shouldClip}` toggles with the data instead of
    /// freezing at whatever the generator saw.
    @ViewBuilder
    func clipToBounds(_ enabled: Bool) -> some View {
        if enabled {
            #if canImport(UIKit)
            HitTestClippingView { self }
            #else
            self.clipped()
            #endif
        } else {
            self
        }
    }
}

#if canImport(UIKit)

/// Clipping that clips hit testing too. The SwiftUI content is hosted in a
/// `UIHostingConfiguration` content view (no view controller needed) inside
/// a `clipsToBounds` UIKit container — UIKit's `hitTest` returns nil for
/// points outside the container's bounds, which is exactly the semantics
/// SwiftUI's `.clipped()` cannot express.
///
/// The container reports the hosted content's own fitting size, so the
/// wrapper is layout-transparent: whatever size the clipped node's frame
/// modifiers resolved to is the size the wrapper occupies.
public struct HitTestClippingView<Content: View>: UIViewRepresentable {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public func makeUIView(context: Context) -> HitTestClipContainer {
        let container = HitTestClipContainer()
        container.clipsToBounds = true
        container.backgroundColor = .clear
        let hosted = UIHostingConfiguration { content }
            .margins(.all, 0)
            .makeContentView()
        hosted.backgroundColor = .clear
        container.hosted = hosted
        container.addSubview(hosted)
        return container
    }

    public func updateUIView(_ container: HitTestClipContainer, context: Context) {
        if var hosted = container.hosted as? UIContentView {
            hosted.configuration = UIHostingConfiguration { content }.margins(.all, 0)
        }
    }

    public func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView container: HitTestClipContainer,
        context: Context
    ) -> CGSize? {
        guard let hosted = container.hosted else { return nil }
        let target = CGSize(
            width: proposal.width ?? UIView.layoutFittingCompressedSize.width,
            height: proposal.height ?? UIView.layoutFittingCompressedSize.height
        )
        let size = hosted.systemLayoutSizeFitting(
            target,
            withHorizontalFittingPriority: proposal.width == nil ? .fittingSizeLevel : .required,
            verticalFittingPriority: proposal.height == nil ? .fittingSizeLevel : .required
        )
        return size
    }
}

/// The clipping container: `hitTest` is bounds-restricted by UIKit itself,
/// so no override is needed — only the frame plumbing for the hosted view.
public final class HitTestClipContainer: UIView {
    var hosted: UIView?

    public override func layoutSubviews() {
        super.layoutSubviews()
        hosted?.frame = bounds
    }
}
#endif
