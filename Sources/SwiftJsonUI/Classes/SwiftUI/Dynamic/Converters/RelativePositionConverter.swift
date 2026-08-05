//
//  RelativePositionConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to RelativeChildConfig for RelativePositionContainer
//

import SwiftUI
#if DEBUG


public struct RelativePositionConverter {
    
    /// Convert DynamicComponent to RelativeChildConfig for use in RelativePositionContainer
    public static func convert(
        component: DynamicComponent,
        index: Int,
        viewBuilder: (DynamicComponent) -> AnyView,
        data: [String: Any] = [:]
    ) -> RelativeChildConfig {

        let id = component.id ?? "child_\(index)"
        let view = viewBuilder(component)
        let constraints = buildConstraints(from: component, data: data)
        let margins = buildMargins(from: component, data: data)
        let widthMode = buildSizeMode(from: component.widthRaw, numericValue: component.declaredWidth)
        let heightMode = buildSizeMode(from: component.heightRaw, numericValue: component.declaredHeight)

        return RelativeChildConfig(
            id: id,
            view: view,
            constraints: constraints,
            margins: margins,
            widthMode: widthMode,
            heightMode: heightMode
        )
    }

    /// The CONTAINER's own size intent, read off the parent component so a
    /// `matchParent` parent does not collapse to content size (which left
    /// every parent-relative constraint nothing to resolve against).
    static func containerSizeModes(
        for parent: DynamicComponent?
    ) -> (width: RelativeSizeMode, height: RelativeSizeMode) {
        guard let parent else { return (.wrapContent, .wrapContent) }
        return (
            buildSizeMode(from: parent.widthRaw, numericValue: parent.declaredWidth),
            buildSizeMode(from: parent.heightRaw, numericValue: parent.declaredHeight)
        )
    }

    /// Build RelativeSizeMode from raw string value and numeric value
    private static func buildSizeMode(from rawValue: String?, numericValue: CGFloat?) -> RelativeSizeMode {
        // Check raw string value first
        if let raw = rawValue {
            switch raw.lowercased() {
            case "matchparent", "match_parent", "-1":
                return .matchParent
            case "wrapcontent", "wrap_content":
                return .wrapContent
            default:
                // Try to parse as numeric
                if let value = Double(raw), value > 0 {
                    return .fixed(CGFloat(value))
                }
            }
        }

        // Check numeric value
        if let value = numericValue {
            if value == -1 || value == .infinity {
                return .matchParent
            } else if value > 0 {
                return .fixed(value)
            }
        }

        // Default to wrapContent
        return .wrapContent
    }
    
    /// Build RelativePositionConstraints from DynamicComponent properties
    /// The seven parent-alignment flags are all `boolean|binding`. They used
    /// to be read off the hand-decoded slots with `== true`, which is nil for
    /// `@{expr}` — so a bound alignment placed nothing and the child stayed
    /// at the container's default corner.
    private static func buildConstraints(
        from component: DynamicComponent,
        data: [String: Any] = [:]
    ) -> [RelativePositionConstraint] {
        var constraints: [RelativePositionConstraint] = []
        let common = component.typedAttributes(CommonAttributes.self)
        func flag(_ attr: AttrValue<Bool>?) -> Bool {
            DynamicHelpers.resolveBool(attr, legacy: nil, data: data) == true
        }

        // Parent alignment constraints (these have empty targetId)
        if flag(common.alignTop) {
            constraints.append(RelativePositionConstraint(type: .parentTop, targetId: ""))
        }
        
        if flag(common.alignBottom) {
            constraints.append(RelativePositionConstraint(type: .parentBottom, targetId: ""))
        }
        
        if flag(common.alignLeft) {
            constraints.append(RelativePositionConstraint(type: .parentLeft, targetId: ""))
        }
        
        if flag(common.alignRight) {
            constraints.append(RelativePositionConstraint(type: .parentRight, targetId: ""))
        }
        
        if flag(common.centerHorizontal) {
            constraints.append(RelativePositionConstraint(type: .parentCenterHorizontal, targetId: ""))
        }
        
        if flag(common.centerVertical) {
            constraints.append(RelativePositionConstraint(type: .parentCenterVertical, targetId: ""))
        }
        
        if flag(common.centerInParent) {
            constraints.append(RelativePositionConstraint(type: .parentCenter, targetId: ""))
        }
        
        // Relative positioning to other views
        // alignLeftOfView/alignRightOfView from JSON map to leftOf/rightOf constraint types
        if let target = component.alignLeftOfView {
            constraints.append(RelativePositionConstraint(type: .leftOf, targetId: target))
        }
        
        if let target = component.alignRightOfView {
            constraints.append(RelativePositionConstraint(type: .rightOf, targetId: target))
        }
        
        // alignTopOfView/alignBottomOfView from JSON map to above/below constraint types
        if let target = component.alignTopOfView {
            constraints.append(RelativePositionConstraint(type: .above, targetId: target))
        }
        
        if let target = component.alignBottomOfView {
            constraints.append(RelativePositionConstraint(type: .below, targetId: target))
        }
        
        // Edge alignment with other views
        if let target = component.alignTopView {
            constraints.append(RelativePositionConstraint(type: .alignTop, targetId: target))
        }
        
        if let target = component.alignBottomView {
            constraints.append(RelativePositionConstraint(type: .alignBottom, targetId: target))
        }
        
        if let target = component.alignLeftView {
            constraints.append(RelativePositionConstraint(type: .alignLeft, targetId: target))
        }
        
        if let target = component.alignRightView {
            constraints.append(RelativePositionConstraint(type: .alignRight, targetId: target))
        }
        
        // Center alignment with other views
        if let target = component.alignCenterVerticalView {
            constraints.append(RelativePositionConstraint(type: .centerVertical, targetId: target))
        }
        
        if let target = component.alignCenterHorizontalView {
            constraints.append(RelativePositionConstraint(type: .centerHorizontal, targetId: target))
        }

        // A child that declares no positioning at all still has to honour its
        // margins, and the container's default corner does not add them —
        // only an explicit parent constraint does. Without this, a sibling
        // that declares `topMargin: 60, leftMargin: 60` and nothing else sat
        // at the very corner, and every view anchored to it inherited the
        // 60pt error. relative_positioning_helper.rb:408-413 synthesises the
        // same pair for the same stated reason ("so that margins are properly
        // applied"); 49-G traced the Compose half of this to the same place.
        if constraints.isEmpty {
            constraints.append(RelativePositionConstraint(type: .parentTop, targetId: ""))
            constraints.append(RelativePositionConstraint(type: .parentLeft, targetId: ""))
        }

        return constraints
    }
    
    /// Build EdgeInsets from DynamicComponent margin properties
    /// Supports binding expressions like @{propertyName} which can be resolved via data dictionary
    private static func buildMargins(from component: DynamicComponent, data: [String: Any] = [:]) -> EdgeInsets {
        let top = component.margin(.topMargin, data: data)
        let leading = component.hasMargin(.leftMargin)
            ? component.margin(.leftMargin, data: data)
            : component.margin(.startMargin, data: data)
        let bottom = component.margin(.bottomMargin, data: data)
        let trailing = component.hasMargin(.rightMargin)
            ? component.margin(.rightMargin, data: data)
            : component.margin(.endMargin, data: data)

        return EdgeInsets(
            top: top,
            leading: leading,
            bottom: bottom,
            trailing: trailing
        )
    }
    
    /// A parent-alignment flag counts as DECLARED when the layout wrote it at
    /// all. Routing and conflict detection both run before `data` exists, so a
    /// bound flag has to count — otherwise the container never routes to
    /// relative positioning and the value resolved later in `buildConstraints`
    /// has nowhere to land. A literal `false` still does not count, which is
    /// what the `component.x == true` reads these replace did.
    private static func declaredFlag(
        _ component: DynamicComponent,
        _ keyPath: KeyPath<CommonAttributes, AttrValue<Bool>?>
    ) -> Bool {
        let attr = component.typedAttributes(CommonAttributes.self)[keyPath: keyPath]
        if case .some(.binding) = attr { return true }
        return attr?.value == true
    }

    /// Check if a component needs relative positioning
    public static func needsRelativePositioning(_ component: DynamicComponent) -> Bool {
        // Routing happens before `data` exists, so a BOUND flag counts as
        // declared regardless of its current value — otherwise the container
        // would never route here and the resolved constraint would have
        // nowhere to land. A literal `false` still does not route, which is
        // what it did before.
        let declared = { declaredFlag(component, $0) }
        return declared(\.alignTop) ||
               declared(\.alignBottom) ||
               declared(\.alignLeft) ||
               declared(\.alignRight) ||
               declared(\.centerInParent) ||
               declared(\.centerHorizontal) ||
               declared(\.centerVertical) ||
               component.alignLeftOfView != nil ||
               component.alignRightOfView != nil ||
               component.alignTopOfView != nil ||
               component.alignBottomOfView != nil ||
               component.alignTopView != nil ||
               component.alignBottomView != nil ||
               component.alignLeftView != nil ||
               component.alignRightView != nil ||
               component.alignCenterVerticalView != nil ||
               component.alignCenterHorizontalView != nil
    }
    
    /// Check if any children need relative positioning
    public static func childrenNeedRelativePositioning(_ children: [DynamicComponent]) -> Bool {
        return children.contains { needsRelativePositioning($0) }
    }
    
    /// Check if children have conflicting alignments that require relative positioning
    /// Takes into account parent orientation - alignments perpendicular to orientation are OK
    public static func childrenHaveConflictingAlignments(_ children: [DynamicComponent], parentOrientation: String? = nil) -> Bool {
        let alignedChildren = children.filter { needsRelativePositioning($0) }
        
        // If no children need alignment, no conflict
        if alignedChildren.isEmpty {
            return false
        }
        
        // Check for relative-to-view alignments (these always require relative positioning)
        let hasRelativeToView = alignedChildren.contains { 
            $0.alignLeftOfView != nil || 
            $0.alignRightOfView != nil || 
            $0.alignTopOfView != nil || 
            $0.alignBottomOfView != nil ||
            $0.alignTopView != nil ||
            $0.alignBottomView != nil ||
            $0.alignLeftView != nil ||
            $0.alignRightView != nil ||
            $0.alignCenterVerticalView != nil ||
            $0.alignCenterHorizontalView != nil
        }
        
        // If any relative-to-view alignments, need relative positioning
        if hasRelativeToView {
            return true
        }
        
        // If only one child needs alignment, no conflict
        if alignedChildren.count == 1 {
            return false
        }
        
        // Check for conflicting alignments based on parent orientation
        if parentOrientation == "horizontal" {
            // In HStack, vertical alignments (top/bottom/centerVertical) are OK - they align within the row
            // But horizontal alignments (left/right/centerHorizontal) would conflict
            let hasLeft = alignedChildren.contains { declaredFlag($0, \.alignLeft) }
            let hasRight = alignedChildren.contains { declaredFlag($0, \.alignRight) }
            let hasCenterHorizontal = alignedChildren.contains { declaredFlag($0, \.centerHorizontal) || declaredFlag($0, \.centerInParent) }
            
            // Conflict if multiple horizontal alignments in horizontal layout
            let horizontalConflicts = [hasLeft, hasRight, hasCenterHorizontal].filter { $0 }.count > 1
            return horizontalConflicts
            
        } else if parentOrientation == "vertical" {
            // In VStack, horizontal alignments (left/right/centerHorizontal) are OK - they align within the column
            // But vertical alignments (top/bottom/centerVertical) would conflict
            let hasTop = alignedChildren.contains { declaredFlag($0, \.alignTop) }
            let hasBottom = alignedChildren.contains { declaredFlag($0, \.alignBottom) }
            let hasCenterVertical = alignedChildren.contains { declaredFlag($0, \.centerVertical) || declaredFlag($0, \.centerInParent) }
            
            // Conflict if multiple vertical alignments in vertical layout
            let verticalConflicts = [hasTop, hasBottom, hasCenterVertical].filter { $0 }.count > 1
            return verticalConflicts
            
        } else {
            // No orientation specified - check for any conflicting alignments
            let hasTop = alignedChildren.contains { declaredFlag($0, \.alignTop) }
            let hasBottom = alignedChildren.contains { declaredFlag($0, \.alignBottom) }
            let hasCenterVertical = alignedChildren.contains { declaredFlag($0, \.centerVertical) || declaredFlag($0, \.centerInParent) }
            
            let hasLeft = alignedChildren.contains { declaredFlag($0, \.alignLeft) }
            let hasRight = alignedChildren.contains { declaredFlag($0, \.alignRight) }
            let hasCenterHorizontal = alignedChildren.contains { declaredFlag($0, \.centerHorizontal) || declaredFlag($0, \.centerInParent) }
            
            let verticalConflicts = [hasTop, hasBottom, hasCenterVertical].filter { $0 }.count > 1
            let horizontalConflicts = [hasLeft, hasRight, hasCenterHorizontal].filter { $0 }.count > 1
            
            return verticalConflicts || horizontalConflicts
        }
    }
}

// Extension to add marginTop, marginBottom, marginLeft, marginRight properties
extension DynamicComponent {
    var marginTop: CGFloat? { nil }  // These would need to be added to DynamicComponent if not present
    var marginBottom: CGFloat? { nil }
    var marginLeft: CGFloat? { nil }
    var marginRight: CGFloat? { nil }
}
#endif // DEBUG
