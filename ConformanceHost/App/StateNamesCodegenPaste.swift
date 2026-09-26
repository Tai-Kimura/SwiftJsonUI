//
//  StateNamesCodegenPaste.swift
//  ConformanceHost
//
//  What `sjui build` (sjui_tools of jsonui-cli rel/v1.8.121 = 621d3136) emits for
//  StateNamesProbeView's layout — id-less stateful controls in pairs, two
//  Radio groups, two Radios over items — the generated Data struct, the
//  view-local state, the body and its sections, pasted unchanged but for any
//  state declared twice under one name with different seeds: the second does
//  not compile beside the first ("invalid redeclaration"), so it is left out
//  where it was, with a note, and every reference goes to the first. For ticket
//  sjui-codegen-state-declarations-collide-by-name.
//

import SwiftUI
import SwiftJsonUI

struct StateNamesData {
    // Data properties from JSON
    var selectedH: String = ""
    var selectedRadiogroup: String = ""
    var selectedG: String = ""

    // Update properties from dictionary
    mutating func update(dictionary: [String: Any]) {
        if let value = dictionary["selectedH"] {
            if let stringValue = value as? String {
                self.selectedH = stringValue
            }
        }
        if let value = dictionary["selectedRadiogroup"] {
            if let stringValue = value as? String {
                self.selectedRadiogroup = stringValue
            }
        }
        if let value = dictionary["selectedG"] {
            if let stringValue = value as? String {
                self.selectedG = stringValue
            }
        }
    }

    // Convert properties to dictionary for Dynamic mode
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Data properties
        dict["selectedH"] = selectedH
        dict["selectedRadiogroup"] = selectedRadiogroup
        dict["selectedG"] = selectedG
        
        return dict
    }

    #if DEBUG
    // Convert properties to binding dictionary for Dynamic mode reactivity
    // SwiftUI.Binding<T> values enable automatic re-rendering on changes
    func toDictionary(binding dataBinding: SwiftUI.Binding<StateNamesData>) -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Data properties as SwiftUI.Binding for reactivity
        dict["selectedH"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.selectedH },
            set: { dataBinding.wrappedValue.selectedH = $0 }
        )
        dict["selectedRadiogroup"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.selectedRadiogroup },
            set: { dataBinding.wrappedValue.selectedRadiogroup = $0 }
        )
        dict["selectedG"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.selectedG },
            set: { dataBinding.wrappedValue.selectedG = $0 }
        )
        
        return dict
    }
    #endif
}

struct StateNamesCodegenPaste: View {
    @SwiftUI.Binding var data: StateNamesData
    @State private var toggleIsOn: Bool = false
    @State private var checkboxIsOn: Bool = false
    @State private var selectedSegment: Int = 0
    @State private var sliderValue: Double = 0.2
    @State private var textFieldText: String = "t"
    @State private var selectedH: String = ""
    @State private var selectedRadio: String = "i1"
    // (a second `@State private var selectedRadio: String = "j1"` here — left out, see the header)
    @State private var selectedG: String = "radio"
    // (a second `@State private var selectedG: String = ""` here — left out, see the header)

    var body: some View {
            AnyView(section0())
    }

    @ViewBuilder private func section0() -> some View {
        VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: $toggleIsOn) {
                    Text("")
                }
                    .labelsHidden()
                Toggle(isOn: $toggleIsOn) {
                    Text("")
                }
                    .labelsHidden()
                CheckBoxView(
                    isOn: $checkboxIsOn,
                    label: "c1",
                )
                CheckBoxView(
                    isOn: $checkboxIsOn,
                    label: "c2",
                )
                Picker("", selection: $selectedSegment) {
                    Text("a1".localized()).tag(0)
                    Text("a2".localized()).tag(1)
                }
                    .pickerStyle(.segmented)
                Picker("", selection: $selectedSegment) {
                    Text("b1".localized()).tag(0)
                    Text("b2".localized()).tag(1)
                }
                    .pickerStyle(.segmented)
                Slider(value: $sliderValue, in: 0...1)
                Slider(value: $sliderValue, in: 0...1)
                TextField("", text: $textFieldText)
                    .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
                TextField("", text: $textFieldText)
                    .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
                HStack {
                    Image(systemName: selectedH == "radio" ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(.blue)
                        .onTapGesture {
                        selectedH = "radio"
                    }
                    Text("h1")
                }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("h1")
                HStack {
                    Image(systemName: selectedH == "radio" ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(.blue)
                        .onTapGesture {
                        selectedH = "radio"
                    }
                    Text("h2")
                }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("h2")
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: selectedRadio == "i1" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedRadio = "i1"
                        }
                        Text("i1")
                    }
                    HStack {
                        Image(systemName: selectedRadio == "i2" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedRadio = "i2"
                        }
                        Text("i2")
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: selectedRadio == "j1" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedRadio = "j1"
                        }
                        Text("j1")
                    }
                    HStack {
                        Image(systemName: selectedRadio == "j2" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedRadio = "j2"
                        }
                        Text("j2")
                    }
                }
                HStack {
                    Image(systemName: selectedG == "radio" ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(.blue)
                        .onTapGesture {
                        selectedG = "radio"
                    }
                    Text("g1")
                }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("g1")
                HStack {
                    Image(systemName: selectedG == "radio" ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(.blue)
                        .onTapGesture {
                        selectedG = "radio"
                    }
                    Text("g2")
                }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("g2")
        }
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
