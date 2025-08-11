import SwiftUI

/// Represents a relative positioning constraint between views
public struct RelativePositionConstraint: Codable {
    public enum ConstraintType: String, Codable {
        case alignTop = "alignTopOfView"
        case alignBottom = "alignBottomOfView"
        case alignLeft = "alignLeftOfView"
        case alignRight = "alignRightOfView"
        case above = "alignTopView"
        case below = "alignBottomView"
        case leftOf = "alignLeftView"
        case rightOf = "alignRightView"
    }
    
    public let type: ConstraintType
    public let targetId: String
    public let spacing: CGFloat
    
    public init(type: ConstraintType, targetId: String, spacing: CGFloat = 0) {
        self.type = type
        self.targetId = targetId
        self.spacing = spacing
    }
}

/// Configuration for a child view in relative positioning
public struct RelativeChildConfig: Identifiable {
    public let id: String
    public let view: AnyView
    public let constraints: [RelativePositionConstraint]
    public let margins: EdgeInsets
    public let size: CGSize?
    
    public init(
        id: String,
        view: AnyView,
        constraints: [RelativePositionConstraint] = [],
        margins: EdgeInsets = .init(),
        size: CGSize? = nil
    ) {
        self.id = id
        self.view = view
        self.constraints = constraints
        self.margins = margins
        self.size = size
    }
}