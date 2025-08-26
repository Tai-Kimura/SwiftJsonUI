//
//  CustomComponentRegistration.swift
//  Auto-generated registration file for custom component adapters
//

import SwiftUI
import SwiftJsonUI

#if DEBUG

/// Helper to register all custom component adapters
public struct CustomComponentRegistration {
    
    /// Register all custom component adapters with the registry
    public static func registerAll() {
        let adapters: [CustomComponentAdapter] = [
            BindingTestComponentAdapter()
        ]
        
        CustomComponentRegistry.shared.registerAll(adapters)
        
        print("✅ Registered \(adapters.count) custom component adapters")
    }
}

#endif
