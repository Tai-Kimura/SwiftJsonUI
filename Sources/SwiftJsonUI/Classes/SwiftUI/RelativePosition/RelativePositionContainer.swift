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
    }
    
    public var body: some View {
        ZStack(alignment: alignment) {
            // Background color if specified
            if let backgroundColor = backgroundColor {
                backgroundColor.ignoresSafeArea()
            }
            
            // Render children with positioning
            ForEach(children) { child in
                child.view
                    .saveFrame(id: child.id, in: .named("container"))
                    .offset(calculateOffset(for: child))
                    .padding(child.margins)
            }
        }
        .coordinateSpace(name: "container")
        .onPreferenceChange(ViewFramePreferenceKey.self) { frames in
            viewFrames = frames
        }
    }
    
    private func calculateOffset(for child: RelativeChildConfig) -> CGSize {
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0
        
        for constraint in child.constraints {
            guard let targetFrame = viewFrames[constraint.targetId] else { continue }
            
            switch constraint.type {
            case .alignTop:
                offsetY = targetFrame.minY - (viewFrames[child.id]?.minY ?? 0)
            case .alignBottom:
                offsetY = targetFrame.maxY - (viewFrames[child.id]?.maxY ?? 0)
            case .alignLeft:
                offsetX = targetFrame.minX - (viewFrames[child.id]?.minX ?? 0)
            case .alignRight:
                offsetX = targetFrame.maxX - (viewFrames[child.id]?.maxX ?? 0)
            case .above:
                offsetY = targetFrame.minY - (viewFrames[child.id]?.maxY ?? 0) - constraint.spacing
            case .below:
                offsetY = targetFrame.maxY - (viewFrames[child.id]?.minY ?? 0) + constraint.spacing
            case .leftOf:
                offsetX = targetFrame.minX - (viewFrames[child.id]?.maxX ?? 0) - constraint.spacing
            case .rightOf:
                offsetX = targetFrame.maxX - (viewFrames[child.id]?.minX ?? 0) + constraint.spacing
            }
        }
        
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