//
//  WeightedStackContainer.swift
//  SwiftJsonUI
//
//  Dynamic mode equivalent of view_converter.rb WeightedStack handling.
//  Creates WeightedHStack/WeightedVStack matching tool-generated code exactly.
//

import SwiftUI
#if DEBUG


// MARK: - Weighted Stack Container
public struct WeightedStackContainer: View {
    let orientation: String
    let children: [DynamicComponent]
    let component: DynamicComponent
    let data: [String: Any]
    let viewId: String?

    public init(
        orientation: String,
        children: [DynamicComponent],
        component: DynamicComponent,
        data: [String: Any],
        viewId: String? = nil
    ) {
        self.orientation = orientation
        self.children = children
        self.component = component
        self.data = data
        self.viewId = viewId
    }

    // Build children array with weights for horizontal orientation
    private func buildHorizontalChildren() -> [(view: AnyView, weight: CGFloat)] {
        children.map { child in
            let weightValue = child.weight ?? 0
            let widthWeightValue = child.widthWeight ?? 0
            let weight = CGFloat(max(weightValue, widthWeightValue))

            var childData = data
            if weight > 0 {
                childData["__isWeightedChild"] = true
                childData["__weightedParentOrientation"] = "horizontal"
            }

            let builtView = AnyView(
                DynamicComponentBuilder(
                    component: child,
                    data: childData,
                    viewId: viewId,
                    isWeightedChild: weight > 0,
                    parentOrientation: "horizontal"
                )
            )
            // weight==0 AND width is wrapContent → fixedSize to shrink to intrinsic width
            let needsFixedSize = weight == 0 && child.width == nil
            let childView = needsFixedSize
                ? AnyView(builtView.fixedSize(horizontal: true, vertical: false))
                : builtView
            return (view: childView, weight: weight)
        }
    }

    // Build children array with weights for vertical orientation
    private func buildVerticalChildren() -> [(view: AnyView, weight: CGFloat)] {
        children.map { child in
            let weightValue = child.weight ?? 0
            let heightWeightValue = child.heightWeight ?? 0
            let weight = CGFloat(max(weightValue, heightWeightValue))

            var childData = data
            if weight > 0 {
                childData["__isWeightedChild"] = true
                childData["__weightedParentOrientation"] = "vertical"
            }

            let builtView = AnyView(
                DynamicComponentBuilder(
                    component: child,
                    data: childData,
                    viewId: viewId,
                    isWeightedChild: weight > 0,
                    parentOrientation: "vertical"
                )
            )
            // weight==0 AND height is wrapContent → fixedSize to shrink to intrinsic height
            let needsFixedSize = weight == 0 && child.height == nil
            let childView = needsFixedSize
                ? AnyView(builtView.fixedSize(horizontal: false, vertical: true))
                : builtView
            return (view: childView, weight: weight)
        }
    }

    public var body: some View {
        let spacingValue = component.spacing ?? 0

        // Use Layout protocol directly for proper weight distribution.
        // Add .fixedSize on the cross-axis so the layout reports intrinsic height/width
        // instead of accepting the parent's proposed size (which would make it expand).
        // .layoutWeight() must be applied OUTSIDE AnyView for LayoutValueKey to work.
        if orientation == "horizontal" {
            let builtChildren = buildHorizontalChildren()
            let hasMatchParentHeight = children.contains { $0.height == .infinity || $0.height == -1 }
            WeightedHStackLayout(alignment: getVerticalAlignment(), spacing: spacingValue) {
                ForEach(0..<builtChildren.count, id: \.self) { index in
                    builtChildren[index].view
                        .layoutWeight(builtChildren[index].weight)
                }
            }
            .fixedSize(horizontal: false, vertical: !hasMatchParentHeight)
        } else {
            let builtChildren = buildVerticalChildren()
            WeightedVStackLayout(alignment: getHorizontalAlignment(), spacing: spacingValue) {
                ForEach(0..<builtChildren.count, id: \.self) { index in
                    builtChildren[index].view
                        .layoutWeight(builtChildren[index].weight)
                }
            }
        }
    }

    private func getVerticalAlignment() -> VerticalAlignment {
        guard let alignment = component.alignment else { return .top }
        switch alignment {
        case .top, .topLeading, .topTrailing: return .top
        case .bottom, .bottomLeading, .bottomTrailing: return .bottom
        case .center, .leading, .trailing: return .center
        default: return .top
        }
    }

    private func getHorizontalAlignment() -> HorizontalAlignment {
        guard let alignment = component.alignment else { return .leading }
        switch alignment {
        case .leading, .topLeading, .bottomLeading: return .leading
        case .trailing, .topTrailing, .bottomTrailing: return .trailing
        case .center, .top, .bottom: return .center
        default: return .leading
        }
    }
}
// MARK: - Force re-evaluation when data dictionary changes
extension WeightedStackContainer: Equatable {
    public static func == (lhs: WeightedStackContainer, rhs: WeightedStackContainer) -> Bool { false }
}
#endif // DEBUG
