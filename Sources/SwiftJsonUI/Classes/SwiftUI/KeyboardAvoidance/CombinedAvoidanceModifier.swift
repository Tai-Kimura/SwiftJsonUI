//
//  CombinedAvoidanceModifier.swift
//  SwiftJsonUI
//
//  Created by SwiftJsonUI on 2025/01/13.
//

import SwiftUI

/// ViewModifier that combines keyboard and SelectBox sheet avoidance behaviors
public struct CombinedAvoidanceModifier: ViewModifier {
    @StateObject private var keyboardResponder = KeyboardResponder.shared
    @StateObject private var sheetResponder = SelectBoxSheetResponder.shared
    @State private var additionalBottomPadding: CGFloat = 0
    
    private let keyboardConfig: KeyboardAvoidanceConfiguration
    private let selectBoxConfig: SelectBoxAvoidanceConfiguration
    
    public init(
        keyboardConfig: KeyboardAvoidanceConfiguration = .default,
        selectBoxConfig: SelectBoxAvoidanceConfiguration = .default
    ) {
        self.keyboardConfig = keyboardConfig
        self.selectBoxConfig = selectBoxConfig
    }
    
    public func body(content: Content) -> some View {
        content
            .onReceive(keyboardResponder.$currentHeight) { keyboardHeight in
                updatePadding(keyboardHeight: keyboardHeight, sheetHeight: sheetResponder.currentHeight)
            }
            .onReceive(sheetResponder.$currentHeight) { sheetHeight in
                updatePadding(keyboardHeight: keyboardResponder.currentHeight, sheetHeight: sheetHeight)
            }
            .safeAreaInset(edge: .bottom) {
                // Use a transparent spacer for keyboard/sheet
                Color.clear
                    .frame(height: additionalBottomPadding)
            }
    }
    
    private func updatePadding(keyboardHeight: CGFloat, sheetHeight: CGFloat) {
        withAnimation(.easeOut(duration: 0.25)) {
            // Use the maximum of keyboard or sheet height
            let keyboardPadding = keyboardConfig.isEnabled && keyboardHeight > 0 
                ? keyboardHeight + keyboardConfig.additionalPadding 
                : 0
            let sheetPadding = selectBoxConfig.isEnabled && sheetHeight > 0 
                ? sheetHeight + selectBoxConfig.additionalPadding 
                : 0
            
            additionalBottomPadding = max(keyboardPadding, sheetPadding)
        }
    }
}

/// View extension for easier usage
public extension View {
    /// Adds both keyboard and SelectBox sheet avoidance behavior to the view
    /// - Parameters:
    ///   - keyboardConfig: Configuration for keyboard avoidance behavior
    ///   - selectBoxConfig: Configuration for SelectBox sheet avoidance behavior
    /// - Returns: Modified view with combined avoidance
    func combinedAvoidance(
        keyboardConfig: KeyboardAvoidanceConfiguration = .default,
        selectBoxConfig: SelectBoxAvoidanceConfiguration = .default
    ) -> some View {
        modifier(CombinedAvoidanceModifier(
            keyboardConfig: keyboardConfig,
            selectBoxConfig: selectBoxConfig
        ))
    }
    
    /// Enables both keyboard and SelectBox avoidance with default configurations
    /// - Returns: Modified view with combined avoidance
    func avoidKeyboardAndSelectBox() -> some View {
        modifier(CombinedAvoidanceModifier())
    }
}