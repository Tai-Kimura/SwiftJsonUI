import SwiftUI

/// Container that manages relative positioning of child views
public struct RelativePositionContainer: View {
    public let children: [RelativeChildConfig]
    public let alignment: Alignment
    public let backgroundColor: Color?
    
    @State private var viewSizes: [String: CGSize] = [:]
    @State private var viewPositions: [String: CGPoint] = [:]
    @State private var isFirstPass = true
    
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
        ZStack {
            // Background
            if let backgroundColor = backgroundColor {
                backgroundColor
            }
            
            if isFirstPass {
                // First pass: Measure all views
                ZStack {
                    ForEach(children) { child in
                        child.view
                            .padding(child.margins)
                            .fixedSize()
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear {
                                            viewSizes[child.id] = geometry.size
                                            // After measuring all views, move to second pass
                                            if viewSizes.count == children.count {
                                                calculatePositions()
                                                isFirstPass = false
                                            }
                                        }
                                }
                            )
                            .hidden() // Hide during measurement
                    }
                }
            } else {
                // Second pass: Position views based on calculated positions
                GeometryReader { geometry in
                    ForEach(children) { child in
                        let relativePos = viewPositions[child.id] ?? CGPoint.zero
                        let absoluteX = geometry.size.width/2 + relativePos.x
                        let absoluteY = geometry.size.height/2 + relativePos.y
                        
                        child.view
                            .padding(child.margins)
                            .fixedSize()
                            .position(x: absoluteX, y: absoluteY)
                    }
                }
            }
        }
    }
    
    private func calculatePositions() {
        // Find anchor view (no constraints or has centerInParent)
        guard let anchorChild = children.first(where: { $0.constraints.isEmpty }) else {
            return
        }
        
        let anchorSize = viewSizes[anchorChild.id] ?? CGSize(width: 100, height: 50)
        
        // Place anchor at center (will be adjusted by GeometryReader)
        viewPositions[anchorChild.id] = CGPoint(x: 0, y: 0) // Center placeholder
        
        // Calculate positions for other views
        for child in children where child.id != anchorChild.id {
            let childSize = viewSizes[child.id] ?? CGSize(width: 100, height: 30)
            var x: CGFloat = 0
            var y: CGFloat = 0
            
            for constraint in child.constraints {
                guard constraint.targetId == anchorChild.id else { continue }
                
                switch constraint.type {
                case .alignTop:
                    // Top edges aligned
                    y = -anchorSize.height/2 + childSize.height/2
                case .alignBottom:
                    // Bottom edges aligned
                    y = anchorSize.height/2 - childSize.height/2
                case .alignLeft:
                    // Left edges aligned
                    x = -anchorSize.width/2 + childSize.width/2
                case .alignRight:
                    // Right edges aligned
                    x = anchorSize.width/2 - childSize.width/2
                case .above:
                    // Position above anchor
                    y = -anchorSize.height/2 - childSize.height/2 - constraint.spacing
                case .below:
                    // Position below anchor
                    y = anchorSize.height/2 + childSize.height/2 + constraint.spacing
                case .leftOf:
                    // Position to the left of anchor
                    x = -anchorSize.width/2 - childSize.width/2 - constraint.spacing
                case .rightOf:
                    // Position to the right of anchor
                    x = anchorSize.width/2 + childSize.width/2 + constraint.spacing
                }
            }
            
            // Apply margins as additional offset
            x += child.margins.leading - child.margins.trailing
            y += child.margins.top - child.margins.bottom
            
            viewPositions[child.id] = CGPoint(x: x, y: y)
        }
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