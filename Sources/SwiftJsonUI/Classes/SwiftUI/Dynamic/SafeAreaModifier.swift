//
//  SafeAreaModifier.swift
//  SwiftJsonUI
//
//  Custom modifier to handle SafeArea based on component type
//

import SwiftUI

/// Modifier that applies ignoresSafeArea for View but not for SafeAreaView
struct SafeAreaModifier: ViewModifier {
    let component: DynamicComponent
    
    func body(content: Content) -> some View {
        if component.type == "SafeAreaView" {
            // SafeAreaView should respect safe area
            content
        } else {
            // Regular View should ignore safe area (full screen)
            content.ignoresSafeArea()
        }
    }
}