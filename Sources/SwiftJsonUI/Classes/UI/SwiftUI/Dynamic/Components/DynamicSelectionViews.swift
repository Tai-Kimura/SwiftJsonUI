//
//  DynamicSelectionViews.swift
//  SwiftJsonUI
//
//  Dynamic selection components
//

import SwiftUI

struct DynamicSelectBoxView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        let id = component.id ?? UUID().uuidString
        SelectBoxView(
            id: id,
            prompt: component.text,
            selectItemType: .normal,
            items: component.items ?? [],
            datePickerStyle: .wheel
        )
    }
}

struct DynamicSwitchView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        let id = component.id ?? UUID().uuidString
        Toggle(
            component.text ?? "",
            isOn: SwiftUI.Binding(
                get: { viewModel.toggleValues[id] ?? component.isOn ?? false },
                set: { viewModel.toggleValues[id] = $0 }
            )
        )
        .font(DynamicHelpers.fontFromComponent(component))
    }
}