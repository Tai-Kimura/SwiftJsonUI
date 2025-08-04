//
//  DynamicTextInputViews.swift
//  SwiftJsonUI
//
//  Dynamic text input components
//

import SwiftUI

struct DynamicTextFieldView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        let id = component.id ?? UUID().uuidString
        TextField(
            component.hint ?? component.text ?? "",
            text: Binding(
                get: { viewModel.textFieldValues[id] ?? "" },
                set: { newValue in
                    viewModel.textFieldValues[id] = newValue
                    // onChange イベント
                    if let onChange = component.onChange {
                        let context = DynamicEventContext(
                            componentId: id,
                            eventType: .onChange,
                            action: onChange,
                            value: newValue,
                            component: component,
                            viewModel: viewModel
                        )
                        DynamicEventManager.shared.handleEvent(context)
                    }
                }
            )
        )
        .font(DynamicHelpers.fontFromComponent(component))
        .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor))
        .onSubmit {
            // onSubmit イベント
            if let onSubmit = component.onSubmit {
                let context = DynamicEventContext(
                    componentId: id,
                    eventType: .onSubmit,
                    action: onSubmit,
                    value: viewModel.textFieldValues[id],
                    component: component,
                    viewModel: viewModel
                )
                DynamicEventManager.shared.handleEvent(context)
            }
        }
    }
}

struct DynamicTextViewWrapper: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        let id = component.id ?? UUID().uuidString
        TextViewWithPlaceholder(
            text: Binding(
                get: { viewModel.textFieldValues[id] ?? "" },
                set: { viewModel.textFieldValues[id] = $0 }
            ),
            hint: component.hint,
            hintColor: DynamicHelpers.colorFromHex(component.hintColor) ?? Color.gray.opacity(0.6),
            hintFont: component.hintFont,
            hideOnFocused: component.hideOnFocused ?? true,
            fontSize: component.fontSize ?? 16,
            fontColor: DynamicHelpers.colorFromHex(component.fontColor) ?? .primary,
            fontName: component.font,
            backgroundColor: DynamicHelpers.colorFromHex(component.background) ?? Color(UIColor.systemBackground),
            cornerRadius: component.cornerRadius ?? 0,
            containerInset: DynamicHelpers.paddingFromArray(component.containerInset),
            flexible: component.flexible ?? false,
            minHeight: component.minHeight,
            maxHeight: component.maxHeight
        )
    }
}