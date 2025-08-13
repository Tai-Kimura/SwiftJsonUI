//
//  DynamicContainerViews.swift
//  SwiftJsonUI
//
//  Dynamic container components
//

import SwiftUI

struct DynamicViewContainer: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    let viewId: String?
    
    init(component: DynamicComponent, viewModel: DynamicViewModel, viewId: String? = nil) {
        self.component = component
        self.viewModel = viewModel
        self.viewId = viewId
    }
    
    @ViewBuilder
    var body: some View {
        let children = getChildren()
        
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
                (child.weight ?? child.widthWeight ?? child.heightWeight ?? 0) > 0
            }
            
            // 相対配置が必要かチェック
            let needsRelativePositioning = children.contains { child in
                child.alignParentTop == true ||
                child.alignParentBottom == true ||
                child.alignParentLeft == true ||
                child.alignParentRight == true ||
                child.centerInParent == true ||
                child.centerHorizontal == true ||
                child.centerVertical == true ||
                child.alignLeftOf != nil ||
                child.alignRightOf != nil ||
                child.above != nil ||
                child.below != nil
            }
            
            if needsRelativePositioning && orientation == nil {
                // 相対配置用のZStack
                RelativePositioningContainer(children: children, viewModel: viewModel, viewId: viewId)
            } else if hasWeights && (orientation == "horizontal" || orientation == "vertical") {
                // Weight対応のStack
                WeightedStackContainer(
                    orientation: orientation ?? "vertical",
                    children: children,
                    gravity: component.gravity,
                    viewModel: viewModel,
                    viewId: viewId
                )
            } else if orientation == "horizontal" {
                // 通常のHStack
                HStack(alignment: getVerticalAlignment(component.gravity), spacing: 0) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                    }
                }
            } else if orientation == "vertical" {
                // 通常のVStack
                VStack(alignment: getHorizontalAlignment(component.gravity), spacing: 0) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                    }
                }
            } else {
                // orientationなし = ZStack
                ZStack(alignment: getZStackAlignment(component.gravity)) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                    }
                }
            }
        }
    }
    
    private func getChildren() -> [DynamicComponent] {
        if let child = component.child {
            // Check if value is array of DynamicComponent directly
            if let componentArray = child.asDynamicComponentArray {
                return componentArray
            }
            // Check if value is array of AnyCodable (which may contain DynamicComponents and/or data objects)
            else if let anyCodableArray = child.value as? [AnyCodable] {
                var components: [DynamicComponent] = []
                for item in anyCodableArray {
                    if let comp = item.value as? DynamicComponent {
                        components.append(comp)
                    }
                }
                return components
            }
            // Check if single component
            else if let singleComponent = child.asDynamicComponent {
                return [singleComponent]
            }
        }
        
        if let children = component.children {
            return children
        }
        
        return []
    }
    
    private func getVerticalAlignment(_ gravity: String?) -> VerticalAlignment {
        switch gravity {
        case "top":
            return .top
        case "bottom":
            return .bottom
        case "center_vertical", "center":
            return .center
        default:
            return .center
        }
    }
    
    private func getHorizontalAlignment(_ gravity: String?) -> HorizontalAlignment {
        switch gravity {
        case "left", "start":
            return .leading
        case "right", "end":
            return .trailing
        case "center_horizontal", "center":
            return .center
        default:
            return .leading
        }
    }
    
    private func getZStackAlignment(_ gravity: String?) -> Alignment {
        switch gravity {
        case "top":
            return .top
        case "bottom":
            return .bottom
        case "left", "start":
            return .leading
        case "right", "end":
            return .trailing
        case "topLeft", "top|left":
            return .topLeading
        case "topRight", "top|right":
            return .topTrailing
        case "bottomLeft", "bottom|left":
            return .bottomLeading
        case "bottomRight", "bottom|right":
            return .bottomTrailing
        case "center":
            return .center
        default:
            return .center
        }
    }
}

// MARK: - Weighted Stack Container
struct WeightedStackContainer: View {
    let orientation: String
    let children: [DynamicComponent]
    let gravity: String?
    @ObservedObject var viewModel: DynamicViewModel
    let viewId: String?
    
    var body: some View {
        if orientation == "horizontal" {
            WeightedHStack(
                alignment: getVerticalAlignment(gravity),
                spacing: 0,
                children: children.map { child in
                    let weight = CGFloat(child.weight ?? child.widthWeight ?? child.heightWeight ?? 0)
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
                alignment: getHorizontalAlignment(gravity),
                spacing: 0,
                children: children.map { child in
                    let weight = CGFloat(child.weight ?? child.widthWeight ?? child.heightWeight ?? 0)
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
    
    private func getVerticalAlignment(_ gravity: String?) -> VerticalAlignment {
        switch gravity {
        case "top":
            return .top
        case "bottom":
            return .bottom
        case "center_vertical", "center":
            return .center
        default:
            return .center
        }
    }
    
    private func getHorizontalAlignment(_ gravity: String?) -> HorizontalAlignment {
        switch gravity {
        case "left", "start":
            return .leading
        case "right", "end":
            return .trailing
        case "center_horizontal", "center":
            return .center
        default:
            return .leading
        }
    }
}

// MARK: - Relative Positioning Container
struct RelativePositioningContainer: View {
    let children: [DynamicComponent]
    @ObservedObject var viewModel: DynamicViewModel
    let viewId: String?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                    DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                        .position(
                            x: calculateX(for: child, in: geometry.size),
                            y: calculateY(for: child, in: geometry.size)
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func calculateX(for component: DynamicComponent, in size: CGSize) -> CGFloat {
        if component.centerInParent == true || component.centerHorizontal == true {
            return size.width / 2
        } else if component.alignParentLeft == true {
            return 0
        } else if component.alignParentRight == true {
            return size.width
        }
        // デフォルトは中央
        return size.width / 2
    }
    
    private func calculateY(for component: DynamicComponent, in size: CGSize) -> CGFloat {
        if component.centerInParent == true || component.centerVertical == true {
            return size.height / 2
        } else if component.alignParentTop == true {
            return 0
        } else if component.alignParentBottom == true {
            return size.height
        }
        // デフォルトは中央
        return size.height / 2
    }
}

// MARK: - ScrollView Container
struct DynamicScrollViewContainer: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    let viewId: String?
    
    init(component: DynamicComponent, viewModel: DynamicViewModel, viewId: String? = nil) {
        self.component = component
        self.viewModel = viewModel
        self.viewId = viewId
    }
    
    @ViewBuilder
    var body: some View {
        ScrollView {
            // ScrollView内部はViewコンテナとして処理
            let innerComponent = DynamicComponent(
                type: "View",
                id: component.id,
                text: component.text,
                fontSize: component.fontSize,
                fontColor: component.fontColor,
                font: component.font,
                width: component.width,
                height: component.height,
                background: nil, // ScrollViewの背景は外側で処理
                padding: component.padding,
                margin: component.margin,
                margins: component.margins,
                paddings: component.paddings,
                leftMargin: component.leftMargin,
                rightMargin: component.rightMargin,
                topMargin: component.topMargin,
                bottomMargin: component.bottomMargin,
                leftPadding: component.leftPadding,
                rightPadding: component.rightPadding,
                topPadding: component.topPadding,
                bottomPadding: component.bottomPadding,
                paddingLeft: component.paddingLeft,
                paddingRight: component.paddingRight,
                paddingTop: component.paddingTop,
                paddingBottom: component.paddingBottom,
                insets: component.insets,
                insetHorizontal: component.insetHorizontal,
                cornerRadius: component.cornerRadius,
                borderWidth: component.borderWidth,
                borderColor: component.borderColor,
                alpha: component.alpha,
                hidden: component.hidden,
                visibility: component.visibility,
                shadow: component.shadow,
                clipToBounds: component.clipToBounds,
                minWidth: component.minWidth,
                maxWidth: component.maxWidth,
                minHeight: component.minHeight,
                maxHeight: component.maxHeight,
                aspectWidth: component.aspectWidth,
                aspectHeight: component.aspectHeight,
                userInteractionEnabled: component.userInteractionEnabled,
                centerInParent: component.centerInParent,
                weight: component.weight,
                child: component.child,
                children: component.children,
                orientation: component.orientation ?? "vertical",
                contentMode: component.contentMode,
                url: component.url,
                placeholder: component.placeholder,
                renderingMode: component.renderingMode,
                headers: component.headers,
                items: component.items,
                data: component.data,
                hint: component.hint,
                hintColor: component.hintColor,
                hintFont: component.hintFont,
                flexible: component.flexible,
                containerInset: component.containerInset,
                hideOnFocused: component.hideOnFocused,
                action: component.action,
                iconOn: component.iconOn,
                iconOff: component.iconOff,
                iconColor: component.iconColor,
                iconPosition: component.iconPosition,
                textAlign: component.textAlign,
                selectedItem: component.selectedItem,
                isOn: component.isOn,
                progress: component.progress,
                value: component.value,
                minValue: component.minValue,
                maxValue: component.maxValue,
                indicatorStyle: component.indicatorStyle,
                selectedIndex: component.selectedIndex,
                onClick: component.onClick,
                onLongPress: component.onLongPress,
                onAppear: component.onAppear,
                onDisappear: component.onDisappear,
                onChange: component.onChange,
                onSubmit: component.onSubmit,
                onToggle: component.onToggle,
                onSelect: component.onSelect,
                include: component.include,
                variables: component.variables,
                gravity: component.gravity,
                widthWeight: component.widthWeight,
                heightWeight: component.heightWeight,
                alignParentTop: component.alignParentTop,
                alignParentBottom: component.alignParentBottom,
                alignParentLeft: component.alignParentLeft,
                alignParentRight: component.alignParentRight,
                centerHorizontal: component.centerHorizontal,
                centerVertical: component.centerVertical,
                alignLeftOf: component.alignLeftOf,
                alignRightOf: component.alignRightOf,
                above: component.above,
                below: component.below
            )
            
            DynamicViewContainer(component: innerComponent, viewModel: viewModel, viewId: viewId)
        }
    }
}