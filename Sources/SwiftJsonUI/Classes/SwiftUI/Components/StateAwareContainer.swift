//
//  StateAwareContainer.swift
//  SwiftJsonUI
//
//  Container component that tracks pressed state for tapBackground support
//  Used for View, HStack, VStack, ZStack components
//

import SwiftUI

// MARK: - State-aware Container (non-Dynamic)
public struct StateAwareContainer<Content: View>: View {
    let content: Content
    let background: Color?
    let tapBackground: Color?
    
    @State private var isPressed = false
    
    // Get background color based on state
    private var backgroundColor: Color {
        if isPressed {
            // Use tapBackground if available when pressed
            if let tapBg = tapBackground {
                return tapBg
            }
        }
        
        // Normal state - use regular background
        if let bg = background {
            return bg
        }
        
        return Color.clear
    }
    
    public init(
        background: Color? = nil,
        tapBackground: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.background = background
        self.tapBackground = tapBackground
        self.content = content()
    }
    
    public var body: some View {
        content
            .background(backgroundColor)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
                pressing: { pressing in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = pressing
                    }
                },
                perform: {}
            )
    }
}

#if DEBUG
// MARK: - Extension for Dynamic mode
extension StateAwareContainer {
    public init(component: DynamicComponent, @ViewBuilder content: () -> Content) {
        self.init(
            background: DynamicHelpers.colorFromHex(component.background),
            tapBackground: DynamicHelpers.colorFromHex(component.tapBackground),
            content: content
        )
    }
}
#endif // DEBUG