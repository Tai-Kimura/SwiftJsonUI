//
//  DynamicScrollViewContainer.swift
//  SwiftJsonUI
//
//  ScrollView container for dynamic layouts
//

import SwiftUI

// MARK: - ScrollView Container
public struct DynamicScrollViewContainer: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    let viewId: String?
    @State private var zoomScale: CGFloat = 1.0
    
    public init(component: DynamicComponent, viewModel: DynamicViewModel, viewId: String? = nil) {
        self.component = component
        self.viewModel = viewModel
        self.viewId = viewId
    }
    
    private var scrollAxes: Axis.Set {
        determineScrollAxes()
    }
    
    private var showsIndicators: Bool {
        determineShowsIndicators()
    }
    
    private var baseContent: some View {
        Group {
            // ScrollView should have exactly one child
            if let children = component.child, let firstChild = children.first {
                DynamicComponentBuilder(component: firstChild, viewModel: viewModel, viewId: viewId)
            }
        }
    }
    
    private var scrollViewContent: AnyView {
        // Apply zoom if maxZoom or minZoom is specified
        if component.maxZoom != nil || component.minZoom != nil {
            let minZoom = component.minZoom ?? 1.0
            let maxZoom = component.maxZoom ?? 1.0
            return AnyView(
                baseContent
                    .scaleEffect(zoomScale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let newScale = min(max(value, minZoom), maxZoom)
                                zoomScale = newScale
                            }
                    )
            )
        } else {
            return AnyView(baseContent)
        }
    }
    
    private var scrollView: AnyView {
        let axes = scrollAxes
        let indicators = showsIndicators
        
        // Use different ScrollView implementations based on features needed
        if component.paging == true {
            // Paging requires a custom implementation
            return AnyView(
                ScrollView(axes, showsIndicators: indicators) {
                    scrollViewContent
                }
                .onAppear {
                    // Note: Paging is not directly supported in SwiftUI
                    // Would need UIViewRepresentable for true paging
                }
            )
        } else {
            // Use AdvancedKeyboardAvoidingScrollView for keyboard avoidance
            return AnyView(
                AdvancedKeyboardAvoidingScrollView(
                    axes,
                    showsIndicators: indicators
                ) {
                    scrollViewContent
                }
            )
        }
    }
    
    @ViewBuilder
    public var body: some View {
        let _ = print("📜 DynamicScrollViewContainer: id=\(component.id ?? "no-id"), childCount=\(component.child?.count ?? 0), width=\(component.width ?? -999), height=\(component.height ?? -999)")
        
        let modifiedScrollView = scrollView
            .disabled(component.scrollEnabled == false)
        
        // Apply ignoresSafeArea based on contentInsetAdjustmentBehavior
        Group {
            if let contentInsetAdjustmentBehavior = component.contentInsetAdjustmentBehavior {
                switch contentInsetAdjustmentBehavior {
                case "never":
                    modifiedScrollView
                        .ignoresSafeArea()
                        .modifier(CommonModifiers(component: component, viewModel: viewModel))
                case "scrollableAxes":
                    modifiedScrollView
                        .ignoresSafeArea(edges: .horizontal)
                        .modifier(CommonModifiers(component: component, viewModel: viewModel))
                case "always", "automatic":
                    // Default behavior - respect safe area
                    modifiedScrollView
                        .modifier(CommonModifiers(component: component, viewModel: viewModel))
                default:
                    // Default behavior for unknown values
                    modifiedScrollView
                        .modifier(CommonModifiers(component: component, viewModel: viewModel))
                }
            } else {
                // Default behavior when contentInsetAdjustmentBehavior is not specified
                // Default to "always" - respect safe area
                modifiedScrollView
                    .modifier(CommonModifiers(component: component, viewModel: viewModel))
            }
        }
    }
    
    private func determineScrollAxes() -> Axis.Set {
        // Check for explicit horizontal scroll
        if let firstChild = component.child?.first,
           firstChild.orientation == "horizontal" {
            return .horizontal
        }
        // Default to vertical
        return .vertical
    }
    
    private func determineShowsIndicators() -> Bool {
        let axes = determineScrollAxes()
        if axes == .horizontal {
            return component.showsHorizontalScrollIndicator ?? true
        } else {
            return component.showsVerticalScrollIndicator ?? true
        }
    }
}