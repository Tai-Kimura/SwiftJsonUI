//
//  PickArityCodegenPaste.swift
//  ConformanceHost
//
//  What `sjui build` (sjui_tools of jsonui-cli triage/date-selectbox-index 452afd91) emits for
//  PickArityProbeView's layout — SelectBoxes whose onValueChange is declared
//  `(String)`, `(String, Int)` and `(String, String)` — the generated Data
//  struct, the view-local state, the body and its sections, pasted unchanged.
//  For ticket control-onclick-is-called-differently-on-every-path.
//

import SwiftUI
import SwiftJsonUI

struct PickArityData {
    // Data properties from JSON
    var pSi: ((String) -> Void)? = nil
    var pSx: ((String) -> Void)? = nil
    var pSn: ((String) -> Void)? = nil
    var pIi: ((String, Int) -> Void)? = nil
    var pIx: ((String, Int) -> Void)? = nil
    var pIn: ((String, Int) -> Void)? = nil
    var pNi: ((String, String) -> Void)? = nil
    var pNx: ((String, String) -> Void)? = nil
    var pNn: ((String, String) -> Void)? = nil
    var dS: ((String) -> Void)? = nil
    var dN: ((String, String) -> Void)? = nil
    var aI: ((String, Int) -> Void)? = nil
    var aN: ((String, String) -> Void)? = nil
    var dI: ((String, Int) -> Void)? = nil
    var dayI: String = "2026-01-02"
    var selS: String = ""
    var idxS: Int = 0
    var selI: String = ""
    var idxI: Int = 0
    var selN: String = ""
    var idxN: Int = 0
    var dayS: String = "2026-01-02"
    var dayN: String = "2026-01-02"

    // Update properties from dictionary
    mutating func update(dictionary: [String: Any]) {
        if let value = dictionary["pSi"] {
            if let typedValue = value as? ((String) -> Void)? {
                self.pSi = typedValue
            }
        }
        if let value = dictionary["pSx"] {
            if let typedValue = value as? ((String) -> Void)? {
                self.pSx = typedValue
            }
        }
        if let value = dictionary["pSn"] {
            if let typedValue = value as? ((String) -> Void)? {
                self.pSn = typedValue
            }
        }
        if let value = dictionary["pIi"] {
            if let typedValue = value as? ((String, Int) -> Void)? {
                self.pIi = typedValue
            }
        }
        if let value = dictionary["pIx"] {
            if let typedValue = value as? ((String, Int) -> Void)? {
                self.pIx = typedValue
            }
        }
        if let value = dictionary["pIn"] {
            if let typedValue = value as? ((String, Int) -> Void)? {
                self.pIn = typedValue
            }
        }
        if let value = dictionary["pNi"] {
            if let typedValue = value as? ((String, String) -> Void)? {
                self.pNi = typedValue
            }
        }
        if let value = dictionary["pNx"] {
            if let typedValue = value as? ((String, String) -> Void)? {
                self.pNx = typedValue
            }
        }
        if let value = dictionary["pNn"] {
            if let typedValue = value as? ((String, String) -> Void)? {
                self.pNn = typedValue
            }
        }
        if let value = dictionary["dS"] {
            if let typedValue = value as? ((String) -> Void)? {
                self.dS = typedValue
            }
        }
        if let value = dictionary["dN"] {
            if let typedValue = value as? ((String, String) -> Void)? {
                self.dN = typedValue
            }
        }
        if let value = dictionary["aI"] {
            if let typedValue = value as? ((String, Int) -> Void)? {
                self.aI = typedValue
            }
        }
        if let value = dictionary["aN"] {
            if let typedValue = value as? ((String, String) -> Void)? {
                self.aN = typedValue
            }
        }
        if let value = dictionary["dI"] {
            if let typedValue = value as? ((String, Int) -> Void)? {
                self.dI = typedValue
            }
        }
        if let value = dictionary["dayI"] {
            if let stringValue = value as? String {
                self.dayI = stringValue
            }
        }
        if let value = dictionary["selS"] {
            if let stringValue = value as? String {
                self.selS = stringValue
            }
        }
        if let value = dictionary["idxS"] {
            if let intValue = value as? Int {
                self.idxS = intValue
            }
        }
        if let value = dictionary["selI"] {
            if let stringValue = value as? String {
                self.selI = stringValue
            }
        }
        if let value = dictionary["idxI"] {
            if let intValue = value as? Int {
                self.idxI = intValue
            }
        }
        if let value = dictionary["selN"] {
            if let stringValue = value as? String {
                self.selN = stringValue
            }
        }
        if let value = dictionary["idxN"] {
            if let intValue = value as? Int {
                self.idxN = intValue
            }
        }
        if let value = dictionary["dayS"] {
            if let stringValue = value as? String {
                self.dayS = stringValue
            }
        }
        if let value = dictionary["dayN"] {
            if let stringValue = value as? String {
                self.dayN = stringValue
            }
        }
    }

    // Convert properties to dictionary for Dynamic mode
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Data properties
        if let value = pSi {
            dict["pSi"] = value
        }
        if let value = pSx {
            dict["pSx"] = value
        }
        if let value = pSn {
            dict["pSn"] = value
        }
        if let value = pIi {
            dict["pIi"] = value
        }
        if let value = pIx {
            dict["pIx"] = value
        }
        if let value = pIn {
            dict["pIn"] = value
        }
        if let value = pNi {
            dict["pNi"] = value
        }
        if let value = pNx {
            dict["pNx"] = value
        }
        if let value = pNn {
            dict["pNn"] = value
        }
        if let value = dS {
            dict["dS"] = value
        }
        if let value = dN {
            dict["dN"] = value
        }
        if let value = aI {
            dict["aI"] = value
        }
        if let value = aN {
            dict["aN"] = value
        }
        if let value = dI {
            dict["dI"] = value
        }
        dict["dayI"] = dayI
        dict["selS"] = selS
        dict["idxS"] = idxS
        dict["selI"] = selI
        dict["idxI"] = idxI
        dict["selN"] = selN
        dict["idxN"] = idxN
        dict["dayS"] = dayS
        dict["dayN"] = dayN
        
        return dict
    }

    #if DEBUG
    // Convert properties to binding dictionary for Dynamic mode reactivity
    // SwiftUI.Binding<T> values enable automatic re-rendering on changes
    func toDictionary(binding dataBinding: SwiftUI.Binding<PickArityData>) -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Data properties as SwiftUI.Binding for reactivity
        if let pSi = pSi {
            dict["pSi"] = pSi
        }
        if let pSx = pSx {
            dict["pSx"] = pSx
        }
        if let pSn = pSn {
            dict["pSn"] = pSn
        }
        if let pIi = pIi {
            dict["pIi"] = pIi
        }
        if let pIx = pIx {
            dict["pIx"] = pIx
        }
        if let pIn = pIn {
            dict["pIn"] = pIn
        }
        if let pNi = pNi {
            dict["pNi"] = pNi
        }
        if let pNx = pNx {
            dict["pNx"] = pNx
        }
        if let pNn = pNn {
            dict["pNn"] = pNn
        }
        if let dS = dS {
            dict["dS"] = dS
        }
        if let dN = dN {
            dict["dN"] = dN
        }
        if let aI = aI {
            dict["aI"] = aI
        }
        if let aN = aN {
            dict["aN"] = aN
        }
        if let dI = dI {
            dict["dI"] = dI
        }
        dict["dayI"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.dayI },
            set: { dataBinding.wrappedValue.dayI = $0 }
        )
        dict["selS"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.selS },
            set: { dataBinding.wrappedValue.selS = $0 }
        )
        dict["idxS"] = SwiftUI.Binding<Int>(
            get: { dataBinding.wrappedValue.idxS },
            set: { dataBinding.wrappedValue.idxS = $0 }
        )
        dict["selI"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.selI },
            set: { dataBinding.wrappedValue.selI = $0 }
        )
        dict["idxI"] = SwiftUI.Binding<Int>(
            get: { dataBinding.wrappedValue.idxI },
            set: { dataBinding.wrappedValue.idxI = $0 }
        )
        dict["selN"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.selN },
            set: { dataBinding.wrappedValue.selN = $0 }
        )
        dict["idxN"] = SwiftUI.Binding<Int>(
            get: { dataBinding.wrappedValue.idxN },
            set: { dataBinding.wrappedValue.idxN = $0 }
        )
        dict["dayS"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.dayS },
            set: { dataBinding.wrappedValue.dayS = $0 }
        )
        dict["dayN"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.dayN },
            set: { dataBinding.wrappedValue.dayN = $0 }
        )
        
        return dict
    }
    #endif
}

struct PickArityCodegenPaste: View {
    @SwiftUI.Binding var data: PickArityData


    var body: some View {
            AnyView(section0())
    }

    @ViewBuilder private func section0() -> some View {
        VStack(alignment: .leading, spacing: 3) {
                SelectBoxView(
                    id: "sbSi",
                    selectItemType: .normal,
                    items: ["Si1", "Si2"],
                    selectedIndexBinding: SwiftUI.Binding(get: { ["Si1", "Si2"].firstIndex(of: (data.selS)) ?? -1 }, set: { index in data.selS = ["Si1", "Si2"].indices.contains(index) ? ["Si1", "Si2"][index] : "" }),
                    onValueChange: { newValue in data.pSi?(newValue) }
                )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
                    .accessibilityIdentifier("sbSi")
                SelectBoxView(
                    id: "sbSx",
                    selectItemType: .normal,
                    items: ["Sx1", "Sx2"],
                    selectedIndexBinding: $data.idxS,
                    onValueChange: { newValue in data.pSx?(newValue) }
                )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
                    .accessibilityIdentifier("sbSx")
                SelectBoxView(
                    id: "sbSn",
                    selectItemType: .normal,
                    items: ["Sn1", "Sn2"],
                    onValueChange: { newValue in data.pSn?(newValue) }
                )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
                    .accessibilityIdentifier("sbSn")
                SelectBoxView(
                    id: "sbIi",
                    selectItemType: .normal,
                    items: ["Ii1", "Ii2"],
                    selectedIndexBinding: SwiftUI.Binding(get: { ["Ii1", "Ii2"].firstIndex(of: (data.selI)) ?? -1 }, set: { index in data.selI = ["Ii1", "Ii2"].indices.contains(index) ? ["Ii1", "Ii2"][index] : "" }),
                    onValueChange: { newValue in data.pIi?("sbIi", (["Ii1", "Ii2"].firstIndex(of: newValue) ?? -1)) }
                )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
                    .accessibilityIdentifier("sbIi")
                SelectBoxView(
                    id: "sbIx",
                    selectItemType: .normal,
                    items: ["Ix1", "Ix2"],
                    selectedIndexBinding: $data.idxI,
                    onValueChange: { newValue in data.pIx?("sbIx", data.idxI) }
                )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
                    .accessibilityIdentifier("sbIx")
                SelectBoxView(
                    id: "sbIn",
                    selectItemType: .normal,
                    items: ["In1", "In2"],
                    onValueChange: { newValue in data.pIn?("sbIn", (["In1", "In2"].firstIndex(of: newValue) ?? -1)) }
                )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
                    .accessibilityIdentifier("sbIn")
                SelectBoxView(
                    id: "sbNi",
                    selectItemType: .normal,
                    items: ["Ni1", "Ni2"],
                    selectedIndexBinding: SwiftUI.Binding(get: { ["Ni1", "Ni2"].firstIndex(of: (data.selN)) ?? -1 }, set: { index in data.selN = ["Ni1", "Ni2"].indices.contains(index) ? ["Ni1", "Ni2"][index] : "" }),
                    onValueChange: { newValue in data.pNi?("sbNi", newValue) }
                )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
                    .accessibilityIdentifier("sbNi")
                SelectBoxView(
                    id: "sbNx",
                    selectItemType: .normal,
                    items: ["Nx1", "Nx2"],
                    selectedIndexBinding: $data.idxN,
                    onValueChange: { newValue in data.pNx?("sbNx", newValue) }
                )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
                    .accessibilityIdentifier("sbNx")
                SelectBoxView(
                    id: "sbNn",
                    selectItemType: .normal,
                    items: ["Nn1", "Nn2"],
                    onValueChange: { newValue in data.pNn?("sbNn", newValue) }
                )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
                    .accessibilityIdentifier("sbNn")
                SelectBoxView(
                    id: "sbDS",
                    selectItemType: .date,
                    datePickerMode: .date,
                    dateStringFormat: "yyyy-MM-dd",
                    selectedDate: data.dayS.toDate(format: "yyyy-MM-dd"),
                    onValueChange: { newValue in
                        data.dayS = newValue
                        data.dS?(newValue)
                    }
                )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
                    .accessibilityIdentifier("sbDS")
                SelectBoxView(
                    id: "sbDN",
                    selectItemType: .date,
                    datePickerMode: .date,
                    dateStringFormat: "yyyy-MM-dd",
                    selectedDate: data.dayN.toDate(format: "yyyy-MM-dd"),
                    onValueChange: { newValue in
                        data.dayN = newValue
                        data.dN?("sbDN", newValue)
                    }
                )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
                    .accessibilityIdentifier("sbDN")
                SelectBoxView(
                    id: "selectBox_0_11",
                    selectItemType: .normal,
                    items: ["aI1", "aI2"],
                    selectedIndex: 0,
                    onValueChange: { newValue in data.aI?("selectBox_0_11", (["aI1", "aI2"].firstIndex(of: newValue) ?? -1)) }
                )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
                SelectBoxView(
                    id: "selectBox_0_12",
                    selectItemType: .normal,
                    items: ["aN1", "aN2"],
                    selectedIndex: 0,
                    onValueChange: { newValue in data.aN?("selectBox_0_12", newValue) }
                )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
                SelectBoxView(
                    id: "sbDI",
                    selectItemType: .date,
                    datePickerMode: .date,
                    dateStringFormat: "yyyy-MM-dd",
                    selectedDate: data.dayI.toDate(format: "yyyy-MM-dd"),
                    onValueChange: { newValue in
                        data.dayI = newValue
                        // ERROR: SelectBox.onValueChange dI is not called: a date SelectBox has no index: declare onValueChange as (String) or (String, String)
                    }
                )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
                    .accessibilityIdentifier("sbDI")
        }
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
