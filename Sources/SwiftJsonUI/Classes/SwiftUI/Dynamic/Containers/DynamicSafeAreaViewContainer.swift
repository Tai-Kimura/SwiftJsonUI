//
//  DynamicSafeAreaViewContainer.swift
//  SwiftJsonUI
//
//  Dynamic mode equivalent of view_converter.rb for SafeAreaView type.
//  Same as DynamicViewContainer but applies safe area insets after modifiers.
//
//  Modifier order (matches view_converter.rb):
//    1. Container content (same as DynamicViewContainer)
//    2. applyStandardModifiers
//    3. gradient (if set)
//    4. safe area insets (safeAreaInsetPositions)
//

import SwiftUI
#if DEBUG


// MARK: - SafeAreaView Container
public struct DynamicSafeAreaViewContainer: View {
    let component: DynamicComponent
    let data: [String: Any]
    let viewId: String?

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
        let orientation = component.orientation
        let needsRelativePositioning = orientation == nil &&
            RelativePositionConverter.childrenNeedRelativePositioning(children)

        // --- 1. Build container content ---
        var result: AnyView

        if children.isEmpty {
            result = AnyView(EmptyView())
        } else if needsRelativePositioning {
            result = AnyView(RelativePositioningContainer(
                children: children,
                parentComponent: component,
                data: childData,
                viewId: viewId
            ))
        } else {
            let hasWeights = children.contains { child in
                (child.weight ?? 0) > 0 || (child.widthWeight ?? 0) > 0 || (child.heightWeight ?? 0) > 0
            }

            if hasWeights && (orientation == "horizontal" || orientation == "vertical") {
                result = AnyView(
                    WeightedStackContainer(
                        orientation: orientation!,
                        children: children,
                        component: component,
                        data: childData,
                        viewId: viewId
                    )
                )
            } else if orientation == "horizontal" {
                // Gravity-driven spacers, same as DynamicViewContainer (and
                // view_converter.rb): default gravity is left|top, so an
                // expanding stack pins content to the leading/top edge with a
                // trailing Spacer. Without them SwiftUI centered the stack —
                // measured as SafeAreaView_orientation__* parity d=50/73.
                let spacingValue = component.number(ViewAttributes.self, \.spacing, data: data) ?? 0
                let widthExpands = component.widthRaw == "matchParent" || component.widthRaw == "-1" ||
                    component.width == .infinity || component.width == -1
                let hGravity = Self.extractHorizontalFromGravity(component.gravity)
                result = AnyView(
                    HStack(alignment: getVerticalAlignment(), spacing: spacingValue) {
                        if widthExpands && hGravity == "right" {
                            Spacer(minLength: 0)
                        }
                        ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                            DynamicComponentBuilder(
                                component: child,
                                data: childData,
                                viewId: viewId,
                                parentOrientation: "horizontal"
                            )
                        }
                        if widthExpands && hGravity == "left" {
                            Spacer(minLength: 0)
                        }
                    }
                )
            } else if orientation == "vertical" {
                let spacingValue = component.number(ViewAttributes.self, \.spacing, data: data) ?? 0
                let heightExpands = component.heightRaw == "matchParent" || component.heightRaw == "-1" ||
                    component.height == .infinity || component.height == -1
                let vGravity = Self.extractVerticalFromGravity(component.gravity)
                result = AnyView(
                    VStack(alignment: getHorizontalAlignment(), spacing: spacingValue) {
                        if heightExpands && vGravity == "bottom" {
                            Spacer(minLength: 0)
                        }
                        ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                            DynamicComponentBuilder(
                                component: child,
                                data: childData,
                                viewId: viewId,
                                parentOrientation: "vertical"
                            )
                        }
                        if heightExpands && vGravity == "top" {
                            Spacer(minLength: 0)
                        }
                    }
                )
            } else {
                result = AnyView(
                    ZStack(alignment: component.alignment ?? .topLeading) {
                        ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                            DynamicComponentBuilder(component: child, data: childData, viewId: viewId)
                        }
                    }
                )
            }
        }

        // --- 2. applyStandardModifiers ---
        result = DynamicModifierHelper.applyStandardModifiers(
            result,
            component: component,
            data: data,
            skipPadding: needsRelativePositioning
        )

        // --- 3. Safe area insets ---
        // Applied by the shared chain above (DynamicModifierHelper
        // applySafeAreaInsets), because codegen applies it to every component
        // rather than only to SafeAreaView. This block used to read
        // `rawData[...]` directly AND used `.ignoresSafeArea`, which reserves
        // nothing — the opposite of what the attribute means.

        return result
    }

    private func getChildren() -> [DynamicComponent] {
        guard let children = component.childComponents else { return [] }
        return children.filter { $0.isValid || $0.include != nil }
    }

    private func getVerticalAlignment() -> VerticalAlignment {
        switch component.alignment {
        case .top, .topLeading, .topTrailing: return .top
        case .bottom, .bottomLeading, .bottomTrailing: return .bottom
        default: return .center
        }
    }

    private func getHorizontalAlignment() -> HorizontalAlignment {
        switch component.alignment {
        case .leading, .topLeading, .bottomLeading: return .leading
        case .trailing, .topTrailing, .bottomTrailing: return .trailing
        default: return .center
        }
    }

    /// Matches Ruby extract_horizontal_from_gravity (default left).
    static func extractHorizontalFromGravity(_ gravity: [String]?) -> String {
        guard let parts = gravity, !parts.isEmpty else { return "left" }
        if let h = parts.first(where: { ["left", "center", "right", "centerHorizontal"].contains($0) }) {
            return h == "centerHorizontal" ? "center" : h
        }
        return "left"
    }

    /// Matches Ruby extract_vertical_from_gravity (default top).
    static func extractVerticalFromGravity(_ gravity: [String]?) -> String {
        guard let parts = gravity, !parts.isEmpty else { return "top" }
        if let v = parts.first(where: { ["top", "center", "bottom", "centerVertical"].contains($0) }) {
            return v == "centerVertical" ? "center" : v
        }
        return "top"
    }
}
// MARK: - Force re-evaluation when data dictionary changes
extension DynamicSafeAreaViewContainer: Equatable {
    public static func == (lhs: DynamicSafeAreaViewContainer, rhs: DynamicSafeAreaViewContainer) -> Bool { false }
}
#endif // DEBUG
