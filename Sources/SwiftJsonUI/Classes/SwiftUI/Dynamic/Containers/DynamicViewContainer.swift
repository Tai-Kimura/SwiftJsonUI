//
//  DynamicViewContainer.swift
//  SwiftJsonUI
//
//  Dynamic View container component
//

import SwiftUI

// MARK: - View Container
public struct DynamicViewContainer: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    let viewId: String?
    
    public init(component: DynamicComponent, viewModel: DynamicViewModel, viewId: String? = nil) {
        self.component = component
        self.viewModel = viewModel
        self.viewId = viewId
    }
    
    @ViewBuilder
    public var body: some View {
        let children = getChildren()
        let _ = print("📦 DynamicViewContainer: id=\(component.id ?? "no-id"), orientation=\(component.orientation ?? "none"), childCount=\(children.count)")
        
        if children.isEmpty {
            // 子要素がない場合
            if component.background != nil {
                Rectangle()
                    .fill(DynamicHelpers.colorFromHex(component.background) ?? Color.clear)
            } else {
                EmptyView()
            }
        } else {
            // orientation と weight をチェック
            let orientation = component.orientation
            let hasWeights = children.contains { child in
                let weightValue = child.weight ?? 0
                let widthWeightValue = child.widthWeight ?? 0
                let heightWeightValue = child.heightWeight ?? 0
                let totalWeight = CGFloat(max(weightValue, widthWeightValue, heightWeightValue))
                // width:0 または height:0 の場合もweightありとして扱う
                let hasZeroWidth = child.width == 0
                let hasZeroHeight = child.height == 0
                return totalWeight > 0 || hasZeroWidth || hasZeroHeight
            }
            
            // 相対配置が必要かチェック
            let needsRelativePositioning = RelativePositionConverter.childrenNeedRelativePositioning(children)
            let hasConflictingAlignments = RelativePositionConverter.childrenHaveConflictingAlignments(children, parentOrientation: orientation)
            
            // 相対配置が必要な場合:
            // 1. orientationが指定されていない場合
            // 2. 子要素に競合するalignmentがある場合（orientationに関わらず）
            if needsRelativePositioning && (orientation == nil || hasConflictingAlignments) {
                // 相対配置用のZStack
                RelativePositioningContainer(children: children, viewModel: viewModel, viewId: viewId)
            } else if hasWeights && (orientation == "horizontal" || orientation == "vertical") {
                // Weight対応のStack
                WeightedStackContainer(
                    orientation: orientation ?? "vertical",
                    children: children,
                    alignment: component.alignment,
                    viewModel: viewModel,
                    viewId: viewId
                )
            } else if orientation == "horizontal" {
                // 通常のHStack
                HStack(alignment: getVerticalAlignmentFromAlignment(component.alignment), spacing: 0) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if orientation == "vertical" {
                // 通常のVStack
                VStack(alignment: getHorizontalAlignmentFromAlignment(component.alignment), spacing: 0) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // orientationなし = ZStack
                ZStack(alignment: component.alignment ?? .topLeading) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                    }
                }
            }
        }
    }
    
    private func getChildren() -> [DynamicComponent] {
        // child is always an array
        if let child = component.child {
            // Process data elements first
            processDataElements(child)
            // Then filter to get only valid components
            return filterDataElements(child)
        }
        return []
    }
    
    // data要素を処理してからフィルタリング
    private func filterDataElements(_ components: [DynamicComponent]) -> [DynamicComponent] {
        return components.filter { comp in
            // typeがあるものだけを処理（isValidプロパティを使用）
            return comp.isValid
        }
    }
    
    // data要素から変数を抽出して設定
    private func processDataElements(_ components: [DynamicComponent]) {
        for component in components {
            // data配列がある場合は変数として処理
            if let dataArray = component.data {
                for dataItem in dataArray {
                    if let dict = dataItem.value as? [String: Any],
                       let name = dict["name"] as? String,
                       let defaultValue = dict["defaultValue"] {
                        // ViewModelに変数を設定
                        viewModel.variables[name] = String(describing: defaultValue)
                    }
                }
            }
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
