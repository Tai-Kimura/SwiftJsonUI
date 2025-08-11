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
    private let configuration: KeyboardAvoidanceConfiguration
    
    public init(configuration: KeyboardAvoidanceConfiguration = .default) {
        self.configuration = configuration
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(.bottom, configuration.isEnabled ? calculateBottomPadding() : 0)
            .animation(.easeOut(duration: keyboardResponder.animationDuration), value: keyboardResponder.currentHeight)
    }
    
    private func calculateBottomPadding() -> CGFloat {
        guard keyboardResponder.isKeyboardVisible else { return 0 }
        return keyboardResponder.currentHeight + configuration.additionalPadding
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