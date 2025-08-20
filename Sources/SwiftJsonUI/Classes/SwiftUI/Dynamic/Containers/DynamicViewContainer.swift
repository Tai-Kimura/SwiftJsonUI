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
    
    private var processedChildren: [DynamicComponent] {
        let initialChildren = getChildren()
        
        // Apply direction to reverse children if needed
        if let direction = component.direction {
            switch direction.lowercased() {
            case "bottomtotop", "righttoleft":
                return initialChildren.reversed()
            default:
                return initialChildren
            }
        } else {
            return initialChildren
        }
    }
    
    @ViewBuilder
    public var body: some View {
        let children = processedChildren
        let _ = print("📦 DynamicViewContainer: id=\(component.id ?? "no-id"), type=\(component.type ?? "View"), orientation=\(component.orientation ?? "none"), direction=\(component.direction ?? "none"), childCount=\(children.count)")
        
        // Create the main content
        let mainContent = Group {
            // Wrap in StateAwareContainer if tapBackground is set
            if component.tapBackground != nil {
                StateAwareContainer(component: component) {
                    containerContent(children: children)
                }
            } else {
                containerContent(children: children)
            }
        }
        
        // Apply tap gesture if canTap is true
        let contentWithTap = if component.canTap == true {
            mainContent
                .contentShape(Rectangle()) // Make entire area tappable
                .onTapGesture {
                    // Handle tap action if onclick is defined
                    if let onclick = component.onclick ?? component.onClick {
                        viewModel.handleAction(onclick)
                    }
                }
        } else {
            mainContent
        }
        
        // Process data elements on appear to avoid state mutation during view update
        contentWithTap
            .onAppear {
                if let child = component.childComponents {
                    processDataElements(child)
                }
            }
    }
    
    @ViewBuilder
    private func containerContent(children: [DynamicComponent]) -> some View {
        
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
                RelativePositioningContainer(children: children, parentComponent: component, viewModel: viewModel, viewId: viewId)
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
                let hAlignment = getHorizontalAlignmentFromAlignment(component.alignment)
                HStack(alignment: getVerticalAlignmentFromAlignment(component.alignment), spacing: 0) {
                    // Add Spacer at beginning for trailing alignment
                    if hAlignment == .trailing {
                        Spacer(minLength: 0)
                    }
                    
                    ForEach(Array(children.enumerated()), id: \.offset) { index, child in
                        DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId, parentOrientation: "horizontal")
                        
                        // Add spacers between children based on distribution
                        if index < children.count - 1 {
                            if let distribution = component.distribution {
                                switch distribution.lowercased() {
                                case "fillequally", "equalspacing":
                                    Spacer(minLength: 0)
                                case "equalcentering":
                                    Spacer(minLength: 0)
                                default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                    
                    // Add Spacer at end for leading alignment
                    if hAlignment == .leading {
                        Spacer(minLength: 0)
                    }
                    // No Spacer for center alignment
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Apply ignoresSafeArea for regular View, but not for SafeAreaView
                .modifier(SafeAreaModifier(component: component))
            } else if orientation == "vertical" {
                // 通常のVStack
                let vAlignment = getVerticalAlignmentFromAlignment(component.alignment)
                VStack(alignment: getHorizontalAlignmentFromAlignment(component.alignment), spacing: 0) {
                    // Add Spacer at beginning for bottom alignment
                    if vAlignment == .bottom {
                        Spacer(minLength: 0)
                    }
                    
                    ForEach(Array(children.enumerated()), id: \.offset) { index, child in
                        DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId, parentOrientation: "vertical")
                        
                        // Add spacers between children based on distribution
                        if index < children.count - 1 {
                            if let distribution = component.distribution {
                                switch distribution.lowercased() {
                                case "fillequally", "equalspacing":
                                    Spacer(minLength: 0)
                                case "equalcentering":
                                    Spacer(minLength: 0)
                                default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                    
                    // Add Spacer at end for top alignment
                    if vAlignment == .top {
                        Spacer(minLength: 0)
                    }
                    // No Spacer for center alignment
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Apply ignoresSafeArea for regular View, but not for SafeAreaView
                .modifier(SafeAreaModifier(component: component))
            } else {
                // orientationなし = ZStack
                ZStack(alignment: component.alignment ?? .topLeading) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                    }
                }
                // Apply ignoresSafeArea for regular View, but not for SafeAreaView
                .modifier(SafeAreaModifier(component: component))
            }
        }
    }
    
    private func getChildren() -> [DynamicComponent] {
        // Use childComponents property which supports both 'child' and 'children'
        if let child = component.childComponents {
            // Debug: Print all child types
            for (index, comp) in child.enumerated() {
                print("📝 Child[\(index)]: type=\(comp.type ?? "nil"), id=\(comp.id ?? "no-id"), include=\(comp.include ?? "nil"), data=\(comp.data != nil)")
            }
            // Don't process data elements here - it modifies state during view update
            // processDataElements(child) // Removed to avoid state mutation
            // Then filter to get only valid components
            let filtered = filterDataElements(child)
            print("📝 Filtered children count: \(filtered.count)")
            
            // Debug: Print filtered children
            for (index, comp) in filtered.enumerated() {
                print("📝 Filtered[\(index)]: type=\(comp.type ?? "nil"), include=\(comp.include ?? "nil")")
            }
            
            return filtered
        }
        return []
    }
    
    // data要素を処理してからフィルタリング
    private func filterDataElements(_ components: [DynamicComponent]) -> [DynamicComponent] {
        return components.filter { comp in
            // typeがあるもの、またはincludeがあるものを処理
            let shouldInclude = comp.isValid || comp.include != nil
            if comp.include != nil {
                print("📍 Filtering: include=\(comp.include!), isValid=\(comp.isValid), shouldInclude=\(shouldInclude)")
            }
            return shouldInclude
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
                        // Check if value is provided in viewModel.data first
                        if let providedValue = viewModel.data[name] {
                            // Use the provided value from Include
                            viewModel.variables[name] = String(describing: providedValue)
                        } else {
                            // Use default value
                            viewModel.variables[name] = String(describing: defaultValue)
                        }
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
