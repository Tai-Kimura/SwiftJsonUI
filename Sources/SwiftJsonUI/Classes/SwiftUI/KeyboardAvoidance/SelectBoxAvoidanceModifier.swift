//
//  SelectBoxAvoidanceModifier.swift
//  SwiftJsonUI
//
//  Created by SwiftJsonUI on 2025/01/13.
//

import SwiftUI

/// Configuration for SelectBox sheet avoidance behavior
public struct SelectBoxAvoidanceConfiguration {
    public var isEnabled: Bool
    public var additionalPadding: CGFloat
    public var autoScrollToSelectBox: Bool
    
    public init(
        isEnabled: Bool = true,
        additionalPadding: CGFloat = 20,
        autoScrollToSelectBox: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.additionalPadding = additionalPadding
        self.autoScrollToSelectBox = autoScrollToSelectBox
    }
    
    public static let `default` = SelectBoxAvoidanceConfiguration()
}

/// ViewModifier that adds SelectBox sheet avoidance behavior to ScrollView
public struct SelectBoxAvoidanceModifier: ViewModifier {
    @StateObject private var sheetResponder = SelectBoxSheetResponder.shared
    @State private var additionalBottomPadding: CGFloat = 0
    private let configuration: SelectBoxAvoidanceConfiguration
    
    public init(configuration: SelectBoxAvoidanceConfiguration = .default) {
        self.configuration = configuration
    }
    
    public func body(content: Content) -> some View {
        content
            .onReceive(sheetResponder.$currentHeight) { sheetHeight in
                withAnimation(.easeOut(duration: sheetResponder.animationDuration)) {
                    updatePadding(sheetHeight: sheetHeight)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Use a transparent spacer for the sheet
                Color.clear
                    .frame(height: additionalBottomPadding)
            }
    }
    
    private func updatePadding(sheetHeight: CGFloat) {
        guard configuration.isEnabled else {
            additionalBottomPadding = 0
            return
        }
        
        if sheetHeight > 0 {
            // Add padding for sheet plus additional padding
            additionalBottomPadding = sheetHeight + configuration.additionalPadding
        } else {
            additionalBottomPadding = 0
        }
    }
}

/// View extension for easier usage
public extension View {
    /// Adds SelectBox sheet avoidance behavior to the view
    /// - Parameter configuration: Configuration for SelectBox sheet avoidance behavior
    /// - Returns: Modified view with SelectBox sheet avoidance
    func selectBoxAvoidance(configuration: SelectBoxAvoidanceConfiguration = .default) -> some View {
        modifier(SelectBoxAvoidanceModifier(configuration: configuration))
    }
    
    /// Enables SelectBox sheet avoidance with default configuration
    /// - Returns: Modified view with SelectBox sheet avoidance
    func avoidSelectBoxSheet() -> some View {
        modifier(SelectBoxAvoidanceModifier())
    }
}