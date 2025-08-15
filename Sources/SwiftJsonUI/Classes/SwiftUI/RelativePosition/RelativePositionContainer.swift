import SwiftUI

/// Container that manages relative positioning of child views
public struct RelativePositionContainer: View {
    public let children: [RelativeChildConfig]
    public let alignment: Alignment
    public let backgroundColor: Color?

    @State private var viewSizes: [String: CGSize] = [:]
    @State private var viewPositions: [String: CGPoint] = [:]
    @State private var isFirstPass = true
    @State private var containerSize: CGSize = .zero

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
                                            Logger.debug(
                                                "📏 Measured \(child.id): \(geometry.size)"
                                            )
                                            // After measuring all views, move to second pass
                                            if viewSizes.count == children.count
                                            {
                                                Logger.debug(
                                                    "📊 All views measured, moving to positioning phase..."
                                                )
                                                isFirstPass = false
                                            }
                                        }
                                }
                            )
                            .hidden()  // Hide during measurement
                    }
                }
            } else {
                // Second pass: Position views based on calculated positions
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            if containerSize == .zero {
                                containerSize = geometry.size
                                calculatePositions()
                            }
                        }
                    ForEach(children) { child in
                        let relativePos =
                            viewPositions[child.id] ?? CGPoint.zero
                        let absoluteX = geometry.size.width / 2 + relativePos.x
                        let absoluteY = geometry.size.height / 2 + relativePos.y

                        let _ = Logger.debug(
                            "🎯 Positioning \(child.id): relative(\(relativePos.x), \(relativePos.y)) -> absolute(\(absoluteX), \(absoluteY)) in container(\(geometry.size.width), \(geometry.size.height))"
                        )

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

        // Process views in dependency order
        var processedViews = Set<String>()
        var remainingChildren = children
        
        // First, process views with only parent constraints
        let parentOnlyViews = children.filter { child in
            child.constraints.allSatisfy { constraint in
                [.parentTop, .parentBottom, .parentLeft, .parentRight,
                 .parentCenterHorizontal, .parentCenterVertical, .parentCenter]
                    .contains(constraint.type)
            }
        }
        
        // Process parent-only constrained views first
        for child in parentOnlyViews {
            let childSize = viewSizes[child.id] ?? CGSize(width: 100, height: 50)
            calculateChildPosition(
                child: child,
                anchorChild: nil,
                anchorSize: .zero
            )
            processedViews.insert(child.id)
            Logger.debug("✅ Processed parent-constrained view: \(child.id)")
        }
        
        // Remove processed views from remaining
        remainingChildren.removeAll { processedViews.contains($0.id) }
        
        // Process remaining views that depend on other views
        var iterationCount = 0
        let maxIterations = remainingChildren.count + 1
        
        while !remainingChildren.isEmpty && iterationCount < maxIterations {
            iterationCount += 1
            var processedInThisIteration = [RelativeChildConfig]()
            
            for child in remainingChildren {
                // Check if all dependencies are already processed
                let canProcess = child.constraints.allSatisfy { constraint in
                    // Parent constraints are always ready
                    if [.parentTop, .parentBottom, .parentLeft, .parentRight,
                        .parentCenterHorizontal, .parentCenterVertical, .parentCenter]
                        .contains(constraint.type) {
                        return true
                    }
                    // For other constraints, check if target is processed
                    return constraint.targetId.isEmpty || processedViews.contains(constraint.targetId)
                }
                
                if canProcess {
                    // Find the target view if there is one
                    var targetChild: RelativeChildConfig? = nil
                    var targetSize = CGSize.zero
                    
                    // Find the first non-parent constraint to get the target
                    for constraint in child.constraints {
                        if ![.parentTop, .parentBottom, .parentLeft, .parentRight,
                             .parentCenterHorizontal, .parentCenterVertical, .parentCenter]
                            .contains(constraint.type) && !constraint.targetId.isEmpty {
                            targetChild = children.first { $0.id == constraint.targetId }
                            if let target = targetChild {
                                targetSize = viewSizes[target.id] ?? CGSize(width: 100, height: 50)
                            }
                            break
                        }
                    }
                    
                    calculateChildPosition(
                        child: child,
                        anchorChild: targetChild,
                        anchorSize: targetSize
                    )
                    processedViews.insert(child.id)
                    processedInThisIteration.append(child)
                    Logger.debug("✅ Processed view with dependencies: \(child.id)")
                }
            }
            
            // Remove processed views from remaining
            remainingChildren.removeAll { view in
                processedInThisIteration.contains { $0.id == view.id }
            }
            
            // If no views were processed in this iteration, we have a circular dependency
            if processedInThisIteration.isEmpty && !remainingChildren.isEmpty {
                Logger.debug("⚠️ Circular dependency detected or unresolvable constraints")
                // Process remaining views anyway
                for child in remainingChildren {
                    calculateChildPosition(
                        child: child,
                        anchorChild: nil,
                        anchorSize: .zero
                    )
                }
                break
            }
        }

        Logger.debug("📍 All positions calculated:")
        for (id, pos) in viewPositions {
            Logger.debug("   \(id): (\(pos.x), \(pos.y))")
        }
    }

    private func calculateChildPosition(
        child: RelativeChildConfig,
        anchorChild: RelativeChildConfig?,
        anchorSize: CGSize
    ) {
        let childSize = viewSizes[child.id] ?? CGSize(width: 100, height: 30)

        // Default position based on container alignment
        var x: CGFloat = 0
        var y: CGFloat = 0

        // Set default positions based on alignment
        switch alignment {
        case .topLeading:
            x = -containerSize.width / 2 + childSize.width / 2
            y = -containerSize.height / 2 + childSize.height / 2
        case .top:
            x = 0
            y = -containerSize.height / 2 + childSize.height / 2
        case .topTrailing:
            x = containerSize.width / 2 - childSize.width / 2
            y = -containerSize.height / 2 + childSize.height / 2
        case .leading:
            x = -containerSize.width / 2 + childSize.width / 2
            y = 0
        case .center:
            x = 0
            y = 0
        case .trailing:
            x = containerSize.width / 2 - childSize.width / 2
            y = 0
        case .bottomLeading:
            x = -containerSize.width / 2 + childSize.width / 2
            y = containerSize.height / 2 - childSize.height / 2
        case .bottom:
            x = 0
            y = containerSize.height / 2 - childSize.height / 2
        case .bottomTrailing:
            x = containerSize.width / 2 - childSize.width / 2
            y = containerSize.height / 2 - childSize.height / 2
        default:
            x = 0
            y = 0
        }

        Logger.debug(
            "📐 Calculating position for \(child.id), size: \(childSize)"
        )
        Logger.debug(
            "   Default position from alignment (\(alignment)): x=\(x), y=\(y)"
        )
        Logger.debug("   Margins: \(child.margins)")

        // Check for centering properties in the original child data
        // Note: We need to pass this information from the JSON
        // For now, we'll handle it based on constraint types

        for constraint in child.constraints {
            // Parent alignment constraints don't need targetId
            let isParentConstraint = [
                .parentTop, .parentBottom, .parentLeft, .parentRight,
                .parentCenterHorizontal, .parentCenterVertical, .parentCenter,
            ]
            .contains(constraint.type)

            if !isParentConstraint {
                guard let anchorChild = anchorChild,
                    constraint.targetId == anchorChild.id
                else {
                    Logger.debug(
                        "   ⚠️ Constraint target \(constraint.targetId) is not anchor or no anchor exists"
                    )
                    continue
                }
            }

            Logger.debug(
                "   Constraint: \(constraint.type) -> \(isParentConstraint ? "parent" : constraint.targetId)"
            )

            switch constraint.type {
            case .alignTop:
                // Align top edges - child's top aligns with anchor's top
                let anchorPos = anchorChild != nil ? viewPositions[anchorChild!.id] ?? CGPoint.zero : CGPoint.zero
                y = anchorPos.y - anchorSize.height / 2 + childSize.height / 2
                // For vertical-only alignment, preserve x from anchorPos if not already set
                if x == 0 && alignment == .center {
                    x = anchorPos.x
                }
                Logger.debug("   alignTop: y = \(y), x = \(x)")
            case .alignBottom:
                // Align bottom edges - child's bottom aligns with anchor's bottom
                let anchorPos = anchorChild != nil ? viewPositions[anchorChild!.id] ?? CGPoint.zero : CGPoint.zero
                y = anchorPos.y + anchorSize.height / 2 - childSize.height / 2
                // For vertical-only alignment, preserve x from anchorPos if not already set
                if x == 0 && alignment == .center {
                    x = anchorPos.x
                }
                Logger.debug("   alignBottom: y = \(y), x = \(x)")
            case .alignLeft:
                // Align left edges - child's left aligns with anchor's left
                let anchorPos = anchorChild != nil ? viewPositions[anchorChild!.id] ?? CGPoint.zero : CGPoint.zero
                x = anchorPos.x - anchorSize.width / 2 + childSize.width / 2
                // For horizontal-only alignment, preserve y from anchorPos if not already set
                if y == 0 && alignment == .center {
                    y = anchorPos.y
                }
                Logger.debug("   alignLeft: x = \(x), y = \(y)")
            case .alignRight:
                // Align right edges - child's right aligns with anchor's right
                let anchorPos = anchorChild != nil ? viewPositions[anchorChild!.id] ?? CGPoint.zero : CGPoint.zero
                x = anchorPos.x + anchorSize.width / 2 - childSize.width / 2
                // For horizontal-only alignment, preserve y from anchorPos if not already set
                if y == 0 && alignment == .center {
                    y = anchorPos.y
                }
                Logger.debug("   alignRight: x = \(x), y = \(y)")
            case .above:
                // Position above anchor - child's bottom touches anchor's top (considering anchor's top margin)
                let anchorTopMargin = anchorChild?.margins.top ?? 0
                let anchorPos = anchorChild != nil ? viewPositions[anchorChild!.id] ?? CGPoint.zero : CGPoint.zero
                y = anchorPos.y - anchorSize.height / 2 - childSize.height / 2
                    - constraint.spacing - anchorTopMargin
                Logger.debug(
                    "   above: y = \(y) = \(anchorPos.y) - \(anchorSize.height/2) - \(childSize.height/2) - \(constraint.spacing) - \(anchorTopMargin)"
                )
            case .below:
                // Position below anchor - child's top touches anchor's bottom (considering anchor's bottom margin)
                let anchorBottomMargin = anchorChild?.margins.bottom ?? 0
                let anchorPos = anchorChild != nil ? viewPositions[anchorChild!.id] ?? CGPoint.zero : CGPoint.zero
                y = anchorPos.y + anchorSize.height / 2 + childSize.height / 2
                    + constraint.spacing + anchorBottomMargin
                Logger.debug(
                    "   below: y = \(y) = \(anchorPos.y) + \(anchorSize.height/2) + \(childSize.height/2) + \(constraint.spacing) + \(anchorBottomMargin)"
                )
            case .leftOf:
                // Position to the left of anchor - child's right touches anchor's left (considering anchor's left margin)
                let anchorLeftMargin = anchorChild?.margins.leading ?? 0
                let anchorPos = anchorChild != nil ? viewPositions[anchorChild!.id] ?? CGPoint.zero : CGPoint.zero
                x = anchorPos.x - anchorSize.width / 2 - childSize.width / 2
                    - constraint.spacing - anchorLeftMargin
                Logger.debug(
                    "   leftOf: x = \(x) = \(anchorPos.x) - \(anchorSize.width/2) - \(childSize.width/2) - \(constraint.spacing) - \(anchorLeftMargin)"
                )
            case .rightOf:
                // Position to the right of anchor - child's left touches anchor's right (considering anchor's right margin)
                let anchorRightMargin = anchorChild?.margins.trailing ?? 0
                let anchorPos = anchorChild != nil ? viewPositions[anchorChild!.id] ?? CGPoint.zero : CGPoint.zero
                x = anchorPos.x + anchorSize.width / 2 + childSize.width / 2
                    + constraint.spacing + anchorRightMargin
                Logger.debug(
                    "   rightOf: x = \(x) = \(anchorPos.x) + \(anchorSize.width/2) + \(childSize.width/2) + \(constraint.spacing) + \(anchorRightMargin)"
                )
            case .parentTop:
                // Align to parent top with margin
                y =
                    -containerSize.height / 2 + childSize.height / 2
                    + constraint.spacing + child.margins.top
                Logger.debug("   parentTop: y = \(y)")
            case .parentBottom:
                // Align to parent bottom with margin
                y =
                    containerSize.height / 2 - childSize.height / 2
                    - constraint.spacing - child.margins.bottom
                Logger.debug("   parentBottom: y = \(y)")
            case .parentLeft:
                // Align to parent left with margin
                x =
                    -containerSize.width / 2 + childSize.width / 2
                    + constraint.spacing + child.margins.leading
                Logger.debug("   parentLeft: x = \(x)")
            case .parentRight:
                // Align to parent right with margin
                x =
                    containerSize.width / 2 - childSize.width / 2
                    - constraint.spacing - child.margins.trailing
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

        // Margins are already applied in parent constraint calculations above
        // No additional margin offset needed here
        Logger.debug("   Final position: (\(x), \(y))")

        viewPositions[child.id] = CGPoint(x: x, y: y)
    }
}

/// Helper to create child configurations from JSON-like dictionaries
extension RelativeChildConfig {
    public static func from(
        dict: [String: Any],
        view: AnyView
    ) -> RelativeChildConfig? {
        guard let id = dict["id"] as? String else { return nil }

        var constraints: [RelativePositionConstraint] = []

        // Check for parent alignment constraints first
        if dict["centerInParent"] as? Bool == true {
            constraints.append(
                RelativePositionConstraint(
                    type: .parentCenter,
                    targetId: "",
                    spacing: 0
                )
            )
        } else {
            // Check individual parent alignment properties
            if dict["alignTop"] as? Bool == true {
                constraints.append(
                    RelativePositionConstraint(
                        type: .parentTop,
                        targetId: "",
                        spacing: 0
                    )
                )
            } else if dict["alignBottom"] as? Bool == true {
                constraints.append(
                    RelativePositionConstraint(
                        type: .parentBottom,
                        targetId: "",
                        spacing: 0
                    )
                )
            }
            
            if dict["alignLeft"] as? Bool == true {
                constraints.append(
                    RelativePositionConstraint(
                        type: .parentLeft,
                        targetId: "",
                        spacing: 0
                    )
                )
            } else if dict["alignRight"] as? Bool == true {
                constraints.append(
                    RelativePositionConstraint(
                        type: .parentRight,
                        targetId: "",
                        spacing: 0
                    )
                )
            }
            
            if dict["centerHorizontal"] as? Bool == true {
                constraints.append(
                    RelativePositionConstraint(
                        type: .parentCenterHorizontal,
                        targetId: "",
                        spacing: 0
                    )
                )
            }
            
            if dict["centerVertical"] as? Bool == true {
                constraints.append(
                    RelativePositionConstraint(
                        type: .parentCenterVertical,
                        targetId: "",
                        spacing: 0
                    )
                )
            }
        }

        // Check for alignment constraints to other views
        let constraintMappings:
            [(String, RelativePositionConstraint.ConstraintType)] = [
                ("alignTopOfView", .above),  // Position above the view
                ("alignBottomOfView", .below),  // Position below the view
                ("alignLeftOfView", .leftOf),  // Position to the left of the view
                ("alignRightOfView", .rightOf),  // Position to the right of the view
                ("alignTopView", .alignTop),  // Align top edges
                ("alignBottomView", .alignBottom),  // Align bottom edges
                ("alignLeftView", .alignLeft),  // Align left edges
                ("alignRightView", .alignRight),  // Align right edges
            ]

        for (key, type) in constraintMappings {
            if let targetId = dict[key] as? String {
                let spacing = CGFloat(dict["spacing"] as? Double ?? 0)
                constraints.append(
                    RelativePositionConstraint(
                        type: type,
                        targetId: targetId,
                        spacing: spacing
                    )
                )
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
            let height = dict["height"] as? Double
        {
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
