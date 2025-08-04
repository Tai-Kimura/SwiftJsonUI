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
        switch component.type {
        case "View":
            DynamicViewContainer(component: component, viewModel: viewModel, viewId: viewId)
        case "Text", "Label":
            DynamicTextView(component: component, viewModel: viewModel)
        case "Button":
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
        default:
            EmptyView()
        }
    }
}