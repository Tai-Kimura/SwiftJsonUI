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
                            .fixedSize()
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear {
                                            viewSizes[child.id] = geometry.size
                                            Logger.debug("📏 Measured \(child.id): \(geometry.size)")
                                            // After measuring all views, move to second pass
                                            if viewSizes.count == children.count {
                                                Logger.debug("📊 All views measured, calculating positions...")
                                                calculatePositions()
                                                isFirstPass = false
                                            }
                                        }
                                }
                            )
                            .padding(child.margins)
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
                        
                        let _ = Logger.debug("🎯 Positioning \(child.id): relative(\(relativePos.x), \(relativePos.y)) -> absolute(\(absoluteX), \(absoluteY)) in container(\(geometry.size.width), \(geometry.size.height))")
                        
                        child.view
                            .fixedSize()
                            .position(x: absoluteX, y: absoluteY)
                    }
                }
            }
        }
    }
    
    private func calculatePositions() {
        Logger.debug("🔧 calculatePositions() called")
        
        // Find anchor view (no constraints or has centerInParent)
        guard let anchorChild = children.first(where: { $0.constraints.isEmpty }) else {
            Logger.debug("⚠️ No anchor view found")
            return
        }
        
        let anchorSize = viewSizes[anchorChild.id] ?? CGSize(width: 100, height: 50)
        Logger.debug("⚓ Anchor: \(anchorChild.id), size: \(anchorSize)")
        
        // Place anchor at center (will be adjusted by GeometryReader)
        viewPositions[anchorChild.id] = CGPoint(x: 0, y: 0) // Center placeholder
        
        // Calculate positions for other views
        for child in children where child.id != anchorChild.id {
            let childSize = viewSizes[child.id] ?? CGSize(width: 100, height: 30)
            var x: CGFloat = 0
            var y: CGFloat = 0
            
            Logger.debug("📐 Calculating position for \(child.id), size: \(childSize)")
            Logger.debug("   Margins: \(child.margins)")
            
            // Check for centering properties in the original child data
            // Note: We need to pass this information from the JSON
            // For now, we'll handle it based on constraint types
            
            for constraint in child.constraints {
                // Parent alignment constraints don't need targetId
                let isParentConstraint = [.parentTop, .parentBottom, .parentLeft, .parentRight, 
                                         .parentCenterHorizontal, .parentCenterVertical, .parentCenter]
                                         .contains(constraint.type)
                
                if !isParentConstraint {
                    guard constraint.targetId == anchorChild.id else { 
                        Logger.debug("   ⚠️ Constraint target \(constraint.targetId) is not anchor")
                        continue 
                    }
                }
                
                Logger.debug("   Constraint: \(constraint.type) -> \(isParentConstraint ? "parent" : constraint.targetId)")
                
                switch constraint.type {
                case .alignTop:
                    // Align top edges - child's top aligns with anchor's top
                    // Child center should be at: anchor_top + child_height/2
                    y = -anchorSize.height/2 + childSize.height/2
                    // For alignTop/Bottom, typically centerHorizontal is used
                    x = 0  // Center horizontally
                    Logger.debug("   alignTop: y = \(y), x = 0 (centered)")
                case .alignBottom:
                    // Align bottom edges - child's bottom aligns with anchor's bottom
                    // Child center should be at: anchor_bottom - child_height/2
                    y = anchorSize.height/2 - childSize.height/2
                    // For alignTop/Bottom, typically centerHorizontal is used
                    x = 0  // Center horizontally
                    Logger.debug("   alignBottom: y = \(y), x = 0 (centered)")
                case .alignLeft:
                    // Align left edges - child's left aligns with anchor's left
                    // Child center should be at: anchor_left + child_width/2
                    x = -anchorSize.width/2 + childSize.width/2
                    // For alignLeft/Right, typically centerVertical is used
                    y = 0  // Center vertically
                    Logger.debug("   alignLeft: x = \(x), y = 0 (centered)")
                case .alignRight:
                    // Align right edges - child's right aligns with anchor's right
                    // Child center should be at: anchor_right - child_width/2
                    x = anchorSize.width/2 - childSize.width/2
                    // For alignLeft/Right, typically centerVertical is used
                    y = 0  // Center vertically
                    Logger.debug("   alignRight: x = \(x), y = 0 (centered)")
                case .above:
                    // Position above anchor - child's bottom touches anchor's top
                    y = -anchorSize.height/2 - childSize.height/2 - constraint.spacing
                    Logger.debug("   above: y = \(y) = -\(anchorSize.height/2) - \(childSize.height/2) - \(constraint.spacing)")
                case .below:
                    // Position below anchor - child's top touches anchor's bottom
                    y = anchorSize.height/2 + childSize.height/2 + constraint.spacing
                    Logger.debug("   below: y = \(y) = \(anchorSize.height/2) + \(childSize.height/2) + \(constraint.spacing)")
                case .leftOf:
                    // Position to the left of anchor - child's right touches anchor's left
                    x = -anchorSize.width/2 - childSize.width/2 - constraint.spacing
                    Logger.debug("   leftOf: x = \(x) = -\(anchorSize.width/2) - \(childSize.width/2) - \(constraint.spacing)")
                case .rightOf:
                    // Position to the right of anchor - child's left touches anchor's right
                    x = anchorSize.width/2 + childSize.width/2 + constraint.spacing
                    Logger.debug("   rightOf: x = \(x) = \(anchorSize.width/2) + \(childSize.width/2) + \(constraint.spacing)")
                case .parentTop:
                    // Align to parent top
                    y = -geometry.size.height/2 + childSize.height/2 + constraint.spacing
                    Logger.debug("   parentTop: y = \(y)")
                case .parentBottom:
                    // Align to parent bottom
                    y = geometry.size.height/2 - childSize.height/2 - constraint.spacing
                    Logger.debug("   parentBottom: y = \(y)")
                case .parentLeft:
                    // Align to parent left
                    x = -geometry.size.width/2 + childSize.width/2 + constraint.spacing
                    Logger.debug("   parentLeft: x = \(x)")
                case .parentRight:
                    // Align to parent right
                    x = geometry.size.width/2 - childSize.width/2 - constraint.spacing
                    Logger.debug("   parentRight: x = \(x)")
                case .parentCenterHorizontal:
                    // Center horizontally in parent
                    x = 0
                    Logger.debug("   parentCenterHorizontal: x = 0")
                case .parentCenterVertical:
                    // Center vertically in parent
                    y = 0
                    Logger.debug("   parentCenterVertical: y = 0")
                case .parentCenter:
                    // Center in parent (both axes)
                    x = 0
                    y = 0
                    Logger.debug("   parentCenter: x = 0, y = 0")
                }
            }
            
            // Apply margins as additional offset
            let marginOffsetX = child.margins.leading - child.margins.trailing
            let marginOffsetY = child.margins.top - child.margins.bottom
            x += marginOffsetX
            y += marginOffsetY
            
            Logger.debug("   After margins: x += \(marginOffsetX), y += \(marginOffsetY)")
            Logger.debug("   Final position: (\(x), \(y))")
            
            viewPositions[child.id] = CGPoint(x: x, y: y)
        }
        
        Logger.debug("📍 All positions calculated:")
        for (id, pos) in viewPositions {
            Logger.debug("   \(id): (\(pos.x), \(pos.y))")
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
            ("alignTopOfView", .above),       // Position above the view
            ("alignBottomOfView", .below),    // Position below the view
            ("alignLeftOfView", .leftOf),     // Position to the left of the view
            ("alignRightOfView", .rightOf),   // Position to the right of the view
            ("alignTopView", .alignTop),      // Align top edges
            ("alignBottomView", .alignBottom),// Align bottom edges
            ("alignLeftView", .alignLeft),    // Align left edges
            ("alignRightView", .alignRight)   // Align right edges
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