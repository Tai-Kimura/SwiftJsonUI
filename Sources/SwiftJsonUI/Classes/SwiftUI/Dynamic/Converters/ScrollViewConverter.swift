//
//  ScrollViewConverter.swift
//  SwiftJsonUI
//
//  Dynamic mode equivalent of scrollview_converter.rb
//  Creates AdvancedKeyboardAvoidingScrollView matching tool-generated code exactly.
//
//  Modifier order (matches scrollview_converter.rb):
//    1. AdvancedKeyboardAvoidingScrollView(axes, showsIndicators, configuration?) { VStack/HStack { children + Spacer } .frame(maxWidth: .infinity, maxHeight: .infinity) }
//    2. .scrollDisabled(_:)                   -- always emitted (true when scrollEnabled == false)
//    3. .ignoresSafeArea()                    -- when contentInsetAdjustmentBehavior == "never"
//       .ignoresSafeArea(edges: .horizontal)  -- when contentInsetAdjustmentBehavior == "scrollableAxes"
//    4. .scrollTargetBehavior(.paging)        -- when paging == true (iOS 17+)
//    5. .scaleEffect / .gesture(MagnificationGesture) -- when maxZoom is set
//    6. applyStandardModifiers()
//

import SwiftUI
#if DEBUG


public struct ScrollViewConverter {

    /// Convert DynamicComponent to SwiftUI ScrollView
    public static func convert(
        component: DynamicComponent,
        data: [String: Any],
        viewId: String? = nil
    ) -> AnyView {
        let children = component.childComponents ?? []

        // --- Determine scroll direction ---
        var orientation = component.orientation
        let horizontalScroll = component.horizontalScroll

        // If single child is a View, inherit its orientation
        if children.count == 1, children[0].type == "View" {
            let childOrientation = children[0].orientation
            if orientation == nil {
                orientation = childOrientation
            }
        }

        let isHorizontal = (horizontalScroll == true) || (orientation == "horizontal")
        let axes: Axis.Set = isHorizontal ? .horizontal : .vertical

        // --- Indicator visibility ---
        let showsIndicators: Bool
        if isHorizontal {
            showsIndicators = component.showsHorizontalScrollIndicator ?? true
        } else {
            showsIndicators = component.showsVerticalScrollIndicator ?? true
        }

        // --- Keyboard avoidance ---
        let keyboardAvoidance = (component.rawData["keyboardAvoidance"] as? Bool) ?? true

        // --- Build inner stack content ---
        let innerContent = buildInnerContent(
            children: children,
            axes: axes,
            isHorizontal: isHorizontal,
            component: component,
            data: data,
            viewId: viewId
        )

        // --- 1. AdvancedKeyboardAvoidingScrollView ---
        var result: AnyView
        if keyboardAvoidance {
            result = AnyView(
                AdvancedKeyboardAvoidingScrollView(axes, showsIndicators: showsIndicators) {
                    innerContent
                }
            )
        } else {
            result = AnyView(
                AdvancedKeyboardAvoidingScrollView(
                    axes,
                    showsIndicators: showsIndicators,
                    configuration: KeyboardAvoidanceConfiguration(isEnabled: false)
                ) {
                    innerContent
                }
            )
        }

        // --- 2. .scrollDisabled(_:) when scrollEnabled == false ---
        // Use scrollDisabled (not disabled) so an in-flight pan / deceleration
        // is not killed when the binding flips to false, and so the modifier
        // chain shape stays the same regardless of value (preserves view identity
        // across toggles).
        var scrollEnabled: Bool = component.scrollEnabled ?? true
        if let scrollEnabledBinding = component.rawData["scrollEnabled"] as? String,
           scrollEnabledBinding.hasPrefix("@{") && scrollEnabledBinding.hasSuffix("}") {
            let propName = String(scrollEnabledBinding.dropFirst(2).dropLast())
            if let value = data[propName] as? Bool {
                scrollEnabled = value
            }
        }
        result = AnyView(result.scrollDisabled(!scrollEnabled))

        // --- 3. .ignoresSafeArea() based on contentInsetAdjustmentBehavior ---
        if let behavior = component.contentInsetAdjustmentBehavior {
            switch behavior {
            case "never":
                result = AnyView(result.ignoresSafeArea())
            case "scrollableAxes":
                result = AnyView(result.ignoresSafeArea(edges: .horizontal))
            default:
                // "always", "automatic" = default behavior, no modifier needed
                break
            }
        }

        // --- 4. .scrollTargetBehavior(.paging) for iOS 17+ ---
        if component.paging == true {
            if #available(iOS 17.0, *) {
                result = AnyView(result.scrollTargetBehavior(.paging))
            }
        }

        // --- 4.5. .defaultScrollAnchor for iOS 17+ ---
        var resolvedDefaultScrollAnchor = component.defaultScrollAnchor
        if let binding = component.rawData["defaultScrollAnchor"] as? String,
           binding.hasPrefix("@{") && binding.hasSuffix("}") {
            let propName = String(binding.dropFirst(2).dropLast())
            if let value = data[propName] as? String {
                resolvedDefaultScrollAnchor = value
            }
        }
        if let anchorStr = resolvedDefaultScrollAnchor {
            if #available(iOS 17.0, *) {
                let anchor: UnitPoint
                switch anchorStr {
                case "top": anchor = .top
                case "center": anchor = .center
                case "bottom": anchor = .bottom
                default: anchor = .top
                }
                result = AnyView(result.defaultScrollAnchor(anchor))
            }
        }

        // --- 5. .scaleEffect / .gesture(MagnificationGesture) for zoom ---
        if let maxZoom = component.maxZoom {
            let minZoom = component.minZoom ?? 1.0
            result = AnyView(
                ZoomableWrapper(content: result, minZoom: minZoom, maxZoom: maxZoom)
            )
        }

        // --- 6. applyStandardModifiers() ---
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }

    // MARK: - Private Helpers

    /// Build the inner VStack/HStack content for the scroll view
    private static func buildInnerContent(
        children: [DynamicComponent],
        axes: Axis.Set,
        isHorizontal: Bool,
        component: DynamicComponent,
        data: [String: Any],
        viewId: String?
    ) -> AnyView {
        if children.count == 1 {
            return buildSingleChildContent(
                child: children[0],
                axes: axes,
                isHorizontal: isHorizontal,
                data: data,
                viewId: viewId
            )
        } else {
            return buildMultipleChildrenContent(
                children: children,
                axes: axes,
                isHorizontal: isHorizontal,
                data: data,
                viewId: viewId
            )
        }
    }

    /// Build content for a single child, wrapped in VStack/HStack with alignment-based Spacer
    private static func buildSingleChildContent(
        child: DynamicComponent,
        axes: Axis.Set,
        isHorizontal: Bool,
        data: [String: Any],
        viewId: String?
    ) -> AnyView {
        if axes == .vertical {
            // VStack - check child's gravity for horizontal alignment
            let horizontal = extractHorizontalFromGravity(child.gravity)
            let alignment: HorizontalAlignment
            switch horizontal {
            case "center": alignment = .center
            case "right":  alignment = .trailing
            default:       alignment = .leading
            }

            return AnyView(
                VStack(alignment: alignment, spacing: 0) {
                    DynamicComponentBuilder(component: child, data: data, viewId: viewId)
                    // Add Spacer for leading alignment (default) to fill remaining space
                    if horizontal != "center" && horizontal != "right" {
                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        } else {
            // HStack for horizontal scroll
            return AnyView(
                HStack(alignment: .top, spacing: 0) {
                    DynamicComponentBuilder(component: child, data: data, viewId: viewId)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        }
    }

    /// Build content for multiple children, wrapped in VStack/HStack with default alignment
    private static func buildMultipleChildrenContent(
        children: [DynamicComponent],
        axes: Axis.Set,
        isHorizontal: Bool,
        data: [String: Any],
        viewId: String?
    ) -> AnyView {
        if axes == .vertical {
            return AnyView(
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        DynamicComponentBuilder(component: child, data: data, viewId: viewId)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        } else {
            return AnyView(
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        DynamicComponentBuilder(component: child, data: data, viewId: viewId)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        }
    }

    /// Extract horizontal alignment from gravity array/string
    /// Matches Ruby: extract_horizontal_from_gravity
    private static func extractHorizontalFromGravity(_ gravity: [String]?) -> String {
        guard let gravity = gravity else { return "left" }
        let horizontalValues = ["left", "center", "right"]
        return gravity.first(where: { horizontalValues.contains($0) }) ?? "left"
    }
}

// MARK: - ZoomableWrapper (for maxZoom support)

private struct ZoomableWrapper: View {
    let content: AnyView
    let minZoom: CGFloat
    let maxZoom: CGFloat
    @State private var zoomScale: CGFloat = 1.0

    var body: some View {
        content
            .scaleEffect(zoomScale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        zoomScale = min(max(value, minZoom), maxZoom)
                    }
            )
    }
}
#endif // DEBUG
