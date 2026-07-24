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

    /// Data with weighted child flags stripped (for building children only)
    private var childData: [String: Any] {
        var d = data
        d.removeValue(forKey: "__isWeightedChild")
        d.removeValue(forKey: "__weightedParentOrientation")
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
        let backgroundColor = parentComponent?.background != nil ?
            DynamicHelpers.getColor(parentComponent!.background) : nil

        RelativePositionContainer(
            children: childConfigs,
            alignment: .topLeading,
            backgroundColor: backgroundColor,
            parentPadding: parentPadding
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
