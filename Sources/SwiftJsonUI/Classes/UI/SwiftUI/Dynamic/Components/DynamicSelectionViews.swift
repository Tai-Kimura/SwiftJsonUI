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
            items: SwiftUI.Binding(
                get: { component.items ?? [] },
                set: { _ in }
            ),
            selectedItem: SwiftUI.Binding(
                get: { viewModel.textFieldValues[id] ?? component.selectedItem ?? "" },
                set: { viewModel.textFieldValues[id] = $0 }
            ),
            selectItemType: .normal,
            datePickerStyle: .wheel,
            text: component.text ?? ""
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