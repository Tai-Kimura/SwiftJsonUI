import SwiftUI

/// Container that manages relative positioning of child views using Layout protocol
@available(iOS 16.0, *)
public struct RelativePositionContainer: View {
    public let children: [RelativeChildConfig]
    public let alignment: Alignment
    public let backgroundColor: Color?
    public let parentPadding: EdgeInsets

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
        let _ = Logger.debug("[RelativePositionContainer] body called with \(children.count) children: \(children.map { $0.id })")
        RelativePositionLayout(
            children: children,
            alignment: alignment,
            parentPadding: parentPadding
        ) {
            ForEach(children) { child in
                child.view
                    .layoutValue(key: ChildIdKey.self, value: child.id)
            }
        }
        .background(backgroundColor ?? Color.clear)
    }
}

// Layout value key for passing child ID to layout
private struct ChildIdKey: LayoutValueKey {
    static let defaultValue: String = ""
}

/// Custom Layout that handles relative positioning
@available(iOS 16.0, *)
struct RelativePositionLayout: Layout {
    let children: [RelativeChildConfig]
    let alignment: Alignment
    let parentPadding: EdgeInsets

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let childIds = children.map { $0.id }
        Logger.debug("[RelativePositionLayout] sizeThatFits children=\(childIds), proposal: \(proposal.width ?? -1), \(proposal.height ?? -1)")

        // Check if any child has matchParent mode
        let hasWidthMatchParent = children.contains { if case .matchParent = $0.widthMode { return true } else { return false } }
        let hasHeightMatchParent = children.contains { if case .matchParent = $0.heightMode { return true } else { return false } }

        var width: CGFloat = 0
        var height: CGFloat = 0

        // If matchParent is used, take the proposed size
        if hasWidthMatchParent, let proposedWidth = proposal.width, proposedWidth > 0 && !proposedWidth.isInfinite {
            width = proposedWidth
        }
        if hasHeightMatchParent, let proposedHeight = proposal.height, proposedHeight > 0 && !proposedHeight.isInfinite {
            height = proposedHeight
        }

        // Calculate size from children (for wrapContent behavior)
        for (index, child) in children.enumerated() {
            guard index < subviews.count else { continue }
            let subview = subviews[index]
            let childId = subview[ChildIdKey.self]

            // Get child's natural size
            let childSize = subview.sizeThatFits(.unspecified)
            Logger.debug("[RelativePositionLayout] sizeThatFits child '\(childId)' naturalSize: \(childSize), widthMode: \(child.widthMode), heightMode: \(child.heightMode)")

            // Width calculation
            if !hasWidthMatchParent {
                var childWidth: CGFloat = 0
                switch child.widthMode {
                case .fixed(let fixedWidth):
                    childWidth = fixedWidth
                case .wrapContent:
                    if !childSize.width.isNaN && !childSize.width.isInfinite && childSize.width > 0 {
                        childWidth = childSize.width
                    }
                case .matchParent:
                    // Already handled above
                    break
                }
                childWidth += child.margins.leading + child.margins.trailing
                width = max(width, childWidth)
            }

            // Height calculation
            if !hasHeightMatchParent {
                var childHeight: CGFloat = 0
                switch child.heightMode {
                case .fixed(let fixedHeight):
                    childHeight = fixedHeight
                case .wrapContent:
                    if !childSize.height.isNaN && !childSize.height.isInfinite && childSize.height > 0 {
                        childHeight = childSize.height
                    }
                case .matchParent:
                    // Already handled above
                    break
                }
                childHeight += child.margins.top + child.margins.bottom
                height = max(height, childHeight)
            }
        }

        // Add parent padding
        width += parentPadding.leading + parentPadding.trailing
        height += parentPadding.top + parentPadding.bottom

        // Ensure we return valid values (minimum 1x1)
        let safeWidth = (width.isNaN || width.isInfinite || width <= 0) ? 100 : width
        let safeHeight = (height.isNaN || height.isInfinite || height <= 0) ? 100 : height

        Logger.debug("[RelativePositionLayout] sizeThatFits returning: \(safeWidth), \(safeHeight)")

        return CGSize(width: safeWidth, height: safeHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let childIds = children.map { $0.id }
        Logger.debug("[RelativePositionLayout] placeSubviews children=\(childIds), bounds: \(bounds)")

        // Guard against invalid bounds
        guard bounds.width > 0 && bounds.height > 0 &&
              !bounds.width.isNaN && !bounds.height.isNaN &&
              !bounds.width.isInfinite && !bounds.height.isInfinite else {
            Logger.debug("[RelativePositionLayout] placeSubviews: invalid bounds, returning early")
            return
        }

        // First, collect natural sizes for all subviews (for wrapContent and fixed modes only)
        // matchParent sizes will be calculated later based on positions
        var naturalSizes: [String: CGSize] = [:]
        for subview in subviews {
            let childId = subview[ChildIdKey.self]
            if !childId.isEmpty {
                let size = subview.sizeThatFits(.unspecified)
                naturalSizes[childId] = size
                Logger.debug("[RelativePositionLayout] placeSubviews child '\(childId)' naturalSize: \(size)")
            }
        }

        // Calculate initial sizes (wrapContent and fixed only, matchParent gets placeholder)
        var viewSizes: [String: CGSize] = [:]
        for child in children {
            let naturalSize = naturalSizes[child.id] ?? .zero

            var width: CGFloat = 0
            switch child.widthMode {
            case .matchParent:
                // Will be calculated based on constraints later
                width = bounds.width - child.margins.leading - child.margins.trailing
            case .wrapContent:
                width = (naturalSize.width.isNaN || naturalSize.width.isInfinite || naturalSize.width <= 0)
                    ? bounds.width : naturalSize.width
            case .fixed(let fixedWidth):
                width = fixedWidth
            }

            var height: CGFloat = 0
            switch child.heightMode {
            case .matchParent:
                // Will be calculated based on constraints later
                height = bounds.height - child.margins.top - child.margins.bottom
            case .wrapContent:
                height = (naturalSize.height.isNaN || naturalSize.height.isInfinite || naturalSize.height <= 0)
                    ? bounds.height : naturalSize.height
            case .fixed(let fixedHeight):
                height = fixedHeight
            }

            viewSizes[child.id] = CGSize(width: width, height: height)
            Logger.debug("[RelativePositionLayout] placeSubviews child '\(child.id)' initialSize: \(viewSizes[child.id]!), widthMode: \(child.widthMode), heightMode: \(child.heightMode)")
        }

        // Calculate positions based on constraints (this also updates matchParent sizes)
        let positions = calculatePositions(
            containerSize: bounds.size,
            viewSizes: &viewSizes
        )

        // Place each subview
        for subview in subviews {
            let childId = subview[ChildIdKey.self]
            if !childId.isEmpty {
                let size = viewSizes[childId] ?? CGSize(width: 10, height: 10)
                let relativePos = positions[childId] ?? .zero

                Logger.debug("[RelativePositionLayout] placeSubviews child '\(childId)' relativePos: \(relativePos), bounds.mid: (\(bounds.midX), \(bounds.midY))")

                // Convert relative position to absolute position
                let absoluteX = bounds.midX + relativePos.x
                let absoluteY = bounds.midY + relativePos.y

                Logger.debug("[RelativePositionLayout] placeSubviews child '\(childId)' absolutePos: (\(absoluteX), \(absoluteY))")

                // Guard against NaN/infinite - use center as fallback
                let safeX = (absoluteX.isNaN || absoluteX.isInfinite) ? bounds.midX : absoluteX
                let safeY = (absoluteY.isNaN || absoluteY.isInfinite) ? bounds.midY : absoluteY

                // Final validation
                let finalX = safeX.isNaN ? bounds.midX : safeX
                let finalY = safeY.isNaN ? bounds.midY : safeY

                Logger.debug("[RelativePositionLayout] placeSubviews child '\(childId)' finalPos: (\(finalX), \(finalY)), size: \(size)")

                subview.place(
                    at: CGPoint(x: finalX, y: finalY),
                    anchor: .center,
                    proposal: ProposedViewSize(size)
                )
            }
        }
    }

    private func calculatePositions(
        containerSize: CGSize,
        viewSizes: inout [String: CGSize]
    ) -> [String: CGPoint] {
        var localPositions: [String: CGPoint] = [:]

        // Process views in dependency order
        var processedViews = Set<String>()
        var remainingChildren = children

        // First, process views with only parent constraints OR no constraints (empty)
        let parentOnlyViews = children.filter { child in
            child.constraints.isEmpty || child.constraints.allSatisfy { constraint in
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
                viewSizes: &viewSizes
            )
            localPositions[child.id] = position
            processedViews.insert(child.id)
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
                let canProcess = child.constraints.isEmpty || child.constraints.allSatisfy { constraint in
                    if [.parentTop, .parentBottom, .parentLeft, .parentRight,
                        .parentCenterHorizontal, .parentCenterVertical, .parentCenter]
                        .contains(constraint.type) {
                        return true
                    }
                    return constraint.targetId.isEmpty || processedViews.contains(constraint.targetId)
                }

                if canProcess {
                    let position = calculateChildPosition(
                        child: child,
                        localPositions: localPositions,
                        containerSize: containerSize,
                        viewSizes: &viewSizes
                    )
                    localPositions[child.id] = position
                    processedViews.insert(child.id)
                    processedInThisIteration.append(child)
                }
            }

            remainingChildren.removeAll { view in
                processedInThisIteration.contains { $0.id == view.id }
            }

            if processedInThisIteration.isEmpty && !remainingChildren.isEmpty {
                // Circular dependency - process remaining anyway
                for child in remainingChildren {
                    let position = calculateChildPosition(
                        child: child,
                        localPositions: localPositions,
                        containerSize: containerSize,
                        viewSizes: &viewSizes
                    )
                    localPositions[child.id] = position
                }
                break
            }
        }

        return localPositions
    }

    private func calculateChildPosition(
        child: RelativeChildConfig,
        localPositions: [String: CGPoint],
        containerSize: CGSize,
        viewSizes: inout [String: CGSize]
    ) -> CGPoint {
        Logger.debug("[RelativePositionLayout] calculateChildPosition for '\(child.id)', constraints: \(child.constraints.map { "\($0.type):\($0.targetId)" })")

        var childSize = viewSizes[child.id] ?? .zero

        Logger.debug("[RelativePositionLayout] calculateChildPosition '\(child.id)' childSize: \(childSize), containerSize: \(containerSize)")

        // Guard against NaN/infinite sizes
        if childSize.width.isNaN || childSize.width.isInfinite {
            Logger.debug("[RelativePositionLayout] calculateChildPosition '\(child.id)' width is NaN/infinite, setting to 0")
            childSize.width = 0
        }
        if childSize.height.isNaN || childSize.height.isInfinite {
            Logger.debug("[RelativePositionLayout] calculateChildPosition '\(child.id)' height is NaN/infinite, setting to 0")
            childSize.height = 0
        }

        // Default position based on container alignment
        var x: CGFloat = 0
        var y: CGFloat = 0

        // Edge positions for matchParent calculation
        // These track where the view's edges should be positioned
        var topEdge: CGFloat? = nil      // If set, top edge is fixed at this position
        var bottomEdge: CGFloat? = nil   // If set, bottom edge is fixed at this position
        var leftEdge: CGFloat? = nil     // If set, left edge is fixed at this position
        var rightEdge: CGFloat? = nil    // If set, right edge is fixed at this position

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

        for constraint in child.constraints {
            let isParentConstraint = [
                .parentTop, .parentBottom, .parentLeft, .parentRight,
                .parentCenterHorizontal, .parentCenterVertical, .parentCenter,
            ].contains(constraint.type)

            var anchorChild: RelativeChildConfig? = nil
            var anchorSize = CGSize.zero

            if !isParentConstraint && !constraint.targetId.isEmpty {
                anchorChild = children.first { $0.id == constraint.targetId }
                if let anchor = anchorChild {
                    anchorSize = viewSizes[anchor.id] ?? .zero
                } else {
                    continue
                }
            }

            // Safe size calculations
            let safeAnchorWidth = (anchorSize.width.isNaN || anchorSize.width.isInfinite) ? 0 : anchorSize.width
            let safeAnchorHeight = (anchorSize.height.isNaN || anchorSize.height.isInfinite) ? 0 : anchorSize.height
            let safeChildWidth = (childSize.width.isNaN || childSize.width.isInfinite) ? 0 : childSize.width
            let safeChildHeight = (childSize.height.isNaN || childSize.height.isInfinite) ? 0 : childSize.height

            switch constraint.type {
            case .alignTop:
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? .zero : .zero
                y = anchorPos.y - safeAnchorHeight / 2 + safeChildHeight / 2 + child.margins.top
            case .alignBottom:
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? .zero : .zero
                y = anchorPos.y + safeAnchorHeight / 2 - safeChildHeight / 2 - child.margins.bottom
            case .alignLeft:
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? .zero : .zero
                x = anchorPos.x - safeAnchorWidth / 2 + safeChildWidth / 2 + child.margins.leading
            case .alignRight:
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? .zero : .zero
                x = anchorPos.x + safeAnchorWidth / 2 - safeChildWidth / 2 - child.margins.trailing
            case .above:
                let anchorTopMargin = anchorChild?.margins.top ?? 0
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? .zero : .zero
                let anchorTopY = anchorPos.y - safeAnchorHeight / 2 - anchorTopMargin
                // Child's bottom edge should be at anchor's top - child's bottom margin
                bottomEdge = anchorTopY - child.margins.bottom
                y = anchorPos.y - safeAnchorHeight / 2 - safeChildHeight / 2 - anchorTopMargin - child.margins.bottom
            case .below:
                let anchorBottomMargin = anchorChild?.margins.bottom ?? 0
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? .zero : .zero
                // Calculate anchor's bottom edge in absolute coordinates (relative to container center)
                let anchorBottomY = anchorPos.y + safeAnchorHeight / 2 + anchorBottomMargin
                // Child's top edge should be at anchor's bottom + child's top margin
                let childTopY = anchorBottomY + child.margins.top
                // Store the top edge position for later matchParent calculation
                topEdge = childTopY
                // Child center is at child's top + half of child's height (will be recalculated after matchParent)
                y = childTopY + safeChildHeight / 2
            case .leftOf:
                let anchorLeftMargin = anchorChild?.margins.leading ?? 0
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? .zero : .zero
                let anchorLeftX = anchorPos.x - safeAnchorWidth / 2 - anchorLeftMargin
                // Child's right edge should be at anchor's left - child's right margin
                rightEdge = anchorLeftX - child.margins.trailing
                x = anchorPos.x - safeAnchorWidth / 2 - safeChildWidth / 2 - anchorLeftMargin - child.margins.trailing
            case .rightOf:
                let anchorRightMargin = anchorChild?.margins.trailing ?? 0
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? .zero : .zero
                let anchorRightX = anchorPos.x + safeAnchorWidth / 2 + anchorRightMargin
                // Child's left edge should be at anchor's right + child's left margin
                leftEdge = anchorRightX + child.margins.leading
                x = anchorPos.x + safeAnchorWidth / 2 + safeChildWidth / 2 + anchorRightMargin + child.margins.leading
            case .centerVertical:
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? .zero : .zero
                y = anchorPos.y
            case .centerHorizontal:
                let anchorPos = anchorChild != nil ? localPositions[anchorChild!.id] ?? .zero : .zero
                x = anchorPos.x
            case .parentTop:
                topEdge = -containerSize.height / 2 + child.margins.top + parentPadding.top
                y = -containerSize.height / 2 + safeChildHeight / 2 + child.margins.top + parentPadding.top
            case .parentBottom:
                bottomEdge = containerSize.height / 2 - child.margins.bottom - parentPadding.bottom
                y = containerSize.height / 2 - safeChildHeight / 2 - child.margins.bottom - parentPadding.bottom
            case .parentLeft:
                leftEdge = -containerSize.width / 2 + child.margins.leading + parentPadding.leading
                x = -containerSize.width / 2 + safeChildWidth / 2 + child.margins.leading + parentPadding.leading
            case .parentRight:
                rightEdge = containerSize.width / 2 - child.margins.trailing - parentPadding.trailing
                x = containerSize.width / 2 - safeChildWidth / 2 - child.margins.trailing - parentPadding.trailing
            case .parentCenterHorizontal:
                x = 0
            case .parentCenterVertical:
                y = 0
            case .parentCenter:
                x = 0
                y = 0
            }
        }

        // Now handle matchParent size calculation based on edge constraints
        // This must happen after all constraints are processed
        if case .matchParent = child.widthMode {
            // Calculate available width based on edge constraints
            let containerLeft = -containerSize.width / 2 + child.margins.leading + parentPadding.leading
            let containerRight = containerSize.width / 2 - child.margins.trailing - parentPadding.trailing

            let effectiveLeft = leftEdge ?? containerLeft
            let effectiveRight = rightEdge ?? containerRight

            let availableWidth = effectiveRight - effectiveLeft
            if availableWidth > 0 {
                childSize.width = availableWidth
                // Center x between the edges
                x = (effectiveLeft + effectiveRight) / 2
                Logger.debug("[RelativePositionLayout] calculateChildPosition '\(child.id)' matchParent width: \(childSize.width), x: \(x)")
            }
        }

        if case .matchParent = child.heightMode {
            // Calculate available height based on edge constraints
            let containerTop = -containerSize.height / 2 + child.margins.top + parentPadding.top
            let containerBottom = containerSize.height / 2 - child.margins.bottom - parentPadding.bottom

            let effectiveTop = topEdge ?? containerTop
            let effectiveBottom = bottomEdge ?? containerBottom

            let availableHeight = effectiveBottom - effectiveTop
            if availableHeight > 0 {
                childSize.height = availableHeight
                // Center y between the edges
                y = (effectiveTop + effectiveBottom) / 2
                Logger.debug("[RelativePositionLayout] calculateChildPosition '\(child.id)' matchParent height: \(childSize.height), y: \(y)")
            }
        }

        // Update viewSizes with final calculated size
        viewSizes[child.id] = childSize

        Logger.debug("[RelativePositionLayout] calculateChildPosition '\(child.id)' raw result: (\(x), \(y)), size: \(childSize)")

        // Guard against NaN values
        let safeX = x.isNaN || x.isInfinite ? 0 : x
        let safeY = y.isNaN || y.isInfinite ? 0 : y

        if x.isNaN || x.isInfinite || y.isNaN || y.isInfinite {
            Logger.debug("[RelativePositionLayout] calculateChildPosition '\(child.id)' NaN/infinite detected! x.isNaN=\(x.isNaN), x.isInfinite=\(x.isInfinite), y.isNaN=\(y.isNaN), y.isInfinite=\(y.isInfinite)")
        }

        Logger.debug("[RelativePositionLayout] calculateChildPosition '\(child.id)' final result: (\(safeX), \(safeY))")

        return CGPoint(x: safeX, y: safeY)
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
                RelativePositionConstraint(type: .parentCenter, targetId: "")
            )
        } else {
            if dict["alignTop"] as? Bool == true {
                constraints.append(RelativePositionConstraint(type: .parentTop, targetId: ""))
            } else if dict["alignBottom"] as? Bool == true {
                constraints.append(RelativePositionConstraint(type: .parentBottom, targetId: ""))
            }

            if dict["alignLeft"] as? Bool == true {
                constraints.append(RelativePositionConstraint(type: .parentLeft, targetId: ""))
            } else if dict["alignRight"] as? Bool == true {
                constraints.append(RelativePositionConstraint(type: .parentRight, targetId: ""))
            }

            if dict["centerHorizontal"] as? Bool == true {
                constraints.append(RelativePositionConstraint(type: .parentCenterHorizontal, targetId: ""))
            }

            if dict["centerVertical"] as? Bool == true {
                constraints.append(RelativePositionConstraint(type: .parentCenterVertical, targetId: ""))
            }
        }

        // Check for alignment constraints to other views
        let constraintMappings: [(String, RelativePositionConstraint.ConstraintType)] = [
            ("alignTopOfView", .above),
            ("alignBottomOfView", .below),
            ("alignLeftOfView", .leftOf),
            ("alignRightOfView", .rightOf),
            ("alignTopView", .alignTop),
            ("alignBottomView", .alignBottom),
            ("alignLeftView", .alignLeft),
            ("alignRightView", .alignRight),
        ]

        for (key, type) in constraintMappings {
            if let targetId = dict[key] as? String {
                constraints.append(RelativePositionConstraint(type: type, targetId: targetId))
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
        if let width = dict["width"] as? Double, let height = dict["height"] as? Double {
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
