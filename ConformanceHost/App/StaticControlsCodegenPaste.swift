//
//  StaticControlsCodegenPaste.swift
//  ConformanceHost
//
//  What `sjui build` (sjui_tools of jsonui-cli rel/v1.8.121 = 24f7fad0) emits
//  for a layout of controls with static values — the @State declarations and
//  the generated sections, pasted unchanged — so DynamicStateProbeView's
//  `codegen` form can tap the codegen path next to the dynamic one (ticket
//  static-valued-controls-do-not-change-on-a-users-tap). The layout is
//  DynamicStateProbeView.layout("static"), Toggle written as Switch (the
//  normalizer's canonical type).
//

import SwiftUI
import SwiftJsonUI

struct StaticControlsCodegenPaste: View {
    @State private var swIsOn: Bool = false
    @State private var tgIsOn: Bool = false
    @State private var cbIsOn: Bool = false
    @State private var selectedRv: String = "ra"
    @State private var selectedGrp: String = "rg1"
    // sjui emitted a second `@State private var selectedGrp: String = ""` here — one
    // per Radio of the group, deduplicated as whole lines, so the checked
    // option's seed and the other's empty one both stay: "invalid redeclaration
    // of 'selectedGrp'" (measured 2026-09-26, Xcode 26.6). The only line not
    // pasted unchanged.
    @State private var selectedSeg: Int = 0
    @State private var tabSelection: Int = 0
    @State private var sliderValuesl: Double = 0.2

    var body: some View {
        section0()
    }

    @ViewBuilder private func section0() -> some View {
        VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $swIsOn) {
                    Text("")
                }
                    .labelsHidden()
                    .accessibilityIdentifier("sw")
                Toggle(isOn: $tgIsOn) {
                    Text("")
                }
                    .labelsHidden()
                    .accessibilityIdentifier("tg")
                CheckBoxView(
                    isOn: $cbIsOn,
                    label: "cbl",
                )
                    .accessibilityIdentifier("cb")
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: selectedRv == "ra" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedRv = "ra"
                        }
                        Text("ra")
                    }
                    HStack {
                        Image(systemName: selectedRv == "rb" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            selectedRv = "rb"
                        }
                        Text("rb")
                    }
                }
                    .accessibilityIdentifier("rv")
                HStack {
                    Image(systemName: selectedGrp == "rg1" ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(.blue)
                        .onTapGesture {
                        selectedGrp = "rg1"
                    }
                    Text("rg1")
                }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("rg1")
                    .accessibilityIdentifier("rg1")
                HStack {
                    Image(systemName: selectedGrp == "rg2" ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(.blue)
                        .onTapGesture {
                        selectedGrp = "rg2"
                    }
                    Text("rg2")
                }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("rg2")
                    .accessibilityIdentifier("rg2")
                Picker("", selection: $selectedSeg) {
                    Text("sx".localized()).tag(0)
                    Text("sy".localized()).tag(1)
                }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("seg")
                ZStack(alignment: .topLeading) {
                    Group {
                        AnyView(section0_0())
                    }
                }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 130, idealHeight: 130, maxHeight: 130)
                Slider(value: $sliderValuesl, in: 0...1)
                    .accessibilityIdentifier("sl")
                SelectBoxView(
                    id: "sb",
                    selectItemType: .normal,
                    items: ["pp", "qq"],
                    selectedIndex: 0,
                )
                    .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                    .accessibilityIdentifier("sb")
                SelectBoxView(
                    id: "sbi",
                    selectItemType: .normal,
                    items: ["pp", "qq"],
                    selectedIndex: 0,
                )
                    .frame(minHeight: 40, idealHeight: 40, maxHeight: 40)
                    .accessibilityIdentifier("sbi")
        }
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder private func section0_0() -> some View {
        TabView(selection: $tabSelection) {
            Text("ta")
                .tabItem {
                    Label("ta", systemImage: "circle")
                }
                .tag(0)
            Text("tb")
                .tabItem {
                    Label("tb", systemImage: "circle")
                }
                .tag(1)
        }
            .accessibilityIdentifier("tab")
    }
}
