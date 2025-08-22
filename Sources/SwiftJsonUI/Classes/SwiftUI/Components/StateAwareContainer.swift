//
//  StateAwareContainer.swift
//  SwiftJsonUI
//
//  Container component that tracks pressed state for tapBackground support
//  Used for View, HStack, VStack, ZStack components
//

import SwiftUI

#if DEBUG
public struct StateAwareContainer<Content: View>: View {
    let component: DynamicComponent
    let content: Content
    
    @State private var isPressed = false
    
    // Get background color based on state
    private var backgroundColor: Color {
        if isPressed {
            // Use tapBackground if available when pressed
            if let tapBg = component.tapBackground {
                return DynamicHelpers.colorFromHex(tapBg) ?? Color.clear
            }
        }
        
        // Normal state - use regular background
        if let bg = component.background {
            return DynamicHelpers.colorFromHex(bg) ?? Color.clear
        }
        
        return Color.clear
    }
    
    public init(component: DynamicComponent, @ViewBuilder content: () -> Content) {
        self.component = component
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
#endif // DEBUG