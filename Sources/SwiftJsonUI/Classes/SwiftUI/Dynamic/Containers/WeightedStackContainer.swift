//
//  WeightedStackContainer.swift
//  SwiftJsonUI
//
//  Weighted stack container for dynamic layouts
//

import SwiftUI

// MARK: - Weighted Stack Container
public struct WeightedStackContainer: View {
    let orientation: String
    let children: [DynamicComponent]
    let alignment: Alignment?
    @ObservedObject var viewModel: DynamicViewModel
    let viewId: String?
    
    public init(
        orientation: String,
        children: [DynamicComponent],
        alignment: Alignment? = nil,
        viewModel: DynamicViewModel,
        viewId: String? = nil
    ) {
        self.orientation = orientation
        self.children = children
        self.alignment = alignment
        self.viewModel = viewModel
        self.viewId = viewId
    }
    
    public var body: some View {
        let _ = print("⚖️ WeightedStackContainer: orientation=\(orientation), childCount=\(children.count)")
        if orientation == "horizontal" {
            WeightedHStack(
                alignment: getVerticalAlignmentFromAlignment(alignment),
                spacing: 0,
                children: children.map { child in
                    // width:0の場合はweightを使用
                    let hasZeroWidth = child.width == 0
                    let weightValue = child.weight ?? 0
                    let widthWeightValue = child.widthWeight ?? 0
                    let heightWeightValue = child.heightWeight ?? 0
                    
                    let weight: CGFloat = hasZeroWidth ? 
                        CGFloat(max(weightValue, widthWeightValue, 1)) :
                        CGFloat(max(weightValue, widthWeightValue, heightWeightValue))
                    
                    return (
                        view: AnyView(
                            DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                        ),
                        weight: weight
                    )
                }
            )
        } else {
            WeightedVStack(
                alignment: getHorizontalAlignmentFromAlignment(alignment),
                spacing: 0,
                children: children.map { child in
                    // height:0の場合はweightを使用
                    let hasZeroHeight = child.height == 0
                    let weightValue = child.weight ?? 0
                    let widthWeightValue = child.widthWeight ?? 0
                    let heightWeightValue = child.heightWeight ?? 0
                    
                    let weight: CGFloat = hasZeroHeight ?
                        CGFloat(max(weightValue, heightWeightValue, 1)) :
                        CGFloat(max(weightValue, widthWeightValue, heightWeightValue))
                    
                    return (
                        view: AnyView(
                            DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                        ),
                        weight: weight
                    )
                }
            )
        }
    }
    
    private func getVerticalAlignmentFromAlignment(_ alignment: Alignment?) -> VerticalAlignment {
        switch alignment {
        case .top, .topLeading, .topTrailing:
            return .top
        case .bottom, .bottomLeading, .bottomTrailing:
            return .bottom
        case .center, .leading, .trailing:
            return .center
        default:
            return .top  // デフォルトはtop (topLeadingから)
        }
    }
    
    private func getHorizontalAlignmentFromAlignment(_ alignment: Alignment?) -> HorizontalAlignment {
        switch alignment {
        case .leading, .topLeading, .bottomLeading:
            return .leading
        case .trailing, .topTrailing, .bottomTrailing:
            return .trailing
        case .center, .top, .bottom:
            return .center
        default:
            return .leading  // デフォルトはleading (topLeadingから)
        }
    }
}