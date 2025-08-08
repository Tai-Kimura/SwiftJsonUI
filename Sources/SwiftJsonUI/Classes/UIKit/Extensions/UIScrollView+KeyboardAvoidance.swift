//
//  UIScrollView+KeyboardAvoidance.swift
//  SwiftJsonUI
//
//  Created by SwiftJsonUI on 2025/08/08.
//

import UIKit

public protocol KeyboardAvoidanceScrollView: UIScrollView {
    var isKeyboardAvoidanceEnabled: Bool { get set }
}

private var keyboardAvoidanceEnabledKey: UInt8 = 0
private var keyboardObserversKey: UInt8 = 0
private var originalContentInsetKey: UInt8 = 0

extension UIScrollView: KeyboardAvoidanceScrollView {
    
    @objc public var isKeyboardAvoidanceEnabled: Bool {
        get {
            return objc_getAssociatedObject(self, &keyboardAvoidanceEnabledKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &keyboardAvoidanceEnabledKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if newValue {
                setupKeyboardObservers()
            } else {
                removeKeyboardObservers()
            }
        }
    }
    
    private var keyboardObservers: [NSObjectProtocol]? {
        get {
            return objc_getAssociatedObject(self, &keyboardObserversKey) as? [NSObjectProtocol]
        }
        set {
            objc_setAssociatedObject(self, &keyboardObserversKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var originalContentInset: UIEdgeInsets? {
        get {
            return objc_getAssociatedObject(self, &originalContentInsetKey) as? UIEdgeInsets
        }
        set {
            objc_setAssociatedObject(self, &originalContentInsetKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private func setupKeyboardObservers() {
        removeKeyboardObservers() // Remove any existing observers
        
        var observers = [NSObjectProtocol]()
        
        let willChangeFrameObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboardWillChangeFrame(notification)
        }
        observers.append(willChangeFrameObserver)
        
        let willShowObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboardWillShow(notification)
        }
        observers.append(willShowObserver)
        
        let didHideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardDidHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboardDidHide(notification)
        }
        observers.append(didHideObserver)
        
        keyboardObservers = observers
    }
    
    private func removeKeyboardObservers() {
        keyboardObservers?.forEach { NotificationCenter.default.removeObserver($0) }
        keyboardObservers = nil
    }
    
    @objc private func handleKeyboardWillChangeFrame(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrameEndValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let window = self.window else { return }
        
        var keyboardFrameEnd = keyboardFrameEndValue.cgRectValue
        keyboardFrameEnd = self.convert(keyboardFrameEnd, from: window)
        
        // Store original content inset if not already stored
        if originalContentInset == nil {
            originalContentInset = self.contentInset
        }
        
        // Calculate the keyboard height relative to the scroll view
        if keyboardFrameEnd.origin.y >= self.bounds.height {
            // Keyboard is hidden
            if let original = originalContentInset {
                UIView.animate(withDuration: KeyboardAvoidanceConfig.shared.animationDuration) {
                    self.contentInset.bottom = original.bottom
                }
            }
        } else {
            // Keyboard is visible - calculate the overlap
            let scrollViewFrame = self.convert(self.bounds, to: window)
            let scrollViewBottom = scrollViewFrame.origin.y + scrollViewFrame.size.height
            let keyboardTop = keyboardFrameEnd.origin.y
            
            if keyboardTop < scrollViewBottom {
                let overlap = scrollViewBottom - keyboardTop
                UIView.animate(withDuration: KeyboardAvoidanceConfig.shared.animationDuration) {
                    self.contentInset.bottom = overlap + (self.originalContentInset?.bottom ?? 0)
                }
                
                // Scroll to make the first responder visible
                if KeyboardAvoidanceConfig.shared.autoScrollToFirstResponder {
                    scrollToFirstResponder(keyboardTop: keyboardTop)
                }
            }
        }
    }
    
    @objc private func handleKeyboardWillShow(_ notification: Notification) {
        // Store original content inset when keyboard will show
        if originalContentInset == nil {
            originalContentInset = self.contentInset
        }
    }
    
    @objc private func handleKeyboardDidHide(_ notification: Notification) {
        // Reset content offset if needed
        if contentSize.height <= frame.size.height && contentOffset.y > 0 {
            setContentOffset(.zero, animated: true)
        }
        
        // Clear the stored original inset
        originalContentInset = nil
    }
    
    private func scrollToFirstResponder(keyboardTop: CGFloat) {
        // Find the first responder in the scroll view
        guard let firstResponder = findFirstResponder(in: self) else { return }
        
        // Convert first responder frame to scroll view coordinates
        let responderFrame = firstResponder.convert(firstResponder.bounds, to: self)
        let responderBottom = responderFrame.origin.y + responderFrame.size.height + KeyboardAvoidanceConfig.shared.additionalBottomPadding
        
        // Check if the responder is hidden by keyboard
        let visibleHeight = keyboardTop - self.frame.origin.y
        if responderBottom > visibleHeight {
            let offsetY = responderBottom - visibleHeight + contentOffset.y
            if offsetY > 0 {
                setContentOffset(CGPoint(x: contentOffset.x, y: offsetY), animated: true)
            }
        }
    }
    
    private func findFirstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder {
            return view
        }
        
        for subview in view.subviews {
            if let firstResponder = findFirstResponder(in: subview) {
                return firstResponder
            }
        }
        
        return nil
    }
}

// Convenience method to enable keyboard avoidance on creation
extension UIScrollView {
    @objc public func enableKeyboardAvoidance() {
        isKeyboardAvoidanceEnabled = true
    }
    
    @objc public func disableKeyboardAvoidance() {
        isKeyboardAvoidanceEnabled = false
    }
}