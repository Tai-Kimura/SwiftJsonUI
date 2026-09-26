//
//  A11yActivationProbeView.swift
//  ConformanceHost
//
//  Whether a screen reader can operate what `userInteractionEnabled` stops.
//  NOT part of the conformance suite. Launch with `-a11yActivationProbe`.
//
//  A touch is stopped by hit testing (`.allowsHitTesting(false)`). VoiceOver
//  does not always touch: its double tap calls the focused element's
//  `accessibilityActivate()`, and only when that returns false does it send a
//  touch to the element's activation point. This probe calls
//  `accessibilityActivate()` on each element itself (A11yActivator walks the
//  key window's accessibility tree) and reports what it returned and what it
//  called; the UI test sends the touch for each element that returned false.
//
//  Left: what `sjui build` emits for the two layouts below — sjui_tools of
//  jsonui-cli support4f/tap-rule-uie-round5 (on b9d10daf; jsonui-cli 1.9.0 in
//  progress: a control a stop holds carries `.jsonuiStoppedControl(…)`, a
//  Segment's with `items: true`),
//  JsonToSwiftUIConverter over a layouts directory holding both, as the build
//  calls it — the probe's body and the cell's body pasted unchanged
//  (A11yActivationCodegenBody, AxCellGeneratedView). The cell's View / Data /
//  ViewModel are the shapes `sjui g collection` writes (collection_generator
//  .rb): the cell view is Equatable on its cellId, and a Collection with
//  `sections` draws it `.equatable()`. The rows:
//  - no stop (the controls): a Label with onClick, a Button, a Switch, a
//    Segment and a Radio group (the wrapper controls: each segment and each
//    item is an element of its own — the item "b", the glyph "circle");
//  - inside a View with `userInteractionEnabled: false`: a Button, a Label
//    with onClick, a View with onClick, a Switch, a Segment, a Radio group;
//  - inside a View with `userInteractionEnabled: "@{gateOpen}"`: the same
//    four, and a Collection whose cell has a Label with onClick (the cell is
//    a layout the stop reaches: it reads `jsonuiInteractionStopped`);
//  - a Button and a Switch with `userInteractionEnabled: false` of their own.
//    ax_probe.json:
//      {"type": "View", "id": "cgRoot", "orientation": "vertical", "spacing": 6, "child": [
//        {"type": "Label", "id": "cgLblPlain", "text": "cgLblPlain", "onClick": "@{onLblPlain}"}
//        {"type": "Button", "id": "cgBtnPlain", "text": "cgBtnPlain", "onClick": "@{onBtnPlain}"}
//        {"type": "Switch", "id": "cgSwPlain", "isOn": "@{swPlain}"}
//        {"type": "Segment", "id": "cgSegPlain", "items": ["a", "b"], "selectedIndex": "@{segPlain}"}
//        {"type": "Radio", "id": "cgRadPlain", "items": ["a", "b"], "selectedValue": "@{radPlain}"}
//        {"type": "View", "id": "cgParFalse", "orientation": "vertical", "spacing": 4, "userInteractionEnabled": false, "child": [
//          {"type": "Button", "id": "cgBtnInFalse", "text": "cgBtnInFalse", "onClick": "@{onBtnInFalse}"}
//          {"type": "Label", "id": "cgLblInFalse", "text": "cgLblInFalse", "onClick": "@{onLblInFalse}"}
//          {"type": "View", "id": "cgViewInFalse", "width": 80, "height": 30, "background": "#3366CC", "onClick": "@{onViewInFalse}"}
//          {"type": "Switch", "id": "cgSwInFalse", "isOn": "@{swInFalse}"}
//          {"type": "Segment", "id": "cgSegInFalse", "items": ["a", "b"], "selectedIndex": "@{segInFalse}"}
//          {"type": "Radio", "id": "cgRadInFalse", "items": ["a", "b"], "selectedValue": "@{radInFalse}"}
//        ]}
//        {"type": "View", "id": "cgParBound", "orientation": "vertical", "spacing": 4, "userInteractionEnabled": "@{gateOpen}", "child": [
//          {"type": "Button", "id": "cgBtnInBound", "text": "cgBtnInBound", "onClick": "@{onBtnInBound}"}
//          {"type": "Label", "id": "cgLblInBound", "text": "cgLblInBound", "onClick": "@{onLblInBound}"}
//          {"type": "View", "id": "cgViewInBound", "width": 80, "height": 30, "background": "#3366CC", "onClick": "@{onViewInBound}"}
//          {"type": "Switch", "id": "cgSwInBound", "isOn": "@{swInBound}"}
//          {"type": "Collection", "id": "cgListBound", "items": "@{rows}", "width": 200, "height": 40, "layout": "horizontal", "sections": [{"cell": "ax_cell"}]}
//        ]}
//        {"type": "Button", "id": "cgBtnSelfFalse", "text": "cgBtnSelfFalse", "onClick": "@{onBtnSelfFalse}", "userInteractionEnabled": false}
//        {"type": "Switch", "id": "cgSwSelfFalse", "isOn": "@{swSelfFalse}", "userInteractionEnabled": false}
//      ]}
//    ax_cell.json:
//      {"type": "View", "id": "cgCell", "child": [
//        {"type": "Label", "id": "cgCellLbl", "text": "cgCellLbl", "onClick": "@{onRow}"}
//      ]}
//  Below the paste, not emitted: the same cell drawn without `.equatable()`
//  (the contrast for the cell), and the candidate fixes for a Switch and a
//  Button inside a stop (A11yActivationProbeView.candidates) — the setter
//  gated, `.accessibilityRespondsToUserInteraction(false)`, the button and
//  toggle traits removed, a no-op default action, `.accessibilityElement(
//  children: .ignore)`, and `.disabled(true)` as the reference. Each entry
//  reports the activation, what it moved, and what a screen reader reads:
//  the traits (hex, and the toggle trait), respondsToUserInteraction, the
//  value.
//
//  Right: the Dynamic runtime with the same rows (no Collection: its cells are
//  layouts loaded by name, and this host bundles none).
//
//  `a11y_flip` flips `gateOpen`; the UI test runs open → closed → open again,
//  so the bound stop is measured both ways and the cell is measured after the
//  binding flipped under an `.equatable()` view.
//

import SwiftUI
import SwiftJsonUI
import UIKit

final class A11yActivationProbeData: ObservableObject {
    @Published var counts: [String: Int] = [:]
    /// The last run's entries, its walk census, and its number.
    @Published var act = ""
    @Published var walk = ""
    @Published var ran = 0

    func bump(_ name: String) { counts[name, default: 0] += 1 }

    // The codegen rows' data surface. A Switch counts each change of value.
    @Published var gateOpen: Bool? = true
    @Published var swPlain = false { didSet { if swPlain != oldValue { bump("cgSwPlain") } } }
    @Published var swInFalse = false { didSet { if swInFalse != oldValue { bump("cgSwInFalse") } } }
    @Published var swInBound = false { didSet { if swInBound != oldValue { bump("cgSwInBound") } } }
    @Published var swSelfFalse = false { didSet { if swSelfFalse != oldValue { bump("cgSwSelfFalse") } } }
    // The wrapper controls: a Segment and a Radio group count each change of
    // their selection (a segment's, an item's).
    @Published var segPlain = 0 { didSet { if segPlain != oldValue { bump("cgSegPlain") } } }
    @Published var radPlain = "a" { didSet { if radPlain != oldValue { bump("cgRadPlain") } } }
    @Published var segInFalse = 0 { didSet { if segInFalse != oldValue { bump("cgSegInFalse") } } }
    @Published var radInFalse = "a" { didSet { if radInFalse != oldValue { bump("cgRadInFalse") } } }
    @Published var dynSel: [String: String] = [:]
    // The candidates (not emitted): each Switch counts each change of value.
    @Published var cand: [String: Bool] = [:]
    func candBinding(_ name: String) -> SwiftUI.Binding<Bool> {
        SwiftUI.Binding(get: { self.cand[name] ?? false }, set: { value in
            if (self.cand[name] ?? false) != value { self.bump(name) }
            self.cand[name] = value
        })
    }
    @Published var candValues: [String: Double] = [:]
    func candSlider(_ name: String) -> SwiftUI.Binding<Double> {
        SwiftUI.Binding(get: { self.candValues[name] ?? 0.5 }, set: { value in
            if (self.candValues[name] ?? 0.5) != value { self.bump(name) }
            self.candValues[name] = value
        })
    }
    func candSegment(_ name: String) -> SwiftUI.Binding<Int> {
        SwiftUI.Binding(get: { Int(self.candValues[name] ?? 0) }, set: { value in
            if Int(self.candValues[name] ?? 0) != value { self.bump(name) }
            self.candValues[name] = Double(value)
        })
    }
    @Published var candTexts: [String: String] = [:]
    func candText(_ name: String) -> SwiftUI.Binding<String> {
        SwiftUI.Binding(get: { self.candTexts[name] ?? "" }, set: { self.candTexts[name] = $0 })
    }
    /// The setter gate the candidates try: a stopped Switch takes no value.
    func gatedBinding(_ name: String) -> SwiftUI.Binding<Bool> {
        SwiftUI.Binding(get: { self.cand[name] ?? false }, set: { _ in })
    }
    @Published var dynSw: [String: Bool] = [:]
    lazy var onLblPlain: (() -> Void)? = { [weak self] in self?.bump("cgLblPlain") }
    lazy var onBtnPlain: (() -> Void)? = { [weak self] in self?.bump("cgBtnPlain") }
    lazy var onBtnInFalse: (() -> Void)? = { [weak self] in self?.bump("cgBtnInFalse") }
    lazy var onLblInFalse: (() -> Void)? = { [weak self] in self?.bump("cgLblInFalse") }
    lazy var onViewInFalse: (() -> Void)? = { [weak self] in self?.bump("cgViewInFalse") }
    lazy var onBtnInBound: (() -> Void)? = { [weak self] in self?.bump("cgBtnInBound") }
    lazy var onLblInBound: (() -> Void)? = { [weak self] in self?.bump("cgLblInBound") }
    lazy var onViewInBound: (() -> Void)? = { [weak self] in self?.bump("cgViewInBound") }
    lazy var onBtnSelfFalse: (() -> Void)? = { [weak self] in self?.bump("cgBtnSelfFalse") }
    lazy var rows: CollectionDataSource? = cellRows("cgCellEq")
    lazy var rowsNoEq: CollectionDataSource? = cellRows("cgCellNoEq")

    private func cellRows(_ name: String) -> CollectionDataSource {
        let onRow: (() -> Void)? = { [weak self] in self?.bump(name) }
        var section = CollectionDataSection()
        section.setCells(viewName: "AxCell", data: [["cellId": name, "onRow": onRow as Any]])
        return CollectionDataSource(sections: [section])
    }
}

// MARK: - the cell, as `sjui g collection` writes it (collection_generator.rb)

struct AxCellData {
    var onRow: (() -> Void)? = nil

    mutating func update(dictionary: [String: Any]) {
        if let value = dictionary["onRow"] {
            if let typedValue = value as? (() -> Void)? {
                self.onRow = typedValue
            }
        }
    }
}

final class AxCellViewModel: ObservableObject {
    let jsonFileName = "ax_cell"

    @Published var data = AxCellData()
    private var lastCellId: String?

    func setData(_ itemData: Any) {
        guard let dict = itemData as? [String: Any] else { return }
        let cellId = dict["cellId"] as? String
        guard cellId != lastCellId else { return }
        lastCellId = cellId
        data.update(dictionary: dict)
    }
}

struct AxCellView: View, Equatable {
    @StateObject private var viewModel: AxCellViewModel
    let cellId: String
    let cellData: Any

    init(data: Any) {
        let dict = data as? [String: Any]
        self.cellId = dict?["cellId"] as? String ?? ""
        self.cellData = data
        _viewModel = StateObject(wrappedValue: Self.makeViewModel(with: data))
    }

    private static func makeViewModel(with data: Any) -> AxCellViewModel {
        let vm = AxCellViewModel()
        vm.setData(data)
        return vm
    }

    static func == (lhs: AxCellView, rhs: AxCellView) -> Bool {
        lhs.cellId == rhs.cellId
    }

    var body: some View {
        AxCellGeneratedView(data: $viewModel.data)
            .onChange(of: cellId) { _, _ in
                viewModel.setData(cellData)
            }
    }
}

struct AxCellGeneratedView: View {
    @SwiftUI.Binding var data: AxCellData
    // the state line the emission names for ax_cell (a layout a stop reaches)
    @Environment(\.jsonuiInteractionStopped) private var jsonuiInteractionStopped

    var body: some View {
        ZStack(alignment: .topLeading) {
            Group {
                PartialAttributedText(
                    "cgCellLbl",
                    textAlignment: .leading
                )
                    .contentShape(Rectangle())
                    .gesture(TapGesture().onEnded {
                            data.onRow?()
                        }, including: !jsonuiInteractionStopped ? .all : .subviews)
                    .accessibilityAddTraits(!jsonuiInteractionStopped ? AccessibilityTraits.isButton : [])
                    .accessibilityIdentifier("cgCellLbl")
            }
        }
            .overlay(alignment: .topLeading) {
                Color.clear
                    .frame(width: 0.5, height: 0.5)
                    .accessibilityElement(children: .ignore)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cgCell")
    }
}

// MARK: - the body `sjui build` emits for ax_probe, pasted unchanged

struct A11yActivationCodegenBody: View {
    @ObservedObject var data: A11yActivationProbeData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
                PartialAttributedText(
                    "cgLblPlain",
                    textAlignment: .leading
                )
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.onLblPlain?()
                        }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("cgLblPlain")
                StateAwareButtonView(
                    text: "cgBtnPlain",
                    action: { data.onBtnPlain?() },
                    isEnabled: true
                )
                    .accessibilityIdentifier("cgBtnPlain")
                Toggle(isOn: $data.swPlain) {
                    Text("")
                }
                    .labelsHidden()
                    .accessibilityIdentifier("cgSwPlain")
                Picker("", selection: $data.segPlain) {
                    Text("a".localized()).tag(0)
                    Text("b".localized()).tag(1)
                }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("cgSegPlain")
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: data.radPlain == "a" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            data.radPlain = "a"
                        }
                        Text("a")
                    }
                    HStack {
                        Image(systemName: data.radPlain == "b" ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                            data.radPlain = "b"
                        }
                        Text("b")
                    }
                }
                    .accessibilityIdentifier("cgRadPlain")
                VStack(alignment: .leading, spacing: 4) {
                        StateAwareButtonView(
                            text: "cgBtnInFalse",
                            action: { },
                            isEnabled: true
                        )
                            .jsonuiStoppedControl(true)
                            .accessibilityIdentifier("cgBtnInFalse")
                        PartialAttributedText(
                            "cgLblInFalse",
                            textAlignment: .leading
                        )
                            .accessibilityIdentifier("cgLblInFalse")
                        Rectangle()
                            .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                            .frame(width: 80, height: 30)
                            .overlay(alignment: .topLeading) {
                                Color.clear
                                    .frame(width: 0.5, height: 0.5)
                                    .accessibilityElement(children: .ignore)
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("cgViewInFalse")
                        Toggle(isOn: $data.swInFalse) {
                            Text("")
                        }
                            .labelsHidden()
                            .jsonuiStoppedControl(true)
                            .accessibilityIdentifier("cgSwInFalse")
                        Picker("", selection: $data.segInFalse) {
                            Text("a".localized()).tag(0)
                            Text("b".localized()).tag(1)
                        }
                            .pickerStyle(.segmented)
                            .jsonuiStoppedControl(true, items: true)
                            .accessibilityIdentifier("cgSegInFalse")
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: data.radInFalse == "a" ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(.blue)
                                    .onTapGesture {
                                    data.radInFalse = "a"
                                }
                                Text("a")
                            }
                            HStack {
                                Image(systemName: data.radInFalse == "b" ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(.blue)
                                    .onTapGesture {
                                    data.radInFalse = "b"
                                }
                                Text("b")
                            }
                        }
                            .jsonuiStoppedControl(true)
                            .accessibilityIdentifier("cgRadInFalse")
                }
                    .allowsHitTesting(false)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cgParFalse")
                VStack(alignment: .leading, spacing: 4) {
                        StateAwareButtonView(
                            text: "cgBtnInBound",
                            action: { if (data.gateOpen ?? false) { data.onBtnInBound?() } },
                            isEnabled: true
                        )
                            .jsonuiStoppedControl(!((data.gateOpen ?? false)))
                            .accessibilityIdentifier("cgBtnInBound")
                        PartialAttributedText(
                            "cgLblInBound",
                            textAlignment: .leading
                        )
                            .contentShape(Rectangle())
                            .gesture(TapGesture().onEnded {
                                            data.onLblInBound?()
                                        }, including: (data.gateOpen ?? false) ? .all : .subviews)
                            .accessibilityAddTraits((data.gateOpen ?? false) ? AccessibilityTraits.isButton : [])
                            .accessibilityIdentifier("cgLblInBound")
                        Rectangle()
                            .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                            .frame(width: 80, height: 30)
                            .contentShape(Rectangle())
                            .gesture(TapGesture().onEnded {
                                            data.onViewInBound?()
                                        }, including: (data.gateOpen ?? false) ? .all : .subviews)
                            .accessibilityAddTraits((data.gateOpen ?? false) ? AccessibilityTraits.isButton : [])
                            .overlay(alignment: .topLeading) {
                                Color.clear
                                    .frame(width: 0.5, height: 0.5)
                                    .accessibilityElement(children: .ignore)
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("cgViewInBound")
                        Toggle(isOn: $data.swInBound) {
                            Text("")
                        }
                            .labelsHidden()
                            .jsonuiStoppedControl(!((data.gateOpen ?? false)))
                            .accessibilityIdentifier("cgSwInBound")
                        CollectionStackView(
                            mode: .lazy,
                            axis: .horizontal,
                            verticalAlignment: .top,
                            spacing: 0,
                            showsIndicators: true,
                            scrollDisabled: false
                        ) {
                            if let dataSource = data.rows, dataSource.sections.count > 0 {
                                let section = dataSource.sections[0]
                                if let cellsData = section.cells?.data {
                                    ForEach(Array(cellsData.enumerated()), id: \.offset) { cellIndex, cellData in
                                        AxCellView(data: cellData).equatable()
                                            .accessibilityIdentifier("cgListBound_item_\(cellIndex)")
                                    }
                                }
                            }
                        }
                            .frame(width: 200, height: 40)
                            .accessibilityIdentifier("cgListBound")
                }
                    .allowsHitTesting((data.gateOpen ?? false))
                    .transformEnvironment(\.jsonuiInteractionStopped) { $0 = $0 || !(data.gateOpen ?? false) }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cgParBound")
                StateAwareButtonView(
                    text: "cgBtnSelfFalse",
                    action: { },
                    isEnabled: true
                )
                    .allowsHitTesting(false)
                    .jsonuiStoppedControl(true)
                    .accessibilityIdentifier("cgBtnSelfFalse")
                Toggle(isOn: $data.swSelfFalse) {
                    Text("")
                }
                    .labelsHidden()
                    .allowsHitTesting(false)
                    .jsonuiStoppedControl(true)
                    .accessibilityIdentifier("cgSwSelfFalse")
        }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cgRoot")
    }
}

// MARK: - a candidate modifier for the library

/// While `stopped`: no button or toggle trait, not responding to user
/// interaction, and the default action (VoiceOver's activation) replaced by
/// nothing. Not stopped: the view as it is.
struct ProbeStoppedControl: ViewModifier {
    let stopped: Bool
    func body(content: Content) -> some View {
        if stopped {
            content
                .accessibilityAction { }
                .accessibilityRemoveTraits([.isButton, .isToggle])
                .accessibilityRespondsToUserInteraction(false)
        } else {
            content
        }
    }
}

// MARK: - the walk VoiceOver's double tap takes

/// Finds an element in the key window's accessibility tree by its
/// identifier, as a screen reader reaches it, and activates it.
enum A11yActivator {
    static func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }.first { $0.isKeyWindow }
    }

    static func children(_ node: NSObject) -> [NSObject] {
        var out: [NSObject] = []
        if let elements = node.accessibilityElements {
            out += elements.compactMap { $0 as? NSObject }
        } else {
            let n = node.accessibilityElementCount()
            if n != NSNotFound && n > 0 {
                for i in 0..<n {
                    if let e = node.accessibilityElement(at: i) as? NSObject { out.append(e) }
                }
            }
        }
        if let view = node as? UIView { out += view.subviews }
        return out
    }

    /// A SwiftUI element answers `accessibilityIdentifier` without declaring
    /// UIAccessibilityIdentification, so the cast alone misses it.
    static func identifier(_ node: NSObject) -> String? {
        if let id = (node as? UIAccessibilityIdentification)?.accessibilityIdentifier { return id }
        let getter = NSSelectorFromString("accessibilityIdentifier")
        guard node.responds(to: getter) else { return nil }
        return node.perform(getter)?.takeUnretainedValue() as? String
    }

    /// How much of the tree the walk reached: nodes, and nodes with an
    /// identifier — printed with each run, so an empty walk reads as one.
    static func census() -> (nodes: Int, identified: Int) {
        guard let window = keyWindow() else { return (0, 0) }
        var seen = Set<ObjectIdentifier>()
        var stack: [NSObject] = [window]
        var identified = 0
        while let node = stack.popLast() {
            guard seen.insert(ObjectIdentifier(node)).inserted else { continue }
            if let id = identifier(node), !id.isEmpty { identified += 1 }
            stack += children(node)
        }
        return (seen.count, identified)
    }

    /// Every node with the identifier, in walk order.
    static func matches(_ id: String, under root: NSObject) -> [NSObject] {
        var out: [NSObject] = []
        var seen = Set<ObjectIdentifier>()
        var stack: [NSObject] = [root]
        while let node = stack.popLast() {
            guard seen.insert(ObjectIdentifier(node)).inserted else { continue }
            if identifier(node) == id { out.append(node) }
            stack += children(node).reversed()
        }
        return out
    }

    /// The first accessibility element at or under a node.
    static func firstElement(under root: NSObject) -> NSObject? {
        var seen = Set<ObjectIdentifier>()
        var stack: [NSObject] = [root]
        while let node = stack.popLast() {
            guard seen.insert(ObjectIdentifier(node)).inserted else { continue }
            if node.isAccessibilityElement { return node }
            stack += children(node).reversed()
        }
        return nil
    }

    /// The element a screen reader would focus for `id` (searched under the
    /// node `scope` when given), and how it was found: `self` (the node with
    /// the identifier is an element), `child` (the first element under it),
    /// `container` (no element at all), `none` (no node with the id).
    /// The element labelled `label` under the node `scope` (a Picker's segment).
    /// Every node with the scope's identifier is searched: an identifier on
    /// a stack that is no element lands on each of its elements (a Radio's
    /// items).
    static func labelled(_ label: String, scope: String) -> (NSObject?, String, Int) {
        guard let window = keyWindow() else { return (nil, "nowindow", 0) }
        let roots = matches(scope, under: window)
        guard !roots.isEmpty else { return (nil, "noscope", 0) }
        var seen = Set<ObjectIdentifier>()
        var stack: [NSObject] = roots.reversed()
        while let node = stack.popLast() {
            guard seen.insert(ObjectIdentifier(node)).inserted else { continue }
            if node.isAccessibilityElement && node.accessibilityLabel == label { return (node, "label", 1) }
            stack += children(node).reversed()
        }
        return (nil, "none", 0)
    }

    static func target(_ id: String, scope: String?) -> (NSObject?, String, Int) {
        guard let window = keyWindow() else { return (nil, "nowindow", 0) }
        var root: NSObject = window
        if let scope {
            guard let s = matches(scope, under: window).first else { return (nil, "noscope", 0) }
            root = s
        }
        let found = matches(id, under: root)
        if let e = found.first(where: { $0.isAccessibilityElement }) { return (e, "self", found.count) }
        if let c = found.first, let e = firstElement(under: c) { return (e, "child", found.count) }
        return (found.first, found.isEmpty ? "none" : "container", found.count)
    }
}

/// One element the probe activates: its name (the count it moves), its
/// identifier, and the node it is searched under.
struct A11yTarget {
    let name: String
    let id: String
    let scope: String?
    /// Found by its accessibility label under `scope` (a segment of a Picker).
    let label: String?
    /// VoiceOver's swipe up on an adjustable element, not its double tap.
    let increment: Bool
    init(_ name: String, id: String? = nil, scope: String? = nil, label: String? = nil, increment: Bool = false) {
        self.name = name
        self.id = id ?? name
        self.scope = scope
        self.label = label
        self.increment = increment
    }
}

struct A11yActivationProbeView: View {
    @StateObject private var data = A11yActivationProbeData()

    /// The wrapper controls (a Segment's segments and a Radio's items are
    /// elements of their own): with no stop, and inside `false`.
    static let wrapperRows = ["SegPlain", "RadPlain", "SegInFalse", "RadInFalse"]

    static let rows = ["LblPlain", "BtnPlain", "SwPlain",
                       "BtnInFalse", "LblInFalse", "ViewInFalse", "SwInFalse",
                       "BtnInBound", "LblInBound", "ViewInBound", "SwInBound",
                       "BtnSelfFalse", "SwSelfFalse"]
    // Built statement by statement: the one `+` chain took Swift 6.2.4 (the
    // CI pin) past its type-check limit (scripts/typecheck_swift62.sh).
    static let targets: [A11yTarget] = {
        var out: [A11yTarget] = rows.map { A11yTarget("cg\($0)") }
        out.append(A11yTarget("cgCellEq", id: "cgCellLbl", scope: "cgListBound"))
        out.append(A11yTarget("cgCellNoEq", id: "cgCellLbl", scope: "cgListBoundNoEq"))
        out += rows.map { A11yTarget("dyn\($0)") }
        // A wrapper control's item, found by its label under the control: a
        // segment "b", a Radio item's glyph (an unselected one reads
        // "circle").
        for side in ["cg", "dyn"] {
            for row in wrapperRows {
                let name = "\(side)\(row)"
                out.append(A11yTarget(name, scope: name, label: row.hasPrefix("Seg") ? "b" : "circle"))
            }
        }
        out += A11yActivationProbeView.candidates.map { A11yTarget($0) }
        out += ["candSlPlain", "candSlEmitted", "candSlMod", "candSlHidden"].map { A11yTarget($0, increment: true) }
        out += ["candSegPlain", "candSegEmitted", "candSegMod", "candSegHidden"].map { A11yTarget($0, scope: $0, label: "b") }
        out += ["candTfPlain", "candTfEmitted", "candTfMod", "candTfHidden"].map { A11yTarget($0) }
        return out
    }()

    /// The candidate fixes, each inside a stop drawn as the codegen draws
    /// `userInteractionEnabled: false` (`.allowsHitTesting(false)`): the
    /// Switch and the Button as emitted, then with one change or a pair.
    static let candidates = ["candSwEmitted", "candSwEmitted2", "candSwGate", "candSwGateTraitsResp", "candSwGateButtonResp",
                             "candSwGateResp", "candSwActionTraitsResp", "candSwDisabled",
                             "candBtnEmitted", "candBtnEmitted2", "candBtnTraitsResp", "candBtnDisabled",
                             "candCondOpenSw", "candCondOpenBtn", "candHiddenSw", "candHiddenBtn", "candHiddenLbl",
                             "candSwMod", "candSwModOpen", "candBtnMod", "candBtnModOpen"]

    /// The Dynamic rows, with the ids and handlers of the codegen rows.
    static let dynamicLayout: DynamicComponent? = {
        func kids(_ s: String, _ gate: String) -> String {
            #"{"type": "View", "id": "dynPar\#(s)", "orientation": "vertical", "spacing": 4, "userInteractionEnabled": \#(gate), "child": ["#
                + #"{"type": "Button", "id": "dynBtnIn\#(s)", "text": "dynBtnIn\#(s)", "onClick": "@{on_dynBtnIn\#(s)}"}, "#
                + #"{"type": "Label", "id": "dynLblIn\#(s)", "text": "dynLblIn\#(s)", "onClick": "@{on_dynLblIn\#(s)}"}, "#
                + ##"{"type": "View", "id": "dynViewIn\##(s)", "width": 80, "height": 30, "background": "#3366CC", "onClick": "@{on_dynViewIn\##(s)}"}, "##
                + #"{"type": "Switch", "id": "dynSwIn\#(s)", "isOn": "@{dynSwIn\#(s)}"}"#
                + (s == "False" ? #", {"type": "Segment", "id": "dynSegInFalse", "items": ["a", "b"], "selectedIndex": "@{dynSegInFalse}"}, "#
                    + #"{"type": "Radio", "id": "dynRadInFalse", "items": ["a", "b"], "selectedValue": "@{dynRadInFalse}"}"# : "")
                + "]}"
        }
        let json = #"{"type": "View", "orientation": "vertical", "spacing": 6, "child": ["#
            + #"{"type": "Label", "id": "dynLblPlain", "text": "dynLblPlain", "onClick": "@{on_dynLblPlain}"}, "#
            + #"{"type": "Button", "id": "dynBtnPlain", "text": "dynBtnPlain", "onClick": "@{on_dynBtnPlain}"}, "#
            + #"{"type": "Switch", "id": "dynSwPlain", "isOn": "@{dynSwPlain}"}, "#
            + #"{"type": "Segment", "id": "dynSegPlain", "items": ["a", "b"], "selectedIndex": "@{dynSegPlain}"}, "#
            + #"{"type": "Radio", "id": "dynRadPlain", "items": ["a", "b"], "selectedValue": "@{dynRadPlain}"}, "#
            + kids("False", "false") + ", " + kids("Bound", #""@{gateOpen}""#) + ", "
            + #"{"type": "Button", "id": "dynBtnSelfFalse", "text": "dynBtnSelfFalse", "onClick": "@{on_dynBtnSelfFalse}", "userInteractionEnabled": false}, "#
            + #"{"type": "Switch", "id": "dynSwSelfFalse", "isOn": "@{dynSwSelfFalse}", "userInteractionEnabled": false}]}"#
        return try? JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }()

    private var dynamicData: [String: Any] {
        let data = self.data
        var out: [String: Any] = ["gateOpen": data.gateOpen ?? false]
        for row in Self.rows where !row.hasPrefix("Sw") {
            let name = "dyn\(row)"
            out["on_\(name)"] = { () -> Void in data.bump(name) }
        }
        for row in Self.rows where row.hasPrefix("Sw") {
            let name = "dyn\(row)"
            out[name] = SwiftUI.Binding<Bool>(get: { data.dynSw[name] ?? false }, set: { value in
                if (data.dynSw[name] ?? false) != value { data.bump(name) }
                data.dynSw[name] = value
            })
        }
        // The wrapper controls' selections: a change counts as the row's.
        for row in Self.wrapperRows {
            let name = "dyn\(row)"
            if row.hasPrefix("Seg") {
                out[name] = SwiftUI.Binding<Int>(get: { Int(data.dynSel[name] ?? "0") ?? 0 }, set: { value in
                    if (Int(data.dynSel[name] ?? "0") ?? 0) != value { data.bump(name) }
                    data.dynSel[name] = String(value)
                })
            } else {
                out[name] = SwiftUI.Binding<String>(get: { data.dynSel[name] ?? "a" }, set: { value in
                    if (data.dynSel[name] ?? "a") != value { data.bump(name) }
                    data.dynSel[name] = value
                })
            }
        }
        return out
    }

    /// Activates every target in turn, a moment apart, and writes one entry
    /// each: name=via/element/button/notEnabled/returned/calls/x,y — `calls`
    /// is what the activation moved (handler calls, or Switch changes), x,y
    /// the activation point VoiceOver touches when `returned` is 0.
    private func run() {
        if Self.wrappersOnly { runWrappers(); return }
        // The wrapper controls with no stop start each run on their first
        // item, so the item a run operates ("b", an unselected glyph) moves
        // the selection again.
        data.segPlain = 0
        data.radPlain = "a"
        data.dynSel = [:]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { runTargets() }
    }

    private func runTargets() {
        let phase = data.ran + 1
        var entries: [String] = []
        let census = A11yActivator.census()
        data.walk = "\(census.nodes)/\(census.identified)"
        func step(_ i: Int) {
            guard i < Self.targets.count else {
                data.act = entries.joined(separator: ";")
                data.ran = phase
                return
            }
            let t = Self.targets[i]
            let (element, via, n) = t.label.map { A11yActivator.labelled($0, scope: t.scope ?? t.id) } ?? A11yActivator.target(t.id, scope: t.scope)
            let before = data.counts[t.name] ?? 0
            guard let element else {
                entries.append("\(t.name)=\(via)/0/0/0/0/0/-1,-1/0/0/0/")
                step(i + 1)
                return
            }
            let traits = element.accessibilityTraits
            let point = element.accessibilityActivationPoint
            let responds = element.accessibilityRespondsToUserInteraction
            let value = (element.accessibilityValue ?? "").replacingOccurrences(of: "/", with: "|").replacingOccurrences(of: ";", with: ",")
            let returned: Bool
            if t.increment {
                element.accessibilityIncrement()
                returned = true
            } else {
                returned = element.accessibilityActivate()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                let moved = (data.counts[t.name] ?? 0) - before
                entries.append("\(t.name)=\(via)\(n > 1 ? "\(n)" : "")/\(element.isAccessibilityElement ? 1 : 0)/"
                    + "\(traits.contains(.button) ? 1 : 0)/\(traits.contains(.notEnabled) ? 1 : 0)/"
                    + "\(returned ? 1 : 0)/\(moved)/\(Int(point.x.rounded())),\(Int(point.y.rounded()))/"
                    + "\(String(traits.rawValue, radix: 16))/\(traits.contains(.toggleButton) ? 1 : 0)/\(responds ? 1 : 0)/\(value)")
                step(i + 1)
            }
        }
        step(0)
    }

    /// Every accessibility element under each wrapper scope, in walk order:
    /// scope#i=label/value/traits/button/notEnabled/responds/returned/moved/x,y
    /// — `moved` is what the scope's selection moved after the activation.
    private func runWrappers() {
        let phase = data.ran + 1
        var entries: [String] = []
        var queue: [(String, NSObject)] = []
        guard let window = A11yActivator.keyWindow() else { return }
        for scope in WrapperStopCandidates.scopes {
            guard let root = A11yActivator.matches(scope, under: window).first else {
                entries.append("\(scope)#-=noscope")
                continue
            }
            var seen = Set<ObjectIdentifier>()
            var stack: [NSObject] = [root]
            var found = 0
            while let node = stack.popLast() {
                guard seen.insert(ObjectIdentifier(node)).inserted else { continue }
                if node.isAccessibilityElement { queue.append((scope, node)); found += 1 }
                stack += A11yActivator.children(node).reversed()
            }
            if found == 0 { entries.append("\(scope)#-=noelement") }
        }
        func clean(_ s: String?) -> String {
            (s ?? "").replacingOccurrences(of: "/", with: "|").replacingOccurrences(of: ";", with: ",").replacingOccurrences(of: "=", with: ":")
        }
        var index: [String: Int] = [:]
        func step(_ i: Int) {
            guard i < queue.count else {
                data.act = entries.joined(separator: ";")
                data.ran = phase
                return
            }
            let (scope, element) = queue[i]
            let n = index[scope, default: 0]
            index[scope] = n + 1
            let traits = element.accessibilityTraits
            let point = element.accessibilityActivationPoint
            let before = data.counts[scope] ?? 0
            let returned = element.accessibilityActivate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                let moved = (data.counts[scope] ?? 0) - before
                entries.append("\(scope)#\(n)=\(clean(element.accessibilityLabel))/\(clean(element.accessibilityValue))/"
                    + "\(String(traits.rawValue, radix: 16))/\(traits.contains(.button) ? 1 : 0)/\(traits.contains(.notEnabled) ? 1 : 0)/"
                    + "\(element.accessibilityRespondsToUserInteraction ? 1 : 0)/\(returned ? 1 : 0)/\(moved)/"
                    + "\(Int(point.x.rounded())),\(Int(point.y.rounded()))")
                step(i + 1)
            }
        }
        step(0)
    }

    // Lets and one interpolated literal (see InteractionGateProbeView): the
    // counts are live, so the UI test reads what a touch moved as well.
    private var readout: String {
        let counts = data.counts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
        let gate = (data.gateOpen ?? false) ? "open" : "closed"
        return "ran=\(data.ran) gate=\(gate) walk=\(data.walk) act[\(data.act)] counts[\(counts)]"
    }


    @FocusState private var focus: String?

    /// `-candidates`: the candidate fixes alone, on a screen of their own (the
    /// probe's two columns fill the screen).
    static let candidatesOnly = ProcessInfo.processInfo.arguments.contains("-candidates")
    /// `-wrappers`: the wrapper controls' candidates (WrapperStopCandidates).
    static let wrappersOnly = ProcessInfo.processInfo.arguments.contains("-wrappers")

    @ViewBuilder private var candidatesBlock: some View {
        // not emitted: the candidate fixes, inside a stop as emitted — the
        // conditional forms take `stopped` (the stop, as a codegen would
        // read it); `candCondOpen…` are the same forms with it false
        let stopped = true
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: data.candBinding("candSwEmitted")) { Text("") }
                .labelsHidden().accessibilityIdentifier("candSwEmitted")
            Toggle(isOn: data.candBinding("candSwEmitted2")) { Text("") }
                .labelsHidden().accessibilityIdentifier("candSwEmitted2")
            Toggle(isOn: data.gatedBinding("candSwGate")) { Text("") }
                .labelsHidden().accessibilityIdentifier("candSwGate")
            Toggle(isOn: data.gatedBinding("candSwGateTraitsResp")) { Text("") }
                .labelsHidden()
                .accessibilityRemoveTraits(stopped ? [.isButton, .isToggle] : [])
                .accessibilityRespondsToUserInteraction(!stopped)
                .accessibilityIdentifier("candSwGateTraitsResp")
            Toggle(isOn: data.gatedBinding("candSwGateButtonResp")) { Text("") }
                .labelsHidden()
                .accessibilityRemoveTraits(stopped ? .isButton : [])
                .accessibilityRespondsToUserInteraction(!stopped)
                .accessibilityIdentifier("candSwGateButtonResp")
            Toggle(isOn: data.gatedBinding("candSwGateResp")) { Text("") }
                .labelsHidden()
                .accessibilityRespondsToUserInteraction(!stopped)
                .accessibilityIdentifier("candSwGateResp")
            Toggle(isOn: data.candBinding("candSwActionTraitsResp")) { Text("") }
                .labelsHidden()
                .accessibilityAction { }
                .accessibilityRemoveTraits([.isButton, .isToggle])
                .accessibilityRespondsToUserInteraction(false)
                .accessibilityIdentifier("candSwActionTraitsResp")
            Toggle(isOn: data.candBinding("candSwDisabled")) { Text("") }
                .labelsHidden()
                .disabled(true)
                .accessibilityIdentifier("candSwDisabled")
            StateAwareButtonView(text: "B", action: { }, isEnabled: true)
                .accessibilityIdentifier("candBtnEmitted")
            StateAwareButtonView(text: "B", action: { }, isEnabled: true)
                .accessibilityIdentifier("candBtnEmitted2")
            StateAwareButtonView(text: "B", action: { }, isEnabled: true)
                .accessibilityRemoveTraits(stopped ? .isButton : [])
                .accessibilityRespondsToUserInteraction(!stopped)
                .accessibilityIdentifier("candBtnTraitsResp")
            StateAwareButtonView(text: "B", action: { data.bump("candBtnDisabled") }, isEnabled: true)
                .disabled(true)
                .accessibilityIdentifier("candBtnDisabled")
        }
            .allowsHitTesting(false)
        // one modifier, conditional on the stop: the traits and the response
        // follow it; the default action is replaced by nothing while it is
        // stopped (ProbeStoppedControl, the candidate for the library)
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: data.candBinding("candSwMod")) { Text("") }
                .labelsHidden().modifier(ProbeStoppedControl(stopped: true)).accessibilityIdentifier("candSwMod")
            Toggle(isOn: data.candBinding("candSwModOpen")) { Text("") }
                .labelsHidden().modifier(ProbeStoppedControl(stopped: false)).accessibilityIdentifier("candSwModOpen")
            StateAwareButtonView(text: "B", action: { data.bump("candBtnMod") }, isEnabled: true)
                .modifier(ProbeStoppedControl(stopped: true)).accessibilityIdentifier("candBtnMod")
            StateAwareButtonView(text: "B", action: { data.bump("candBtnModOpen") }, isEnabled: true)
                .modifier(ProbeStoppedControl(stopped: false)).accessibilityIdentifier("candBtnModOpen")
        }
        // a Slider (VoiceOver adjusts it: swipe up), a segmented Picker (each
        // segment its own element) and a text field (double tap: focus), each
        // as emitted, with the modifier, and under a hidden stop
        VStack(alignment: .leading, spacing: 4) {
            Slider(value: data.candSlider("candSlEmitted"), in: 0...1).frame(width: 160).accessibilityIdentifier("candSlEmitted")
            Slider(value: data.candSlider("candSlMod"), in: 0...1).frame(width: 160)
                .modifier(ProbeStoppedControl(stopped: true)).accessibilityIdentifier("candSlMod")
            Picker("", selection: data.candSegment("candSegEmitted")) { Text("a").tag(0); Text("b").tag(1) }
                .pickerStyle(.segmented).frame(width: 160).accessibilityIdentifier("candSegEmitted")
            Picker("", selection: data.candSegment("candSegMod")) { Text("a").tag(0); Text("b").tag(1) }
                .pickerStyle(.segmented).frame(width: 160)
                .modifier(ProbeStoppedControl(stopped: true)).accessibilityIdentifier("candSegMod")
            TextField("tf", text: data.candText("candTfEmitted")).frame(width: 160)
                .focused($focus, equals: "candTfEmitted").accessibilityIdentifier("candTfEmitted")
            TextField("tf", text: data.candText("candTfMod")).frame(width: 160)
                .focused($focus, equals: "candTfMod")
                .modifier(ProbeStoppedControl(stopped: true)).accessibilityIdentifier("candTfMod")
        }
            .allowsHitTesting(false)
        VStack(alignment: .leading, spacing: 4) {
            Slider(value: data.candSlider("candSlHidden"), in: 0...1).frame(width: 160).accessibilityIdentifier("candSlHidden")
            Picker("", selection: data.candSegment("candSegHidden")) { Text("a").tag(0); Text("b").tag(1) }
                .pickerStyle(.segmented).frame(width: 160).accessibilityIdentifier("candSegHidden")
            TextField("tf", text: data.candText("candTfHidden")).frame(width: 160)
                .focused($focus, equals: "candTfHidden").accessibilityIdentifier("candTfHidden")
        }
            .allowsHitTesting(false)
            .accessibilityHidden(stopped)
            .onChange(of: focus) { _, now in if let now { data.bump(now) } }
        // the same three with no stop: the controls for them
        VStack(alignment: .leading, spacing: 4) {
            Slider(value: data.candSlider("candSlPlain"), in: 0...1).frame(width: 160).accessibilityIdentifier("candSlPlain")
            Picker("", selection: data.candSegment("candSegPlain")) { Text("a").tag(0); Text("b").tag(1) }
                .pickerStyle(.segmented).frame(width: 160).accessibilityIdentifier("candSegPlain")
            TextField("tf", text: data.candText("candTfPlain")).frame(width: 160)
                .focused($focus, equals: "candTfPlain").accessibilityIdentifier("candTfPlain")
        }
        // the stop hides what it holds from assistive technologies — the
        // container's `.accessibilityHidden(stopped)`, as web's inert
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: data.candBinding("candHiddenSw")) { Text("") }
                .labelsHidden().accessibilityIdentifier("candHiddenSw")
            StateAwareButtonView(text: "B", action: { data.bump("candHiddenBtn") }, isEnabled: true)
                .accessibilityIdentifier("candHiddenBtn")
            Text("candHiddenLbl").accessibilityIdentifier("candHiddenLbl")
        }
            .allowsHitTesting(false)
            .accessibilityHidden(stopped)
        // the same conditional forms with nothing stopped (outside a stop):
        // a Switch that switches and a Button that calls, read as they are
        let open = false
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: SwiftUI.Binding(get: { data.cand["candCondOpenSw"] ?? false }, set: { value in
                if !open { data.candBinding("candCondOpenSw").wrappedValue = value }
            })) { Text("") }
                .labelsHidden()
                .accessibilityRemoveTraits(open ? [.isButton, .isToggle] : [])
                .accessibilityRespondsToUserInteraction(!open)
                .accessibilityIdentifier("candCondOpenSw")
            StateAwareButtonView(text: "B", action: { if !open { data.bump("candCondOpenBtn") } }, isEnabled: true)
                .accessibilityRemoveTraits(open ? .isButton : [])
                .accessibilityRespondsToUserInteraction(!open)
                .accessibilityIdentifier("candCondOpenBtn")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 16) {
                Text("a11y activation probe").accessibilityIdentifier("a11y_probe_ready")
                Button("run") { run() }.accessibilityIdentifier("a11y_run")
                Button("flip") { data.gateOpen = !(data.gateOpen ?? false) }.accessibilityIdentifier("a11y_flip")
            }
            // A fixed frame: the readout grows with each run, and a layout
            // that moved after the activation points were read sent the
            // touches beside the elements (measured: 32 pt / 19 pt off after
            // the first run).
            Text(readout).font(.system(size: 4)).lineLimit(nil)
                .frame(width: 360, height: 60, alignment: .topLeading).clipped()
                .accessibilityIdentifier("a11y_readout")
            if Self.wrappersOnly {
                WrapperStopCandidates(data: data)
            } else if Self.candidatesOnly {
                ScrollView { VStack(alignment: .leading, spacing: 4) { candidatesBlock } }
            } else {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    A11yActivationCodegenBody(data: data)
                    // not emitted: the cell without `.equatable()`, under the
                    // same bound stop — the contrast for the cell
                    VStack(alignment: .leading, spacing: 0) {
                        CollectionStackView(
                            mode: .lazy,
                            axis: .horizontal,
                            verticalAlignment: .top,
                            spacing: 0,
                            showsIndicators: true,
                            scrollDisabled: false
                        ) {
                            if let dataSource = data.rowsNoEq, dataSource.sections.count > 0 {
                                let section = dataSource.sections[0]
                                if let cellsData = section.cells?.data {
                                    ForEach(Array(cellsData.enumerated()), id: \.offset) { cellIndex, cellData in
                                        AxCellView(data: cellData)
                                            .accessibilityIdentifier("cgListBoundNoEq_item_\(cellIndex)")
                                    }
                                }
                            }
                        }
                            .frame(width: 200, height: 40)
                            .accessibilityIdentifier("cgListBoundNoEq")
                    }
                        .allowsHitTesting((data.gateOpen ?? false))
                        .transformEnvironment(\.jsonuiInteractionStopped) { $0 = $0 || !(data.gateOpen ?? false) }
                }
                if let layout = Self.dynamicLayout {
                    DynamicComponentBuilder(component: layout, data: dynamicData)
                } else {
                    Text("layout did not decode").accessibilityIdentifier("a11y_decode_failed")
                }
            }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - wrapper controls inside a stop (measurement only, not emitted)

/// A Segment's segments and a Radio's items are elements of their own inside
/// the control: what each reads and what its activation moves, inside a stop
/// drawn as the codegen draws `userInteractionEnabled: false`
/// (`.allowsHitTesting(false)`), as emitted today and with each candidate.
struct WrapperStopCandidates: View {
    @ObservedObject var data: A11yActivationProbeData

    static let scopes = ["wSegPlain", "wSegEm", "wSegIgnore", "wSegCombine", "wSegDisabled",
                         "wSegReprText", "wSegReprDisabled", "wSegIgnoreValue", "wSegReprContent", "wSegReprContentOpen", "wRadReprContent",
                         "wRadPlain", "wRadEm", "wRadItem", "wRadCombine", "wRadDisabled"]

    private func segment(_ name: String) -> some View {
        Picker("", selection: data.candSegment(name)) { Text("a").tag(0); Text("b").tag(1) }
            .pickerStyle(.segmented).frame(width: 160)
    }

    private func radioBinding(_ name: String) -> SwiftUI.Binding<String> {
        SwiftUI.Binding(get: { data.candTexts[name] ?? "a" }, set: { value in
            if (data.candTexts[name] ?? "a") != value { data.bump(name) }
            data.candTexts[name] = value
        })
    }

    /// As sjui emits a Radio's items (radio_converter.rb), each item's tap
    /// on its Image; `itemStop` puts the stopped control's treatment on each
    /// item too.
    private func radio(_ name: String, itemStop: Bool = false) -> some View {
        let sel = radioBinding(name)
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(["a", "b"], id: \.self) { v in
                HStack {
                    Image(systemName: sel.wrappedValue == v ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(.blue)
                        .onTapGesture { sel.wrappedValue = v }
                        .jsonuiStoppedControl(itemStop)
                    Text(v)
                }
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                segment("wSegPlain").accessibilityIdentifier("wSegPlain")
                Group {
                    segment("wSegEm").jsonuiStoppedControl(true).accessibilityIdentifier("wSegEm")
                    segment("wSegIgnore").accessibilityElement(children: .ignore).jsonuiStoppedControl(true).accessibilityIdentifier("wSegIgnore")
                    segment("wSegCombine").accessibilityElement(children: .combine).jsonuiStoppedControl(true).accessibilityIdentifier("wSegCombine")
                    segment("wSegDisabled").disabled(true).jsonuiStoppedControl(true).accessibilityIdentifier("wSegDisabled")
                }
                    .allowsHitTesting(false)
                Group {
                    segment("wSegReprText")
                        .accessibilityRepresentation {
                            HStack {
                                ForEach(Array(["a", "b"].enumerated()), id: \.offset) { i, t in
                                    Text(t).accessibilityAddTraits(Int(data.candValues["wSegReprText"] ?? 0) == i ? .isSelected : [])
                                }
                            }
                        }
                        .jsonuiStoppedControl(true).accessibilityIdentifier("wSegReprText")
                    segment("wSegReprDisabled")
                        .accessibilityRepresentation {
                            Picker("", selection: data.candSegment("wSegReprDisabled")) { Text("a").tag(0); Text("b").tag(1) }
                                .pickerStyle(.segmented).disabled(true)
                        }
                        .jsonuiStoppedControl(true).accessibilityIdentifier("wSegReprDisabled")
                    segment("wSegReprContent").modifier(ProbeStoppedItems(stopped: true)).accessibilityIdentifier("wSegReprContent")
                    segment("wSegReprContentOpen").modifier(ProbeStoppedItems(stopped: false)).accessibilityIdentifier("wSegReprContentOpen")
                    radio("wRadReprContent").modifier(ProbeStoppedItems(stopped: true)).accessibilityElement(children: .contain).accessibilityIdentifier("wRadReprContent")
                    segment("wSegIgnoreValue").accessibilityElement(children: .ignore)
                        .accessibilityValue(Text(["a", "b"][Int(data.candValues["wSegIgnoreValue"] ?? 0)]))
                        .jsonuiStoppedControl(true).accessibilityIdentifier("wSegIgnoreValue")
                }
                    .allowsHitTesting(false)
                radio("wRadPlain").accessibilityElement(children: .contain).accessibilityIdentifier("wRadPlain")
                Group {
                    radio("wRadEm").jsonuiStoppedControl(true).accessibilityElement(children: .contain).accessibilityIdentifier("wRadEm")
                    radio("wRadItem", itemStop: true).jsonuiStoppedControl(true).accessibilityElement(children: .contain).accessibilityIdentifier("wRadItem")
                    radio("wRadCombine").accessibilityElement(children: .combine).jsonuiStoppedControl(true).accessibilityIdentifier("wRadCombine")
                    radio("wRadDisabled").disabled(true).jsonuiStoppedControl(true).accessibilityElement(children: .contain).accessibilityIdentifier("wRadDisabled")
                }
                    .allowsHitTesting(false)
            }
        }
    }
}

/// The candidate for a wrapper control's items: while stopped, a screen
/// reader reads the control as the same control disabled (not drawn).
struct ProbeStoppedItems: ViewModifier {
    let stopped: Bool
    func body(content: Content) -> some View {
        if stopped {
            content.accessibilityRepresentation { content.disabled(true) }
        } else {
            content
        }
    }
}
