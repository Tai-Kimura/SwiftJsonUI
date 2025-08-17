//
//  SafeAreaModifier.swift
//  SwiftJsonUI
//
//  Custom modifier to handle SafeArea based on component type
//

import SwiftUI

/// Modifier that applies ignoresSafeArea for View and ScrollView types only
struct SafeAreaModifier: ViewModifier {
    let component: DynamicComponent
    
    func body(content: Content) -> some View {
        if component.type == "SafeAreaView" {
            // SafeAreaView should respect safe area
            content
        } else if component.type == "View" {
            // View type should ignore safe area by default (full screen)
            content.ignoresSafeArea()
        } else {
            // Other types respect safe area by default
            content
        }
    }
}