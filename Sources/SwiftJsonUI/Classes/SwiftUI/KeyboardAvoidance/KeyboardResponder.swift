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
                    // Dismissed means "below the WINDOW", not "below the display". A
                    // window that does not reach the bottom of the display — Split View,
                    // Stage Manager, a folded device — used to read as dismissed here.
                    // `nil` is "no window to measure against"; keep the current state
                    // rather than guessing the keyboard is gone.
                    let dismissed = SJUIKeyboardGeometry.isDismissed(
                        keyboardFrameInScreen: keyboardInfo.frame,
                        area: SJUIWindowMetrics.boundsAssumingMainActor())
                    if dismissed == true {
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
        
        // How much of OUR window the keyboard covers. The notification frame is in
        // screen coordinates, so the reference must be the window, not the display.
        // (On iPhone the keyboard frame already includes the safe area; nothing is
        // subtracted again.)
        //
        // `nil` is "no window to measure against" — different from 0, which means
        // "measured, covers nothing". Treating nil as 0 hides a visible keyboard, so
        // fall back to the frame's own height.
        let keyboardHeight = SJUIKeyboardGeometry.overlapHeight(
            keyboardFrameInScreen: keyboardFrame,
            area: SJUIWindowMetrics.boundsAssumingMainActor()) ?? keyboardFrame.height
        
        return (height: max(0, keyboardHeight), frame: keyboardFrame, duration: duration)
    }
}