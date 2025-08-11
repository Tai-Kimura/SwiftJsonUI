//
//  KeyboardAvoidingScrollView.swift
//  SwiftJsonUI
//
//  Created by SwiftJsonUI on 2025/01/11.
//

import SwiftUI

/// A ScrollView that automatically adjusts its content to avoid the keyboard
public struct KeyboardAvoidingScrollView<Content: View>: View {
    @StateObject private var keyboardResponder = KeyboardResponder.shared
    @State private var contentOffset: CGFloat = 0
    @Namespace private var scrollSpace
    @FocusState private var focusedField: String?
    
    private let axes: Axis.Set
    private let showsIndicators: Bool
    private let configuration: KeyboardAvoidanceConfiguration
    private let content: Content
    
    public init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        configuration: KeyboardAvoidanceConfiguration = .default,
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.configuration = configuration
        self.content = content()
    }
    
    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(axes, showsIndicators: showsIndicators) {
                VStack(spacing: 0) {
                    content
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(
                                        key: ScrollViewContentPreferenceKey.self,
                                        value: geometry.frame(in: .named(scrollSpace))
                                    )
                            }
                        )
                    
                    // Add extra space at bottom when keyboard is shown
                    if configuration.isEnabled && keyboardResponder.isKeyboardVisible {
                        Color.clear
                            .frame(height: keyboardResponder.currentHeight + configuration.additionalPadding)
                            .id("keyboard_spacer")
                    }
                }
            }
            .coordinateSpace(name: scrollSpace)
            .onPreferenceChange(ScrollViewContentPreferenceKey.self) { frame in
                // Handle content frame changes if needed
            }
            .onChange(of: keyboardResponder.isKeyboardVisible) { isVisible in
                if isVisible && configuration.autoScrollToFocused {
                    // Scroll to keyboard spacer to ensure focused field is visible
                    withAnimation(.easeOut(duration: keyboardResponder.animationDuration)) {
                        proxy.scrollTo("keyboard_spacer", anchor: .bottom)
                    }
                }
            }
        }
    }
}

/// PreferenceKey for tracking ScrollView content frame
private struct ScrollViewContentPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}