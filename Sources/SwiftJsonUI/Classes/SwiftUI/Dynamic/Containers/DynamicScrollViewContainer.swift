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
        d.removeValue(forKey: "__distributionFillOrientation")
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

        // `keyboardDismissMode` is a declared enum, so the generated parser
        // canonicalises the alias spellings — reading the raw string here
        // would keep whatever the layout wrote instead.
        let scrollAttrs = component.typedAttributes(ScrollViewAttributes.self)
        let keyboardAvoidance = scrollAttrs.keyboardAvoidance ?? true
        let keyboardDismissMode = scrollAttrs.keyboardDismissMode?.knownValue?.rawValue

        if keyboardAvoidance {
            result = AnyView(
                AdvancedKeyboardAvoidingScrollView(
                    axes,
                    showsIndicators: showsIndicators,
                    keyboardDismissMode: keyboardDismissMode
                ) {
                    scrollContent(children: children, isHorizontal: isHorizontal)
                }
            )
        } else {
            result = AnyView(
                AdvancedKeyboardAvoidingScrollView(
                    axes,
                    showsIndicators: showsIndicators,
                    configuration: KeyboardAvoidanceConfiguration(isEnabled: false),
                    keyboardDismissMode: keyboardDismissMode
                ) {
                    scrollContent(children: children, isHorizontal: isHorizontal)
                }
            )
        }

        // --- 2. .disabled (scrollEnabled) ---
        if DynamicHelpers.resolveBool(
            component.typedAttributes(ScrollViewAttributes.self).scrollEnabled,
            legacy: nil, data: data
        ) == false {
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

        // --- 4.5 defaultScrollAnchor (iOS 17+) ---
        // The codegen face emits `.defaultScrollAnchor(...)` for the same
        // declared enum; nothing here read it, so an anchored ScrollView
        // opened at the top on the dynamic path only
        // (ScrollView_defaultScrollAnchor__bottom/center parity d=82/96,
        // run 31202080745).
        if #available(iOS 17.0, *) {
            switch component.enumString(ScrollViewAttributes.self, \.defaultScrollAnchor)?.lowercased() {
            case "bottom": result = AnyView(result.defaultScrollAnchor(.bottom))
            case "center": result = AnyView(result.defaultScrollAnchor(.center))
            case "top": result = AnyView(result.defaultScrollAnchor(.top))
            default: break
            }
        }

        // --- 5. zoom gesture ---
        let declaredMinZoom = component.number(ScrollViewAttributes.self, \.minZoom, data: data)
        let declaredMaxZoom = component.number(ScrollViewAttributes.self, \.maxZoom, data: data)
        if declaredMinZoom != nil || declaredMaxZoom != nil {
            let minZoom = declaredMinZoom ?? 1.0
            let maxZoom = declaredMaxZoom ?? 1.0
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
            .environment(\.jsonuiScrollingAncestor, true)
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
            // Everything inside a ScrollView sits under a scrolling ancestor
            // — the fact a wrapping flow Collection below needs to hand its
            // scrolling up (ScrollingAncestorContext). Either axis, as the
            // static codegen marks it (sjui 912739e2). This container is what
            // the builder dispatches "ScrollView" to — a converter of the same
            // name used to exist beside the others and was reached by nothing;
            // it is gone so the next change lands here.
            .environment(\.jsonuiScrollingAncestor, true)
        }
    }

    // MARK: - Helpers

    private func getChildren() -> [DynamicComponent] {
        guard let children = component.childComponents else { return [] }
        return children.filter { $0.isValid || $0.include != nil }
    }

    /// Resolve scroll direction from component attributes
    private func resolveIsHorizontal(children: [DynamicComponent]) -> Bool {
        if component.typedAttributes(ScrollViewAttributes.self).horizontalScroll == true {
            return true
        }
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
