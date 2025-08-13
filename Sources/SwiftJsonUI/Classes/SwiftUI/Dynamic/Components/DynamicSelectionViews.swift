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

struct DynamicToggleView: View {
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

struct DynamicCheckboxView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        let id = component.id ?? UUID().uuidString
        HStack {
            Image(systemName: (viewModel.toggleValues[id] ?? component.isOn ?? false) ? "checkmark.square.fill" : "square")
                .foregroundColor((viewModel.toggleValues[id] ?? component.isOn ?? false) ? .accentColor : .gray)
                .onTapGesture {
                    viewModel.toggleValues[id] = !(viewModel.toggleValues[id] ?? component.isOn ?? false)
                }
            if let text = component.text {
                Text(text)
                    .font(DynamicHelpers.fontFromComponent(component))
            }
        }
    }
}

struct DynamicProgressView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        let id = component.id ?? UUID().uuidString
        let value = viewModel.progressValues[id] ?? component.progress ?? 0.0
        
        VStack(alignment: .leading, spacing: 4) {
            if let text = component.text {
                Text(text)
                    .font(DynamicHelpers.fontFromComponent(component))
            }
            ProgressView(value: value, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
        }
    }
}

struct DynamicSliderView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        let id = component.id ?? UUID().uuidString
        let minValue = component.minValue ?? 0.0
        let maxValue = component.maxValue ?? 1.0
        
        VStack(alignment: .leading, spacing: 4) {
            if let text = component.text {
                Text(text)
                    .font(DynamicHelpers.fontFromComponent(component))
            }
            Slider(
                value: SwiftUI.Binding(
                    get: { viewModel.sliderValues[id] ?? component.value ?? minValue },
                    set: { viewModel.sliderValues[id] = $0 }
                ),
                in: minValue...maxValue
            )
        }
    }
}

struct DynamicIndicatorView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        VStack {
            if component.indicatorStyle == "circular" {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                ProgressView()
            }
            if let text = component.text {
                Text(text)
                    .font(DynamicHelpers.fontFromComponent(component))
                    .padding(.top, 4)
            }
        }
    }
}

struct DynamicSegmentView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        let id = component.id ?? UUID().uuidString
        let items = component.items ?? []
        
        VStack(alignment: .leading) {
            if let text = component.text {
                Text(text)
                    .font(DynamicHelpers.fontFromComponent(component))
            }
            Picker("", selection: SwiftUI.Binding(
                get: { viewModel.selectedSegments[id] ?? component.selectedIndex ?? 0 },
                set: { viewModel.selectedSegments[id] = $0 }
            )) {
                ForEach(0..<items.count, id: \.self) { index in
                    Text(items[index])
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

struct DynamicRadioView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        let id = component.id ?? UUID().uuidString
        let items = component.items ?? []
        
        VStack(alignment: .leading, spacing: 8) {
            if let text = component.text {
                Text(text)
                    .font(DynamicHelpers.fontFromComponent(component))
            }
            ForEach(0..<items.count, id: \.self) { index in
                HStack {
                    Image(systemName: (viewModel.selectedRadios[id] ?? component.selectedIndex ?? 0) == index ? "largecircle.fill.circle" : "circle")
                        .foregroundColor((viewModel.selectedRadios[id] ?? component.selectedIndex ?? 0) == index ? .accentColor : .gray)
                        .onTapGesture {
                            viewModel.selectedRadios[id] = index
                        }
                    Text(items[index])
                        .font(DynamicHelpers.fontFromComponent(component))
                }
            }
        }
    }
}