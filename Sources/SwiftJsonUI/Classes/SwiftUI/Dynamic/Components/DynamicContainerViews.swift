//
//  DynamicContainerViews.swift
//  SwiftJsonUI
//
//  Dynamic container components
//

import SwiftUI

// MARK: - View Container
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
                let weight = child.weight ?? child.widthWeight ?? child.heightWeight ?? 0
                // width:0 または height:0 の場合もweightありとして扱う
                let hasZeroWidth = (child.width?.asArray.first == "0" || child.width?.asArray.first == "0.0")
                let hasZeroHeight = (child.height?.asArray.first == "0" || child.height?.asArray.first == "0.0")
                return weight > 0 || hasZeroWidth || hasZeroHeight
            }
            
            // 相対配置が必要かチェック
            let needsRelativePositioning = children.contains { child in
                child.alignParentTop == true || child.alignTop == true ||
                child.alignParentBottom == true || child.alignBottom == true ||
                child.alignParentLeft == true || child.alignLeft == true ||
                child.alignParentRight == true || child.alignRight == true ||
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
                        ChildView(component: child, viewModel: viewModel, viewId: viewId)
                    }
                }
            } else if orientation == "vertical" {
                // 通常のVStack
                VStack(alignment: getHorizontalAlignment(component.gravity), spacing: 0) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        ChildView(component: child, viewModel: viewModel, viewId: viewId)
                    }
                }
            } else {
                // orientationなし = ZStack
                ZStack(alignment: getZStackAlignment(component.gravity)) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        ChildView(component: child, viewModel: viewModel, viewId: viewId)
                    }
                }
            }
        }
    }
    
    private func getChildren() -> [DynamicComponent] {
        // childが存在する場合
        if let child = component.child {
            // 配列の場合
            if let componentArray = child.asDynamicComponentArray {
                return filterDataElements(componentArray)
            }
            // AnyCodableの配列の場合
            else if let anyCodableArray = child.value as? [AnyCodable] {
                var components: [DynamicComponent] = []
                for item in anyCodableArray {
                    if let comp = item.value as? DynamicComponent {
                        components.append(comp)
                    } else if let dict = item.value as? [String: Any] {
                        // data要素はスキップ（あとで実装）
                        if dict["data"] == nil && dict["type"] != nil {
                            // 通常のコンポーネントとして処理を試みる
                        }
                    }
                }
                return components
            }
            // 単一要素の場合
            else if let singleComponent = child.asDynamicComponent {
                return [singleComponent]
            }
            // 配列として直接入っている場合（ScrollViewなど）
            else if let array = child.value as? [DynamicComponent] {
                return filterDataElements(array)
            }
        }
        
        // childrenプロパティがある場合
        if let children = component.children {
            return filterDataElements(children)
        }
        
        return []
    }
    
    // data要素をフィルタリング（あとで実装）
    private func filterDataElements(_ components: [DynamicComponent]) -> [DynamicComponent] {
        return components.filter { comp in
            // typeがあるものだけを処理
            return !comp.type.isEmpty
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

// MARK: - Child View with Visibility
struct ChildView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    let viewId: String?
    
    @ViewBuilder
    var body: some View {
        // Visibility処理
        if component.visibility == "gone" || component.hidden == true {
            // goneまたはhiddenの場合は何も表示しない
            EmptyView()
        } else if component.visibility == "invisible" {
            // invisibleの場合は透明にして空間は維持
            DynamicComponentBuilder(component: component, viewModel: viewModel, viewId: viewId)
                .opacity(0)
        } else {
            // 通常表示
            DynamicComponentBuilder(component: component, viewModel: viewModel, viewId: viewId)
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
                    // width:0の場合はweightを使用
                    let hasZeroWidth = (child.width?.asArray.first == "0" || child.width?.asArray.first == "0.0")
                    let weight = hasZeroWidth ? 
                        CGFloat(child.weight ?? child.widthWeight ?? 1) :
                        CGFloat(child.weight ?? child.widthWeight ?? child.heightWeight ?? 0)
                    
                    return (
                        view: AnyView(
                            ChildView(component: child, viewModel: viewModel, viewId: viewId)
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
                    // height:0の場合はweightを使用
                    let hasZeroHeight = (child.height?.asArray.first == "0" || child.height?.asArray.first == "0.0")
                    let weight = hasZeroHeight ?
                        CGFloat(child.weight ?? child.heightWeight ?? 1) :
                        CGFloat(child.weight ?? child.widthWeight ?? child.heightWeight ?? 0)
                    
                    return (
                        view: AnyView(
                            ChildView(component: child, viewModel: viewModel, viewId: viewId)
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
                ForEach(Array(children.enumerated()), id: \.offset) { index, child in
                    ChildView(component: child, viewModel: viewModel, viewId: viewId)
                        .anchorPreference(key: BoundsPreferenceKey.self, value: .bounds) { [$0] }
                        .position(
                            calculatePosition(for: child, at: index, in: geometry.size)
                        )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    private func calculatePosition(for component: DynamicComponent, at index: Int, in size: CGSize) -> CGPoint {
        var x: CGFloat = size.width / 2
        var y: CGFloat = size.height / 2
        
        // 親に対する配置
        if component.alignParentLeft == true || component.alignLeft == true {
            x = 0
        } else if component.alignParentRight == true || component.alignRight == true {
            x = size.width
        } else if component.centerHorizontal == true || component.centerInParent == true {
            x = size.width / 2
        }
        
        if component.alignParentTop == true || component.alignTop == true {
            y = 0
        } else if component.alignParentBottom == true || component.alignBottom == true {
            y = size.height
        } else if component.centerVertical == true || component.centerInParent == true {
            y = size.height / 2
        }
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Bounds Preference Key
struct BoundsPreferenceKey: PreferenceKey {
    static var defaultValue: [Anchor<CGRect>] = []
    
    static func reduce(value: inout [Anchor<CGRect>], nextValue: () -> [Anchor<CGRect>]) {
        value.append(contentsOf: nextValue())
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
            // childを取得して処理
            if let child = component.child {
                // 配列の場合はViewでラップ
                if let array = child.value as? [Any] {
                    // 配列の場合はViewコンテナでラップ
                    let wrapperComponent = createWrapperComponent(with: array)
                    DynamicViewContainer(component: wrapperComponent, viewModel: viewModel, viewId: viewId)
                }
                // 単一要素の場合
                else if let singleComponent = child.asDynamicComponent {
                    DynamicComponentBuilder(component: singleComponent, viewModel: viewModel, viewId: viewId)
                }
                // 既にViewコンテナの場合
                else {
                    let wrapperComponent = createWrapperComponent(with: component.child)
                    DynamicViewContainer(component: wrapperComponent, viewModel: viewModel, viewId: viewId)
                }
            }
            // childrenの場合
            else if let children = component.children {
                let wrapperComponent = createWrapperComponent(withChildren: children)
                DynamicViewContainer(component: wrapperComponent, viewModel: viewModel, viewId: viewId)
            }
        }
    }
    
    private func createWrapperComponent(with child: AnyCodable?) -> DynamicComponent {
        return DynamicComponent(
            type: "View",
            id: nil,
            text: nil,
            fontSize: nil,
            fontColor: nil,
            font: nil,
            fontWeight: nil,
            width: Dynamic.single("matchParent"),
            height: nil,
            background: nil,
            padding: nil,
            margin: nil,
            margins: nil,
            paddings: nil,
            leftMargin: nil,
            rightMargin: nil,
            topMargin: nil,
            bottomMargin: nil,
            leftPadding: nil,
            rightPadding: nil,
            topPadding: nil,
            bottomPadding: nil,
            paddingLeft: nil,
            paddingRight: nil,
            paddingTop: nil,
            paddingBottom: nil,
            insets: nil,
            insetHorizontal: nil,
            cornerRadius: nil,
            borderWidth: nil,
            borderColor: nil,
            alpha: nil,
            opacity: nil,
            hidden: nil,
            visibility: nil,
            shadow: nil,
            clipToBounds: nil,
            minWidth: nil,
            maxWidth: nil,
            minHeight: nil,
            maxHeight: nil,
            aspectWidth: nil,
            aspectHeight: nil,
            userInteractionEnabled: nil,
            centerInParent: nil,
            weight: nil,
            child: child,
            children: nil,
            orientation: "vertical",
            contentMode: nil,
            url: nil,
            placeholder: nil,
            renderingMode: nil,
            headers: nil,
            items: nil,
            data: nil,
            hint: nil,
            hintColor: nil,
            hintFont: nil,
            flexible: nil,
            containerInset: nil,
            hideOnFocused: nil,
            action: nil,
            iconOn: nil,
            iconOff: nil,
            iconColor: nil,
            iconPosition: nil,
            textAlign: nil,
            selectedItem: nil,
            isOn: nil,
            progress: nil,
            value: nil,
            minValue: nil,
            maxValue: nil,
            indicatorStyle: nil,
            selectedIndex: nil,
            onClick: nil,
            onLongPress: nil,
            onAppear: nil,
            onDisappear: nil,
            onChange: nil,
            onSubmit: nil,
            onToggle: nil,
            onSelect: nil,
            include: nil,
            variables: nil,
            gravity: nil,
            widthWeight: nil,
            heightWeight: nil,
            alignParentTop: nil,
            alignParentBottom: nil,
            alignParentLeft: nil,
            alignParentRight: nil,
            alignTop: nil,
            alignBottom: nil,
            alignLeft: nil,
            alignRight: nil,
            centerHorizontal: nil,
            centerVertical: nil,
            alignLeftOf: nil,
            alignRightOf: nil,
            above: nil,
            below: nil
        )
    }
    
    private func createWrapperComponent(with array: [Any]) -> DynamicComponent {
        // 配列をAnyCodableとして格納
        let wrappedChild = AnyCodable(array)
        return createWrapperComponent(with: wrappedChild)
    }
    
    private func createWrapperComponent(withChildren children: [DynamicComponent]) -> DynamicComponent {
        var wrapper = createWrapperComponent(with: nil as AnyCodable?)
        return DynamicComponent(
            type: wrapper.type,
            id: wrapper.id,
            text: wrapper.text,
            fontSize: wrapper.fontSize,
            fontColor: wrapper.fontColor,
            font: wrapper.font,
            fontWeight: wrapper.fontWeight,
            width: wrapper.width,
            height: wrapper.height,
            background: wrapper.background,
            padding: wrapper.padding,
            margin: wrapper.margin,
            margins: wrapper.margins,
            paddings: wrapper.paddings,
            leftMargin: wrapper.leftMargin,
            rightMargin: wrapper.rightMargin,
            topMargin: wrapper.topMargin,
            bottomMargin: wrapper.bottomMargin,
            leftPadding: wrapper.leftPadding,
            rightPadding: wrapper.rightPadding,
            topPadding: wrapper.topPadding,
            bottomPadding: wrapper.bottomPadding,
            paddingLeft: wrapper.paddingLeft,
            paddingRight: wrapper.paddingRight,
            paddingTop: wrapper.paddingTop,
            paddingBottom: wrapper.paddingBottom,
            insets: wrapper.insets,
            insetHorizontal: wrapper.insetHorizontal,
            cornerRadius: wrapper.cornerRadius,
            borderWidth: wrapper.borderWidth,
            borderColor: wrapper.borderColor,
            alpha: wrapper.alpha,
            opacity: wrapper.opacity,
            hidden: wrapper.hidden,
            visibility: wrapper.visibility,
            shadow: wrapper.shadow,
            clipToBounds: wrapper.clipToBounds,
            minWidth: wrapper.minWidth,
            maxWidth: wrapper.maxWidth,
            minHeight: wrapper.minHeight,
            maxHeight: wrapper.maxHeight,
            aspectWidth: wrapper.aspectWidth,
            aspectHeight: wrapper.aspectHeight,
            userInteractionEnabled: wrapper.userInteractionEnabled,
            centerInParent: wrapper.centerInParent,
            weight: wrapper.weight,
            child: wrapper.child,
            children: children,
            orientation: wrapper.orientation,
            contentMode: wrapper.contentMode,
            url: wrapper.url,
            placeholder: wrapper.placeholder,
            renderingMode: wrapper.renderingMode,
            headers: wrapper.headers,
            items: wrapper.items,
            data: wrapper.data,
            hint: wrapper.hint,
            hintColor: wrapper.hintColor,
            hintFont: wrapper.hintFont,
            flexible: wrapper.flexible,
            containerInset: wrapper.containerInset,
            hideOnFocused: wrapper.hideOnFocused,
            action: wrapper.action,
            iconOn: wrapper.iconOn,
            iconOff: wrapper.iconOff,
            iconColor: wrapper.iconColor,
            iconPosition: wrapper.iconPosition,
            textAlign: wrapper.textAlign,
            selectedItem: wrapper.selectedItem,
            isOn: wrapper.isOn,
            progress: wrapper.progress,
            value: wrapper.value,
            minValue: wrapper.minValue,
            maxValue: wrapper.maxValue,
            indicatorStyle: wrapper.indicatorStyle,
            selectedIndex: wrapper.selectedIndex,
            onClick: wrapper.onClick,
            onLongPress: wrapper.onLongPress,
            onAppear: wrapper.onAppear,
            onDisappear: wrapper.onDisappear,
            onChange: wrapper.onChange,
            onSubmit: wrapper.onSubmit,
            onToggle: wrapper.onToggle,
            onSelect: wrapper.onSelect,
            include: wrapper.include,
            variables: wrapper.variables,
            gravity: wrapper.gravity,
            widthWeight: wrapper.widthWeight,
            heightWeight: wrapper.heightWeight,
            alignParentTop: wrapper.alignParentTop,
            alignParentBottom: wrapper.alignParentBottom,
            alignParentLeft: wrapper.alignParentLeft,
            alignParentRight: wrapper.alignParentRight,
            alignTop: wrapper.alignTop,
            alignBottom: wrapper.alignBottom,
            alignLeft: wrapper.alignLeft,
            alignRight: wrapper.alignRight,
            centerHorizontal: wrapper.centerHorizontal,
            centerVertical: wrapper.centerVertical,
            alignLeftOf: wrapper.alignLeftOf,
            alignRightOf: wrapper.alignRightOf,
            above: wrapper.above,
            below: wrapper.below
        )
    }
}