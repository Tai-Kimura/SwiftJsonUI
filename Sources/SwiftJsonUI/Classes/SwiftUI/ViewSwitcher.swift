//
//  ViewSwitcher.swift
//  SwiftJsonUI
//
//  Simple static configuration for switching between Dynamic and Generated modes
//

import SwiftUI

/// Observable configuration for Dynamic mode switching
public class ViewSwitcher: ObservableObject {
    /// Shared instance for SwiftUI observation
    public static let shared = ViewSwitcher()

    /// Published flag for dynamic mode state - triggers view updates
    @Published public var isDynamic: Bool = true

    private init() {}

    /// Global flag to enable/disable Dynamic mode (read-only)
    public static var isDynamicMode: Bool {
        #if DEBUG
        return shared.isDynamic
        #else
        return false
        #endif
    }

    /// Set the dynamic mode
    public static func setDynamicMode(_ enabled: Bool) {
        DispatchQueue.main.async {
            shared.isDynamic = enabled
            #if DEBUG
            // Reconnect HotLoader when switching to Dynamic mode
            if enabled {
                HotLoader.instance.reconnectIfNeeded()
            }
            #endif
        }
    }

    /// Toggle dynamic mode
    public static func toggleDynamicMode() {
        DispatchQueue.main.async {
            shared.isDynamic.toggle()
            #if DEBUG
            // Reconnect HotLoader when switching to Dynamic mode
            if shared.isDynamic {
                HotLoader.instance.reconnectIfNeeded()
            }
            #endif
        }
    }
}