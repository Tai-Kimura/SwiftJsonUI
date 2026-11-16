//
//  SafeAreaModifier.swift
//  SwiftJsonUI
//
//  Custom modifier to handle SafeArea based on component type
//

import SwiftUI
#if DEBUG


/// Modifier that applies ignoresSafeArea based on component type
/// Note: Static mode (ViewConverter) does NOT apply ignoresSafeArea to View type
struct SafeAreaModifier: ViewModifier {
    let component: DynamicComponent

    func body(content: Content) -> some View {
        // Static mode does not apply ignoresSafeArea to any component type
        // SafeAreaView and View both respect safe area by default
        content
    }
}
#endif // DEBUG
