//
//  StateNamesCodegenPaste.swift
//  ConformanceHost
//
//  What `sjui build` (sjui_tools of jsonui-cli triage/state-names-by-path a04c876f, on rel/v1.8.121 = 621d3136) emits for
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
    @State private var toggle_0_0IsOn: Bool = false
    @State private var toggle_0_1IsOn: Bool = false
    @State private var checkbox_0_2IsOn: Bool = false
    @State private var checkbox_0_3IsOn: Bool = false
    @State private var selectedSegment_0_4: Int = 0
    @State private var selectedSegment_0_5: Int = 0
    @State private var slider_0_6Value: Double = 0.2
    @State private var slider_0_7Value: Double = 0.2
    @State private var textField_0_8Text: String = "t"
    @State private var textField_0_9Text: String = "t"
    @State private var selectedH: String = ""
    @State private var selectedRadio_0_12: String = "i1"
    @State private var selectedRadio_0_13: String = "j1"
    @State private var selectedG: String = "radio_0_14"

    var body: some View {
            AnyView(section0())
    }

    @ViewBuilder private func section0() -> some View {
        VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: $toggle_0_0IsOn) {
                    Text("")
                }
                    .labelsHidden()
                Toggle(isOn: $toggle_0_1IsOn) {
                    Text("")
                }
                    .labelsHidden()
                CheckBoxView(
                    isOn: $checkbox_0_2IsOn,
                    label: "c1",
                )
                CheckBoxView(
                    isOn: $checkbox_0_3IsOn,
                    label: "c2",
                )
                Picker("", selection: $selectedSegment_0_4) {
                    Text("a1".localized()).tag(0)
                    Text("a2".localized()).tag(1)
                }
                    .pickerStyle(.segmented)
                Picker("", selection: $selectedSegment_0_5) {
                    Text("b1".localized()).tag(0)
                    Text("b2".localized()).tag(1)
                }
                    .pickerStyle(.segmented)
                Slider(value: $slider_0_6Value, in: 0...1)
                Slider(value: $slider_0_7Value, in: 0...1)
                TextField("", text: $textField_0_8Text)
                    .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
                TextField("", text: $textField_0_9Text)
                    .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
                HStack {
                    Image(systemName: selectedH == "radio_0_10" ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(.blue)
                        .onTapGesture {
                        selectedH = "radio_0_10"
                    }
                    Text("h1")
                }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("h1")
                HStack {
                    Image(systemName: selectedH == "radio_0_11" ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(.blue)
                        .onTapGesture {
                        selectedH = "radio_0_11"
                    }
                    Text("h2")
                }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("h2")
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: selectedRadio_0_12 == "i1" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedRadio_0_12 = "i1"
                        }
                        Text("i1")
                    }
                    HStack {
                        Image(systemName: selectedRadio_0_12 == "i2" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedRadio_0_12 = "i2"
                        }
                        Text("i2")
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: selectedRadio_0_13 == "j1" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedRadio_0_13 = "j1"
                        }
                        Text("j1")
                    }
                    HStack {
                        Image(systemName: selectedRadio_0_13 == "j2" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedRadio_0_13 = "j2"
                        }
                        Text("j2")
                    }
                }
                HStack {
                    Image(systemName: selectedG == "radio_0_14" ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(.blue)
                        .onTapGesture {
                        selectedG = "radio_0_14"
                    }
                    Text("g1")
                }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("g1")
                HStack {
                    Image(systemName: selectedG == "radio_0_15" ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(.blue)
                        .onTapGesture {
                        selectedG = "radio_0_15"
                    }
                    Text("g2")
                }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("g2")
        }
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
