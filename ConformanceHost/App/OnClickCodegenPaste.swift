//
//  OnClickCodegenPaste.swift
//  ConformanceHost
//
//  What `sjui build` (sjui_tools of jsonui-cli triage/control-onclick df223c03, on rel/v1.8.121 = 19f1328e) emits for
//  OnClickProbeView's three layouts — the controls with an onClick, under no
//  gate, `canTap: false` and `enabled: false` — the generated Data structs, the
//  view-local state, the body and its sections, pasted unchanged but for one
//  line each: sjui declares a Radio group's `@State` once per Radio, and the
//  checked one's seed and the other's "" do not compile together (ticket
//  sjui-codegen-state-declarations-collide-by-name) — the second is left out.
//  For ticket control-onclick-is-called-differently-on-every-path.
//

import SwiftUI
import SwiftJsonUI

struct OnClickNData {
    // Data properties from JSON
    var onSwN: (() -> Void)? = nil
    var onCbN: (() -> Void)? = nil
    var onRvN: (() -> Void)? = nil
    var onRgaN: (() -> Void)? = nil
    var onRgbN: (() -> Void)? = nil
    var onSegN: (() -> Void)? = nil
    var onSlN: (() -> Void)? = nil
    var onSbN: (() -> Void)? = nil
    var onTfN: (() -> Void)? = nil
    var onTvN: (() -> Void)? = nil
    var onSwlN: (() -> Void)? = nil
    var selectedRadiogroup: String = ""
    var selectedGrpn: String = ""
    var tfNIsFocused: Bool = false
    var tvNIsFocused: Bool = false

    // Update properties from dictionary
    mutating func update(dictionary: [String: Any]) {
        if let value = dictionary["onSwN"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSwN = typedValue
            }
        }
        if let value = dictionary["onCbN"] {
            if let typedValue = value as? (() -> Void)? {
                self.onCbN = typedValue
            }
        }
        if let value = dictionary["onRvN"] {
            if let typedValue = value as? (() -> Void)? {
                self.onRvN = typedValue
            }
        }
        if let value = dictionary["onRgaN"] {
            if let typedValue = value as? (() -> Void)? {
                self.onRgaN = typedValue
            }
        }
        if let value = dictionary["onRgbN"] {
            if let typedValue = value as? (() -> Void)? {
                self.onRgbN = typedValue
            }
        }
        if let value = dictionary["onSegN"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSegN = typedValue
            }
        }
        if let value = dictionary["onSlN"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSlN = typedValue
            }
        }
        if let value = dictionary["onSbN"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSbN = typedValue
            }
        }
        if let value = dictionary["onTfN"] {
            if let typedValue = value as? (() -> Void)? {
                self.onTfN = typedValue
            }
        }
        if let value = dictionary["onTvN"] {
            if let typedValue = value as? (() -> Void)? {
                self.onTvN = typedValue
            }
        }
        if let value = dictionary["onSwlN"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSwlN = typedValue
            }
        }
        if let value = dictionary["selectedRadiogroup"] {
            if let stringValue = value as? String {
                self.selectedRadiogroup = stringValue
            }
        }
        if let value = dictionary["selectedGrpn"] {
            if let stringValue = value as? String {
                self.selectedGrpn = stringValue
            }
        }
        if let value = dictionary["tfNIsFocused"] {
            if let boolValue = value as? Bool {
                self.tfNIsFocused = boolValue
            }
        }
        if let value = dictionary["tvNIsFocused"] {
            if let boolValue = value as? Bool {
                self.tvNIsFocused = boolValue
            }
        }
    }

    // Convert properties to dictionary for Dynamic mode
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Data properties
        if let value = onSwN {
            dict["onSwN"] = value
        }
        if let value = onCbN {
            dict["onCbN"] = value
        }
        if let value = onRvN {
            dict["onRvN"] = value
        }
        if let value = onRgaN {
            dict["onRgaN"] = value
        }
        if let value = onRgbN {
            dict["onRgbN"] = value
        }
        if let value = onSegN {
            dict["onSegN"] = value
        }
        if let value = onSlN {
            dict["onSlN"] = value
        }
        if let value = onSbN {
            dict["onSbN"] = value
        }
        if let value = onTfN {
            dict["onTfN"] = value
        }
        if let value = onTvN {
            dict["onTvN"] = value
        }
        if let value = onSwlN {
            dict["onSwlN"] = value
        }
        dict["selectedRadiogroup"] = selectedRadiogroup
        dict["selectedGrpn"] = selectedGrpn
        dict["tfNIsFocused"] = tfNIsFocused
        dict["tvNIsFocused"] = tvNIsFocused
        
        return dict
    }

    #if DEBUG
    // Convert properties to binding dictionary for Dynamic mode reactivity
    // SwiftUI.Binding<T> values enable automatic re-rendering on changes
    func toDictionary(binding dataBinding: SwiftUI.Binding<OnClickNData>) -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Data properties as SwiftUI.Binding for reactivity
        if let onSwN = onSwN {
            dict["onSwN"] = onSwN
        }
        if let onCbN = onCbN {
            dict["onCbN"] = onCbN
        }
        if let onRvN = onRvN {
            dict["onRvN"] = onRvN
        }
        if let onRgaN = onRgaN {
            dict["onRgaN"] = onRgaN
        }
        if let onRgbN = onRgbN {
            dict["onRgbN"] = onRgbN
        }
        if let onSegN = onSegN {
            dict["onSegN"] = onSegN
        }
        if let onSlN = onSlN {
            dict["onSlN"] = onSlN
        }
        if let onSbN = onSbN {
            dict["onSbN"] = onSbN
        }
        if let onTfN = onTfN {
            dict["onTfN"] = onTfN
        }
        if let onTvN = onTvN {
            dict["onTvN"] = onTvN
        }
        if let onSwlN = onSwlN {
            dict["onSwlN"] = onSwlN
        }
        dict["selectedRadiogroup"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.selectedRadiogroup },
            set: { dataBinding.wrappedValue.selectedRadiogroup = $0 }
        )
        dict["selectedGrpn"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.selectedGrpn },
            set: { dataBinding.wrappedValue.selectedGrpn = $0 }
        )
        dict["tfNIsFocused"] = SwiftUI.Binding<Bool>(
            get: { dataBinding.wrappedValue.tfNIsFocused },
            set: { dataBinding.wrappedValue.tfNIsFocused = $0 }
        )
        dict["tvNIsFocused"] = SwiftUI.Binding<Bool>(
            get: { dataBinding.wrappedValue.tvNIsFocused },
            set: { dataBinding.wrappedValue.tvNIsFocused = $0 }
        )
        
        return dict
    }
    #endif
}

struct OnClickNCodegenPaste: View {
    @SwiftUI.Binding var data: OnClickNData
    @State private var swNIsOn: Bool = false
    @State private var cbNIsOn: Bool = false
    @State private var selectedRvn: String = "ra"
    @State private var selectedGrpn: String = "rgaN"
    // (a second `@State private var selectedGrpn: String = ""` here — left out, see the header)
    @State private var selectedSegn: Int = 0
    @State private var sliderValueslN: Double = 0.2
    @State private var tfNText: String = "t0"
    @FocusState private var tfNIsFocused: Bool
    @State private var tvNText: String = "v0"
    @State private var swlNIsOn: Bool = false

    var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                    Toggle(isOn: SwiftUI.Binding(get: { $swNIsOn.wrappedValue }, set: { newValue in $swNIsOn.wrappedValue = newValue; data.onSwN?() })) {
                        Text("")
                    }
                        .labelsHidden()
                        .accessibilityIdentifier("swN")
                    CheckBoxView(
                        isOn: $cbNIsOn,
                        label: "cbl",
                        onValueChanged: { newValue in data.onCbN?() }
                    )
                        .accessibilityIdentifier("cbN")
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: selectedRvn == "ra" ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(.blue)
                                .onTapGesture {
                                selectedRvn = "ra"
                                data.onRvN?()
                            }
                            Text("ra")
                        }
                        HStack {
                            Image(systemName: selectedRvn == "rb" ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(.blue)
                                .onTapGesture {
                                selectedRvn = "rb"
                                data.onRvN?()
                            }
                            Text("rb")
                        }
                    }
                        .accessibilityIdentifier("rvN")
                    HStack {
                        Image(systemName: selectedGrpn == "rgaN" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedGrpn = "rgaN"
                            data.onRgaN?()
                        }
                        Text("rg1")
                    }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("rg1")
                        .accessibilityIdentifier("rgaN")
                    HStack {
                        Image(systemName: selectedGrpn == "rgbN" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedGrpn = "rgbN"
                            data.onRgbN?()
                        }
                        Text("rg2")
                    }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("rg2")
                        .accessibilityIdentifier("rgbN")
                    Picker("", selection: SwiftUI.Binding(get: { $selectedSegn.wrappedValue }, set: { newValue in $selectedSegn.wrappedValue = newValue; data.onSegN?() })) {
                        Text("sx".localized()).tag(0)
                        Text("sy".localized()).tag(1)
                    }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("segN")
                    Slider(value: $sliderValueslN, in: 0...1, onEditingChanged: { editing in if !editing { data.onSlN?() } })
                        .accessibilityIdentifier("slN")
                    SelectBoxView(
                        id: "sbN",
                        selectItemType: .normal,
                        items: ["pp", "qq"],
                        selectedIndex: 0,
                        onValueChange: { newValue in data.onSbN?() }
                    )
                        .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                        .accessibilityIdentifier("sbN")
                    TextField("", text: $tfNText)
                        .focused($tfNIsFocused)
                        .onChange(of: data.tfNIsFocused) { _, newValue in
                        tfNIsFocused = newValue
                    }
                        .onChange(of: tfNIsFocused) { _, newValue in
                        data.tfNIsFocused = newValue
                    }
                        .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                        .accessibilityIdentifier("tfN")
                    TextViewWithPlaceholder(
                        text: $tvNText,
                        isFocused: $data.tvNIsFocused
                    )
                        .frame(minHeight: 50, idealHeight: 50, maxHeight: 50)
                        .accessibilityIdentifier("tvN")
                    Toggle(isOn: SwiftUI.Binding(get: { $swlNIsOn.wrappedValue }, set: { newValue in $swlNIsOn.wrappedValue = newValue; data.onSwlN?() })) {
                        Text("swl label")
                    }
                        .accessibilityIdentifier("swlN")
            }
                .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

struct OnClickCData {
    // Data properties from JSON
    var onSwC: (() -> Void)? = nil
    var onCbC: (() -> Void)? = nil
    var onRvC: (() -> Void)? = nil
    var onRgaC: (() -> Void)? = nil
    var onRgbC: (() -> Void)? = nil
    var onSegC: (() -> Void)? = nil
    var onSlC: (() -> Void)? = nil
    var onSbC: (() -> Void)? = nil
    var onTfC: (() -> Void)? = nil
    var onTvC: (() -> Void)? = nil
    var onSwlC: (() -> Void)? = nil
    var selectedRadiogroup: String = ""
    var selectedGrpc: String = ""
    var tfCIsFocused: Bool = false
    var tvCIsFocused: Bool = false

    // Update properties from dictionary
    mutating func update(dictionary: [String: Any]) {
        if let value = dictionary["onSwC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSwC = typedValue
            }
        }
        if let value = dictionary["onCbC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onCbC = typedValue
            }
        }
        if let value = dictionary["onRvC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onRvC = typedValue
            }
        }
        if let value = dictionary["onRgaC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onRgaC = typedValue
            }
        }
        if let value = dictionary["onRgbC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onRgbC = typedValue
            }
        }
        if let value = dictionary["onSegC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSegC = typedValue
            }
        }
        if let value = dictionary["onSlC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSlC = typedValue
            }
        }
        if let value = dictionary["onSbC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSbC = typedValue
            }
        }
        if let value = dictionary["onTfC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onTfC = typedValue
            }
        }
        if let value = dictionary["onTvC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onTvC = typedValue
            }
        }
        if let value = dictionary["onSwlC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSwlC = typedValue
            }
        }
        if let value = dictionary["selectedRadiogroup"] {
            if let stringValue = value as? String {
                self.selectedRadiogroup = stringValue
            }
        }
        if let value = dictionary["selectedGrpc"] {
            if let stringValue = value as? String {
                self.selectedGrpc = stringValue
            }
        }
        if let value = dictionary["tfCIsFocused"] {
            if let boolValue = value as? Bool {
                self.tfCIsFocused = boolValue
            }
        }
        if let value = dictionary["tvCIsFocused"] {
            if let boolValue = value as? Bool {
                self.tvCIsFocused = boolValue
            }
        }
    }

    // Convert properties to dictionary for Dynamic mode
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Data properties
        if let value = onSwC {
            dict["onSwC"] = value
        }
        if let value = onCbC {
            dict["onCbC"] = value
        }
        if let value = onRvC {
            dict["onRvC"] = value
        }
        if let value = onRgaC {
            dict["onRgaC"] = value
        }
        if let value = onRgbC {
            dict["onRgbC"] = value
        }
        if let value = onSegC {
            dict["onSegC"] = value
        }
        if let value = onSlC {
            dict["onSlC"] = value
        }
        if let value = onSbC {
            dict["onSbC"] = value
        }
        if let value = onTfC {
            dict["onTfC"] = value
        }
        if let value = onTvC {
            dict["onTvC"] = value
        }
        if let value = onSwlC {
            dict["onSwlC"] = value
        }
        dict["selectedRadiogroup"] = selectedRadiogroup
        dict["selectedGrpc"] = selectedGrpc
        dict["tfCIsFocused"] = tfCIsFocused
        dict["tvCIsFocused"] = tvCIsFocused
        
        return dict
    }

    #if DEBUG
    // Convert properties to binding dictionary for Dynamic mode reactivity
    // SwiftUI.Binding<T> values enable automatic re-rendering on changes
    func toDictionary(binding dataBinding: SwiftUI.Binding<OnClickCData>) -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Data properties as SwiftUI.Binding for reactivity
        if let onSwC = onSwC {
            dict["onSwC"] = onSwC
        }
        if let onCbC = onCbC {
            dict["onCbC"] = onCbC
        }
        if let onRvC = onRvC {
            dict["onRvC"] = onRvC
        }
        if let onRgaC = onRgaC {
            dict["onRgaC"] = onRgaC
        }
        if let onRgbC = onRgbC {
            dict["onRgbC"] = onRgbC
        }
        if let onSegC = onSegC {
            dict["onSegC"] = onSegC
        }
        if let onSlC = onSlC {
            dict["onSlC"] = onSlC
        }
        if let onSbC = onSbC {
            dict["onSbC"] = onSbC
        }
        if let onTfC = onTfC {
            dict["onTfC"] = onTfC
        }
        if let onTvC = onTvC {
            dict["onTvC"] = onTvC
        }
        if let onSwlC = onSwlC {
            dict["onSwlC"] = onSwlC
        }
        dict["selectedRadiogroup"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.selectedRadiogroup },
            set: { dataBinding.wrappedValue.selectedRadiogroup = $0 }
        )
        dict["selectedGrpc"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.selectedGrpc },
            set: { dataBinding.wrappedValue.selectedGrpc = $0 }
        )
        dict["tfCIsFocused"] = SwiftUI.Binding<Bool>(
            get: { dataBinding.wrappedValue.tfCIsFocused },
            set: { dataBinding.wrappedValue.tfCIsFocused = $0 }
        )
        dict["tvCIsFocused"] = SwiftUI.Binding<Bool>(
            get: { dataBinding.wrappedValue.tvCIsFocused },
            set: { dataBinding.wrappedValue.tvCIsFocused = $0 }
        )
        
        return dict
    }
    #endif
}

struct OnClickCCodegenPaste: View {
    @SwiftUI.Binding var data: OnClickCData
    @State private var swCIsOn: Bool = false
    @State private var cbCIsOn: Bool = false
    @State private var selectedRvc: String = "ra"
    @State private var selectedGrpc: String = "rgaC"
    // (a second `@State private var selectedGrpc: String = ""` here — left out, see the header)
    @State private var selectedSegc: Int = 0
    @State private var sliderValueslC: Double = 0.2
    @State private var tfCText: String = "t0"
    @FocusState private var tfCIsFocused: Bool
    @State private var tvCText: String = "v0"
    @State private var swlCIsOn: Bool = false

    var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                    Toggle(isOn: $swCIsOn) {
                        Text("")
                    }
                        .labelsHidden()
                        .accessibilityIdentifier("swC")
                    CheckBoxView(
                        isOn: $cbCIsOn,
                        label: "cbl",
                    )
                        .accessibilityIdentifier("cbC")
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: selectedRvc == "ra" ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(.blue)
                                .onTapGesture {
                                selectedRvc = "ra"
                            }
                            Text("ra")
                        }
                        HStack {
                            Image(systemName: selectedRvc == "rb" ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(.blue)
                                .onTapGesture {
                                selectedRvc = "rb"
                            }
                            Text("rb")
                        }
                    }
                        .accessibilityIdentifier("rvC")
                    HStack {
                        Image(systemName: selectedGrpc == "rgaC" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedGrpc = "rgaC"
                        }
                        Text("rg1")
                    }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("rg1")
                        .accessibilityIdentifier("rgaC")
                    HStack {
                        Image(systemName: selectedGrpc == "rgbC" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedGrpc = "rgbC"
                        }
                        Text("rg2")
                    }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("rg2")
                        .accessibilityIdentifier("rgbC")
                    Picker("", selection: $selectedSegc) {
                        Text("sx".localized()).tag(0)
                        Text("sy".localized()).tag(1)
                    }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("segC")
                    Slider(value: $sliderValueslC, in: 0...1)
                        .accessibilityIdentifier("slC")
                    SelectBoxView(
                        id: "sbC",
                        selectItemType: .normal,
                        items: ["pp", "qq"],
                        selectedIndex: 0,
                    )
                        .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                        .accessibilityIdentifier("sbC")
                    TextField("", text: $tfCText)
                        .focused($tfCIsFocused)
                        .onChange(of: data.tfCIsFocused) { _, newValue in
                        tfCIsFocused = newValue
                    }
                        .onChange(of: tfCIsFocused) { _, newValue in
                        data.tfCIsFocused = newValue
                    }
                        .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                        .accessibilityIdentifier("tfC")
                    TextViewWithPlaceholder(
                        text: $tvCText,
                        isFocused: $data.tvCIsFocused
                    )
                        .frame(minHeight: 50, idealHeight: 50, maxHeight: 50)
                        .accessibilityIdentifier("tvC")
                    Toggle(isOn: $swlCIsOn) {
                        Text("swl label")
                    }
                        .accessibilityIdentifier("swlC")
            }
                .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

struct OnClickEData {
    // Data properties from JSON
    var onSwE: (() -> Void)? = nil
    var onCbE: (() -> Void)? = nil
    var onRvE: (() -> Void)? = nil
    var onRgaE: (() -> Void)? = nil
    var onRgbE: (() -> Void)? = nil
    var onSegE: (() -> Void)? = nil
    var onSlE: (() -> Void)? = nil
    var onSbE: (() -> Void)? = nil
    var onTfE: (() -> Void)? = nil
    var onTvE: (() -> Void)? = nil
    var onSwlE: (() -> Void)? = nil
    var selectedRadiogroup: String = ""
    var selectedGrpe: String = ""
    var tfEIsFocused: Bool = false
    var tvEIsFocused: Bool = false

    // Update properties from dictionary
    mutating func update(dictionary: [String: Any]) {
        if let value = dictionary["onSwE"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSwE = typedValue
            }
        }
        if let value = dictionary["onCbE"] {
            if let typedValue = value as? (() -> Void)? {
                self.onCbE = typedValue
            }
        }
        if let value = dictionary["onRvE"] {
            if let typedValue = value as? (() -> Void)? {
                self.onRvE = typedValue
            }
        }
        if let value = dictionary["onRgaE"] {
            if let typedValue = value as? (() -> Void)? {
                self.onRgaE = typedValue
            }
        }
        if let value = dictionary["onRgbE"] {
            if let typedValue = value as? (() -> Void)? {
                self.onRgbE = typedValue
            }
        }
        if let value = dictionary["onSegE"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSegE = typedValue
            }
        }
        if let value = dictionary["onSlE"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSlE = typedValue
            }
        }
        if let value = dictionary["onSbE"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSbE = typedValue
            }
        }
        if let value = dictionary["onTfE"] {
            if let typedValue = value as? (() -> Void)? {
                self.onTfE = typedValue
            }
        }
        if let value = dictionary["onTvE"] {
            if let typedValue = value as? (() -> Void)? {
                self.onTvE = typedValue
            }
        }
        if let value = dictionary["onSwlE"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSwlE = typedValue
            }
        }
        if let value = dictionary["selectedRadiogroup"] {
            if let stringValue = value as? String {
                self.selectedRadiogroup = stringValue
            }
        }
        if let value = dictionary["selectedGrpe"] {
            if let stringValue = value as? String {
                self.selectedGrpe = stringValue
            }
        }
        if let value = dictionary["tfEIsFocused"] {
            if let boolValue = value as? Bool {
                self.tfEIsFocused = boolValue
            }
        }
        if let value = dictionary["tvEIsFocused"] {
            if let boolValue = value as? Bool {
                self.tvEIsFocused = boolValue
            }
        }
    }

    // Convert properties to dictionary for Dynamic mode
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Data properties
        if let value = onSwE {
            dict["onSwE"] = value
        }
        if let value = onCbE {
            dict["onCbE"] = value
        }
        if let value = onRvE {
            dict["onRvE"] = value
        }
        if let value = onRgaE {
            dict["onRgaE"] = value
        }
        if let value = onRgbE {
            dict["onRgbE"] = value
        }
        if let value = onSegE {
            dict["onSegE"] = value
        }
        if let value = onSlE {
            dict["onSlE"] = value
        }
        if let value = onSbE {
            dict["onSbE"] = value
        }
        if let value = onTfE {
            dict["onTfE"] = value
        }
        if let value = onTvE {
            dict["onTvE"] = value
        }
        if let value = onSwlE {
            dict["onSwlE"] = value
        }
        dict["selectedRadiogroup"] = selectedRadiogroup
        dict["selectedGrpe"] = selectedGrpe
        dict["tfEIsFocused"] = tfEIsFocused
        dict["tvEIsFocused"] = tvEIsFocused
        
        return dict
    }

    #if DEBUG
    // Convert properties to binding dictionary for Dynamic mode reactivity
    // SwiftUI.Binding<T> values enable automatic re-rendering on changes
    func toDictionary(binding dataBinding: SwiftUI.Binding<OnClickEData>) -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Data properties as SwiftUI.Binding for reactivity
        if let onSwE = onSwE {
            dict["onSwE"] = onSwE
        }
        if let onCbE = onCbE {
            dict["onCbE"] = onCbE
        }
        if let onRvE = onRvE {
            dict["onRvE"] = onRvE
        }
        if let onRgaE = onRgaE {
            dict["onRgaE"] = onRgaE
        }
        if let onRgbE = onRgbE {
            dict["onRgbE"] = onRgbE
        }
        if let onSegE = onSegE {
            dict["onSegE"] = onSegE
        }
        if let onSlE = onSlE {
            dict["onSlE"] = onSlE
        }
        if let onSbE = onSbE {
            dict["onSbE"] = onSbE
        }
        if let onTfE = onTfE {
            dict["onTfE"] = onTfE
        }
        if let onTvE = onTvE {
            dict["onTvE"] = onTvE
        }
        if let onSwlE = onSwlE {
            dict["onSwlE"] = onSwlE
        }
        dict["selectedRadiogroup"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.selectedRadiogroup },
            set: { dataBinding.wrappedValue.selectedRadiogroup = $0 }
        )
        dict["selectedGrpe"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.selectedGrpe },
            set: { dataBinding.wrappedValue.selectedGrpe = $0 }
        )
        dict["tfEIsFocused"] = SwiftUI.Binding<Bool>(
            get: { dataBinding.wrappedValue.tfEIsFocused },
            set: { dataBinding.wrappedValue.tfEIsFocused = $0 }
        )
        dict["tvEIsFocused"] = SwiftUI.Binding<Bool>(
            get: { dataBinding.wrappedValue.tvEIsFocused },
            set: { dataBinding.wrappedValue.tvEIsFocused = $0 }
        )
        
        return dict
    }
    #endif
}

struct OnClickECodegenPaste: View {
    @SwiftUI.Binding var data: OnClickEData
    @State private var swEIsOn: Bool = false
    @State private var cbEIsOn: Bool = false
    @State private var selectedRve: String = "ra"
    @State private var selectedGrpe: String = "rgaE"
    // (a second `@State private var selectedGrpe: String = ""` here — left out, see the header)
    @State private var selectedSege: Int = 0
    @State private var sliderValueslE: Double = 0.2
    @State private var tfEText: String = "t0"
    @FocusState private var tfEIsFocused: Bool
    @State private var tvEText: String = "v0"
    @State private var swlEIsOn: Bool = false

    var body: some View {
            AnyView(section0())
    }

    @ViewBuilder private func section0() -> some View {
        VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: SwiftUI.Binding(get: { $swEIsOn.wrappedValue }, set: { newValue in $swEIsOn.wrappedValue = newValue; data.onSwE?() })) {
                    Text("")
                }
                    .labelsHidden()
                    .disabled(true)
                    .accessibilityIdentifier("swE")
                    .disabled(true)
                CheckBoxView(
                    isOn: $cbEIsOn,
                    label: "cbl",
                    isEnabled: false,
                    onValueChanged: { newValue in data.onCbE?() }
                )
                    .disabled(true)
                    .accessibilityIdentifier("cbE")
                    .disabled(true)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: selectedRve == "ra" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedRve = "ra"
                            data.onRvE?()
                        }
                        Text("ra")
                    }
                    HStack {
                        Image(systemName: selectedRve == "rb" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedRve = "rb"
                            data.onRvE?()
                        }
                        Text("rb")
                    }
                }
                    .disabled(true)
                    .opacity(0.6)
                    .disabled(true)
                    .accessibilityIdentifier("rvE")
                    .disabled(true)
                HStack {
                    Image(systemName: selectedGrpe == "rgaE" ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(.blue)
                        .onTapGesture {
                        selectedGrpe = "rgaE"
                        data.onRgaE?()
                    }
                    Text("rg1")
                }
                    .disabled(true)
                    .opacity(0.6)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("rg1")
                    .disabled(true)
                    .accessibilityIdentifier("rgaE")
                    .disabled(true)
                HStack {
                    Image(systemName: selectedGrpe == "rgbE" ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(.blue)
                        .onTapGesture {
                        selectedGrpe = "rgbE"
                        data.onRgbE?()
                    }
                    Text("rg2")
                }
                    .disabled(true)
                    .opacity(0.6)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("rg2")
                    .disabled(true)
                    .accessibilityIdentifier("rgbE")
                    .disabled(true)
                Picker("", selection: SwiftUI.Binding(get: { $selectedSege.wrappedValue }, set: { newValue in $selectedSege.wrappedValue = newValue; data.onSegE?() })) {
                    Text("sx".localized()).tag(0)
                    Text("sy".localized()).tag(1)
                }
                    .pickerStyle(.segmented)
                    .disabled(true)
                    .accessibilityIdentifier("segE")
                    .disabled(true)
                Slider(value: $sliderValueslE, in: 0...1, onEditingChanged: { editing in if !editing { data.onSlE?() } })
                    .disabled(true)
                    .disabled(true)
                    .accessibilityIdentifier("slE")
                    .disabled(true)
                SelectBoxView(
                    id: "sbE",
                    selectItemType: .normal,
                    items: ["pp", "qq"],
                    selectedIndex: 0,
                    onValueChange: { newValue in data.onSbE?() }
                )
                    .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                    .disabled(true)
                    .accessibilityIdentifier("sbE")
                    .disabled(true)
                TextField("", text: $tfEText)
                    .focused($tfEIsFocused)
                    .onChange(of: data.tfEIsFocused) { _, newValue in
                    tfEIsFocused = newValue
                }
                    .onChange(of: tfEIsFocused) { _, newValue in
                    data.tfEIsFocused = newValue
                }
                    .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                    .disabled(true)
                    .accessibilityIdentifier("tfE")
                    .disabled(true)
                TextViewWithPlaceholder(
                    text: $tvEText,
                    isFocused: $data.tvEIsFocused
                )
                    .frame(minHeight: 50, idealHeight: 50, maxHeight: 50)
                    .disabled(true)
                    .accessibilityIdentifier("tvE")
                    .disabled(true)
                Toggle(isOn: SwiftUI.Binding(get: { $swlEIsOn.wrappedValue }, set: { newValue in $swlEIsOn.wrappedValue = newValue; data.onSwlE?() })) {
                    Text("swl label")
                }
                    .disabled(true)
                    .accessibilityIdentifier("swlE")
                    .disabled(true)
        }
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

struct OnClickVData {
    // Data properties from JSON
    var onSwuV: (() -> Void)? = nil
    var onSwuC: (() -> Void)? = nil
    var onSwbV: (() -> Void)? = nil
    var onSwbC: (() -> Void)? = nil
    var onCbuV: (() -> Void)? = nil
    var onCbuC: (() -> Void)? = nil
    var onCbbV: (() -> Void)? = nil
    var onCbbC: (() -> Void)? = nil
    var onRvuV: (() -> Void)? = nil
    var onRvuC: (() -> Void)? = nil
    var onRvbV: (() -> Void)? = nil
    var onRvbC: (() -> Void)? = nil
    var onSeguV: (() -> Void)? = nil
    var onSeguC: (() -> Void)? = nil
    var onSegbV: (() -> Void)? = nil
    var onSegbC: (() -> Void)? = nil
    var onSluV: (() -> Void)? = nil
    var onSluC: (() -> Void)? = nil
    var onSlbV: (() -> Void)? = nil
    var onSlbC: (() -> Void)? = nil
    var onSbuV: (() -> Void)? = nil
    var onSbuC: (() -> Void)? = nil
    var onSbbV: (() -> Void)? = nil
    var onSbbC: (() -> Void)? = nil
    var onSbdV: (() -> Void)? = nil
    var onSbdC: (() -> Void)? = nil
    var onSegvuC: (() -> Void)? = nil
    var onSegvuV: (() -> Void)? = nil
    var onSegvbC: (() -> Void)? = nil
    var onSegvbV: (() -> Void)? = nil
    var onSegwuV: (() -> Void)? = nil
    var onSegwuC: (() -> Void)? = nil
    var onSegwuX: (() -> Void)? = nil
    var onSegwbV: (() -> Void)? = nil
    var onSegwbC: (() -> Void)? = nil
    var onSegwbX: (() -> Void)? = nil
    var segvbIdx: Int = 0
    var segwbIdx: Int = 0
    var swbOn: Bool = false
    var cbbOn: Bool = false
    var rvbSel: String = "ba".localized()
    var segbIdx: Int = 0
    var slbVal: Double = 0.2
    var sbbIdx: Int = 0
    var sbdDate: String = "2026-01-02"
    var selectedRadiogroup: String = ""

    // Update properties from dictionary
    mutating func update(dictionary: [String: Any]) {
        if let value = dictionary["onSwuV"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSwuV = typedValue
            }
        }
        if let value = dictionary["onSwuC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSwuC = typedValue
            }
        }
        if let value = dictionary["onSwbV"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSwbV = typedValue
            }
        }
        if let value = dictionary["onSwbC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSwbC = typedValue
            }
        }
        if let value = dictionary["onCbuV"] {
            if let typedValue = value as? (() -> Void)? {
                self.onCbuV = typedValue
            }
        }
        if let value = dictionary["onCbuC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onCbuC = typedValue
            }
        }
        if let value = dictionary["onCbbV"] {
            if let typedValue = value as? (() -> Void)? {
                self.onCbbV = typedValue
            }
        }
        if let value = dictionary["onCbbC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onCbbC = typedValue
            }
        }
        if let value = dictionary["onRvuV"] {
            if let typedValue = value as? (() -> Void)? {
                self.onRvuV = typedValue
            }
        }
        if let value = dictionary["onRvuC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onRvuC = typedValue
            }
        }
        if let value = dictionary["onRvbV"] {
            if let typedValue = value as? (() -> Void)? {
                self.onRvbV = typedValue
            }
        }
        if let value = dictionary["onRvbC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onRvbC = typedValue
            }
        }
        if let value = dictionary["onSeguV"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSeguV = typedValue
            }
        }
        if let value = dictionary["onSeguC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSeguC = typedValue
            }
        }
        if let value = dictionary["onSegbV"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSegbV = typedValue
            }
        }
        if let value = dictionary["onSegbC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSegbC = typedValue
            }
        }
        if let value = dictionary["onSluV"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSluV = typedValue
            }
        }
        if let value = dictionary["onSluC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSluC = typedValue
            }
        }
        if let value = dictionary["onSlbV"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSlbV = typedValue
            }
        }
        if let value = dictionary["onSlbC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSlbC = typedValue
            }
        }
        if let value = dictionary["onSbuV"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSbuV = typedValue
            }
        }
        if let value = dictionary["onSbuC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSbuC = typedValue
            }
        }
        if let value = dictionary["onSbbV"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSbbV = typedValue
            }
        }
        if let value = dictionary["onSbbC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSbbC = typedValue
            }
        }
        if let value = dictionary["onSbdV"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSbdV = typedValue
            }
        }
        if let value = dictionary["onSbdC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSbdC = typedValue
            }
        }
        if let value = dictionary["onSegvuC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSegvuC = typedValue
            }
        }
        if let value = dictionary["onSegvuV"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSegvuV = typedValue
            }
        }
        if let value = dictionary["onSegvbC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSegvbC = typedValue
            }
        }
        if let value = dictionary["onSegvbV"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSegvbV = typedValue
            }
        }
        if let value = dictionary["onSegwuV"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSegwuV = typedValue
            }
        }
        if let value = dictionary["onSegwuC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSegwuC = typedValue
            }
        }
        if let value = dictionary["onSegwuX"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSegwuX = typedValue
            }
        }
        if let value = dictionary["onSegwbV"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSegwbV = typedValue
            }
        }
        if let value = dictionary["onSegwbC"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSegwbC = typedValue
            }
        }
        if let value = dictionary["onSegwbX"] {
            if let typedValue = value as? (() -> Void)? {
                self.onSegwbX = typedValue
            }
        }
        if let value = dictionary["segvbIdx"] {
            if let intValue = value as? Int {
                self.segvbIdx = intValue
            }
        }
        if let value = dictionary["segwbIdx"] {
            if let intValue = value as? Int {
                self.segwbIdx = intValue
            }
        }
        if let value = dictionary["swbOn"] {
            if let boolValue = value as? Bool {
                self.swbOn = boolValue
            }
        }
        if let value = dictionary["cbbOn"] {
            if let boolValue = value as? Bool {
                self.cbbOn = boolValue
            }
        }
        if let value = dictionary["rvbSel"] {
            if let stringValue = value as? String {
                self.rvbSel = stringValue
            }
        }
        if let value = dictionary["segbIdx"] {
            if let intValue = value as? Int {
                self.segbIdx = intValue
            }
        }
        if let value = dictionary["slbVal"] {
            if let doubleValue = value as? Double {
                self.slbVal = doubleValue
            }
        }
        if let value = dictionary["sbbIdx"] {
            if let intValue = value as? Int {
                self.sbbIdx = intValue
            }
        }
        if let value = dictionary["sbdDate"] {
            if let stringValue = value as? String {
                self.sbdDate = stringValue
            }
        }
        if let value = dictionary["selectedRadiogroup"] {
            if let stringValue = value as? String {
                self.selectedRadiogroup = stringValue
            }
        }
    }

    // Convert properties to dictionary for Dynamic mode
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Data properties
        if let value = onSwuV {
            dict["onSwuV"] = value
        }
        if let value = onSwuC {
            dict["onSwuC"] = value
        }
        if let value = onSwbV {
            dict["onSwbV"] = value
        }
        if let value = onSwbC {
            dict["onSwbC"] = value
        }
        if let value = onCbuV {
            dict["onCbuV"] = value
        }
        if let value = onCbuC {
            dict["onCbuC"] = value
        }
        if let value = onCbbV {
            dict["onCbbV"] = value
        }
        if let value = onCbbC {
            dict["onCbbC"] = value
        }
        if let value = onRvuV {
            dict["onRvuV"] = value
        }
        if let value = onRvuC {
            dict["onRvuC"] = value
        }
        if let value = onRvbV {
            dict["onRvbV"] = value
        }
        if let value = onRvbC {
            dict["onRvbC"] = value
        }
        if let value = onSeguV {
            dict["onSeguV"] = value
        }
        if let value = onSeguC {
            dict["onSeguC"] = value
        }
        if let value = onSegbV {
            dict["onSegbV"] = value
        }
        if let value = onSegbC {
            dict["onSegbC"] = value
        }
        if let value = onSluV {
            dict["onSluV"] = value
        }
        if let value = onSluC {
            dict["onSluC"] = value
        }
        if let value = onSlbV {
            dict["onSlbV"] = value
        }
        if let value = onSlbC {
            dict["onSlbC"] = value
        }
        if let value = onSbuV {
            dict["onSbuV"] = value
        }
        if let value = onSbuC {
            dict["onSbuC"] = value
        }
        if let value = onSbbV {
            dict["onSbbV"] = value
        }
        if let value = onSbbC {
            dict["onSbbC"] = value
        }
        if let value = onSbdV {
            dict["onSbdV"] = value
        }
        if let value = onSbdC {
            dict["onSbdC"] = value
        }
        if let value = onSegvuC {
            dict["onSegvuC"] = value
        }
        if let value = onSegvuV {
            dict["onSegvuV"] = value
        }
        if let value = onSegvbC {
            dict["onSegvbC"] = value
        }
        if let value = onSegvbV {
            dict["onSegvbV"] = value
        }
        if let value = onSegwuV {
            dict["onSegwuV"] = value
        }
        if let value = onSegwuC {
            dict["onSegwuC"] = value
        }
        if let value = onSegwuX {
            dict["onSegwuX"] = value
        }
        if let value = onSegwbV {
            dict["onSegwbV"] = value
        }
        if let value = onSegwbC {
            dict["onSegwbC"] = value
        }
        if let value = onSegwbX {
            dict["onSegwbX"] = value
        }
        dict["segvbIdx"] = segvbIdx
        dict["segwbIdx"] = segwbIdx
        dict["swbOn"] = swbOn
        dict["cbbOn"] = cbbOn
        dict["rvbSel"] = rvbSel
        dict["segbIdx"] = segbIdx
        dict["slbVal"] = slbVal
        dict["sbbIdx"] = sbbIdx
        dict["sbdDate"] = sbdDate
        dict["selectedRadiogroup"] = selectedRadiogroup
        
        return dict
    }

    #if DEBUG
    // Convert properties to binding dictionary for Dynamic mode reactivity
    // SwiftUI.Binding<T> values enable automatic re-rendering on changes
    func toDictionary(binding dataBinding: SwiftUI.Binding<OnClickVData>) -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Data properties as SwiftUI.Binding for reactivity
        if let onSwuV = onSwuV {
            dict["onSwuV"] = onSwuV
        }
        if let onSwuC = onSwuC {
            dict["onSwuC"] = onSwuC
        }
        if let onSwbV = onSwbV {
            dict["onSwbV"] = onSwbV
        }
        if let onSwbC = onSwbC {
            dict["onSwbC"] = onSwbC
        }
        if let onCbuV = onCbuV {
            dict["onCbuV"] = onCbuV
        }
        if let onCbuC = onCbuC {
            dict["onCbuC"] = onCbuC
        }
        if let onCbbV = onCbbV {
            dict["onCbbV"] = onCbbV
        }
        if let onCbbC = onCbbC {
            dict["onCbbC"] = onCbbC
        }
        if let onRvuV = onRvuV {
            dict["onRvuV"] = onRvuV
        }
        if let onRvuC = onRvuC {
            dict["onRvuC"] = onRvuC
        }
        if let onRvbV = onRvbV {
            dict["onRvbV"] = onRvbV
        }
        if let onRvbC = onRvbC {
            dict["onRvbC"] = onRvbC
        }
        if let onSeguV = onSeguV {
            dict["onSeguV"] = onSeguV
        }
        if let onSeguC = onSeguC {
            dict["onSeguC"] = onSeguC
        }
        if let onSegbV = onSegbV {
            dict["onSegbV"] = onSegbV
        }
        if let onSegbC = onSegbC {
            dict["onSegbC"] = onSegbC
        }
        if let onSluV = onSluV {
            dict["onSluV"] = onSluV
        }
        if let onSluC = onSluC {
            dict["onSluC"] = onSluC
        }
        if let onSlbV = onSlbV {
            dict["onSlbV"] = onSlbV
        }
        if let onSlbC = onSlbC {
            dict["onSlbC"] = onSlbC
        }
        if let onSbuV = onSbuV {
            dict["onSbuV"] = onSbuV
        }
        if let onSbuC = onSbuC {
            dict["onSbuC"] = onSbuC
        }
        if let onSbbV = onSbbV {
            dict["onSbbV"] = onSbbV
        }
        if let onSbbC = onSbbC {
            dict["onSbbC"] = onSbbC
        }
        if let onSbdV = onSbdV {
            dict["onSbdV"] = onSbdV
        }
        if let onSbdC = onSbdC {
            dict["onSbdC"] = onSbdC
        }
        if let onSegvuC = onSegvuC {
            dict["onSegvuC"] = onSegvuC
        }
        if let onSegvuV = onSegvuV {
            dict["onSegvuV"] = onSegvuV
        }
        if let onSegvbC = onSegvbC {
            dict["onSegvbC"] = onSegvbC
        }
        if let onSegvbV = onSegvbV {
            dict["onSegvbV"] = onSegvbV
        }
        if let onSegwuV = onSegwuV {
            dict["onSegwuV"] = onSegwuV
        }
        if let onSegwuC = onSegwuC {
            dict["onSegwuC"] = onSegwuC
        }
        if let onSegwuX = onSegwuX {
            dict["onSegwuX"] = onSegwuX
        }
        if let onSegwbV = onSegwbV {
            dict["onSegwbV"] = onSegwbV
        }
        if let onSegwbC = onSegwbC {
            dict["onSegwbC"] = onSegwbC
        }
        if let onSegwbX = onSegwbX {
            dict["onSegwbX"] = onSegwbX
        }
        dict["segvbIdx"] = SwiftUI.Binding<Int>(
            get: { dataBinding.wrappedValue.segvbIdx },
            set: { dataBinding.wrappedValue.segvbIdx = $0 }
        )
        dict["segwbIdx"] = SwiftUI.Binding<Int>(
            get: { dataBinding.wrappedValue.segwbIdx },
            set: { dataBinding.wrappedValue.segwbIdx = $0 }
        )
        dict["swbOn"] = SwiftUI.Binding<Bool>(
            get: { dataBinding.wrappedValue.swbOn },
            set: { dataBinding.wrappedValue.swbOn = $0 }
        )
        dict["cbbOn"] = SwiftUI.Binding<Bool>(
            get: { dataBinding.wrappedValue.cbbOn },
            set: { dataBinding.wrappedValue.cbbOn = $0 }
        )
        dict["rvbSel"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.rvbSel },
            set: { dataBinding.wrappedValue.rvbSel = $0 }
        )
        dict["segbIdx"] = SwiftUI.Binding<Int>(
            get: { dataBinding.wrappedValue.segbIdx },
            set: { dataBinding.wrappedValue.segbIdx = $0 }
        )
        dict["slbVal"] = SwiftUI.Binding<Double>(
            get: { dataBinding.wrappedValue.slbVal },
            set: { dataBinding.wrappedValue.slbVal = $0 }
        )
        dict["sbbIdx"] = SwiftUI.Binding<Int>(
            get: { dataBinding.wrappedValue.sbbIdx },
            set: { dataBinding.wrappedValue.sbbIdx = $0 }
        )
        dict["sbdDate"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.sbdDate },
            set: { dataBinding.wrappedValue.sbdDate = $0 }
        )
        dict["selectedRadiogroup"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.selectedRadiogroup },
            set: { dataBinding.wrappedValue.selectedRadiogroup = $0 }
        )
        
        return dict
    }
    #endif
}

struct OnClickVCodegenPaste: View {
    @SwiftUI.Binding var data: OnClickVData
    @State private var swuVIsOn: Bool = false
    @State private var cbuVIsOn: Bool = false
    @State private var selectedRvuv: String = "ua"
    @State private var selectedSeguv: Int = 0
    @State private var sliderValuesluV: Double = 0.2
    @State private var selectedSegvuv: Int = 0
    @State private var selectedSegwuv: Int = 0

    var body: some View {
            AnyView(section0())
    }

    @ViewBuilder private func section0() -> some View {
        VStack(alignment: .leading, spacing: 4) {
                Toggle(isOn: SwiftUI.Binding(get: { $swuVIsOn.wrappedValue }, set: { newValue in let changed = newValue != $swuVIsOn.wrappedValue; $swuVIsOn.wrappedValue = newValue; if changed { data.onSwuV?() }; data.onSwuC?() })) {
                    Text("")
                }
                    .labelsHidden()
                    .accessibilityIdentifier("swuV")
                Toggle(isOn: SwiftUI.Binding(get: { $data.swbOn.wrappedValue }, set: { newValue in let changed = newValue != $data.swbOn.wrappedValue; $data.swbOn.wrappedValue = newValue; if changed { data.onSwbV?() }; data.onSwbC?() })) {
                    Text("")
                }
                    .labelsHidden()
                    .accessibilityIdentifier("swbV")
                CheckBoxView(
                    isOn: $cbuVIsOn,
                    label: "cbu",
                    onValueChanged: { newValue in data.onCbuV?(); data.onCbuC?() }
                )
                    .accessibilityIdentifier("cbuV")
                CheckBoxView(
                    isOn: $data.cbbOn,
                    label: "cbb",
                    onValueChanged: { newValue in data.onCbbV?(); data.onCbbC?() }
                )
                    .accessibilityIdentifier("cbbV")
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: selectedRvuv == "ua" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedRvuv = "ua"
                            data.onRvuV?()
                            data.onRvuC?()
                        }
                        Text("ua")
                    }
                    HStack {
                        Image(systemName: selectedRvuv == "ub" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedRvuv = "ub"
                            data.onRvuV?()
                            data.onRvuC?()
                        }
                        Text("ub")
                    }
                }
                    .accessibilityIdentifier("rvuV")
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: data.rvbSel == "ba" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            data.rvbSel = "ba"
                            data.onRvbV?()
                            data.onRvbC?()
                        }
                        Text("ba")
                    }
                    HStack {
                        Image(systemName: data.rvbSel == "bb" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            data.rvbSel = "bb"
                            data.onRvbV?()
                            data.onRvbC?()
                        }
                        Text("bb")
                    }
                }
                    .accessibilityIdentifier("rvbV")
                Picker("", selection: SwiftUI.Binding(get: { $selectedSeguv.wrappedValue }, set: { newValue in let changed = newValue != $selectedSeguv.wrappedValue; $selectedSeguv.wrappedValue = newValue; if changed { data.onSeguV?() }; data.onSeguC?() })) {
                    Text("ux".localized()).tag(0)
                    Text("uy".localized()).tag(1)
                }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("seguV")
                Picker("", selection: SwiftUI.Binding(get: { $data.segbIdx.wrappedValue }, set: { newValue in let changed = newValue != $data.segbIdx.wrappedValue; $data.segbIdx.wrappedValue = newValue; if changed { data.onSegbV?() }; data.onSegbC?() })) {
                    Text("bx".localized()).tag(0)
                    Text("by".localized()).tag(1)
                }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("segbV")
                Slider(value: SwiftUI.Binding(get: { $sliderValuesluV.wrappedValue }, set: { newValue in let changed = newValue != $sliderValuesluV.wrappedValue; $sliderValuesluV.wrappedValue = newValue; if changed { data.onSluV?() } }), in: 0...1, onEditingChanged: { editing in if !editing { data.onSluC?() } })
                    .accessibilityIdentifier("sluV")
                Slider(value: SwiftUI.Binding(get: { $data.slbVal.wrappedValue }, set: { newValue in let changed = newValue != $data.slbVal.wrappedValue; $data.slbVal.wrappedValue = newValue; if changed { data.onSlbV?() } }), in: 0...1, onEditingChanged: { editing in if !editing { data.onSlbC?() } })
                    .accessibilityIdentifier("slbV")
                SelectBoxView(
                    id: "sbuV",
                    selectItemType: .normal,
                    items: ["up", "uq"],
                    selectedIndex: 0,
                    onValueChange: { newValue in data.onSbuV?(); data.onSbuC?() }
                )
                    .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                    .accessibilityIdentifier("sbuV")
                SelectBoxView(
                    id: "sbbV",
                    selectItemType: .normal,
                    items: ["bp", "bq"],
                    selectedIndexBinding: $data.sbbIdx,
                    onValueChange: { newValue in data.onSbbV?(); data.onSbbC?() }
                )
                    .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                    .accessibilityIdentifier("sbbV")
                SelectBoxView(
                    id: "sbdV",
                    selectItemType: .date,
                    datePickerMode: .date,
                    dateStringFormat: "yyyy-MM-dd",
                    selectedDate: data.sbdDate.toDate(format: "yyyy-MM-dd"),
                    onValueChange: { newValue in
                        data.sbdDate = newValue
                        data.onSbdV?()
                        data.onSbdC?()
                    }
                )
                    .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                    .accessibilityIdentifier("sbdV")
                Picker("", selection: SwiftUI.Binding(get: { $selectedSegvuv.wrappedValue }, set: { newValue in let changed = newValue != $selectedSegvuv.wrappedValue; $selectedSegvuv.wrappedValue = newValue; if changed { data.onSegvuV?() }; data.onSegvuC?() })) {
                    Text("p1".localized()).tag(0)
                    Text("p2".localized()).tag(1)
                }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("segvuV")
                Picker("", selection: SwiftUI.Binding(get: { $data.segvbIdx.wrappedValue }, set: { newValue in let changed = newValue != $data.segvbIdx.wrappedValue; $data.segvbIdx.wrappedValue = newValue; if changed { data.onSegvbV?() }; data.onSegvbC?() })) {
                    Text("q1".localized()).tag(0)
                    Text("q2".localized()).tag(1)
                }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("segvbV")
                Picker("", selection: SwiftUI.Binding(get: { $selectedSegwuv.wrappedValue }, set: { newValue in let changed = newValue != $selectedSegwuv.wrappedValue; $selectedSegwuv.wrappedValue = newValue; if changed { data.onSegwuV?() }; data.onSegwuC?() })) {
                    Text("r1".localized()).tag(0)
                    Text("r2".localized()).tag(1)
                }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("segwuV")
                Picker("", selection: SwiftUI.Binding(get: { $data.segwbIdx.wrappedValue }, set: { newValue in let changed = newValue != $data.segwbIdx.wrappedValue; $data.segwbIdx.wrappedValue = newValue; if changed { data.onSegwbV?() }; data.onSegwbC?() })) {
                    Text("s1".localized()).tag(0)
                    Text("s2".localized()).tag(1)
                }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("segwbV")
        }
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
