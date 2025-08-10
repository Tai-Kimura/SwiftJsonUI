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
    public static var isDynamicMode: Bool = {
        #if DEBUG
        return true  // Default to true in debug mode
        #else
        return false // Default to false in release mode
        #endif
    }()
    
    /// Set the dynamic mode
    public static func setDynamicMode(_ enabled: Bool) {
        isDynamicMode = enabled
    }
    
    /// Toggle dynamic mode
    public static func toggleDynamicMode() {
        isDynamicMode.toggle()
    }
}