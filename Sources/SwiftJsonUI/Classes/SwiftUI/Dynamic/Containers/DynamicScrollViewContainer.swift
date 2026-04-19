//
//  DynamicScrollViewContainer.swift
//  SwiftJsonUI
//
//  Dynamic mode equivalent of scrollview_converter.rb
//  Creates AdvancedKeyboardAvoidingScrollView matching tool-generated code exactly.
//
//  Modifier order (matches scrollview_converter.rb):
//    1. AdvancedKeyboardAvoidingScrollView { VStack/HStack { children } .frame(maxWidth/maxHeight: .infinity) }
//    2. .disabled (scrollEnabled == false)
//    3. .ignoresSafeArea (contentInsetAdjustmentBehavior)
//    4. .scrollTargetBehavior(.paging) (paging == true)
//    5. .scaleEffect + .gesture(MagnificationGesture) (maxZoom)
//    6. applyStandardModifiers
//

import SwiftUI
#if DEBUG


// MARK: - ScrollView Container
public struct DynamicScrollViewContainer: View {
    let component: DynamicComponent
    let data: [String: Any]
    let viewId: String?
    @State private var zoomScale: CGFloat = 1.0

    public init(component: DynamicComponent, data: [String: Any], viewId: String? = nil) {
        self.component = component
        self.data = data
        self.viewId = viewId
    }

    /// Data with weighted child flags stripped (for building children only)
    private var childData: [String: Any] {
        var d = data
        d.removeValue(forKey: "__isWeightedChild")
        d.removeValue(forKey: "__weightedParentOrientation")
        return d
    }

    public var body: some View {
        buildBody()
    }

    private func buildBody() -> AnyView {
        let children = getChildren()
        let isHorizontal = resolveIsHorizontal(children: children)
        let axes: Axis.Set = isHorizontal ? .horizontal : .vertical
        let showsIndicators: Bool = {
            if isHorizontal {
                return component.showsHorizontalScrollIndicator ?? true
            }
            return component.showsVerticalScrollIndicator ?? true
        }()

        // --- 1. ScrollView with content ---
        var result: AnyView

        let keyboardAvoidance = component.rawData["keyboardAvoidance"] as? Bool ?? true

        if keyboardAvoidance {
            result = AnyView(
                AdvancedKeyboardAvoidingScrollView(axes, showsIndicators: showsIndicators) {
                    scrollContent(children: children, isHorizontal: isHorizontal)
                }
            )
        } else {
            result = AnyView(
                AdvancedKeyboardAvoidingScrollView(
                    axes,
                    showsIndicators: showsIndicators,
                    configuration: KeyboardAvoidanceConfiguration(isEnabled: false)
                ) {
                    scrollContent(children: children, isHorizontal: isHorizontal)
                }
            )
        }

        // --- 2. .disabled (scrollEnabled) ---
        if component.scrollEnabled == false {
            result = AnyView(result.disabled(true))
        }

        // --- 3. .ignoresSafeArea (contentInsetAdjustmentBehavior) ---
        if let behavior = component.contentInsetAdjustmentBehavior {
            switch behavior {
            case "never":
                result = AnyView(result.ignoresSafeArea())
            case "scrollableAxes":
                result = AnyView(result.ignoresSafeArea(edges: .horizontal))
            default:
                break
            }
        }

        // --- 4. .scrollTargetBehavior(.paging) ---
        if component.paging == true {
            if #available(iOS 17.0, *) {
                result = AnyView(result.scrollTargetBehavior(.paging))
            }
        }

        // --- 5. zoom gesture ---
        if component.maxZoom != nil || component.minZoom != nil {
            let minZoom = component.minZoom ?? 1.0
            let maxZoom = component.maxZoom ?? 1.0
            result = AnyView(
                result
                    .scaleEffect(zoomScale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                zoomScale = min(max(value, minZoom), maxZoom)
                            }
                    )
            )
        }

        // --- 6. applyStandardModifiers ---
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }

    // MARK: - Scroll Content

    @ViewBuilder
    private func scrollContent(children: [DynamicComponent], isHorizontal: Bool) -> some View {
        if isHorizontal {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                    DynamicComponentBuilder(
                        component: child,
                        data: childData,
                        viewId: viewId,
                        parentOrientation: "horizontal"
                    )
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                    DynamicComponentBuilder(
                        component: child,
                        data: childData,
                        viewId: viewId,
                        parentOrientation: "vertical"
                    )
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Helpers

    private func getChildren() -> [DynamicComponent] {
        guard let children = component.childComponents else { return [] }
        return children.filter { $0.isValid || $0.include != nil }
    }

    /// Resolve scroll direction from component attributes
    private func resolveIsHorizontal(children: [DynamicComponent]) -> Bool {
        if component.rawData["horizontalScroll"] as? Bool == true { return true }
        if component.orientation == "horizontal" { return true }
        if children.count == 1,
           let firstChild = children.first,
           firstChild.type?.lowercased() == "view",
           firstChild.orientation == "horizontal" {
            return true
        }
        return false
    }
}
// MARK: - Force re-evaluation when data dictionary changes
extension DynamicScrollViewContainer: Equatable {
    public static func == (lhs: DynamicScrollViewContainer, rhs: DynamicScrollViewContainer) -> Bool { false }
}
#endif // DEBUG
