//
//  DynamicViewContainer.swift
//  SwiftJsonUI
//
//  Dynamic mode equivalent of view_converter.rb
//  Creates HStack/VStack/ZStack/WeightedStack matching tool-generated code exactly.
//
//  Modifier order (matches view_converter.rb):
//    1. Container content (HStack/VStack/ZStack/WeightedStack/EmptyView/Color.clear/Rectangle)
//    2. .coordinateSpace (if relative positioning in ZStack)
//    3. applyStandardModifiers (skip_padding if relative positioning)
//    4. gradient (if gradient set)
//    5. safe area insets (if SafeAreaView)
//

import SwiftUI
#if DEBUG


// MARK: - View Container
public struct DynamicViewContainer: View {
    let component: DynamicComponent
    let data: [String: Any]
    let viewId: String?

    public init(component: DynamicComponent, data: [String: Any], viewId: String? = nil) {
        self.component = component
        self.data = data
        self.viewId = viewId
    }

    public var body: some View {
        buildBody()
    }

    /// Data with weighted child flags stripped (for building children only)
    private var childData: [String: Any] {
        var d = data
        d.removeValue(forKey: "__isWeightedChild")
        d.removeValue(forKey: "__weightedParentOrientation")
        return d
    }

    private func buildBody() -> AnyView {
        let children = getChildren()
        let orientation = component.orientation
        let needsRelativePositioning = orientation == nil &&
            RelativePositionConverter.childrenNeedRelativePositioning(children)

        // --- 1. Build container content (use childData to avoid flag propagation) ---
        var result: AnyView

        if component.tapBackground != nil {
            result = AnyView(
                StateAwareContainer(component: component, data: data) {
                    containerContent(children: children, orientation: orientation, needsRelativePositioning: needsRelativePositioning)
                }
            )
        } else {
            result = AnyView(
                containerContent(children: children, orientation: orientation, needsRelativePositioning: needsRelativePositioning)
            )
        }

        // --- 2. applyStandardModifiers (use original data with weighted flags for self) ---
        // Empty view with background: emptyContent already painted it as
        // Rectangle().fill (the codegen leaf contract, no safe-area bleed) —
        // painting again via .background stacked a second opaque layer.
        let backgroundPaintedByContent = children.isEmpty && component.commonString(\.background) != nil
        result = DynamicModifierHelper.applyStandardModifiers(
            result,
            component: component,
            data: data,
            skipPadding: needsRelativePositioning,
            skipBackground: backgroundPaintedByContent
        )

        // --- 3. gradient ---
        if let gradientDict = component.rawData["gradient"] as? [String: Any] {
            result = applyGradient(result, gradientDict: gradientDict)
        }

        return result
    }

    @ViewBuilder
    private func containerContent(
        children: [DynamicComponent],
        orientation: String?,
        needsRelativePositioning: Bool
    ) -> some View {
        if children.isEmpty {
            emptyContent()
        } else if needsRelativePositioning {
            RelativePositioningContainer(
                children: children,
                parentComponent: component,
                data: childData,
                viewId: viewId
            )
        } else {
            let hasWeights = children.contains { child in
                (child.weight ?? 0) > 0
                    || (child.number(CommonAttributes.self, \.widthWeight, data: data) ?? 0) > 0
                    || (child.number(CommonAttributes.self, \.heightWeight, data: data) ?? 0) > 0
            }

            if hasWeights && (orientation == "horizontal" || orientation == "vertical") {
                WeightedStackContainer(
                    orientation: orientation!,
                    children: children,
                    component: component,
                    data: childData,
                    viewId: viewId
                )
            } else if orientation == "horizontal" {
                hStackContent(children: children)
            } else if orientation == "vertical" {
                vStackContent(children: children)
            } else {
                zStackContent(children: children)
            }
        }
    }

    // MARK: - Empty content (no children)

    @ViewBuilder
    private func emptyContent() -> some View {
        let hasExplicitSize = (component.width != nil && component.width != 0) ||
            (component.height != nil && component.height != 0)
        let hasWeight = (component.weight ?? 0) > 0 ||
            (component.number(CommonAttributes.self, \.widthWeight, data: data) ?? 0) > 0 ||
            (component.number(CommonAttributes.self, \.heightWeight, data: data) ?? 0) > 0

        // Rectangle().fill is the codegen leaf contract: opaque paint that
        // does NOT bleed into the safe area (unlike .background, whose
        // default extends the colour under the status bar when the view
        // touches a safe-area edge — a declared 40pt child measured 102pt
        // tall through the status bar). The standard chain's applyBackground
        // is skipped for this case (buildBody passes skipBackground) so the
        // colour is painted exactly once — the double opaque layer used to
        // cast the declared .shadow twice.
        if component.commonString(\.background) != nil {
            Rectangle()
                .fill(DynamicHelpers.getColor(component.commonString(\.background)) ?? Color.clear)
        } else if hasExplicitSize || hasWeight {
            Color.clear
        } else {
            EmptyView()
        }
    }

    // MARK: - HStack

    @ViewBuilder
    private func hStackContent(children: [DynamicComponent]) -> some View {
        let spacingValue = component.number(ViewAttributes.self, \.spacing, data: data) ?? 0
        let distribution = component.distribution?.lowercased()
        let gravity = component.gravity
        // Spacer gating follows view_converter.rb exactly, and it is NOT
        // uniform: the leading spacer (:217) and the between-children ones
        // (:367) have no size condition, while the TRAILING one (:383) keeps
        // `width_expands`. Removing all three was wrong — a trailing spacer
        // in a wrapContent container expands it and swallows the right
        // padding, which is how paddingRight/paddingEnd/rightPadding went
        // inert in the 3rd measurement round.
        //
        // The asymmetry is load-bearing because the gravity extractor
        // DEFAULTS to "left"/"top": an undeclared gravity reads as left, so
        // the trailing condition is true for every plain horizontal stack.
        // Only the size gate keeps that from firing everywhere.
        let widthExpands = component.widthRaw == "matchParent" || component.widthRaw == "-1" ||
            component.width == .infinity || component.width == -1

        HStack(alignment: getVerticalAlignmentFromGravity(), spacing: spacingValue) {
            // Leading spacer for right gravity or distribution
            if extractHorizontalFromGravity(gravity) == "right" ||
                distribution == "equalspacing" || distribution == "equalcentering" {
                Spacer(minLength: 0)
            }

            ForEach(Array(children.enumerated()), id: \.offset) { index, child in
                DynamicComponentBuilder(
                    component: child,
                    data: childData,
                    viewId: viewId,
                    parentOrientation: "horizontal"
                )

                // Distribution spacers between children
                if index < children.count - 1 {
                    if distribution == "fillequally" || distribution == "equalspacing" || distribution == "equalcentering" {
                        Spacer(minLength: 0)
                    }
                }
            }

            // Trailing spacer for left gravity or distribution
            if widthExpands && (extractHorizontalFromGravity(gravity) == "left" ||
                distribution == "equalspacing" || distribution == "equalcentering") {
                Spacer(minLength: 0)
            }
        }
        .modifier(SafeAreaModifier(component: component))
    }

    // MARK: - VStack

    @ViewBuilder
    private func vStackContent(children: [DynamicComponent]) -> some View {
        let spacingValue = component.number(ViewAttributes.self, \.spacing, data: data) ?? 0
        let distribution = component.distribution?.lowercased()
        let gravity = component.gravity
        // Same asymmetry as hStackContent: leading and between-children have
        // no size condition, the trailing one keeps it (view_converter.rb:385).
        let heightExpands = component.heightRaw == "matchParent" || component.heightRaw == "-1" ||
            component.height == .infinity || component.height == -1

        VStack(alignment: getHorizontalAlignmentFromGravity(), spacing: spacingValue) {
            // Leading spacer for bottom gravity or distribution
            if extractVerticalFromGravity(gravity) == "bottom" ||
                distribution == "equalspacing" || distribution == "equalcentering" {
                Spacer(minLength: 0)
            }

            ForEach(Array(children.enumerated()), id: \.offset) { index, child in
                DynamicComponentBuilder(
                    component: child,
                    data: childData,
                    viewId: viewId,
                    parentOrientation: "vertical"
                )

                // Distribution spacers between children
                if index < children.count - 1 {
                    if distribution == "fillequally" || distribution == "equalspacing" || distribution == "equalcentering" {
                        Spacer(minLength: 0)
                    }
                }
            }

            // Trailing spacer for top gravity or distribution
            if heightExpands && (extractVerticalFromGravity(gravity) == "top" ||
                distribution == "equalspacing" || distribution == "equalcentering") {
                Spacer(minLength: 0)
            }
        }
        .modifier(SafeAreaModifier(component: component))
    }

    // MARK: - ZStack

    @ViewBuilder
    private func zStackContent(children: [DynamicComponent]) -> some View {
        // Frame-context margins: individual left/right/top/bottomMargin on a
        // ZStack child are a full-margin OFFSET (the codegen contract —
        // apply_zstack_positioning), not padding. Padding around the child
        // half-shifts inside a center-aligned frame (measured d up to 143 on
        // the common margin fixtures); the offset moves the child by exactly
        // the declared margin in every context. The child's own padding pass
        // is suppressed via __zstackMarginChild; center* declarations reset
        // the matching axis, same as the codegen helper.
        ZStack(alignment: component.alignment ?? .topLeading) {
            ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                DynamicComponentBuilder(
                    component: child,
                    data: zstackChildData,
                    viewId: viewId
                )
                .offset(zstackMarginOffset(for: child))
            }
        }
        .modifier(SafeAreaModifier(component: component))
    }

    private var zstackChildData: [String: Any] {
        var d = childData
        d["__zstackMarginChild"] = true
        return d
    }

    private func zstackMarginOffset(for child: DynamicComponent) -> CGSize {
        guard child.margins == nil else { return .zero }
        let left = child.margin(.leftMargin, data: childData)
        let right = child.margin(.rightMargin, data: childData)
        let top = child.margin(.topMargin, data: childData)
        let bottom = child.margin(.bottomMargin, data: childData)
        var x = left - right
        var y = top - bottom
        let common = child.typedAttributes(CommonAttributes.self)
        func centres(_ attr: AttrValue<Bool>?) -> Bool {
            DynamicHelpers.resolveBool(attr, legacy: nil, data: childData) == true
        }
        if centres(common.centerInParent) {
            return .zero
        }
        if centres(common.centerHorizontal) { x = 0 }
        if centres(common.centerVertical) { y = 0 }
        return CGSize(width: x, height: y)
    }

    // MARK: - Gradient

    private func applyGradient(_ view: AnyView, gradientDict: [String: Any]) -> AnyView {
        guard let colorsRaw = gradientDict["colors"] as? [String] else { return view }
        let colors = colorsRaw.compactMap { DynamicHelpers.getColor($0) }
        guard !colors.isEmpty else { return view }

        let startPoint: UnitPoint = {
            if let sp = gradientDict["startPoint"] as? String {
                return unitPointFromString(sp)
            }
            return .top
        }()
        let endPoint: UnitPoint = {
            if let ep = gradientDict["endPoint"] as? String {
                return unitPointFromString(ep)
            }
            return .bottom
        }()

        return AnyView(view.background(
            LinearGradient(colors: colors, startPoint: startPoint, endPoint: endPoint)
        ))
    }

    private func unitPointFromString(_ str: String) -> UnitPoint {
        switch str.lowercased() {
        case "top": return .top
        case "bottom": return .bottom
        case "leading", "left": return .leading
        case "trailing", "right": return .trailing
        case "topleft", "topleading": return .topLeading
        case "topright", "toptrailing": return .topTrailing
        case "bottomleft", "bottomleading": return .bottomLeading
        case "bottomright", "bottomtrailing": return .bottomTrailing
        case "center": return .center
        default: return .top
        }
    }

    // MARK: - Helpers

    private func getChildren() -> [DynamicComponent] {
        guard let child = component.childComponents else { return [] }
        let direction = component.direction?.lowercased()
        let filtered = child.filter { $0.isValid || $0.include != nil }
        if direction == "bottomtotop" || direction == "righttoleft" {
            return filtered.reversed()
        }
        return filtered
    }

    /// Extract horizontal gravity component (matches Ruby extract_horizontal_from_gravity)
    private func extractHorizontalFromGravity(_ gravity: [String]?) -> String {
        guard let parts = gravity, !parts.isEmpty else { return "left" }
        if let h = parts.first(where: { ["left", "center", "right", "centerHorizontal"].contains($0) }) {
            return h == "centerHorizontal" ? "center" : h
        }
        return "left"
    }

    /// Extract vertical gravity component (matches Ruby extract_vertical_from_gravity)
    private func extractVerticalFromGravity(_ gravity: [String]?) -> String {
        guard let parts = gravity, !parts.isEmpty else { return "top" }
        if let v = parts.first(where: { ["top", "center", "bottom", "centerVertical"].contains($0) }) {
            return v == "centerVertical" ? "center" : v
        }
        return "top"
    }

    private func getVerticalAlignmentFromGravity() -> VerticalAlignment {
        let v = extractVerticalFromGravity(component.gravity)
        switch v {
        case "bottom": return .bottom
        case "center": return .center
        default: return .top
        }
    }

    private func getHorizontalAlignmentFromGravity() -> HorizontalAlignment {
        let h = extractHorizontalFromGravity(component.gravity)
        switch h {
        case "right": return .trailing
        case "center": return .center
        default: return .leading
        }
    }
}
// MARK: - Force re-evaluation when data dictionary changes
extension DynamicViewContainer: Equatable {
    public static func == (lhs: DynamicViewContainer, rhs: DynamicViewContainer) -> Bool { false }
}
#endif // DEBUG
