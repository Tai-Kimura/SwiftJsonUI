//
//  ReactiveWrappers.swift
//  SwiftJsonUI
//
//  Wrapper views that use @SwiftUI.Binding for reactive updates.
//  When data dictionary contains Binding<T> instead of plain values,
//  these wrappers enable automatic re-rendering on value changes.
//

import SwiftUI
#if DEBUG

// MARK: - Reactive Visibility Wrapper
/// Uses @Binding so SwiftUI re-renders when visibility changes
public struct ReactiveVisibilityWrapper<Content: View>: View {
    @SwiftUI.Binding var visibility: String
    let content: () -> Content

    public init(visibility: SwiftUI.Binding<String>, @ViewBuilder content: @escaping () -> Content) {
        self._visibility = visibility
        self.content = content
    }

    public var body: some View {
        switch visibility {
        case "gone":
            EmptyView()
        case "invisible":
            content().opacity(0)
        default:
            content()
        }
    }
}

// MARK: - Reactive Hidden Wrapper
public struct ReactiveHiddenWrapper: View {
    @SwiftUI.Binding var isHidden: Bool
    let content: AnyView

    public init(isHidden: SwiftUI.Binding<Bool>, content: AnyView) {
        self._isHidden = isHidden
        self.content = content
    }

    public var body: some View {
        if isHidden {
            content.hidden()
        } else {
            content
        }
    }
}

// MARK: - Reactive Opacity Wrapper
public struct ReactiveOpacityWrapper: View {
    @SwiftUI.Binding var opacity: Double
    let content: AnyView

    public init(opacity: SwiftUI.Binding<Double>, content: AnyView) {
        self._opacity = opacity
        self.content = content
    }

    public var body: some View {
        content.opacity(opacity)
    }
}

// MARK: - Reactive Disabled Wrapper
public struct ReactiveDisabledWrapper: View {
    @SwiftUI.Binding var isDisabled: Bool
    let content: AnyView

    public init(isDisabled: SwiftUI.Binding<Bool>, content: AnyView) {
        self._isDisabled = isDisabled
        self.content = content
    }

    public var body: some View {
        content.disabled(isDisabled)
    }
}

// MARK: - Reactive Text Wrapper
/// For labels/text that change dynamically
public struct ReactiveTextWrapper: View {
    @SwiftUI.Binding var text: String
    let builder: (String) -> AnyView

    public init(text: SwiftUI.Binding<String>, builder: @escaping (String) -> AnyView) {
        self._text = text
        self.builder = builder
    }

    public var body: some View {
        builder(text)
    }
}

#endif // DEBUG
