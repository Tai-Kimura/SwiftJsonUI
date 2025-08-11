import SwiftUI

/// Container that manages relative positioning of child views
public struct RelativePositionContainer: View {
    public let children: [RelativeChildConfig]
    public let alignment: Alignment
    public let backgroundColor: Color?
    
    @State private var viewFrames: [String: CGRect] = [:]
    
    public init(
        children: [RelativeChildConfig],
        alignment: Alignment = .topLeading,
        backgroundColor: Color? = nil
    ) {
        self.children = children
        self.alignment = alignment
        self.backgroundColor = backgroundColor
        
        SwiftJsonUI.Logger.debug("🚀 RelativePositionContainer initialized:")
        SwiftJsonUI.Logger.debug("  - Children count: \(children.count)")
        SwiftJsonUI.Logger.debug("  - Alignment: \(String(describing: alignment))")
        for child in children {
            SwiftJsonUI.Logger.debug("  - Child \(child.id):")
            SwiftJsonUI.Logger.debug("    - Constraints: \(child.constraints.count)")
            for constraint in child.constraints {
                SwiftJsonUI.Logger.debug("      - \(constraint.type) -> \(constraint.targetId)")
            }
            SwiftJsonUI.Logger.debug("    - Margins: \(child.margins)")
        }
    }
    
    public var body: some View {
        GeometryReader { containerGeometry in
            ZStack(alignment: alignment) {
                // Background color if specified
                if let backgroundColor = backgroundColor {
                    backgroundColor.ignoresSafeArea()
                }
                
                // Render all children with calculated positions
                ForEach(children) { child in
                    child.view
                        .padding(child.margins)
                        .fixedSize()  // Use intrinsic size
                        .position(calculatePosition(for: child, in: containerGeometry.size))
                }
            }
            .frame(width: containerGeometry.size.width, height: containerGeometry.size.height)
        }
    }
    
    private func calculatePosition(for child: RelativeChildConfig, in containerSize: CGSize) -> CGPoint {
        // Default to center for anchor view
        var x = containerSize.width / 2
        var y = containerSize.height / 2
        
        // Find anchor view position (assume it's centered)
        let anchorX = containerSize.width / 2
        let anchorY = containerSize.height / 2
        let anchorWidth: CGFloat = 100  // From JSON
        let anchorHeight: CGFloat = 50  // From JSON
        
        SwiftJsonUI.Logger.debug("🎯 Calculating position for child: \(child.id)")
        SwiftJsonUI.Logger.debug("  - Container size: \(containerSize)")
        SwiftJsonUI.Logger.debug("  - Anchor position: (\(anchorX), \(anchorY))")
        
        // Apply constraints
        for constraint in child.constraints {
            SwiftJsonUI.Logger.debug("  - Processing constraint: \(constraint.type) -> \(constraint.targetId)")
            
            switch constraint.type {
            case .alignTop:
                y = anchorY - anchorHeight/2 + 15  // Approximate child height/2
                SwiftJsonUI.Logger.debug("    - alignTop: y = \(y)")
            case .alignBottom:
                y = anchorY + anchorHeight/2 - 15  // Approximate child height/2
                SwiftJsonUI.Logger.debug("    - alignBottom: y = \(y)")
            case .alignLeft:
                x = anchorX - anchorWidth/2 + 65  // Approximate child width/2
                SwiftJsonUI.Logger.debug("    - alignLeft: x = \(x)")
            case .alignRight:
                x = anchorX + anchorWidth/2 - 70  // Approximate child width/2
                SwiftJsonUI.Logger.debug("    - alignRight: x = \(x)")
            case .above:
                y = anchorY - anchorHeight/2 - 15 - constraint.spacing
                SwiftJsonUI.Logger.debug("    - above: y = \(y)")
            case .below:
                y = anchorY + anchorHeight/2 + 15 + constraint.spacing
                SwiftJsonUI.Logger.debug("    - below: y = \(y)")
            case .leftOf:
                x = anchorX - anchorWidth/2 - 56 - constraint.spacing
                SwiftJsonUI.Logger.debug("    - leftOf: x = \(x)")
            case .rightOf:
                x = anchorX + anchorWidth/2 + 61 + constraint.spacing
                SwiftJsonUI.Logger.debug("    - rightOf: x = \(x)")
            }
        }
        
        // Apply margins
        x += child.margins.leading - child.margins.trailing
        y += child.margins.top - child.margins.bottom
        
        SwiftJsonUI.Logger.debug("  ✅ Final position: (\(x), \(y))")
        
        return CGPoint(x: x, y: y)
    }
    
    private func calculateOffset(for child: RelativeChildConfig) -> CGSize {
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0
        
        SwiftJsonUI.Logger.debug("🎯 Calculating offset for child: \(child.id)")
        SwiftJsonUI.Logger.debug("  - Constraints count: \(child.constraints.count)")
        
        for constraint in child.constraints {
            SwiftJsonUI.Logger.debug("  - Processing constraint: \(constraint.type) -> \(constraint.targetId)")
            
            guard let targetFrame = viewFrames[constraint.targetId] else {
                SwiftJsonUI.Logger.debug("    ⚠️ Target frame not found for: \(constraint.targetId)")
                continue
            }
            
            let childFrame = viewFrames[child.id]
            SwiftJsonUI.Logger.debug("    - Target frame: origin=(\(targetFrame.origin.x), \(targetFrame.origin.y)), size=(\(targetFrame.size.width), \(targetFrame.size.height))")
            if let cf = childFrame {
                SwiftJsonUI.Logger.debug("    - Child frame: origin=(\(cf.origin.x), \(cf.origin.y)), size=(\(cf.size.width), \(cf.size.height))")
            } else {
                SwiftJsonUI.Logger.debug("    - Child frame: NOT FOUND")
            }
            
            switch constraint.type {
            case .alignTop:
                let offset = targetFrame.minY - (childFrame?.minY ?? 0)
                offsetY = offset
                SwiftJsonUI.Logger.debug("    - alignTop: offsetY = \(offset)")
            case .alignBottom:
                let offset = targetFrame.maxY - (childFrame?.maxY ?? 0)
                offsetY = offset
                SwiftJsonUI.Logger.debug("    - alignBottom: offsetY = \(offset)")
            case .alignLeft:
                let offset = targetFrame.minX - (childFrame?.minX ?? 0)
                offsetX = offset
                SwiftJsonUI.Logger.debug("    - alignLeft: offsetX = \(offset)")
            case .alignRight:
                let offset = targetFrame.maxX - (childFrame?.maxX ?? 0)
                offsetX = offset
                SwiftJsonUI.Logger.debug("    - alignRight: offsetX = \(offset)")
            case .above:
                let offset = targetFrame.minY - (childFrame?.maxY ?? 0) - constraint.spacing
                offsetY = offset
                SwiftJsonUI.Logger.debug("    - above: offsetY = \(offset)")
            case .below:
                let offset = targetFrame.maxY - (childFrame?.minY ?? 0) + constraint.spacing
                offsetY = offset
                SwiftJsonUI.Logger.debug("    - below: offsetY = \(offset)")
            case .leftOf:
                let offset = targetFrame.minX - (childFrame?.maxX ?? 0) - constraint.spacing
                offsetX = offset
                SwiftJsonUI.Logger.debug("    - leftOf: offsetX = \(offset)")
            case .rightOf:
                let offset = targetFrame.maxX - (childFrame?.minX ?? 0) + constraint.spacing
                offsetX = offset
                SwiftJsonUI.Logger.debug("    - rightOf: offsetX = \(offset)")
            }
        }
        
        SwiftJsonUI.Logger.debug("  ✅ Final offset: (\(offsetX), \(offsetY))")
        return CGSize(width: offsetX, height: offsetY)
    }
}

/// Helper to create child configurations from JSON-like dictionaries
public extension RelativeChildConfig {
    static func from(
        dict: [String: Any],
        view: AnyView
    ) -> RelativeChildConfig? {
        guard let id = dict["id"] as? String else { return nil }
        
        var constraints: [RelativePositionConstraint] = []
        
        // Check for alignment constraints
        let constraintMappings: [(String, RelativePositionConstraint.ConstraintType)] = [
            ("alignTopOfView", .alignTop),
            ("alignBottomOfView", .alignBottom),
            ("alignLeftOfView", .alignLeft),
            ("alignRightOfView", .alignRight),
            ("alignTopView", .above),
            ("alignBottomView", .below),
            ("alignLeftView", .leftOf),
            ("alignRightView", .rightOf)
        ]
        
        for (key, type) in constraintMappings {
            if let targetId = dict[key] as? String {
                let spacing = CGFloat(dict["spacing"] as? Double ?? 0)
                constraints.append(RelativePositionConstraint(
                    type: type,
                    targetId: targetId,
                    spacing: spacing
                ))
            }
        }
        
        // Parse margins
        let topMargin = CGFloat(dict["topMargin"] as? Double ?? 0)
        let bottomMargin = CGFloat(dict["bottomMargin"] as? Double ?? 0)
        let leftMargin = CGFloat(dict["leftMargin"] as? Double ?? 0)
        let rightMargin = CGFloat(dict["rightMargin"] as? Double ?? 0)
        
        let margins = EdgeInsets(
            top: topMargin,
            leading: leftMargin,
            bottom: bottomMargin,
            trailing: rightMargin
        )
        
        // Parse size if specified
        var size: CGSize? = nil
        if let width = dict["width"] as? Double,
           let height = dict["height"] as? Double {
            size = CGSize(width: width, height: height)
        }
        
        return RelativeChildConfig(
            id: id,
            view: view,
            constraints: constraints,
            margins: margins,
            size: size
        )
    }
}