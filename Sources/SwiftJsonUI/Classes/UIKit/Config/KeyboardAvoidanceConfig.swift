//
//  KeyboardAvoidanceConfig.swift
//  SwiftJsonUI
//
//  Created by SwiftJsonUI on 2025/08/08.
//

import Foundation

@objc public class KeyboardAvoidanceConfig: NSObject {
    
    /// Shared instance for global configuration
    @objc public static let shared = KeyboardAvoidanceConfig()
    
    /// Whether keyboard avoidance is enabled by default for scroll views
    /// Set this to false if you want to manually control keyboard avoidance
    @objc public var isEnabledByDefault: Bool = true
    
    /// Additional bottom padding to add when keyboard is shown
    @objc public var additionalBottomPadding: CGFloat = 20.0
    
    /// Animation duration for content inset changes
    @objc public var animationDuration: TimeInterval = 0.25
    
    /// Whether to scroll to make the first responder visible automatically
    @objc public var autoScrollToFirstResponder: Bool = true
    
    private override init() {
        super.init()
    }
}