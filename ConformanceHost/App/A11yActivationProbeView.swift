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
//  jsonui-cli 4476d6d0 with this branch's changes (jsonui-cli 1.9.0 in
//  progress), JsonToSwiftUIConverter over a layouts directory holding both, as
//  the build calls it — the probe's body and the cell's body pasted unchanged
//  (A11yActivationCodegenBody, AxCellGeneratedView). The cell's View / Data /
//  ViewModel are the shapes `sjui g collection` writes (collection_generator
//  .rb): the cell view is Equatable on its cellId, and a Collection with
//  `sections` draws it `.equatable()`. The rows:
//  - no stop (the controls): a Label with onClick, a Button, a Switch;
//  - inside a View with `userInteractionEnabled: false`: a Button, a Label
//    with onClick, a View with onClick, a Switch;
//  - inside a View with `userInteractionEnabled: "@{gateOpen}"`: the same
//    four, and a Collection whose cell has a Label with onClick (the cell is
//    a layout the stop reaches: it reads `jsonuiInteractionStopped`);
//  - a Button and a Switch with `userInteractionEnabled: false` of their own.
//    ax_probe.json:
//      {"type": "View", "id": "cgRoot", "orientation": "vertical", "spacing": 6, "child": [
//        {"type": "Label", "id": "cgLblPlain", "text": "cgLblPlain", "onClick": "@{onLblPlain}"}
//        {"type": "Button", "id": "cgBtnPlain", "text": "cgBtnPlain", "onClick": "@{onBtnPlain}"}
//        {"type": "Switch", "id": "cgSwPlain", "isOn": "@{swPlain}"}
//        {"type": "View", "id": "cgParFalse", "orientation": "vertical", "spacing": 4, "userInteractionEnabled": false, "child": [
//          {"type": "Button", "id": "cgBtnInFalse", "text": "cgBtnInFalse", "onClick": "@{onBtnInFalse}"}
//          {"type": "Label", "id": "cgLblInFalse", "text": "cgLblInFalse", "onClick": "@{onLblInFalse}"}
//          {"type": "View", "id": "cgViewInFalse", "width": 80, "height": 30, "background": "#3366CC", "onClick": "@{onViewInFalse}"}
//          {"type": "Switch", "id": "cgSwInFalse", "isOn": "@{swInFalse}"}
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
//  (the contrast for the cell), and two candidate fixes on a Switch inside a
//  stop — `.disabled(true)` and `.accessibilityRespondsToUserInteraction(false)`.
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
    @Published var fixDisabledSw = false { didSet { if fixDisabledSw != oldValue { bump("fixDisabledSw") } } }
    @Published var fixRespondsSw = false { didSet { if fixRespondsSw != oldValue { bump("fixRespondsSw") } } }
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
                VStack(alignment: .leading, spacing: 4) {
                        StateAwareButtonView(
                            text: "cgBtnInFalse",
                            action: { },
                            isEnabled: true
                        )
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
                            .accessibilityIdentifier("cgSwInFalse")
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
                    .accessibilityIdentifier("cgBtnSelfFalse")
                Toggle(isOn: $data.swSelfFalse) {
                    Text("")
                }
                    .labelsHidden()
                    .allowsHitTesting(false)
                    .accessibilityIdentifier("cgSwSelfFalse")
        }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cgRoot")
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
    init(_ name: String, id: String? = nil, scope: String? = nil) {
        self.name = name
        self.id = id ?? name
        self.scope = scope
    }
}

struct A11yActivationProbeView: View {
    @StateObject private var data = A11yActivationProbeData()

    static let rows = ["LblPlain", "BtnPlain", "SwPlain",
                       "BtnInFalse", "LblInFalse", "ViewInFalse", "SwInFalse",
                       "BtnInBound", "LblInBound", "ViewInBound", "SwInBound",
                       "BtnSelfFalse", "SwSelfFalse"]
    static let targets: [A11yTarget] =
        rows.map { A11yTarget("cg\($0)") }
        + [A11yTarget("cgCellEq", id: "cgCellLbl", scope: "cgListBound"),
           A11yTarget("cgCellNoEq", id: "cgCellLbl", scope: "cgListBoundNoEq")]
        + rows.map { A11yTarget("dyn\($0)") }
        + [A11yTarget("fixDisabledSw"), A11yTarget("fixRespondsSw")]

    /// The Dynamic rows, with the ids and handlers of the codegen rows.
    static let dynamicLayout: DynamicComponent? = {
        func kids(_ s: String, _ gate: String) -> String {
            #"{"type": "View", "id": "dynPar\#(s)", "orientation": "vertical", "spacing": 4, "userInteractionEnabled": \#(gate), "child": ["#
                + #"{"type": "Button", "id": "dynBtnIn\#(s)", "text": "dynBtnIn\#(s)", "onClick": "@{on_dynBtnIn\#(s)}"}, "#
                + #"{"type": "Label", "id": "dynLblIn\#(s)", "text": "dynLblIn\#(s)", "onClick": "@{on_dynLblIn\#(s)}"}, "#
                + ##"{"type": "View", "id": "dynViewIn\##(s)", "width": 80, "height": 30, "background": "#3366CC", "onClick": "@{on_dynViewIn\##(s)}"}, "##
                + #"{"type": "Switch", "id": "dynSwIn\#(s)", "isOn": "@{dynSwIn\#(s)}"}]}"#
        }
        let json = #"{"type": "View", "orientation": "vertical", "spacing": 6, "child": ["#
            + #"{"type": "Label", "id": "dynLblPlain", "text": "dynLblPlain", "onClick": "@{on_dynLblPlain}"}, "#
            + #"{"type": "Button", "id": "dynBtnPlain", "text": "dynBtnPlain", "onClick": "@{on_dynBtnPlain}"}, "#
            + #"{"type": "Switch", "id": "dynSwPlain", "isOn": "@{dynSwPlain}"}, "#
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
        return out
    }

    /// Activates every target in turn, a moment apart, and writes one entry
    /// each: name=via/element/button/notEnabled/returned/calls/x,y — `calls`
    /// is what the activation moved (handler calls, or Switch changes), x,y
    /// the activation point VoiceOver touches when `returned` is 0.
    private func run() {
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
            let (element, via, n) = A11yActivator.target(t.id, scope: t.scope)
            let before = data.counts[t.name] ?? 0
            guard let element else {
                entries.append("\(t.name)=\(via)/0/0/0/0/0/-1,-1")
                step(i + 1)
                return
            }
            let traits = element.accessibilityTraits
            let point = element.accessibilityActivationPoint
            let returned = element.accessibilityActivate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                let moved = (data.counts[t.name] ?? 0) - before
                entries.append("\(t.name)=\(via)\(n > 1 ? "\(n)" : "")/\(element.isAccessibilityElement ? 1 : 0)/"
                    + "\(traits.contains(.button) ? 1 : 0)/\(traits.contains(.notEnabled) ? 1 : 0)/"
                    + "\(returned ? 1 : 0)/\(moved)/\(Int(point.x.rounded())),\(Int(point.y.rounded()))")
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
                    // not emitted: two candidate fixes on a Switch inside a
                    // stop (`userInteractionEnabled: false` as emitted, plus one)
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle(isOn: $data.fixDisabledSw) { Text("") }
                            .labelsHidden()
                            .accessibilityIdentifier("fixDisabledSw")
                    }
                        .allowsHitTesting(false)
                        .disabled(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle(isOn: $data.fixRespondsSw) { Text("") }
                            .labelsHidden()
                            .accessibilityRespondsToUserInteraction(false)
                            .accessibilityIdentifier("fixRespondsSw")
                    }
                        .allowsHitTesting(false)
                }
                if let layout = Self.dynamicLayout {
                    DynamicComponentBuilder(component: layout, data: dynamicData)
                } else {
                    Text("layout did not decode").accessibilityIdentifier("a11y_decode_failed")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
