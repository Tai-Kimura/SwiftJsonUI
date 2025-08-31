//
//  KeyboardAvoidanceModifier.swift
//  SwiftJsonUI
//
//  Created by SwiftJsonUI on 2025/01/11.
//

import SwiftUI

/// Configuration for keyboard avoidance behavior
public struct KeyboardAvoidanceConfiguration {
    public var isEnabled: Bool
    public var additionalPadding: CGFloat
    public var autoScrollToFocused: Bool
    
    public init(
        isEnabled: Bool = true,
        additionalPadding: CGFloat = 20,
        autoScrollToFocused: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.additionalPadding = additionalPadding
        self.autoScrollToFocused = autoScrollToFocused
    }
    
    public static let `default` = KeyboardAvoidanceConfiguration()
}

/// ViewModifier that adds keyboard avoidance behavior to ScrollView
public struct KeyboardAvoidanceModifier: ViewModifier {
    @StateObject private var keyboardResponder = KeyboardResponder.shared
    @State private var additionalBottomPadding: CGFloat = 0
    private let configuration: KeyboardAvoidanceConfiguration
    
    public init(configuration: KeyboardAvoidanceConfiguration = .default) {
        self.configuration = configuration
    }
    
    public func body(content: Content) -> some View {
        content
            .onReceive(keyboardResponder.$currentHeight) { keyboardHeight in
                withAnimation(.easeOut(duration: keyboardResponder.animationDuration)) {
                    updatePadding(keyboardHeight: keyboardHeight)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Use a transparent spacer for the keyboard
                Color.clear
                    .frame(height: additionalBottomPadding)
            }
    }
    
    private func updatePadding(keyboardHeight: CGFloat) {
        guard configuration.isEnabled else {
            additionalBottomPadding = 0
            return
        }
        
        if keyboardHeight > 0 {
            // Add padding for keyboard plus additional padding
            additionalBottomPadding = keyboardHeight + configuration.additionalPadding
        } else {
            additionalBottomPadding = 0
        }
    }
}

/// View extension for easier usage
public extension View {
    /// Adds keyboard avoidance behavior to the view
    /// - Parameter configuration: Configuration for keyboard avoidance behavior
    /// - Returns: Modified view with keyboard avoidance
    func keyboardAvoidance(configuration: KeyboardAvoidanceConfiguration = .default) -> some View {
        modifier(KeyboardAvoidanceModifier(configuration: configuration))
    }
    
    /// Enables keyboard avoidance with default configuration
    /// - Returns: Modified view with keyboard avoidance
    func avoidKeyboard() -> some View {
        modifier(KeyboardAvoidanceModifier())
    }
}