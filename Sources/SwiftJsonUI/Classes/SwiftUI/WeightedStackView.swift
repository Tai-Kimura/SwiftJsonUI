//
//  WeightedStackView.swift
//  SwiftJsonUI
//
//  SwiftUI implementation for weighted layout distribution
//

import SwiftUI

// MARK: - Size Preference Key for measuring views
private struct ViewSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - View extension for measuring size
private extension View {
    func measureSize(onChange: @escaping (CGSize) -> Void) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: ViewSizeKey.self, value: geometry.size)
                    .onPreferenceChange(ViewSizeKey.self, perform: onChange)
            }
        )
    }
}

// MARK: - Weighted Container for HStack
public struct WeightedHStack: View {
    private struct ChildInfo {
        let view: AnyView
        let weight: CGFloat
        let isWeighted: Bool
    }
    
    let alignment: VerticalAlignment
    let spacing: CGFloat
    private let children: [ChildInfo]
    @State private var fixedSizes: [CGSize] = []
    @State private var childVisibilities: [Bool] = []
    @State private var availableWidth: CGFloat = 0
    
    public init(alignment: VerticalAlignment = .center, spacing: CGFloat = 0, children: [(view: AnyView, weight: CGFloat)]) {
        self.alignment = alignment
        self.spacing = spacing
        self.children = children.map { 
            ChildInfo(
                view: $0.view, 
                weight: $0.weight, 
                isWeighted: $0.weight > 0
            ) 
        }
        self._fixedSizes = State(initialValue: Array(repeating: .zero, count: children.count))
        self._childVisibilities = State(initialValue: Array(repeating: true, count: children.count))
    }
    
    public var body: some View {
        GeometryReader { geometry in
            HStack(alignment: alignment, spacing: spacing) {
                ForEach(0..<children.count, id: \.self) { index in
                    let child = children[index]
                    
                    Group {
                        if child.isWeighted {
                            // Weighted view - calculate dynamic width
                            child.view
                                .frame(width: calculateWeightedWidth(for: index, totalWidth: geometry.size.width))
                        } else {
                            // Fixed size view - measure and use natural size
                            child.view
                                .measureSize { size in
                                    if index < fixedSizes.count {
                                        fixedSizes[index] = size
                                    }
                                }
                        }
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    // Check if view is visible (size > 0)
                                    if index < childVisibilities.count {
                                        childVisibilities[index] = geo.size.width > 0 && geo.size.height > 0
                                    }
                                }
                                .onChange(of: geo.size) { newSize in
                                    if index < childVisibilities.count {
                                        childVisibilities[index] = newSize.width > 0 && newSize.height > 0
                                    }
                                }
                        }
                    )
                }
            }
            .onAppear {
                availableWidth = geometry.size.width
            }
            .onChange(of: geometry.size.width) { newWidth in
                availableWidth = newWidth
            }
        }
    }
    
    private func calculateWeightedWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        // Calculate total fixed width and weight, excluding invisible items
        var totalFixedWidth: CGFloat = 0
        var totalWeight: CGFloat = 0
        var visibleCount = 0
        
        for (idx, child) in children.enumerated() {
            // Skip if not visible (determined by actual rendering)
            if idx < childVisibilities.count && !childVisibilities[idx] {
                continue
            }
            
            visibleCount += 1
            
            if child.isWeighted {
                totalWeight += child.weight
            } else if idx < fixedSizes.count {
                totalFixedWidth += fixedSizes[idx].width
            }
        }
        
        // Add spacing (only between visible items)
        let spacingCount = CGFloat(max(0, visibleCount - 1))
        totalFixedWidth += spacing * spacingCount
        
        // Calculate remaining space
        let remainingSpace = max(0, totalWidth - totalFixedWidth)
        
        // Get this child's weight
        let childWeight = children[index].weight
        
        // Return proportional width
        if totalWeight > 0 {
            return remainingSpace * (childWeight / totalWeight)
        }
        return 0
    }
}

// MARK: - Weighted Container for VStack
public struct WeightedVStack: View {
    private struct ChildInfo {
        let view: AnyView
        let weight: CGFloat
        let isWeighted: Bool
    }
    
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    private let children: [ChildInfo]
    @State private var fixedSizes: [CGSize] = []
    @State private var childVisibilities: [Bool] = []
    @State private var availableHeight: CGFloat = 0
    
    public init(alignment: HorizontalAlignment = .leading, spacing: CGFloat = 0, children: [(view: AnyView, weight: CGFloat)]) {
        self.alignment = alignment
        self.spacing = spacing
        self.children = children.map { 
            ChildInfo(
                view: $0.view, 
                weight: $0.weight, 
                isWeighted: $0.weight > 0
            )
        }
        self._fixedSizes = State(initialValue: Array(repeating: .zero, count: children.count))
        self._childVisibilities = State(initialValue: Array(repeating: true, count: children.count))
    }
    
    public var body: some View {
        GeometryReader { geometry in
            VStack(alignment: alignment, spacing: spacing) {
                ForEach(0..<children.count, id: \.self) { index in
                    let child = children[index]
                    
                    Group {
                        if child.isWeighted {
                            // Weighted view - calculate dynamic height
                            child.view
                                .frame(height: calculateWeightedHeight(for: index, totalHeight: geometry.size.height))
                        } else {
                            // Fixed size view - measure and use natural size
                            child.view
                                .measureSize { size in
                                    if index < fixedSizes.count {
                                        fixedSizes[index] = size
                                    }
                                }
                        }
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    // Check if view is visible (size > 0)
                                    if index < childVisibilities.count {
                                        childVisibilities[index] = geo.size.width > 0 && geo.size.height > 0
                                    }
                                }
                                .onChange(of: geo.size) { newSize in
                                    if index < childVisibilities.count {
                                        childVisibilities[index] = newSize.width > 0 && newSize.height > 0
                                    }
                                }
                        }
                    )
                }
            }
            .onAppear {
                availableHeight = geometry.size.height
            }
            .onChange(of: geometry.size.height) { newHeight in
                availableHeight = newHeight
            }
        }
    }
    
    private func calculateWeightedHeight(for index: Int, totalHeight: CGFloat) -> CGFloat {
        // Calculate total fixed height and weight, excluding invisible items
        var totalFixedHeight: CGFloat = 0
        var totalWeight: CGFloat = 0
        var visibleCount = 0
        
        for (idx, child) in children.enumerated() {
            // Skip if not visible (determined by actual rendering)
            if idx < childVisibilities.count && !childVisibilities[idx] {
                continue
            }
            
            visibleCount += 1
            
            if child.isWeighted {
                totalWeight += child.weight
            } else if idx < fixedSizes.count {
                totalFixedHeight += fixedSizes[idx].height
            }
        }
        
        // Add spacing (only between visible items)
        let spacingCount = CGFloat(max(0, visibleCount - 1))
        totalFixedHeight += spacing * spacingCount
        
        // Calculate remaining space
        let remainingSpace = max(0, totalHeight - totalFixedHeight)
        
        // Get this child's weight
        let childWeight = children[index].weight
        
        // Return proportional height
        if totalWeight > 0 {
            return remainingSpace * (childWeight / totalWeight)
        }
        return 0
    }
}