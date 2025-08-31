//
//  ViewSwitcher.swift
//  SwiftJsonUI
//
//  Simple static configuration for switching between Dynamic and Generated modes
//

import SwiftUI

/// Simple configuration for Dynamic mode switching
public struct ViewSwitcher {
    /// Internal flag for dynamic mode state
    private static var _enabled: Bool = true
    
    /// Global flag to enable/disable Dynamic mode (read-only)
    public static var isDynamicMode: Bool {
        #if DEBUG
        return _enabled
        #else
        return false
        #endif
    }
    
    /// Set the dynamic mode
    public static func setDynamicMode(_ enabled: Bool) {
        _enabled = enabled
    }
    
    /// Toggle dynamic mode
    public static func toggleDynamicMode() {
        _enabled.toggle()
    }
}