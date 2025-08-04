//
//  DynamicTextView.swift
//  SwiftJsonUI
//
//  Dynamic text components
//

import SwiftUI

struct DynamicTextView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        Text(component.text ?? "")
            .font(DynamicHelpers.fontFromComponent(component))
            .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor))
            .multilineTextAlignment(DynamicHelpers.textAlignmentFromString(component.textAlign))
    }
}

struct DynamicButtonView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        Button(action: {
            viewModel.handleAction(component.action)
        }) {
            Text(component.text ?? "")
                .font(DynamicHelpers.fontFromComponent(component))
                .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor))
        }
    }
}