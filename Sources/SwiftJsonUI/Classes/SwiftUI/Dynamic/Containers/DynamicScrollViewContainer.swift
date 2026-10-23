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
/// The scroll's content at its own height (before the frame stretches it to
/// the viewport), written down; nothing when the ScrollView is not wrapContent.
private struct ScrollContentHeight: ViewModifier {
    let enabled: Bool
    @SwiftUI.Binding var height: CGFloat?

    func body(content: Content) -> some View {
        if enabled {
            content
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
        } else {
            content
        }
    }
}

public struct DynamicScrollViewContainer: View {
    let component: DynamicComponent
    let data: [String: Any]
    let viewId: String?
    @State private var zoomScale: CGFloat = 1.0
    /// A horizontal ScrollView of height wrapContent: its content's own height
    /// (nil until measured). AdvancedKeyboardAvoidingScrollView is a
    /// GeometryReader framing the scroll at the reader's height, and in a
    /// vertical ScrollView the reader is offered none: it took the height the
    /// outer ScrollView had left — a 28pt row drew 386pt tall in a 420pt
    /// ScrollView (jsonui-cli ticket
    /// 2026-10-23-sjui-geometryreader-in-vertical-scroll-collapses). Measured
    /// here, the ScrollView is framed at it, as KotlinJsonUI's horizontalScroll
    /// row is its content's height. sjui codegen's scrollview_converter
    /// content_fit_height emits the same.
    @State private var contentHeight: CGFloat? = nil

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
        // `keyboardAvoidancePadding` (SSoT: number, default 20): the clearance
        // a focused field keeps from the visible bottom while the keyboard
        // is up. Absent → the configuration's own default, which is the
        // SSoT's 20 — the same emit the codegen makes (scrollview_converter).
        var configuration = KeyboardAvoidanceConfiguration()
        if let padding = scrollAttrs.keyboardAvoidancePadding {
            configuration.additionalPadding = CGFloat(padding)
        }

        if keyboardAvoidance {
            result = AnyView(
                AdvancedKeyboardAvoidingScrollView(
                    axes,
                    showsIndicators: showsIndicators,
                    configuration: configuration,
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
        if isHorizontal && component.heightRaw == "wrapContent" {
            result = AnyView(result.frame(height: contentHeight))
        }

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
            switch DeclaredSpelling.lowered(component.enumString(ScrollViewAttributes.self, \.defaultScrollAnchor), in: ScrollViewAttributes.DefaultScrollAnchor.declaredSpellings) {
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
            .modifier(ScrollContentHeight(enabled: component.heightRaw == "wrapContent", height: $contentHeight))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .environment(\.jsonuiScrollingAncestor, true)
        } else {
            // The ScrollView's own content gravity across the scroll
            // (common.gravity is "Content gravity/alignment";
            // gravityDefaults top|start), read as a View's is. It was not
            // read, so a ScrollView declaring centerHorizontal drew a narrow
            // child at the start where web centred it (2026-10-05). A child's
            // gravity is the child's content's and does not place the child.
            // sjui codegen: scrollview_converter.rb, the same alignment.
            let across = GravityAxes.horizontalAlignment(component.gravity)
            VStack(alignment: across, spacing: 0) {
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
            // At the top, across where the stack is aligned: without an
            // alignment the frame centred the stack, so a 150-wide child of a
            // 200-wide ScrollView drew at x 25 where Android and web drew 0
            // (frame-parity, 2026-10-05; gravityDefaults top|start). sjui
            // codegen: scrollview_converter.rb, the same frame.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: Alignment(horizontal: across, vertical: .top))
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

    private func resolveIsHorizontal(children: [DynamicComponent]) -> Bool {
        Self.isHorizontal(component)
    }

    /// The scroll axis: sideways when `horizontalScroll` is true or the
    /// ScrollView's own `orientation` is `horizontal`, vertical otherwise —
    /// the rule sjui / kjui codegen and rjui share
    /// (attribute_definitions.json ScrollView, user ruling 2026-10-14). The
    /// children never decide: a horizontal child is laid out inside a
    /// vertical scroll (jui-scrollview-axis-from-child-web-disagrees). Until
    /// 10.29.14 a single horizontal child View turned the scroll (and an
    /// earlier commit of the 10.29.14 train, never released on its own, read
    /// that child as written, before its `responsive`).
    /// An orientation and a horizontalScroll that disagree are refused by
    /// jui build (ERROR [scrollview]); neither outranks the other here.
    static func isHorizontal(_ component: DynamicComponent) -> Bool {
        component.typedAttributes(ScrollViewAttributes.self).horizontalScroll == true
            || component.orientation == "horizontal"
    }
}
// MARK: - Force re-evaluation when data dictionary changes
extension DynamicScrollViewContainer: Equatable {
    public static func == (lhs: DynamicScrollViewContainer, rhs: DynamicScrollViewContainer) -> Bool { false }
}
#endif // DEBUG
