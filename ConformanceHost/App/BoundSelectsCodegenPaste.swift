//
//  BoundSelectsCodegenPaste.swift
//  ConformanceHost
//
//  What `sjui build` (sjui_tools of jsonui-cli rel/v1.8.121 = 32785ce8) emits
//  for four SelectBoxes bound to the data — by selectedItem, selectedValue,
//  selectedDate and selectedIndex — the generated Data struct and the body,
//  pasted unchanged, for ticket selectbox-selected-item-binding-is-read-once.
//  DynamicStateProbeView's `bound` screen holds the data and moves it.
//

import SwiftUI
import SwiftJsonUI

struct BoundSelectsData {
    // Data properties from JSON
    var sbiSel: String = "pp".localized()
    var sbvSel: String = "pp".localized()
    var sbdDate: String = "2026-01-02"
    var sbIdx: Int = 0

    // Update properties from dictionary
    mutating func update(dictionary: [String: Any]) {
        if let value = dictionary["sbiSel"] {
            if let stringValue = value as? String {
                self.sbiSel = stringValue
            }
        }
        if let value = dictionary["sbvSel"] {
            if let stringValue = value as? String {
                self.sbvSel = stringValue
            }
        }
        if let value = dictionary["sbdDate"] {
            if let stringValue = value as? String {
                self.sbdDate = stringValue
            }
        }
        if let value = dictionary["sbIdx"] {
            if let intValue = value as? Int {
                self.sbIdx = intValue
            }
        }
    }

    // Convert properties to dictionary for Dynamic mode
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Data properties
        dict["sbiSel"] = sbiSel
        dict["sbvSel"] = sbvSel
        dict["sbdDate"] = sbdDate
        dict["sbIdx"] = sbIdx
        
        return dict
    }

    #if DEBUG
    // Convert properties to binding dictionary for Dynamic mode reactivity
    // SwiftUI.Binding<T> values enable automatic re-rendering on changes
    func toDictionary(binding dataBinding: SwiftUI.Binding<BoundSelectsData>) -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Data properties as SwiftUI.Binding for reactivity
        dict["sbiSel"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.sbiSel },
            set: { dataBinding.wrappedValue.sbiSel = $0 }
        )
        dict["sbvSel"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.sbvSel },
            set: { dataBinding.wrappedValue.sbvSel = $0 }
        )
        dict["sbdDate"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.sbdDate },
            set: { dataBinding.wrappedValue.sbdDate = $0 }
        )
        dict["sbIdx"] = SwiftUI.Binding<Int>(
            get: { dataBinding.wrappedValue.sbIdx },
            set: { dataBinding.wrappedValue.sbIdx = $0 }
        )
        
        return dict
    }
    #endif
}

struct BoundSelectsCodegenPaste: View {
    @SwiftUI.Binding var data: BoundSelectsData

    var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                    SelectBoxView(
                        id: "sbi",
                        selectItemType: .normal,
                        items: ["pp", "qq"],
                        selectedIndex: ["pp", "qq"].firstIndex(of: (data.sbiSel)),
                    )
                        .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                        .accessibilityIdentifier("sbi")
                    SelectBoxView(
                        id: "sbv",
                        selectItemType: .normal,
                        items: ["pp", "qq"],
                        selectedIndex: ["pp", "qq"].firstIndex(of: (data.sbvSel)),
                    )
                        .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                        .accessibilityIdentifier("sbv")
                    SelectBoxView(
                        id: "sbd",
                        selectItemType: .date,
                        datePickerMode: .date,
                        dateStringFormat: "yyyy-MM-dd",
                        selectedDate: data.sbdDate.toDate(format: "yyyy-MM-dd"),
                        onValueChange: { newValue in
                            data.sbdDate = newValue
                        }
                    )
                        .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                        .accessibilityIdentifier("sbd")
                    SelectBoxView(
                        id: "sb",
                        selectItemType: .normal,
                        items: ["pp", "qq"],
                        selectedIndexBinding: $data.sbIdx,
                    )
                        .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                        .accessibilityIdentifier("sb")
            }
                .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
