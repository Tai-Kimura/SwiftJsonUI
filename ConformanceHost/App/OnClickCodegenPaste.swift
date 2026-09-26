//
//  OnClickCodegenPaste.swift
//  ConformanceHost
//
//  What `sjui build` (sjui_tools of jsonui-cli rel/v1.8.121 = 2f654ab3) emits for
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
            AnyView(section0())
    }

    @ViewBuilder private func section0() -> some View {
        VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: $swNIsOn) {
                    Text("")
                }
                    .labelsHidden()
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.onSwN?()
                        }
                    .accessibilityIdentifier("swN")
                CheckBoxView(
                    isOn: $cbNIsOn,
                    label: "cbl",
                    onValueChanged: { newValue in data.onCbN?() }
                )
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.onCbN?()
                        }
                    .accessibilityIdentifier("cbN")
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: selectedRvn == "ra" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedRvn = "ra"
                        }
                        Text("ra")
                    }
                    HStack {
                        Image(systemName: selectedRvn == "rb" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedRvn = "rb"
                        }
                        Text("rb")
                    }
                }
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.onRvN?()
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
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.onRgaN?()
                        }
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
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.onRgbN?()
                        }
                    .accessibilityIdentifier("rgbN")
                Picker("", selection: $selectedSegn) {
                    Text("sx".localized()).tag(0)
                    Text("sy".localized()).tag(1)
                }
                    .pickerStyle(.segmented)
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.onSegN?()
                        }
                    .accessibilityIdentifier("segN")
                Slider(value: $sliderValueslN, in: 0...1)
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.onSlN?()
                        }
                    .accessibilityIdentifier("slN")
                SelectBoxView(
                    id: "sbN",
                    selectItemType: .normal,
                    items: ["pp", "qq"],
                    selectedIndex: 0,
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
                Toggle(isOn: $swlNIsOn) {
                    Text("swl label")
                }
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.onSwlN?()
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
                Toggle(isOn: $swEIsOn) {
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
                        }
                        Text("ra")
                    }
                    HStack {
                        Image(systemName: selectedRve == "rb" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedRve = "rb"
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
                Picker("", selection: $selectedSege) {
                    Text("sx".localized()).tag(0)
                    Text("sy".localized()).tag(1)
                }
                    .pickerStyle(.segmented)
                    .disabled(true)
                    .accessibilityIdentifier("segE")
                    .disabled(true)
                Slider(value: $sliderValueslE, in: 0...1)
                    .disabled(true)
                    .disabled(true)
                    .accessibilityIdentifier("slE")
                    .disabled(true)
                SelectBoxView(
                    id: "sbE",
                    selectItemType: .normal,
                    items: ["pp", "qq"],
                    selectedIndex: 0,
                )
                    .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                    .accessibilityIdentifier("sbE")
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
                Toggle(isOn: $swlEIsOn) {
                    Text("swl label")
                }
                    .disabled(true)
                    .accessibilityIdentifier("swlE")
                    .disabled(true)
        }
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
