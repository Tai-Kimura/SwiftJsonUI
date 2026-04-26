//
//  CollectionStackView.swift
//  SwiftJsonUI
//
//  Stack-based collection container with lazy / eager / none modes.
//
//  Why this exists: SwiftUI's `LazyVStack` virtualizes cell init/destroy as
//  the viewport changes. With heavy cells (rich text, images, attachments)
//  this can cause UI freezes when keyboard transitions trigger lazy
//  re-evaluations. `CollectionStackView` lets layout JSON pick between:
//
//    - lazy   : ScrollView + LazyVStack/LazyHStack (default, virtualized)
//    - eager  : ScrollView + VStack/HStack (no virtualization, smooth scrolling
//               for heavy cells)
//    - none   : VStack/HStack only (parent already provides scrolling)
//
//  The mode is selectable from JSON (`"lazy": "eager"` etc.) and binding-friendly.
//

import SwiftUI

public enum CollectionStackMode: String, Equatable {
    case lazy
    case eager
    case none

    /// Resolve mode from a raw JSON value. Accepts strings, booleans (legacy),
    /// or nil. Unknown strings fall back to `.lazy`.
    public init(json: Any?) {
        switch json {
        case let s as String:
            self = CollectionStackMode(rawValue: s) ?? .lazy
        case let b as Bool:
            self = b ? .lazy : .none
        default:
            self = .lazy
        }
    }
}

public enum CollectionStackAxis {
    case vertical
    case horizontal
}

public struct CollectionStackView<Content: View>: View {
    let mode: CollectionStackMode
    let axis: CollectionStackAxis
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat
    let showsIndicators: Bool
    let scrollDisabled: Bool
    let defaultScrollAnchor: UnitPoint?
    let insetLeading: CGFloat
    let insetTrailing: CGFloat
    let contentInsets: EdgeInsets?
    @ViewBuilder let content: () -> Content

    public init(
        mode: CollectionStackMode,
        axis: CollectionStackAxis = .vertical,
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat = 0,
        showsIndicators: Bool = true,
        scrollDisabled: Bool = false,
        defaultScrollAnchor: UnitPoint? = nil,
        insetLeading: CGFloat = 0,
        insetTrailing: CGFloat = 0,
        contentInsets: EdgeInsets? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.mode = mode
        self.axis = axis
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.showsIndicators = showsIndicators
        self.scrollDisabled = scrollDisabled
        self.defaultScrollAnchor = defaultScrollAnchor
        self.insetLeading = insetLeading
        self.insetTrailing = insetTrailing
        self.contentInsets = contentInsets
        self.content = content
    }

    public var body: some View {
        switch (mode, axis) {
        case (.lazy, .vertical):
            verticalScrollContainer {
                LazyVStack(alignment: horizontalAlignment, spacing: spacing) { content() }
                    .applyContentInsets(contentInsets)
            }
        case (.eager, .vertical):
            verticalScrollContainer {
                VStack(alignment: horizontalAlignment, spacing: spacing) { content() }
                    .applyContentInsets(contentInsets)
            }
        case (.none, .vertical):
            VStack(alignment: horizontalAlignment, spacing: spacing) { content() }
                .applyContentInsets(contentInsets)

        case (.lazy, .horizontal):
            horizontalScrollContainer {
                LazyHStack(alignment: verticalAlignment, spacing: spacing) { content() }
                    .applyContentInsets(contentInsets)
            }
        case (.eager, .horizontal):
            horizontalScrollContainer {
                HStack(alignment: verticalAlignment, spacing: spacing) { content() }
                    .applyContentInsets(contentInsets)
            }
        case (.none, .horizontal):
            HStack(alignment: verticalAlignment, spacing: spacing) { content() }
                .applyContentInsets(contentInsets)
        }
    }

    @ViewBuilder
    private func verticalScrollContainer<Inner: View>(@ViewBuilder _ inner: () -> Inner) -> some View {
        ScrollView(.vertical, showsIndicators: showsIndicators) {
            inner()
        }
        .scrollDisabled(scrollDisabled)
        .applyDefaultScrollAnchor(defaultScrollAnchor)
    }

    @ViewBuilder
    private func horizontalScrollContainer<Inner: View>(@ViewBuilder _ inner: () -> Inner) -> some View {
        ScrollView(.horizontal, showsIndicators: showsIndicators) {
            HStack(spacing: 0) {
                if insetLeading > 0 {
                    Color.clear.frame(width: insetLeading)
                }
                inner()
                if insetTrailing > 0 {
                    Color.clear.frame(width: insetTrailing)
                }
            }
        }
        .scrollDisabled(scrollDisabled)
        .applyDefaultScrollAnchor(defaultScrollAnchor)
    }
}

private extension View {
    @ViewBuilder
    func applyDefaultScrollAnchor(_ anchor: UnitPoint?) -> some View {
        if let anchor = anchor {
            self.defaultScrollAnchor(anchor)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyContentInsets(_ insets: EdgeInsets?) -> some View {
        if let insets = insets {
            self.padding(insets)
        } else {
            self
        }
    }
}
