//
//  ViewSwitcher.swift
//  SwiftJsonUI
//
//  Simple static configuration for switching between Dynamic and Generated modes
//

import SwiftUI

/// Simple configuration for Dynamic mode switching
public struct ViewSwitcher {
    /// Global flag to enable/disable Dynamic mode
    #if DEBUG
    public static var isDynamicMode: Bool = true  // Default to true in debug mode, can be toggled
    #else
    public static var isDynamicMode: Bool = false  // Always false in release mode
    #endif
    
    /// Set the dynamic mode
    public static func setDynamicMode(_ enabled: Bool) {
        isDynamicMode = enabled
    }
    
    /// Toggle dynamic mode
    public static func toggleDynamicMode() {
        isDynamicMode.toggle()
    }
}