//
//  StaticInputsCodegenPaste.swift
//  ConformanceHost
//
//  What `sjui build` (sjui_tools of jsonui-cli rel/v1.8.121 = 32785ce8) emits
//  for a TextField, a TextView and two SelectBoxes (by selectedValue, and a
//  date) with static values — DynamicStateProbeView.layout(_, "inputs") —
//  the declarations and the generated body pasted unchanged, for ticket
//  static-valued-controls-do-not-change-on-a-users-tap. `data` stands in for
//  the generated StaticInputsData: the two focus flags the body reads.
//

import SwiftUI
import SwiftJsonUI

struct StaticInputsCodegenData {
    var tfIsFocused: Bool = false
    var tvIsFocused: Bool = false
}

struct StaticInputsCodegenPaste: View {
    @State private var data = StaticInputsCodegenData()
    @State private var tfText: String = "t0"
    @FocusState private var tfIsFocused: Bool
    @State private var tvText: String = "v0"
    @State private var sliderValuesln: Double = -2

    var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                    TextField("", text: $tfText)
                        .focused($tfIsFocused)
                        .onChange(of: data.tfIsFocused) { _, newValue in
                        tfIsFocused = newValue
                    }
                        .onChange(of: tfIsFocused) { _, newValue in
                        data.tfIsFocused = newValue
                    }
                        .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                        .accessibilityIdentifier("tf")
                    TextViewWithPlaceholder(
                        text: $tvText,
                        isFocused: $data.tvIsFocused
                    )
                        .frame(minHeight: 60, idealHeight: 60, maxHeight: 60)
                        .accessibilityIdentifier("tv")
                    SelectBoxView(
                        id: "sbv",
                        selectItemType: .normal,
                        items: ["pp", "qq"],
                        selectedIndex: 0,
                    )
                        .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                        .accessibilityIdentifier("sbv")
                    SelectBoxView(
                        id: "sbd",
                        selectItemType: .date,
                        datePickerMode: .date,
                        dateStringFormat: "yyyy-MM-dd",
                        selectedDate: "2026-01-02".toDate(format: "yyyy-MM-dd")
                    )
                        .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                        .accessibilityIdentifier("sbd")
                    Slider(value: $sliderValuesln, in: -2...1)
                        .accessibilityIdentifier("sln")
            }
                .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
