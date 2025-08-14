//
//  RelativePositionConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to RelativeChildConfig for RelativePositionContainer
//

import SwiftUI

public struct RelativePositionConverter {
    
    /// Convert DynamicComponent to RelativeChildConfig for use in RelativePositionContainer
    public static func convert(
        component: DynamicComponent,
        index: Int,
        viewBuilder: (DynamicComponent) -> AnyView
    ) -> RelativeChildConfig {
        
        let id = component.id ?? "child_\(index)"
        let view = viewBuilder(component)
        let constraints = buildConstraints(from: component)
        let margins = buildMargins(from: component)
        
        return RelativeChildConfig(
            id: id,
            view: view,
            constraints: constraints,
            margins: margins
        )
    }
    
    /// Build RelativePositionConstraints from DynamicComponent properties
    private static func buildConstraints(from component: DynamicComponent) -> [RelativePositionConstraint] {
        var constraints: [RelativePositionConstraint] = []
        
        // Parent alignment constraints (these have empty targetId)
        if component.alignTop == true {
            constraints.append(RelativePositionConstraint(type: .parentTop, targetId: ""))
        }
        
        if component.alignBottom == true {
            constraints.append(RelativePositionConstraint(type: .parentBottom, targetId: ""))
        }
        
        if component.alignLeft == true {
            constraints.append(RelativePositionConstraint(type: .parentLeft, targetId: ""))
        }
        
        if component.alignRight == true {
            constraints.append(RelativePositionConstraint(type: .parentRight, targetId: ""))
        }
        
        if component.centerHorizontal == true {
            constraints.append(RelativePositionConstraint(type: .parentCenterHorizontal, targetId: ""))
        }
        
        if component.centerVertical == true {
            constraints.append(RelativePositionConstraint(type: .parentCenterVertical, targetId: ""))
        }
        
        if component.centerInParent == true {
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
        
        return constraints
    }
    
    /// Build EdgeInsets from DynamicComponent margin properties
    private static func buildMargins(from component: DynamicComponent) -> EdgeInsets {
        let top = component.topMargin ?? component.marginTop ?? 0
        let leading = component.leftMargin ?? component.marginLeft ?? 0
        let bottom = component.bottomMargin ?? component.marginBottom ?? 0
        let trailing = component.rightMargin ?? component.marginRight ?? 0
        
        return EdgeInsets(
            top: top,
            leading: leading,
            bottom: bottom,
            trailing: trailing
        )
    }
    
    /// Check if a component needs relative positioning
    public static func needsRelativePositioning(_ component: DynamicComponent) -> Bool {
        return component.alignTop == true ||
               component.alignBottom == true ||
               component.alignLeft == true ||
               component.alignRight == true ||
               component.centerInParent == true ||
               component.centerHorizontal == true ||
               component.centerVertical == true ||
               component.alignLeftOfView != nil ||
               component.alignRightOfView != nil ||
               component.alignTopOfView != nil ||
               component.alignBottomOfView != nil
    }
    
    /// Check if any children need relative positioning
    public static func childrenNeedRelativePositioning(_ children: [DynamicComponent]) -> Bool {
        return children.contains { needsRelativePositioning($0) }
    }
    
    /// Check if children have conflicting alignments that require relative positioning
    /// Even if parent has orientation, conflicting alignments require relative positioning
    public static func childrenHaveConflictingAlignments(_ children: [DynamicComponent]) -> Bool {
        let alignedChildren = children.filter { needsRelativePositioning($0) }
        
        // If no children need alignment, no conflict
        if alignedChildren.isEmpty {
            return false
        }
        
        // If only one child needs alignment, no conflict
        if alignedChildren.count == 1 {
            return false
        }
        
        // Check for conflicting vertical alignments (top vs bottom vs center)
        let hasTop = alignedChildren.contains { $0.alignTop == true }
        let hasBottom = alignedChildren.contains { $0.alignBottom == true }
        let hasCenterVertical = alignedChildren.contains { $0.centerVertical == true || $0.centerInParent == true }
        
        // Check for conflicting horizontal alignments (left vs right vs center)
        let hasLeft = alignedChildren.contains { $0.alignLeft == true }
        let hasRight = alignedChildren.contains { $0.alignRight == true }
        let hasCenterHorizontal = alignedChildren.contains { $0.centerHorizontal == true || $0.centerInParent == true }
        
        // Check for relative-to-view alignments (these always require relative positioning)
        let hasRelativeToView = alignedChildren.contains { 
            $0.alignLeftOfView != nil || 
            $0.alignRightOfView != nil || 
            $0.alignTopOfView != nil || 
            $0.alignBottomOfView != nil 
        }
        
        // Conflicts exist if:
        // - Multiple different vertical alignments
        // - Multiple different horizontal alignments  
        // - Any relative-to-view alignments
        let verticalConflicts = [hasTop, hasBottom, hasCenterVertical].filter { $0 }.count > 1
        let horizontalConflicts = [hasLeft, hasRight, hasCenterHorizontal].filter { $0 }.count > 1
        
        return verticalConflicts || horizontalConflicts || hasRelativeToView
    }
}

// Extension to add marginTop, marginBottom, marginLeft, marginRight properties
extension DynamicComponent {
    var marginTop: CGFloat? { nil }  // These would need to be added to DynamicComponent if not present
    var marginBottom: CGFloat? { nil }
    var marginLeft: CGFloat? { nil }
    var marginRight: CGFloat? { nil }
}