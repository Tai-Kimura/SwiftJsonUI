//
//  RelativePositioningContainer.swift
//  SwiftJsonUI
//
//  Relative positioning container using SwiftJsonUI's RelativePositionContainer
//

import SwiftUI
#if DEBUG


// MARK: - Relative Positioning Container
public struct RelativePositioningContainer: View {
    let children: [DynamicComponent]
    let parentComponent: DynamicComponent?
    let data: [String: Any]
    let viewId: String?

    public init(
        children: [DynamicComponent],
        parentComponent: DynamicComponent? = nil,
        data: [String: Any],
        viewId: String? = nil
    ) {
        self.children = children
        self.parentComponent = parentComponent
        self.data = data
        self.viewId = viewId
    }

    /// Data with weighted child flags stripped (for building children only).
    ///
    /// `__relativeMarginChild`: this container consumes each child's FULL
    /// individual margins when it computes the slot (RelativePositionConverter
    /// buildMargins → RelativePositionContainer), so the builder's own margin
    /// pass must not pad them again — inside the fixed, centre-anchored slot
    /// that padding shifted the content by half the asymmetric remainder
    /// (49-B: an anchor declared at (120,120) drew at (180,180)). Same
    /// ownership contract as `__zstackMarginChild`, full-ownership variant.
    /// A margin flag inherited from an outer container is for THIS view,
    /// not for the children — stripped, as `zstackChildData` construction
    /// assumes.
    private var childData: [String: Any] {
        var d = data
        d.removeValue(forKey: "__isWeightedChild")
        d.removeValue(forKey: "__weightedParentOrientation")
        d.removeValue(forKey: "__zstackMarginChild")
        d["__relativeMarginChild"] = true
        return d
    }

    public var body: some View {
        let childConfigs = children.enumerated().map { index, child in
            RelativePositionConverter.convert(
                component: child,
                index: index,
                viewBuilder: { component in
                    AnyView(
                        DynamicComponentBuilder(
                            component: component,
                            data: childData,
                            viewId: viewId
                        )
                        .id("\(component.id ?? "view")_\(index)")
                    )
                },
                data: childData
            )
        }

        let parentPadding = extractParentPadding()
        let backgroundColor = DynamicHelpers.getColor(
            parentComponent?.commonString(\.background), data: childData
        )

        let containerModes = RelativePositionConverter.containerSizeModes(for: parentComponent)

        RelativePositionContainer(
            children: childConfigs,
            alignment: .topLeading,
            backgroundColor: backgroundColor,
            parentPadding: parentPadding,
            containerWidthMode: containerModes.width,
            containerHeightMode: containerModes.height
        )
    }

    private func extractParentPadding() -> EdgeInsets {
        guard let parent = parentComponent else { return .init() }
        return DynamicHelpers.getPadding(from: parent)
    }
}
// MARK: - Force re-evaluation when data dictionary changes
extension RelativePositioningContainer: Equatable {
    public static func == (lhs: RelativePositioningContainer, rhs: RelativePositioningContainer) -> Bool { false }
}
#endif // DEBUG
