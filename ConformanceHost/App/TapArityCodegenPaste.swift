//
//  TapArityCodegenPaste.swift
//  ConformanceHost
//
//  What `sjui build` (sjui_tools of jsonui-cli triage/lifecycle-spellings 80b1df75) emits for
//  TapArityProbeView's layout — a tap, a long press, onAppear and onDisappear
//  on every port, their handlers declared `(String)` — the generated Data
//  struct, the view-local state, the body and its sections, pasted unchanged.
//  For ticket control-onclick-is-called-differently-on-every-path.
//
//  The last row, a ProgressBar the app registers (0_16), comes from sjui_tools
//  of jsonui-cli support/kjui-type-synonym-canon edd494e6 with
//  triage/lifecycle-spellings 38e9d38b merged in, and a probe converter that
//  maps ProgressBar to `ProbeProgressBar()` with the common modifiers
//  (`add_line 'ProbeProgressBar()'` then `apply_modifiers`). What is applied
//  here is the difference between that build's output for the layout without
//  the row and with it. The same build emits the first sixteen rows as they
//  are pasted.
//

import SwiftUI
import SwiftJsonUI

struct TapArityData {
    // Data properties from JSON
    var tS: ((String) -> Void)? = nil
    var iS: ((String) -> Void)? = nil
    var lS: ((String) -> Void)? = nil
    var sS: ((String) -> Void)? = nil
    var bS: ((String) -> Void)? = nil
    var wS: ((String) -> Void)? = nil
    var pS: ((String) -> Void)? = nil
    var aS: ((String) -> Void)? = nil
    var dS: ((String) -> Void)? = nil
    var aB: ((String) -> Void)? = nil
    var aC: ((String) -> Void)? = nil
    var dB: ((String) -> Void)? = nil
    var dC: ((String) -> Void)? = nil
    var t0: (() -> Void)? = nil
    var a0: (() -> Void)? = nil
    var a0b: (() -> Void)? = nil
    var a0c: (() -> Void)? = nil
    var d0: (() -> Void)? = nil
    var d0b: (() -> Void)? = nil
    var d0c: (() -> Void)? = nil
    var shown: String = "visible".localized()
    var txt0: String = "tap tS"
    var txt1: String = "tap t0"
    var txt2: String = "img iS"
    var txt3: String = "tap lS"
    var txt4: String = "tap sS"
    var txt5: String = "tap bS"
    var txt6: String = "press pS"
    var txt7: String = "appear aS"
    var txt8: String = "gone dS"
    var pbS: ((String) -> Void)? = nil

    // Update properties from dictionary
    mutating func update(dictionary: [String: Any]) {
        if let value = dictionary["tS"] {
            if let typedValue = value as? ((String) -> Void)? {
                self.tS = typedValue
            }
        }
        if let value = dictionary["iS"] {
            if let typedValue = value as? ((String) -> Void)? {
                self.iS = typedValue
            }
        }
        if let value = dictionary["lS"] {
            if let typedValue = value as? ((String) -> Void)? {
                self.lS = typedValue
            }
        }
        if let value = dictionary["sS"] {
            if let typedValue = value as? ((String) -> Void)? {
                self.sS = typedValue
            }
        }
        if let value = dictionary["bS"] {
            if let typedValue = value as? ((String) -> Void)? {
                self.bS = typedValue
            }
        }
        if let value = dictionary["wS"] {
            if let typedValue = value as? ((String) -> Void)? {
                self.wS = typedValue
            }
        }
        if let value = dictionary["pS"] {
            if let typedValue = value as? ((String) -> Void)? {
                self.pS = typedValue
            }
        }
        if let value = dictionary["aS"] {
            if let typedValue = value as? ((String) -> Void)? {
                self.aS = typedValue
            }
        }
        if let value = dictionary["dS"] {
            if let typedValue = value as? ((String) -> Void)? {
                self.dS = typedValue
            }
        }
        if let value = dictionary["aB"] {
            if let typedValue = value as? ((String) -> Void)? {
                self.aB = typedValue
            }
        }
        if let value = dictionary["aC"] {
            if let typedValue = value as? ((String) -> Void)? {
                self.aC = typedValue
            }
        }
        if let value = dictionary["dB"] {
            if let typedValue = value as? ((String) -> Void)? {
                self.dB = typedValue
            }
        }
        if let value = dictionary["dC"] {
            if let typedValue = value as? ((String) -> Void)? {
                self.dC = typedValue
            }
        }
        if let value = dictionary["t0"] {
            if let typedValue = value as? (() -> Void)? {
                self.t0 = typedValue
            }
        }
        if let value = dictionary["a0"] {
            if let typedValue = value as? (() -> Void)? {
                self.a0 = typedValue
            }
        }
        if let value = dictionary["a0b"] {
            if let typedValue = value as? (() -> Void)? {
                self.a0b = typedValue
            }
        }
        if let value = dictionary["a0c"] {
            if let typedValue = value as? (() -> Void)? {
                self.a0c = typedValue
            }
        }
        if let value = dictionary["d0"] {
            if let typedValue = value as? (() -> Void)? {
                self.d0 = typedValue
            }
        }
        if let value = dictionary["d0b"] {
            if let typedValue = value as? (() -> Void)? {
                self.d0b = typedValue
            }
        }
        if let value = dictionary["d0c"] {
            if let typedValue = value as? (() -> Void)? {
                self.d0c = typedValue
            }
        }
        if let value = dictionary["shown"] {
            if let stringValue = value as? String {
                self.shown = stringValue
            }
        }
        if let value = dictionary["txt0"] {
            if let stringValue = value as? String {
                self.txt0 = stringValue
            }
        }
        if let value = dictionary["txt1"] {
            if let stringValue = value as? String {
                self.txt1 = stringValue
            }
        }
        if let value = dictionary["txt2"] {
            if let stringValue = value as? String {
                self.txt2 = stringValue
            }
        }
        if let value = dictionary["txt3"] {
            if let stringValue = value as? String {
                self.txt3 = stringValue
            }
        }
        if let value = dictionary["txt4"] {
            if let stringValue = value as? String {
                self.txt4 = stringValue
            }
        }
        if let value = dictionary["txt5"] {
            if let stringValue = value as? String {
                self.txt5 = stringValue
            }
        }
        if let value = dictionary["txt6"] {
            if let stringValue = value as? String {
                self.txt6 = stringValue
            }
        }
        if let value = dictionary["txt7"] {
            if let stringValue = value as? String {
                self.txt7 = stringValue
            }
        }
        if let value = dictionary["txt8"] {
            if let stringValue = value as? String {
                self.txt8 = stringValue
            }
        }
        if let value = dictionary["pbS"] {
            if let typedValue = value as? ((String) -> Void)? {
                self.pbS = typedValue
            }
        }
    }

    // Convert properties to dictionary for Dynamic mode
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Data properties
        if let value = tS {
            dict["tS"] = value
        }
        if let value = iS {
            dict["iS"] = value
        }
        if let value = lS {
            dict["lS"] = value
        }
        if let value = sS {
            dict["sS"] = value
        }
        if let value = bS {
            dict["bS"] = value
        }
        if let value = wS {
            dict["wS"] = value
        }
        if let value = pS {
            dict["pS"] = value
        }
        if let value = aS {
            dict["aS"] = value
        }
        if let value = dS {
            dict["dS"] = value
        }
        if let value = aB {
            dict["aB"] = value
        }
        if let value = aC {
            dict["aC"] = value
        }
        if let value = dB {
            dict["dB"] = value
        }
        if let value = dC {
            dict["dC"] = value
        }
        if let value = t0 {
            dict["t0"] = value
        }
        if let value = a0 {
            dict["a0"] = value
        }
        if let value = a0b {
            dict["a0b"] = value
        }
        if let value = a0c {
            dict["a0c"] = value
        }
        if let value = d0 {
            dict["d0"] = value
        }
        if let value = d0b {
            dict["d0b"] = value
        }
        if let value = d0c {
            dict["d0c"] = value
        }
        dict["shown"] = shown
        dict["txt0"] = txt0
        dict["txt1"] = txt1
        dict["txt2"] = txt2
        dict["txt3"] = txt3
        dict["txt4"] = txt4
        dict["txt5"] = txt5
        dict["txt6"] = txt6
        dict["txt7"] = txt7
        dict["txt8"] = txt8
        if let value = pbS {
            dict["pbS"] = value
        }
        
        return dict
    }

    #if DEBUG
    // Convert properties to binding dictionary for Dynamic mode reactivity
    // SwiftUI.Binding<T> values enable automatic re-rendering on changes
    func toDictionary(binding dataBinding: SwiftUI.Binding<TapArityData>) -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Data properties as SwiftUI.Binding for reactivity
        if let tS = tS {
            dict["tS"] = tS
        }
        if let iS = iS {
            dict["iS"] = iS
        }
        if let lS = lS {
            dict["lS"] = lS
        }
        if let sS = sS {
            dict["sS"] = sS
        }
        if let bS = bS {
            dict["bS"] = bS
        }
        if let wS = wS {
            dict["wS"] = wS
        }
        if let pS = pS {
            dict["pS"] = pS
        }
        if let aS = aS {
            dict["aS"] = aS
        }
        if let dS = dS {
            dict["dS"] = dS
        }
        if let aB = aB {
            dict["aB"] = aB
        }
        if let aC = aC {
            dict["aC"] = aC
        }
        if let dB = dB {
            dict["dB"] = dB
        }
        if let dC = dC {
            dict["dC"] = dC
        }
        if let t0 = t0 {
            dict["t0"] = t0
        }
        if let a0 = a0 {
            dict["a0"] = a0
        }
        if let a0b = a0b {
            dict["a0b"] = a0b
        }
        if let a0c = a0c {
            dict["a0c"] = a0c
        }
        if let d0 = d0 {
            dict["d0"] = d0
        }
        if let d0b = d0b {
            dict["d0b"] = d0b
        }
        if let d0c = d0c {
            dict["d0c"] = d0c
        }
        dict["shown"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.shown },
            set: { dataBinding.wrappedValue.shown = $0 }
        )
        dict["txt0"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.txt0 },
            set: { dataBinding.wrappedValue.txt0 = $0 }
        )
        dict["txt1"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.txt1 },
            set: { dataBinding.wrappedValue.txt1 = $0 }
        )
        dict["txt2"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.txt2 },
            set: { dataBinding.wrappedValue.txt2 = $0 }
        )
        dict["txt3"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.txt3 },
            set: { dataBinding.wrappedValue.txt3 = $0 }
        )
        dict["txt4"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.txt4 },
            set: { dataBinding.wrappedValue.txt4 = $0 }
        )
        dict["txt5"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.txt5 },
            set: { dataBinding.wrappedValue.txt5 = $0 }
        )
        dict["txt6"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.txt6 },
            set: { dataBinding.wrappedValue.txt6 = $0 }
        )
        dict["txt7"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.txt7 },
            set: { dataBinding.wrappedValue.txt7 = $0 }
        )
        dict["txt8"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.txt8 },
            set: { dataBinding.wrappedValue.txt8 = $0 }
        )
        if let pbS = pbS {
            dict["pbS"] = pbS
        }
        
        return dict
    }
    #endif
}

struct TapArityCodegenPaste: View {
    @SwiftUI.Binding var data: TapArityData
    @State private var toggle_0_6IsOn: Bool = false

    var body: some View {
            AnyView(section0())
    }

    @ViewBuilder private func section0() -> some View {
        VStack(alignment: .leading, spacing: 4) {
                ZStack(alignment: .topLeading) {
                    Group {
                        PartialAttributedText(
                            "\(data.txt0)",
                            fontSize: 12,
                            textAlignment: .leading
                        )
                    }
                }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 34, idealHeight: 34, maxHeight: 34)
                    .background(SwiftJsonUIConfiguration.shared.getColor(for: "pale_gray") ?? Color.black)
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.tS?("view_0_0")
                        }
                    .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("")
                ZStack(alignment: .topLeading) {
                    Group {
                        PartialAttributedText(
                            "\(data.txt1)",
                            fontSize: 12,
                            textAlignment: .leading
                        )
                    }
                }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 34, idealHeight: 34, maxHeight: 34)
                    .background(SwiftJsonUIConfiguration.shared.getColor(for: "pale_gray") ?? Color.black)
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.t0?()
                        }
                    .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("")
                Image("probe_none")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .accessibilityLabel(Text((data.txt2)))
                    .accessibilityHidden((data.txt2).isEmpty)
                    .frame(width: 60, height: 30)
                    .background(SwiftJsonUIConfiguration.shared.getColor(for: "pale_blue") ?? Color.black)
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.iS?("image_0_2")
                        }
                    .accessibilityAddTraits(.isButton)
                PartialAttributedText(
                    "\(data.txt3)",
                    fontSize: 12,
                    textAlignment: .leading
                )
                    .frame(minHeight: 30, idealHeight: 30, maxHeight: 30)
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.lS?("label_0_3")
                        }
                    .accessibilityAddTraits(.isButton)
                ZStack(alignment: .topLeading) {
                    Group {
                        PartialAttributedText(
                            "\(data.txt4)",
                            fontSize: 12,
                            textAlignment: .leading
                        )
                    }
                }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 34, idealHeight: 34, maxHeight: 34)
                    .background(SwiftJsonUIConfiguration.shared.getColor(for: "pale_gray") ?? Color.black)
                    .onTapGesture {
                        data.sS?("view_0_4")
                    }
                    .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("")
                StateAwareButtonView(
                    text: "\(data.txt5)",
                    action: { data.bS?("button_0_5") },
                    isEnabled: true,
                    height: 34
                )
                    .frame(minHeight: 34, idealHeight: 34, maxHeight: 34)
                Toggle(isOn: SwiftUI.Binding(get: { $toggle_0_6IsOn.wrappedValue }, set: { newValue in $toggle_0_6IsOn.wrappedValue = newValue; data.wS?("switch_0_6") })) {
                    Text("")
                }
                    .labelsHidden()
                ZStack(alignment: .topLeading) {
                    Group {
                        PartialAttributedText(
                            "\(data.txt6)",
                            fontSize: 12,
                            textAlignment: .leading
                        )
                    }
                }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 34, idealHeight: 34, maxHeight: 34)
                    .background(SwiftJsonUIConfiguration.shared.getColor(for: "pale_gray") ?? Color.black)
                    .onLongPressGesture {
                        data.pS?("view_0_7")
                    }
                ZStack(alignment: .topLeading) {
                    Group {
                        PartialAttributedText(
                            "\(data.txt7)",
                            fontSize: 12,
                            textAlignment: .leading
                        )
                    }
                }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 34, idealHeight: 34, maxHeight: 34)
                    .background(SwiftJsonUIConfiguration.shared.getColor(for: "pale_gray") ?? Color.black)
                    .onAppear {
                            data.aS?("view_0_8")
                        }
            VisibilityWrapper(data.shown) {
                ZStack(alignment: .topLeading) {
                    Group {
                        PartialAttributedText(
                            "\(data.txt8)",
                            fontSize: 12,
                            textAlignment: .leading
                        )
                    }
                }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 34, idealHeight: 34, maxHeight: 34)
                    .background(SwiftJsonUIConfiguration.shared.getColor(for: "pale_gray") ?? Color.black)
                    .onDisappear {
                            data.dS?("view_0_9")
                        }
            }
                Rectangle()
                    .fill(SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 8, idealHeight: 8, maxHeight: 8)
                    .onAppear {
                            data.aB?("view_0_10")
                        }
                Rectangle()
                    .fill(SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 8, idealHeight: 8, maxHeight: 8)
                    .onAppear {
                            data.aC?("view_0_11")
                        }
                Rectangle()
                    .fill(SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 8, idealHeight: 8, maxHeight: 8)
                    .onAppear {
                            data.a0?()
                        }
                Rectangle()
                    .fill(SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 8, idealHeight: 8, maxHeight: 8)
                    .onAppear {
                            data.a0b?()
                        }
                Rectangle()
                    .fill(SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 8, idealHeight: 8, maxHeight: 8)
                    .onAppear {
                            data.a0c?()
                        }
            VisibilityWrapper(data.shown) {
                VStack(alignment: .leading, spacing: 0) {
                        Rectangle()
                            .fill(SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 8, idealHeight: 8, maxHeight: 8)
                            .onDisappear {
                                            data.dB?("view_0_15_0")
                                        }
                        Rectangle()
                            .fill(SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 8, idealHeight: 8, maxHeight: 8)
                            .onDisappear {
                                            data.dC?("view_0_15_1")
                                        }
                        Rectangle()
                            .fill(SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 8, idealHeight: 8, maxHeight: 8)
                            .onDisappear {
                                            data.d0?()
                                        }
                        Rectangle()
                            .fill(SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 8, idealHeight: 8, maxHeight: 8)
                            .onDisappear {
                                            data.d0b?()
                                        }
                        Rectangle()
                            .fill(SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 8, idealHeight: 8, maxHeight: 8)
                            .onDisappear {
                                            data.d0c?()
                                        }
                }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
                ProbeProgressBar()
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 8, idealHeight: 8, maxHeight: 8)
                    .background(SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black)
                    .onAppear {
                            data.pbS?("progressBar_0_16")
                        }
        }
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
