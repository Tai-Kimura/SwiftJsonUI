//
//  ScrollViewKeyboardAvoidanceModifier.swift
//  SwiftJsonUI
//
//  Created by SwiftJsonUI on 2025/01/11.
//

import SwiftUI
import Combine

/// A simpler approach for ScrollView keyboard avoidance
public struct ScrollViewKeyboardAvoidanceModifier: ViewModifier {
    @StateObject private var keyboardResponder = KeyboardResponder.shared
    @State private var bottomPadding: CGFloat = 0
    private let configuration: KeyboardAvoidanceConfiguration
    
    public init(configuration: KeyboardAvoidanceConfiguration = .default) {
        self.configuration = configuration
    }
    
    public func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear
                    .frame(height: bottomPadding)
            }
            .onReceive(keyboardResponder.$currentHeight) { keyboardHeight in
                withAnimation(.easeOut(duration: keyboardResponder.animationDuration)) {
                    if keyboardHeight > 0 {
                        // Add padding only for the keyboard height
                        // The safeAreaInset will automatically handle the safe area
                        bottomPadding = keyboardHeight + configuration.additionalPadding
                    } else {
                        bottomPadding = 0
                    }
                }
            }
    }
}

/// Alternative implementation using just padding
public struct SimplifiedKeyboardAvoidanceModifier: ViewModifier {
    @StateObject private var keyboardResponder = KeyboardResponder.shared
    private let configuration: KeyboardAvoidanceConfiguration
    
    public init(configuration: KeyboardAvoidanceConfiguration = .default) {
        self.configuration = configuration
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(.bottom, calculatePadding())
            .animation(.easeOut(duration: 0.25), value: keyboardResponder.currentHeight)
    }
    
    private func calculatePadding() -> CGFloat {
        guard configuration.isEnabled && keyboardResponder.currentHeight > 0 else { return 0 }
        // Use the keyboard height directly without safe area adjustment
        // since it's already handled in KeyboardResponder
        return keyboardResponder.currentHeight + configuration.additionalPadding
    }
}

public extension View {
    /// Adds keyboard avoidance specifically designed for ScrollView
    func scrollViewKeyboardAvoidance(configuration: KeyboardAvoidanceConfiguration = .default) -> some View {
        modifier(SimplifiedKeyboardAvoidanceModifier(configuration: configuration))
    }
}