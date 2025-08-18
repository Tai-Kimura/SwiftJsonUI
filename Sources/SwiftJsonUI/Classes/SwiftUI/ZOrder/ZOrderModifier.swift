//
//  ZOrderModifier.swift
//  SwiftJsonUI
//
//  Z-order management for relative view positioning
//

import SwiftUI

// MARK: - Z-Index Storage
struct ZIndexKey: PreferenceKey {
    static var defaultValue: [String: Double] = [:]
    
    static func reduce(value: inout [String: Double], nextValue: () -> [String: Double]) {
        value.merge(nextValue()) { $1 }
    }
}

// MARK: - Z-Order Modifier
struct ZOrderModifier: ViewModifier {
    let component: DynamicComponent
    @State private var zIndices: [String: Double] = [:]
    @State private var myZIndex: Double = 0
    
    func body(content: Content) -> some View {
        content
            .zIndex(myZIndex)
            .background(GeometryReader { _ in
                Color.clear
                    .preference(key: ZIndexKey.self,
                               value: component.id != nil ? [component.id!: myZIndex] : [:])
            })
            .onPreferenceChange(ZIndexKey.self) { newIndices in
                zIndices = newIndices
                calculateZIndex()
            }
    }
    
    private func calculateZIndex() {
        // Default z-index
        var newZIndex: Double = 0
        
        if let targetId = component.indexAbove {
            // Place above the specified view
            if let targetZIndex = zIndices[targetId] {
                newZIndex = targetZIndex + 1
            } else {
                // If target not found, use default higher z-index
                newZIndex = 1
            }
        } else if let targetId = component.indexBelow {
            // Place below the specified view
            if let targetZIndex = zIndices[targetId] {
                newZIndex = targetZIndex - 1
            } else {
                // If target not found, use default lower z-index
                newZIndex = -1
            }
        }
        
        // Update if changed
        if myZIndex != newZIndex {
            myZIndex = newZIndex
            
            // Update our own z-index in the preference
            if let myId = component.id {
                zIndices[myId] = newZIndex
            }
        }
    }
}

// MARK: - Extension for applying z-order
extension View {
    func zOrder(component: DynamicComponent) -> some View {
        self.modifier(ZOrderModifier(component: component))
    }
}