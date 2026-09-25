//
//  CanTapCodegenProbeView.swift
//  ConformanceHost
//
//  What `canTap` stops on the codegen types that call the onClick handler
//  from their own operation — an IconLabel's action, a Radio's selection, a
//  CheckBox's value change — and on an Image, whose converter registers its
//  own tap. NOT part of the conformance suite. Launch with
//  `-canTapCodegenProbe`.
//
//  What `jui build` (sjui_tools, JsonToSwiftUIConverter) emits for each under
//  no canTap, `canTap: false`, and a binding resolving false (`gateClosed`)
//  and true (`gateOpen`), pasted unchanged; the `@State` properties are the
//  ones the emission names (the generated view declares them).
//
//  Every handler counts its calls into a label the UI test reads, with the
//  radios' selections and the checkboxes' values.
//

import SwiftUI
import SwiftJsonUI

final class CanTapCodegenProbeData: ObservableObject {
    @Published var counts: [String: Int] = [:]

    func bump(_ name: String) { counts[name, default: 0] += 1 }

    var gateClosed: Bool? = false
    var gateOpen: Bool? = true
    lazy var onCheckBClosed: (() -> Void)? = { [weak self] in self?.bump("CheckBClosed") }
    lazy var onCheckBOpen: (() -> Void)? = { [weak self] in self?.bump("CheckBOpen") }
    lazy var onCheckNone: (() -> Void)? = { [weak self] in self?.bump("CheckNone") }
    lazy var onIclBClosed: (() -> Void)? = { [weak self] in self?.bump("IclBClosed") }
    lazy var onIclBOpen: (() -> Void)? = { [weak self] in self?.bump("IclBOpen") }
    lazy var onIclNone: (() -> Void)? = { [weak self] in self?.bump("IclNone") }
    lazy var onImgBClosed: (() -> Void)? = { [weak self] in self?.bump("ImgBClosed") }
    lazy var onImgBOpen: (() -> Void)? = { [weak self] in self?.bump("ImgBOpen") }
    lazy var onImgNone: (() -> Void)? = { [weak self] in self?.bump("ImgNone") }
    lazy var onRadioBClosed: (() -> Void)? = { [weak self] in self?.bump("RadioBClosed") }
    lazy var onRadioBOpen: (() -> Void)? = { [weak self] in self?.bump("RadioBOpen") }
    lazy var onRadioNone: (() -> Void)? = { [weak self] in self?.bump("RadioNone") }
}

struct CanTapCodegenProbeView: View {
    @StateObject private var data = CanTapCodegenProbeData()
    @State private var selectedGcgradiobclosed = ""
    @State private var selectedGcgradiobopen = ""
    @State private var selectedGcgradiofalse = ""
    @State private var selectedGcgradionone = ""
    @State private var cgCheckBClosedIsOn = false
    @State private var cgCheckBOpenIsOn = false
    @State private var cgCheckFalseIsOn = false
    @State private var cgCheckNoneIsOn = false

    private var readout: String {
        "counts[" + data.counts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ",") + "] " +
            "radios[" + "selectedGcgradiobclosed=\(selectedGcgradiobclosed)" + "," + "selectedGcgradiobopen=\(selectedGcgradiobopen)" + "," + "selectedGcgradiofalse=\(selectedGcgradiofalse)" + "," + "selectedGcgradionone=\(selectedGcgradionone)" + "] " +
            "checks[" + "cgCheckBClosedIsOn=\(cgCheckBClosedIsOn)" + "," + "cgCheckBOpenIsOn=\(cgCheckBOpenIsOn)" + "," + "cgCheckFalseIsOn=\(cgCheckFalseIsOn)" + "," + "cgCheckNoneIsOn=\(cgCheckNoneIsOn)" + "]"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("can tap codegen probe").accessibilityIdentifier("cg_probe_ready")
            Text(readout).font(.system(size: 6)).accessibilityIdentifier("cg_readout")
            VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 12) {
                            IconLabelButton(
                                text: "cgIclNone",
                                iconPosition: .left,
                                action: {
                                    data.onIclNone?()
                                }
                            )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                                data.onIclNone?()
                                            }
                                .accessibilityAddTraits(.isButton)
                                .accessibilityIdentifier("cgIclNone")
                            IconLabelView(
                                text: "cgIclFalse",
                                iconPosition: .left
                            )
                                .accessibilityIdentifier("cgIclFalse")
                            IconLabelButton(
                                text: "cgIclBClosed",
                                iconPosition: .left,
                                action: {
                                    if (data.gateClosed ?? false) { data.onIclBClosed?() }
                                }
                            )
                                .contentShape(Rectangle())
                                .gesture(TapGesture().onEnded {
                                                data.onIclBClosed?()
                                            }, including: (data.gateClosed ?? false) ? .all : .subviews)
                                .accessibilityAddTraits((data.gateClosed ?? false) ? AccessibilityTraits.isButton : [])
                                .accessibilityIdentifier("cgIclBClosed")
                            IconLabelButton(
                                text: "cgIclBOpen",
                                iconPosition: .left,
                                action: {
                                    if (data.gateOpen ?? false) { data.onIclBOpen?() }
                                }
                            )
                                .contentShape(Rectangle())
                                .gesture(TapGesture().onEnded {
                                                data.onIclBOpen?()
                                            }, including: (data.gateOpen ?? false) ? .all : .subviews)
                                .accessibilityAddTraits((data.gateOpen ?? false) ? AccessibilityTraits.isButton : [])
                                .accessibilityIdentifier("cgIclBOpen")
                    }
                    HStack(alignment: .top, spacing: 12) {
                            HStack {
                                Image(systemName: selectedGcgradionone == "cgRadioNone" ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(.blue)
                                    .onTapGesture {
                                    selectedGcgradionone = "cgRadioNone"
                                    data.onRadioNone?()
                                }
                                Text("cgRadioNone")
                            }
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("cgRadioNone")
                                .contentShape(Rectangle())
                                .onTapGesture {
                                                data.onRadioNone?()
                                            }
                                .accessibilityIdentifier("cgRadioNone")
                            HStack {
                                Image(systemName: selectedGcgradiofalse == "cgRadioFalse" ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(.blue)
                                    .onTapGesture {
                                    selectedGcgradiofalse = "cgRadioFalse"
                                }
                                Text("cgRadioFalse")
                            }
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("cgRadioFalse")
                                .accessibilityIdentifier("cgRadioFalse")
                            HStack {
                                Image(systemName: selectedGcgradiobclosed == "cgRadioBClosed" ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(.blue)
                                    .onTapGesture {
                                    selectedGcgradiobclosed = "cgRadioBClosed"
                                    if (data.gateClosed ?? false) { data.onRadioBClosed?() }
                                }
                                Text("cgRadioBClosed")
                            }
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("cgRadioBClosed")
                                .contentShape(Rectangle())
                                .gesture(TapGesture().onEnded {
                                                data.onRadioBClosed?()
                                            }, including: (data.gateClosed ?? false) ? .all : .subviews)
                                .accessibilityIdentifier("cgRadioBClosed")
                            HStack {
                                Image(systemName: selectedGcgradiobopen == "cgRadioBOpen" ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(.blue)
                                    .onTapGesture {
                                    selectedGcgradiobopen = "cgRadioBOpen"
                                    if (data.gateOpen ?? false) { data.onRadioBOpen?() }
                                }
                                Text("cgRadioBOpen")
                            }
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("cgRadioBOpen")
                                .contentShape(Rectangle())
                                .gesture(TapGesture().onEnded {
                                                data.onRadioBOpen?()
                                            }, including: (data.gateOpen ?? false) ? .all : .subviews)
                                .accessibilityIdentifier("cgRadioBOpen")
                    }
                    HStack(alignment: .top, spacing: 12) {
                            CheckBoxView(
                                isOn: $cgCheckNoneIsOn,
                                onValueChanged: { newValue in data.onCheckNone?() }
                            )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                                data.onCheckNone?()
                                            }
                                .accessibilityIdentifier("cgCheckNone")
                            CheckBoxView(
                                isOn: $cgCheckFalseIsOn,
                            )
                                .accessibilityIdentifier("cgCheckFalse")
                            CheckBoxView(
                                isOn: $cgCheckBClosedIsOn,
                                onValueChanged: { newValue in if (data.gateClosed ?? false) { data.onCheckBClosed?() } }
                            )
                                .contentShape(Rectangle())
                                .gesture(TapGesture().onEnded {
                                                data.onCheckBClosed?()
                                            }, including: (data.gateClosed ?? false) ? .all : .subviews)
                                .accessibilityIdentifier("cgCheckBClosed")
                            CheckBoxView(
                                isOn: $cgCheckBOpenIsOn,
                                onValueChanged: { newValue in if (data.gateOpen ?? false) { data.onCheckBOpen?() } }
                            )
                                .contentShape(Rectangle())
                                .gesture(TapGesture().onEnded {
                                                data.onCheckBOpen?()
                                            }, including: (data.gateOpen ?? false) ? .all : .subviews)
                                .accessibilityIdentifier("cgCheckBOpen")
                    }
                    HStack(alignment: .top, spacing: 12) {
                            Image("probe_dot")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 30)
                                .background(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                                data.onImgNone?()
                                            }
                                .accessibilityAddTraits(.isButton)
                                .accessibilityIdentifier("cgImgNone")
                            Image("probe_dot")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .accessibilityHidden(true)
                                .frame(width: 40, height: 30)
                                .background(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                .accessibilityIdentifier("cgImgFalse")
                            Image("probe_dot")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 30)
                                .background(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                .contentShape(Rectangle())
                                .gesture(TapGesture().onEnded {
                                                data.onImgBClosed?()
                                            }, including: (data.gateClosed ?? false) ? .all : .subviews)
                                .accessibilityAddTraits((data.gateClosed ?? false) ? AccessibilityTraits.isButton : [])
                                .accessibilityIdentifier("cgImgBClosed")
                            Image("probe_dot")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 30)
                                .background(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                .contentShape(Rectangle())
                                .gesture(TapGesture().onEnded {
                                                data.onImgBOpen?()
                                            }, including: (data.gateOpen ?? false) ? .all : .subviews)
                                .accessibilityAddTraits((data.gateOpen ?? false) ? AccessibilityTraits.isButton : [])
                                .accessibilityIdentifier("cgImgBOpen")
                    }
            }
        }
    }
}
