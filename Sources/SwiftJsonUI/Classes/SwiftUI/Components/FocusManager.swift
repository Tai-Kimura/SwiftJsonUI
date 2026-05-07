//
//  FocusManager.swift
//  SwiftJsonUI
//
//  Manages focus state for TextFields (focus chain support)
//

import SwiftUI
import Combine

public class FocusManager: ObservableObject {
    public static let shared = FocusManager()

    public let focusRequestPublisher = PassthroughSubject<String, Never>()

    private init() {}

    /// Request focus on a specific field by its id
    public func requestFocus(fieldId: String) {
        DispatchQueue.main.async {
            self.focusRequestPublisher.send(fieldId)
        }
    }

    /// Clear focus from all fields
    public func clearFocus() {
        DispatchQueue.main.async {
            self.focusRequestPublisher.send("")
        }
    }
}
