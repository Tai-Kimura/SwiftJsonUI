//
//  RelativePositioningContainer.swift
//  SwiftJsonUI
//
//  Relative positioning container using SwiftJsonUI's RelativePositionContainer
//

import SwiftUI

// MARK: - Relative Positioning Container
public struct RelativePositioningContainer: View {
    let children: [DynamicComponent]
    let parentComponent: DynamicComponent?
    let viewModel: DynamicViewModel  // Remove @ObservedObject to prevent rerendering
    let viewId: String?
    
    public init(
        children: [DynamicComponent],
        parentComponent: DynamicComponent? = nil,
        viewModel: DynamicViewModel,
        viewId: String? = nil
    ) {
        self.children = children
        self.parentComponent = parentComponent
        self.viewModel = viewModel
        self.viewId = viewId
    }
    
    public var body: some View {
        let _ = print("🎯 RelativePositioningContainer.body called: childCount=\(children.count), viewModel=\(ObjectIdentifier(viewModel))")
        // Convert DynamicComponents to RelativeChildConfigs
        // ビルダーを遅延評価にして、測定フェーズでのviewModel参照を避ける
        let childConfigs = children.enumerated().map { index, child in
            RelativePositionConverter.convert(
                component: child,
                index: index,
                viewBuilder: { component in
                    // ViewBuilderをAnyViewでラップ、viewModelの直接参照を避ける
                    AnyView(
                        DynamicComponentBuilder(
                            component: component, 
                            viewModel: viewModel, 
                            viewId: viewId
                        )
                        .id("\(component.id ?? "view")_\(index)")  // 安定したIDを付与
                    )
                }
            )
        }
        
        // Extract parent padding
        let parentPadding = extractParentPadding()
        
        // Extract parent background color
        let backgroundColor = parentComponent?.background != nil ? 
            DynamicHelpers.colorFromHex(parentComponent!.background) : nil
        
        // Use SwiftJsonUI's RelativePositionContainer
        RelativePositionContainer(
            children: childConfigs,
            alignment: .topLeading,
            backgroundColor: backgroundColor,
            parentPadding: parentPadding
        )
    }
    
    private func extractParentPadding() -> EdgeInsets {
        guard let parent = parentComponent else { return .init() }
        
        var topPadding: CGFloat = 0
        var leadingPadding: CGFloat = 0
        var bottomPadding: CGFloat = 0
        var trailingPadding: CGFloat = 0
        
        // Check padding or paddings array
        if let paddingValue = parent.padding ?? parent.paddings {
            if let paddingArray = paddingValue.value as? [Any] {
                // Handle array format [top, right, bottom, left] or [vertical, horizontal] or [all]
                switch paddingArray.count {
                case 1:
                    if let value = paddingArray[0] as? CGFloat {
                        topPadding = value
                        leadingPadding = value
                        bottomPadding = value
                        trailingPadding = value
                    } else if let value = paddingArray[0] as? Double {
                        topPadding = CGFloat(value)
                        leadingPadding = CGFloat(value)
                        bottomPadding = CGFloat(value)
                        trailingPadding = CGFloat(value)
                    }
                case 2:
                    // Vertical, Horizontal
                    if let vValue = paddingArray[0] as? CGFloat, let hValue = paddingArray[1] as? CGFloat {
                        topPadding = vValue
                        bottomPadding = vValue
                        leadingPadding = hValue
                        trailingPadding = hValue
                    } else if let vValue = paddingArray[0] as? Double, let hValue = paddingArray[1] as? Double {
                        topPadding = CGFloat(vValue)
                        bottomPadding = CGFloat(vValue)
                        leadingPadding = CGFloat(hValue)
                        trailingPadding = CGFloat(hValue)
                    }
                case 4:
                    // Top, Right, Bottom, Left
                    if let top = paddingArray[0] as? CGFloat,
                       let right = paddingArray[1] as? CGFloat,
                       let bottom = paddingArray[2] as? CGFloat,
                       let left = paddingArray[3] as? CGFloat {
                        topPadding = top
                        trailingPadding = right
                        bottomPadding = bottom
                        leadingPadding = left
                    } else if let top = paddingArray[0] as? Double,
                              let right = paddingArray[1] as? Double,
                              let bottom = paddingArray[2] as? Double,
                              let left = paddingArray[3] as? Double {
                        topPadding = CGFloat(top)
                        trailingPadding = CGFloat(right)
                        bottomPadding = CGFloat(bottom)
                        leadingPadding = CGFloat(left)
                    }
                default:
                    break
                }
            } else if let singleValue = paddingValue.value as? CGFloat {
                topPadding = singleValue
                leadingPadding = singleValue
                bottomPadding = singleValue
                trailingPadding = singleValue
            } else if let singleValue = paddingValue.value as? Double {
                topPadding = CGFloat(singleValue)
                leadingPadding = CGFloat(singleValue)
                bottomPadding = CGFloat(singleValue)
                trailingPadding = CGFloat(singleValue)
            }
        } else {
            // Check individual padding properties
            topPadding = parent.topPadding ?? parent.paddingTop ?? 0
            leadingPadding = parent.leftPadding ?? parent.paddingLeft ?? 0
            bottomPadding = parent.bottomPadding ?? parent.paddingBottom ?? 0
            trailingPadding = parent.rightPadding ?? parent.paddingRight ?? 0
        }
        
        return EdgeInsets(
            top: topPadding,
            leading: leadingPadding,
            bottom: bottomPadding,
            trailing: trailingPadding
        )
    }
}