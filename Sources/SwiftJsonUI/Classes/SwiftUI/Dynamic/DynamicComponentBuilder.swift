//
//  DynamicComponentBuilder.swift
//  SwiftJsonUI
//
//  Main component builder for dynamic views
//

import SwiftUI

// MARK: - Component Builder
public struct DynamicComponentBuilder: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    let viewId: String?
    
    public init(component: DynamicComponent, viewModel: DynamicViewModel, viewId: String? = nil) {
        self.component = component
        self.viewModel = viewModel
        self.viewId = viewId
    }
    
    public var body: some View {
        buildView(from: component)
            .applyDynamicModifiers(component)
            .dynamicEvents(component, viewModel: viewModel, viewId: viewId)
    }
    
    @ViewBuilder
    func buildView(from component: DynamicComponent) -> some View {
        let _ = Logger.debug("[DynamicComponentBuilder] Building view for type: \(component.type)")
        
        switch component.type {
        case "View":
            let _ = Logger.debug("[DynamicComponentBuilder] Creating DynamicViewContainer")
            DynamicViewContainer(component: component, viewModel: viewModel, viewId: viewId)
        case "Text", "Label":
            let _ = Logger.debug("[DynamicComponentBuilder] Creating DynamicTextView")
            DynamicTextView(component: component, viewModel: viewModel)
        case "Button":
            let _ = Logger.debug("[DynamicComponentBuilder] Creating DynamicButtonView")
            DynamicButtonView(component: component, viewModel: viewModel)
        case "TextField":
            DynamicTextFieldView(component: component, viewModel: viewModel)
        case "TextView":
            DynamicTextViewWrapper(component: component, viewModel: viewModel)
        case "Image":
            DynamicImageView(component: component, viewModel: viewModel)
        case "NetworkImage":
            DynamicNetworkImageView(component: component, viewModel: viewModel)
        case "SelectBox":
            DynamicSelectBoxView(component: component, viewModel: viewModel)
        case "IconLabel":
            DynamicIconLabelView(component: component, viewModel: viewModel)
        case "Collection":
            DynamicCollectionView(component: component, viewModel: viewModel)
        case "Table":
            DynamicTableView(component: component, viewModel: viewModel)
        case "ScrollView":
            DynamicScrollViewContainer(component: component, viewModel: viewModel, viewId: viewId)
        case "Switch":
            DynamicSwitchView(component: component, viewModel: viewModel)
        case "Toggle", "Check":
            DynamicToggleView(component: component, viewModel: viewModel)
        case "Checkbox":
            DynamicCheckboxView(component: component, viewModel: viewModel)
        case "Progress":
            DynamicProgressView(component: component, viewModel: viewModel)
        case "Slider":
            DynamicSliderView(component: component, viewModel: viewModel)
        case "Indicator":
            DynamicIndicatorView(component: component, viewModel: viewModel)
        case "Segment":
            DynamicSegmentView(component: component, viewModel: viewModel)
        case "Radio":
            DynamicRadioView(component: component, viewModel: viewModel)
        case "Web", "WebView":
            DynamicWebView(component: component, viewModel: viewModel)
        case "CircleImage":
            DynamicCircleImageView(component: component, viewModel: viewModel)
        case "GradientView":
            DynamicGradientView(component: component, viewModel: viewModel)
        case "Blur", "BlurView":
            DynamicBlurView(component: component, viewModel: viewModel)
        case "TabView":
            DynamicTabView(component: component, viewModel: viewModel)
        case "SafeAreaView":
            DynamicSafeAreaView(component: component, viewModel: viewModel)
        default:
            EmptyView()
        }
    }
}