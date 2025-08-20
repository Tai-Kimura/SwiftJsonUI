import SwiftUI

// PreferenceKey for collecting view sizes
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGSize] = [:]
    
    static func reduce(value: inout [String: CGSize], nextValue: () -> [String: CGSize]) {
        value.merge(nextValue()) { _, new in new }
    }
}

/// Container that manages relative positioning of child views
public struct RelativePositionContainer: View {
    public let children: [RelativeChildConfig]
    public let alignment: Alignment
    public let backgroundColor: Color?
    public let parentPadding: EdgeInsets

    @State private var viewSizes: [String: CGSize] = [:]
    @State private var viewPositions: [String: CGPoint] = [:]
    @State private var layoutPhase: LayoutPhase = .measuring
    
    private enum LayoutPhase {
        case measuring
        case positioning
        case completed
    }

    public init(
        children: [RelativeChildConfig],
        alignment: Alignment = .topLeading,
        backgroundColor: Color? = nil,
        parentPadding: EdgeInsets = .init()
    ) {
        self.children = children
        self.alignment = alignment
        self.backgroundColor = backgroundColor
        self.parentPadding = parentPadding
    }

    public var body: some View {
        let _ = print("🔄 RelativePositionContainer.body called - phase: \(layoutPhase), viewSizes: \(viewSizes.count), viewPositions: \(viewPositions.count)")
        
        ZStack {
            // Background
            if let backgroundColor = backgroundColor {
                backgroundColor
            }

            switch layoutPhase {
            case .measuring:
                let _ = print("📏 MEASURING PHASE - children: \(children.count)")
                // First pass: Measure all views
                ZStack {
                    ForEach(children) { child in
                        child.view
                            .fixedSize()
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .preference(
                                            key: SizePreferenceKey.self,
                                            value: [child.id: geometry.size]
                                        )
                                }
                            )
                            .hidden()  // Hide during measurement
                    }
                }
                .onPreferenceChange(SizePreferenceKey.self) { sizes in
                    print("📐 onPreferenceChange called with \(sizes.count) sizes")
                    // Use async dispatch to avoid state change during view update
                    DispatchQueue.main.async {
                        for (id, size) in sizes {
                            if viewSizes[id] == nil {
                                print("   📏 Measuring \(id): \(size)")
                                viewSizes[id] = size
                            } else {
                                print("   ⚠️ Already measured \(id), skipping")
                            }
                        }
                        // After measuring all views, move to positioning phase
                        if viewSizes.count == children.count && layoutPhase == .measuring {
                            print("📊 All \(children.count) views measured, transitioning to positioning phase")
                            layoutPhase = .positioning
                        } else {
                            print("   📊 Progress: \(viewSizes.count)/\(children.count) measured")
                        }
                    }
                }
                
            case .positioning, .completed:
                let _ = print("📍 POSITIONING PHASE - phase: \(layoutPhase)")
                // Second pass: Position views based on calculated positions
                GeometryReader { geometry in
                    let _ = print("   📐 GeometryReader size: \(geometry.size)")
                    ZStack {
                        Color.clear
                        ForEach(children) { child in
                            let relativePos =
                                viewPositions[child.id] ?? CGPoint.zero
                            let absoluteX = geometry.size.width / 2 + relativePos.x
                            let absoluteY = geometry.size.height / 2 + relativePos.y

                            child.view
                                .fixedSize()
                                .position(x: absoluteX, y: absoluteY)
                        }
                    }
                    .task(id: geometry.size) {
                        print("   🔄 task(id: \(geometry.size)) called - phase: \(layoutPhase)")
                        if layoutPhase == .positioning {
                            print("   📊 Calculating positions...")
                            let positions = calculatePositions(containerSize: geometry.size)
                            print("   ✅ Setting \(positions.count) positions and transitioning to completed")
                            viewPositions = positions
                            layoutPhase = .completed
                        } else {
                            print("   ⏭️ Already completed, skipping")
                        }
                    }
                }
            }
        }
    }

    private func calculatePositions(containerSize: CGSize) -> [String: CGPoint] {
        Logger.debug("🔧 calculatePositions() called with containerSize: \(containerSize)")
        
        // Create local copies to avoid modifying state during calculation
        var localPositions: [String: CGPoint] = [:]
        var localViewSizes = viewSizes  // ローカルコピーで作業

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
            let position = calculateChildPosition(
                child: child, 
                localPositions: localPositions,
                containerSize: containerSize,
                viewSizes: &localViewSizes
            )
            localPositions[child.id] = position
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
                    let position = calculateChildPosition(
                        child: child, 
                        localPositions: localPositions,
                        containerSize: containerSize,
                        viewSizes: &localViewSizes
                    )
                    localPositions[child.id] = position
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
                    let position = calculateChildPosition(
                        child: child, 
                        localPositions: localPositions,
                        containerSize: containerSize,
                        viewSizes: &localViewSizes
                    )
                    localPositions[child.id] = position
                }
                break
            }
        }
        
        Logger.debug("📍 All positions calculated:")
        for (id, pos) in localPositions {
            Logger.debug("   \(id): (\(pos.x), \(pos.y))")
        }
        
        return localPositions
    }

    private func calculateChildPosition(
        child: RelativeChildConfig,
        localPositions: [String: CGPoint],
        containerSize: CGSize,
        viewSizes: inout [String: CGSize]
    ) -> CGPoint {
        var childSize = viewSizes[child.id] ?? .zero
        
        // Check if size should be dynamic based on constraints
        let hasLeftConstraint = child.constraints.contains { 
            [.parentLeft, .alignLeft, .rightOf].contains($0.type) 
        }
        let hasRightConstraint = child.constraints.contains { 
            [.parentRight, .alignRight, .leftOf].contains($0.type) 
        }
        let hasTopConstraint = child.constraints.contains { 
            [.parentTop, .alignTop, .below].contains($0.type) 
        }
        let hasBottomConstraint = child.constraints.contains { 
            [.parentBottom, .alignBottom, .above].contains($0.type) 
        }
        
        // If non-fixed size and both sides have constraints, calculate dynamic size
        // This will be recalculated after initial position is determined
        var dynamicWidth = false
        var dynamicHeight = false
        
        if child.size == nil {
            if hasLeftConstraint && hasRightConstraint {
                dynamicWidth = true
            }
            if hasTopConstraint && hasBottomConstraint {
                dynamicHeight = true
            }
        }

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

            // Find the target view for this specific constraint
            var anchorChild: RelativeChildConfig? = nil
            var anchorSize = CGSize.zero
            
            if !isParentConstraint && !constraint.targetId.isEmpty {
                anchorChild = children.first { $0.id == constraint.targetId }
                if let anchor = anchorChild {
                    anchorSize = viewSizes[anchor.id] ?? .zero
                } else {
                    Logger.debug(
                        "   ⚠️ Constraint target \(constraint.targetId) not found"
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
                // Only apply self margin, not anchor's margin
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? CGPoint.zero : CGPoint.zero
                y = anchorPos.y - anchorSize.height / 2 + childSize.height / 2 + child.margins.top
                // x position remains from default alignment calculation, don't change it
                Logger.debug("   alignTop: y = \(y), x = \(x)")
            case .alignBottom:
                // Align bottom edges - child's bottom aligns with anchor's bottom
                // Only apply self margin, not anchor's margin
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? CGPoint.zero : CGPoint.zero
                y = anchorPos.y + anchorSize.height / 2 - childSize.height / 2 - child.margins.bottom
                // x position remains from default alignment calculation, don't change it
                Logger.debug("   alignBottom: y = \(y), x = \(x)")
            case .alignLeft:
                // Align left edges - child's left aligns with anchor's left
                // Only apply self margin, not anchor's margin
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? CGPoint.zero : CGPoint.zero
                x = anchorPos.x - anchorSize.width / 2 + childSize.width / 2 + child.margins.leading
                // y position remains from default alignment calculation, don't change it
                Logger.debug("   alignLeft: x = \(x), y = \(y)")
            case .alignRight:
                // Align right edges - child's right aligns with anchor's right
                // Only apply self margin, not anchor's margin
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? CGPoint.zero : CGPoint.zero
                x = anchorPos.x + anchorSize.width / 2 - childSize.width / 2 - child.margins.trailing
                // y position remains from default alignment calculation, don't change it
                Logger.debug("   alignRight: x = \(x), y = \(y)")
            case .above:
                // Position above anchor - child's bottom touches anchor's top
                // Apply both self and anchor margins
                let anchorTopMargin = anchorChild?.margins.top ?? 0
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? CGPoint.zero : CGPoint.zero
                y = anchorPos.y - anchorSize.height / 2 - childSize.height / 2
                    - anchorTopMargin - child.margins.bottom
                // x position remains from default alignment calculation, don't change it
                Logger.debug(
                    "   above: y = \(y) = \(anchorPos.y) - \(anchorSize.height/2) - \(childSize.height/2) - \(anchorTopMargin)"
                )
            case .below:
                // Position below anchor - child's top touches anchor's bottom
                // Apply both self and anchor margins
                let anchorBottomMargin = anchorChild?.margins.bottom ?? 0
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? CGPoint.zero : CGPoint.zero
                y = anchorPos.y + anchorSize.height / 2 + childSize.height / 2
                    + anchorBottomMargin + child.margins.top
                // x position remains from default alignment calculation, don't change it
                Logger.debug(
                    "   below: y = \(y) = \(anchorPos.y) + \(anchorSize.height/2) + \(childSize.height/2) + \(anchorBottomMargin)"
                )
            case .leftOf:
                // Position to the left of anchor - child's right touches anchor's left
                // Apply both self and anchor margins
                let anchorLeftMargin = anchorChild?.margins.leading ?? 0
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? CGPoint.zero : CGPoint.zero
                x = anchorPos.x - anchorSize.width / 2 - childSize.width / 2
                    - anchorLeftMargin - child.margins.trailing
                // y position remains from default alignment calculation, don't change it
                Logger.debug(
                    "   leftOf: x = \(x) = \(anchorPos.x) - \(anchorSize.width/2) - \(childSize.width/2) - \(anchorLeftMargin)"
                )
            case .rightOf:
                // Position to the right of anchor - child's left touches anchor's right
                // Apply both self and anchor margins
                let anchorRightMargin = anchorChild?.margins.trailing ?? 0
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? CGPoint.zero : CGPoint.zero
                x = anchorPos.x + anchorSize.width / 2 + childSize.width / 2
                    + anchorRightMargin + child.margins.leading
                // y position remains from default alignment calculation, don't change it
                Logger.debug(
                    "   rightOf: x = \(x) = \(anchorPos.x) + \(anchorSize.width/2) + \(childSize.width/2) + \(anchorRightMargin)"
                )
            case .centerVertical:
                // Center vertically with another view
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? CGPoint.zero : CGPoint.zero
                y = anchorPos.y
                Logger.debug("   centerVertical: y = \(y) (aligned with \(constraint.targetId))")
            case .centerHorizontal:
                // Center horizontally with another view
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? CGPoint.zero : CGPoint.zero
                x = anchorPos.x
                Logger.debug("   centerHorizontal: x = \(x) (aligned with \(constraint.targetId))")
            case .parentTop:
                // Align to parent top with margin and parent padding
                y =
                    -containerSize.height / 2 + childSize.height / 2
                    + child.margins.top + parentPadding.top
                Logger.debug("   parentTop: y = \(y)")
            case .parentBottom:
                // Align to parent bottom with margin and parent padding
                y =
                    containerSize.height / 2 - childSize.height / 2
                    - child.margins.bottom - parentPadding.bottom
                Logger.debug("   parentBottom: y = \(y)")
            case .parentLeft:
                // Align to parent left with margin and parent padding
                x =
                    -containerSize.width / 2 + childSize.width / 2
                    + child.margins.leading + parentPadding.leading
                Logger.debug("   parentLeft: x = \(x)")
            case .parentRight:
                // Align to parent right with margin and parent padding
                x =
                    containerSize.width / 2 - childSize.width / 2
                    - child.margins.trailing - parentPadding.trailing
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

        // Handle centering for fixed size with constraints on both sides
        if child.size != nil {
            // Collect left/right constraint positions
            var leftX: CGFloat? = nil
            var rightX: CGFloat? = nil
            var topY: CGFloat? = nil
            var bottomY: CGFloat? = nil
            
            for constraint in child.constraints {
                switch constraint.type {
                case .parentLeft:
                    leftX = -containerSize.width / 2 + child.margins.leading + parentPadding.leading
                case .parentRight:
                    rightX = containerSize.width / 2 - child.margins.trailing - parentPadding.trailing
                case .alignLeft:
                    if let targetView = children.first(where: { $0.id == constraint.targetId }) {
                        let anchorPos = localPositions[targetView.id] ?? CGPoint.zero
                        let anchorSize = viewSizes[targetView.id] ?? .zero
                        leftX = anchorPos.x - anchorSize.width / 2 + child.margins.leading
                    }
                case .alignRight:
                    if let targetView = children.first(where: { $0.id == constraint.targetId }) {
                        let anchorPos = localPositions[targetView.id] ?? CGPoint.zero
                        let anchorSize = viewSizes[targetView.id] ?? .zero
                        rightX = anchorPos.x + anchorSize.width / 2 - child.margins.trailing
                    }
                case .rightOf:
                    if let targetView = children.first(where: { $0.id == constraint.targetId }) {
                        let anchorPos = localPositions[targetView.id] ?? CGPoint.zero
                        let anchorSize = viewSizes[targetView.id] ?? .zero
                        leftX = anchorPos.x + anchorSize.width / 2 + targetView.margins.trailing + child.margins.leading
                    }
                case .leftOf:
                    if let targetView = children.first(where: { $0.id == constraint.targetId }) {
                        let anchorPos = localPositions[targetView.id] ?? CGPoint.zero
                        let anchorSize = viewSizes[targetView.id] ?? .zero
                        rightX = anchorPos.x - anchorSize.width / 2 - targetView.margins.leading - child.margins.trailing
                    }
                case .parentTop:
                    topY = -containerSize.height / 2 + child.margins.top + parentPadding.top
                case .parentBottom:
                    bottomY = containerSize.height / 2 - child.margins.bottom - parentPadding.bottom
                case .alignTop:
                    if let targetView = children.first(where: { $0.id == constraint.targetId }) {
                        let anchorPos = localPositions[targetView.id] ?? CGPoint.zero
                        let anchorSize = viewSizes[targetView.id] ?? .zero
                        topY = anchorPos.y - anchorSize.height / 2 + child.margins.top
                    }
                case .alignBottom:
                    if let targetView = children.first(where: { $0.id == constraint.targetId }) {
                        let anchorPos = localPositions[targetView.id] ?? CGPoint.zero
                        let anchorSize = viewSizes[targetView.id] ?? .zero
                        bottomY = anchorPos.y + anchorSize.height / 2 - child.margins.bottom
                    }
                case .below:
                    if let targetView = children.first(where: { $0.id == constraint.targetId }) {
                        let anchorPos = localPositions[targetView.id] ?? CGPoint.zero
                        let anchorSize = viewSizes[targetView.id] ?? .zero
                        topY = anchorPos.y + anchorSize.height / 2 + targetView.margins.bottom + child.margins.top
                    }
                case .above:
                    if let targetView = children.first(where: { $0.id == constraint.targetId }) {
                        let anchorPos = localPositions[targetView.id] ?? CGPoint.zero
                        let anchorSize = viewSizes[targetView.id] ?? .zero
                        bottomY = anchorPos.y - anchorSize.height / 2 - targetView.margins.top - child.margins.bottom
                    }
                default:
                    break
                }
            }
            
            // Center between constraints if both sides are specified
            if let leftX = leftX, let rightX = rightX {
                x = (leftX + rightX) / 2
                Logger.debug("   Centered horizontally between \(leftX) and \(rightX): x = \(x)")
            }
            if let topY = topY, let bottomY = bottomY {
                y = (topY + bottomY) / 2
                Logger.debug("   Centered vertically between \(topY) and \(bottomY): y = \(y)")
            }
        }
        
        // For dynamic size, calculate the actual size based on constraints
        if dynamicWidth, let leftConstraint = child.constraints.first(where: { 
            [.parentLeft, .alignLeft, .rightOf].contains($0.type) 
        }), let rightConstraint = child.constraints.first(where: { 
            [.parentRight, .alignRight, .leftOf].contains($0.type) 
        }) {
            // Calculate available width between constraints
            var leftEdge: CGFloat = 0
            var rightEdge: CGFloat = 0
            
            switch leftConstraint.type {
            case .parentLeft:
                leftEdge = -containerSize.width / 2 + child.margins.leading + parentPadding.leading
            case .alignLeft:
                if let targetView = children.first(where: { $0.id == leftConstraint.targetId }) {
                    let anchorPos = localPositions[targetView.id] ?? CGPoint.zero
                    let anchorSize = viewSizes[targetView.id] ?? .zero
                    leftEdge = anchorPos.x - anchorSize.width / 2 + child.margins.leading
                }
            case .rightOf:
                if let targetView = children.first(where: { $0.id == leftConstraint.targetId }) {
                    let anchorPos = localPositions[targetView.id] ?? CGPoint.zero
                    let anchorSize = viewSizes[targetView.id] ?? .zero
                    leftEdge = anchorPos.x + anchorSize.width / 2 + targetView.margins.trailing + child.margins.leading
                }
            default:
                break
            }
            
            switch rightConstraint.type {
            case .parentRight:
                rightEdge = containerSize.width / 2 - child.margins.trailing - parentPadding.trailing
            case .alignRight:
                if let targetView = children.first(where: { $0.id == rightConstraint.targetId }) {
                    let anchorPos = localPositions[targetView.id] ?? CGPoint.zero
                    let anchorSize = viewSizes[targetView.id] ?? .zero
                    rightEdge = anchorPos.x + anchorSize.width / 2 - child.margins.trailing
                }
            case .leftOf:
                if let targetView = children.first(where: { $0.id == rightConstraint.targetId }) {
                    let anchorPos = localPositions[targetView.id] ?? CGPoint.zero
                    let anchorSize = viewSizes[targetView.id] ?? .zero
                    rightEdge = anchorPos.x - anchorSize.width / 2 - targetView.margins.leading - child.margins.trailing
                }
            default:
                break
            }
            
            let newWidth = abs(rightEdge - leftEdge)
            if newWidth > 0 {
                childSize.width = newWidth
                viewSizes[child.id] = childSize  // ローカルコピーを更新
                x = (leftEdge + rightEdge) / 2
                Logger.debug("   Dynamic width calculated: \(newWidth), x = \(x)")
            }
        }
        
        if dynamicHeight, let topConstraint = child.constraints.first(where: { 
            [.parentTop, .alignTop, .below].contains($0.type) 
        }), let bottomConstraint = child.constraints.first(where: { 
            [.parentBottom, .alignBottom, .above].contains($0.type) 
        }) {
            // Calculate available height between constraints
            var topEdge: CGFloat = 0
            var bottomEdge: CGFloat = 0
            
            switch topConstraint.type {
            case .parentTop:
                topEdge = -containerSize.height / 2 + child.margins.top + parentPadding.top
            case .alignTop:
                if let targetView = children.first(where: { $0.id == topConstraint.targetId }) {
                    let anchorPos = localPositions[targetView.id] ?? CGPoint.zero
                    let anchorSize = viewSizes[targetView.id] ?? .zero
                    topEdge = anchorPos.y - anchorSize.height / 2 + child.margins.top
                }
            case .below:
                if let targetView = children.first(where: { $0.id == topConstraint.targetId }) {
                    let anchorPos = localPositions[targetView.id] ?? CGPoint.zero
                    let anchorSize = viewSizes[targetView.id] ?? .zero
                    topEdge = anchorPos.y + anchorSize.height / 2 + targetView.margins.bottom + child.margins.top
                }
            default:
                break
            }
            
            switch bottomConstraint.type {
            case .parentBottom:
                bottomEdge = containerSize.height / 2 - child.margins.bottom - parentPadding.bottom
            case .alignBottom:
                if let targetView = children.first(where: { $0.id == bottomConstraint.targetId }) {
                    let anchorPos = localPositions[targetView.id] ?? CGPoint.zero
                    let anchorSize = viewSizes[targetView.id] ?? .zero
                    bottomEdge = anchorPos.y + anchorSize.height / 2 - child.margins.bottom
                }
            case .above:
                if let targetView = children.first(where: { $0.id == bottomConstraint.targetId }) {
                    let anchorPos = localPositions[targetView.id] ?? CGPoint.zero
                    let anchorSize = viewSizes[targetView.id] ?? .zero
                    bottomEdge = anchorPos.y - anchorSize.height / 2 - targetView.margins.top - child.margins.bottom
                }
            default:
                break
            }
            
            let newHeight = abs(bottomEdge - topEdge)
            if newHeight > 0 {
                childSize.height = newHeight
                viewSizes[child.id] = childSize  // ローカルコピーを更新
                y = (topEdge + bottomEdge) / 2
                Logger.debug("   Dynamic height calculated: \(newHeight), y = \(y)")
            }
        }
        
        Logger.debug("   Final position: (\(x), \(y))")

        return CGPoint(x: x, y: y)
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
                    targetId: ""
                )
            )
        } else {
            // Check individual parent alignment properties
            if dict["alignTop"] as? Bool == true {
                constraints.append(
                    RelativePositionConstraint(
                        type: .parentTop,
                        targetId: ""
                    )
                )
            } else if dict["alignBottom"] as? Bool == true {
                constraints.append(
                    RelativePositionConstraint(
                        type: .parentBottom,
                        targetId: ""
                    )
                )
            }
            
            if dict["alignLeft"] as? Bool == true {
                constraints.append(
                    RelativePositionConstraint(
                        type: .parentLeft,
                        targetId: ""
                    )
                )
            } else if dict["alignRight"] as? Bool == true {
                constraints.append(
                    RelativePositionConstraint(
                        type: .parentRight,
                        targetId: ""
                    )
                )
            }
            
            if dict["centerHorizontal"] as? Bool == true {
                constraints.append(
                    RelativePositionConstraint(
                        type: .parentCenterHorizontal,
                        targetId: ""
                    )
                )
            }
            
            if dict["centerVertical"] as? Bool == true {
                constraints.append(
                    RelativePositionConstraint(
                        type: .parentCenterVertical,
                        targetId: ""
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
                constraints.append(
                    RelativePositionConstraint(
                        type: type,
                        targetId: targetId
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
