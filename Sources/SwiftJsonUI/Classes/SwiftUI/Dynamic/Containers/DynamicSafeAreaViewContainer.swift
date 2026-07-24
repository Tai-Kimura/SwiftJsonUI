//
//  DynamicSafeAreaViewContainer.swift
//  SwiftJsonUI
//
//  Dynamic mode equivalent of view_converter.rb for SafeAreaView type.
//  Same as DynamicViewContainer but applies safe area insets after modifiers.
//
//  Modifier order (matches view_converter.rb):
//    1. Container content (same as DynamicViewContainer)
//    2. applyStandardModifiers
//    3. gradient (if set)
//    4. safe area insets (safeAreaInsetPositions)
//

import SwiftUI
#if DEBUG


// MARK: - SafeAreaView Container
public struct DynamicSafeAreaViewContainer: View {
    let component: DynamicComponent
    let data: [String: Any]
    let viewId: String?

    public init(component: DynamicComponent, data: [String: Any], viewId: String? = nil) {
        self.component = component
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
        buildBody()
    }

    private func buildBody() -> AnyView {
        let children = getChildren()
        let orientation = component.orientation
        let needsRelativePositioning = orientation == nil &&
            RelativePositionConverter.childrenNeedRelativePositioning(children)

        // --- 1. Build container content ---
        var result: AnyView

        if children.isEmpty {
            result = AnyView(EmptyView())
        } else if needsRelativePositioning {
            result = AnyView(RelativePositioningContainer(
                children: children,
                parentComponent: component,
                data: childData,
                viewId: viewId
            ))
        } else {
            let hasWeights = children.contains { child in
                (child.weight ?? 0) > 0 || (child.widthWeight ?? 0) > 0 || (child.heightWeight ?? 0) > 0
            }

            if hasWeights && (orientation == "horizontal" || orientation == "vertical") {
                result = AnyView(
                    WeightedStackContainer(
                        orientation: orientation!,
                        children: children,
                        component: component,
                        data: childData,
                        viewId: viewId
                    )
                )
            } else if orientation == "horizontal" {
                let spacingValue = component.spacing ?? 0
                result = AnyView(
                    HStack(alignment: getVerticalAlignment(), spacing: spacingValue) {
                        ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                            DynamicComponentBuilder(
                                component: child,
                                data: childData,
                                viewId: viewId,
                                parentOrientation: "horizontal"
                            )
                        }
                    }
                )
            } else if orientation == "vertical" {
                let spacingValue = component.spacing ?? 0
                result = AnyView(
                    VStack(alignment: getHorizontalAlignment(), spacing: spacingValue) {
                        ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                            DynamicComponentBuilder(
                                component: child,
                                data: childData,
                                viewId: viewId,
                                parentOrientation: "vertical"
                            )
                        }
                    }
                )
            } else {
                result = AnyView(
                    ZStack(alignment: component.alignment ?? .topLeading) {
                        ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                            DynamicComponentBuilder(component: child, data: childData, viewId: viewId)
                        }
                    }
                )
            }
        }

        // --- 2. applyStandardModifiers ---
        result = DynamicModifierHelper.applyStandardModifiers(
            result,
            component: component,
            data: data,
            skipPadding: needsRelativePositioning
        )

        // --- 3. Safe area insets ---
        if let positions = component.rawData["safeAreaInsetPositions"] as? [String] {
            var edges: Edge.Set = []
            for pos in positions {
                switch pos.lowercased() {
                case "top": edges.insert(.top)
                case "bottom": edges.insert(.bottom)
                case "leading", "left": edges.insert(.leading)
                case "trailing", "right": edges.insert(.trailing)
                case "all": edges = .all
                default: break
                }
            }
            if !edges.isEmpty {
                result = AnyView(result.ignoresSafeArea(edges: edges))
            }
        }

        return result
    }

    private func getChildren() -> [DynamicComponent] {
        guard let children = component.childComponents else { return [] }
        return children.filter { $0.isValid || $0.include != nil }
    }

    private func getVerticalAlignment() -> VerticalAlignment {
        switch component.alignment {
        case .top, .topLeading, .topTrailing: return .top
        case .bottom, .bottomLeading, .bottomTrailing: return .bottom
        default: return .center
        }
    }

    private func getHorizontalAlignment() -> HorizontalAlignment {
        switch component.alignment {
        case .leading, .topLeading, .bottomLeading: return .leading
        case .trailing, .topTrailing, .bottomTrailing: return .trailing
        default: return .center
        }
    }
}
// MARK: - Force re-evaluation when data dictionary changes
extension DynamicSafeAreaViewContainer: Equatable {
    public static func == (lhs: DynamicSafeAreaViewContainer, rhs: DynamicSafeAreaViewContainer) -> Bool { false }
}
#endif // DEBUG
