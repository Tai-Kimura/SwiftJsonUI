//
//  KeyboardResponder.swift
//  SwiftJsonUI
//
//  Created by SwiftJsonUI on 2025/01/11.
//

import SwiftUI
import Combine

/// Observes keyboard notifications and provides keyboard frame information
public class KeyboardResponder: ObservableObject {
    public static let shared = KeyboardResponder()
    
    @Published public var currentHeight: CGFloat = 0
    @Published public var isKeyboardVisible: Bool = false
    @Published public var keyboardFrame: CGRect = .zero
    @Published public var animationDuration: Double = 0.25
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    private init() {
        setupKeyboardObservers()
    }
    
    private func setupKeyboardObservers() {
        // Keyboard will show
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification in
                self.extractKeyboardInfo(from: notification)
            }
            .sink { keyboardInfo in
                withAnimation(.easeOut(duration: keyboardInfo.duration)) {
                    self.currentHeight = keyboardInfo.height
                    self.keyboardFrame = keyboardInfo.frame
                    self.isKeyboardVisible = true
                    self.animationDuration = keyboardInfo.duration
                }
            }
            .store(in: &cancellableSet)
        
        // Keyboard will hide
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .compactMap { notification in
                self.extractKeyboardInfo(from: notification)
            }
            .sink { keyboardInfo in
                withAnimation(.easeOut(duration: keyboardInfo.duration)) {
                    self.currentHeight = 0
                    self.keyboardFrame = .zero
                    self.isKeyboardVisible = false
                    self.animationDuration = keyboardInfo.duration
                }
            }
            .store(in: &cancellableSet)
        
        // Keyboard will change frame
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .compactMap { notification in
                self.extractKeyboardInfo(from: notification)
            }
            .sink { keyboardInfo in
                withAnimation(.easeOut(duration: keyboardInfo.duration)) {
                    // Check if keyboard is being dismissed (frame is below screen)
                    if keyboardInfo.frame.origin.y >= UIScreen.main.bounds.height {
                        self.currentHeight = 0
                        self.keyboardFrame = .zero
                        self.isKeyboardVisible = false
                    } else {
                        self.currentHeight = keyboardInfo.height
                        self.keyboardFrame = keyboardInfo.frame
                        self.isKeyboardVisible = true
                    }
                    self.animationDuration = keyboardInfo.duration
                }
            }
            .store(in: &cancellableSet)
    }
    
    private func extractKeyboardInfo(from notification: Notification) -> (height: CGFloat, frame: CGRect, duration: Double)? {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return nil
        }
        
        // Get the actual keyboard height relative to screen bottom
        let screenHeight = UIScreen.main.bounds.height
        let keyboardTop = keyboardFrame.origin.y
        
        // Calculate keyboard height only if it's visible (not below screen)
        let keyboardHeight: CGFloat
        if keyboardTop < screenHeight {
            // For iPhone with home indicator, the keyboard frame already includes the safe area
            // We should NOT subtract it again
            keyboardHeight = screenHeight - keyboardTop
        } else {
            keyboardHeight = 0
        }
        
        return (height: max(0, keyboardHeight), frame: keyboardFrame, duration: duration)
    }
}