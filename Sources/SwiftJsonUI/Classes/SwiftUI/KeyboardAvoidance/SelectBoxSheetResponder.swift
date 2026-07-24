//
//  SelectBoxSheetResponder.swift
//  SwiftJsonUI
//
//  Created by SwiftJsonUI on 2025/01/13.
//

import SwiftUI
import Combine

/// Manages SelectBox sheet presentation state and provides sheet frame information
public class SelectBoxSheetResponder: ObservableObject {
    public static let shared = SelectBoxSheetResponder()
    
    @Published public var currentHeight: CGFloat = 0
    @Published public var isSheetVisible: Bool = false
    @Published public var sheetFrame: CGRect = .zero
    @Published public var animationDuration: Double = 0.25
    @Published public var presentingSelectBoxId: String? = nil
    
    private init() {}
    
    /// Called when a SelectBox sheet will be presented
    public func sheetWillPresent(id: String, height: CGFloat, animationDuration: Double = 0.25) {
        self.presentingSelectBoxId = id
        self.animationDuration = animationDuration
        
        withAnimation(.easeOut(duration: animationDuration)) {
            self.currentHeight = height
            self.isSheetVisible = true
            
            // Calculate sheet frame based on screen size
            let screenHeight = UIScreen.main.bounds.height
            let screenWidth = UIScreen.main.bounds.width
            self.sheetFrame = CGRect(
                x: 0,
                y: screenHeight - height,
                width: screenWidth,
                height: height
            )
        }
    }
    
    /// Called when a SelectBox sheet will be dismissed
    public func sheetWillDismiss(id: String, animationDuration: Double = 0.25) {
        guard presentingSelectBoxId == id else { return }
        
        self.animationDuration = animationDuration
        
        withAnimation(.easeOut(duration: animationDuration)) {
            self.currentHeight = 0
            self.isSheetVisible = false
            self.sheetFrame = .zero
            self.presentingSelectBoxId = nil
        }
    }
    
    /// Reset all state
    public func reset() {
        currentHeight = 0
        isSheetVisible = false
        sheetFrame = .zero
        presentingSelectBoxId = nil
    }
}