import SwiftUI

/// Represents a relative positioning constraint between views
public struct RelativePositionConstraint: Codable {
    public enum ConstraintType: String, Codable {
        case alignTop = "alignTopView"
        case alignBottom = "alignBottomView"
        case alignLeft = "alignLeftView"
        case alignRight = "alignRightView"
        case above = "alignTopOfView"
        case below = "alignBottomOfView"
        case leftOf = "alignLeftOfView"
        case rightOf = "alignRightOfView"
        case centerVertical = "alignCenterVerticalView"
        case centerHorizontal = "alignCenterHorizontalView"
        // Parent alignment constraints
        case parentTop = "alignTop"
        case parentBottom = "alignBottom"
        case parentLeft = "alignLeft"
        case parentRight = "alignRight"
        case parentCenterHorizontal = "centerHorizontal"
        case parentCenterVertical = "centerVertical"
        case parentCenter = "centerInParent"
    }
    
    public let type: ConstraintType
    public let targetId: String
    
    public init(type: ConstraintType, targetId: String) {
        self.type = type
        self.targetId = targetId
    }
}

/// Size mode for relative positioning (matchParent, wrapContent, or fixed)
public enum RelativeSizeMode {
    case matchParent  // Fill available space
    case wrapContent  // Use content's natural size
    case fixed(CGFloat)  // Fixed size in points
}

/// Configuration for a child view in relative positioning
public struct RelativeChildConfig: Identifiable {
    public let id: String
    public let view: AnyView
    public let constraints: [RelativePositionConstraint]
    public let margins: EdgeInsets
    public let size: CGSize?
    public let widthMode: RelativeSizeMode
    public let heightMode: RelativeSizeMode

    public init(
        id: String,
        view: AnyView,
        constraints: [RelativePositionConstraint] = [],
        margins: EdgeInsets = .init(),
        size: CGSize? = nil,
        widthMode: RelativeSizeMode = .wrapContent,
        heightMode: RelativeSizeMode = .wrapContent
    ) {
        self.id = id
        self.view = view
        self.constraints = constraints
        self.margins = margins
        self.size = size
        self.widthMode = widthMode
        self.heightMode = heightMode
    }
}