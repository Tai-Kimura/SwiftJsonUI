//
//  FocusedFieldTracker.swift
//  SwiftJsonUI
//
//  Created by SwiftJsonUI on 2025/01/11.
//

import SwiftUI

/// Tracks the currently focused field and its position
public class FocusedFieldTracker: ObservableObject {
    public static let shared = FocusedFieldTracker()
    
    @Published public var focusedFieldId: String?
    @Published public var focusedFieldFrame: CGRect = .zero
    
    private init() {}
    
    public func updateFocusedField(id: String?, frame: CGRect = .zero) {
        DispatchQueue.main.async {
            self.focusedFieldId = id
            self.focusedFieldFrame = frame
        }
    }
}

/// ViewModifier to track when a field becomes focused
public struct FocusTrackingModifier: ViewModifier {
    let fieldId: String
    @FocusState private var isFocused: Bool
    @StateObject private var tracker = FocusedFieldTracker.shared
    
    public func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: isFocused) { focused in
                            if focused {
                                let frame = geometry.frame(in: .global)
                                tracker.updateFocusedField(id: fieldId, frame: frame)
                            } else if tracker.focusedFieldId == fieldId {
                                tracker.updateFocusedField(id: nil)
                            }
                        }
                }
            )
    }
}

/// View extension for tracking focus
public extension View {
    /// Tracks when this field becomes focused
    /// - Parameter id: Unique identifier for this field
    /// - Returns: Modified view that tracks focus state
    func trackFocus(id: String) -> some View {
        modifier(FocusTrackingModifier(fieldId: id))
    }
}