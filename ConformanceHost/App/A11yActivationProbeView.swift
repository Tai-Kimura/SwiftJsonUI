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
//  Left (codegen host only): what `sjui build` generates from
//  ProbeLayouts/probe_a11y_activation.json and its cell
//  ProbeLayouts/cells/a11y_activation_cell.json, built by
//  scripts/generate_codegen_host.rb with the sjui_tools of the run — not a
//  copy. Until 2026-10 these rows were the build's output pasted here, and
//  the paste kept its shape when sjui's changed: the Radio's
//  `.accessibilityElement(children: .contain)` (SwiftJsonUI 9768b01 /
//  jsonui-cli b5b9815b) never reached it, and the probe read a codegen
//  regression as expected (jsonui-cli ticket
//  sjui-a11y-activation-probe-codegen-rows-are-hand-copies). The generated
//  view's data is its host's; the probe reaches it through a ProbeHostLink
//  (ProbeHostLink.swift): the handlers and the controls' changes count here
//  (ProbeLayouts/handlers/probe_a11y_activation.json: `count`, `watch`), and
//  the probe writes the bound stop (`gateOpen`), the cell rows and the
//  wrapper controls' start (`writes`). The cell's View is the one sjui build
//  scaffolds: Equatable on its key, drawn `.equatable()` by the Collection.
//  The dynamic-only host has no generated rows; its test requires them
//  absent there and present in the codegen host. The rows:
//  - no stop (the controls): a Label with onClick, a Button, a Switch, a
//    Segment and a Radio group (the wrapper controls: each segment and each
//    item is an element of its own — the item "b", the glyph "circle");
//  - inside a View with `userInteractionEnabled: false`: a Button, a Label
//    with onClick, a View with onClick, a Switch, a Segment, a Radio group;
//  - inside a View with `userInteractionEnabled: "@{gateOpen}"`: the same
//    four, and a Collection whose cell has a Label with onClick (the cell is
//    a layout the stop reaches: it reads `jsonuiInteractionStopped`);
//  - a Button and a Switch with `userInteractionEnabled: false` of their own.
//  Written by hand, not emitted: the same generated cell drawn without
//  `.equatable()` (cgCellNoEq, CodegenOnly/A11yActivationCellNoEq.swift — the
//  contrast for the cell; sjui does not emit that form, so it cannot be
//  generated), and the candidate fixes for a Switch and a
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

/// Test-only: holds back a count that a touch causes by a declared delay, so
/// the count reaches the readout well after the tap returns.
///
/// XCUITest's tap returns once the app is idle, and on a fast machine the
/// touch's count is already in the readout by then: run 3 read it after a
/// fixed 0.4 s and passed here every time, and on a slow CI runner it read
/// 0 (sjui-conformance-a11y-activation-run3-touch-not-counted). With the
/// delay set, a read that does not wait for the count goes red on any
/// machine.
///
/// The delay is declared by the run (CONFORMANCE_TAP_COUNT_DELAY, seconds,
/// forwarded as a launch environment variable by the probe); unset or 0 is
/// the ordinary run. Chosen from the test's own numbers, not a measurement:
/// above the old fixed 0.4 s by far, an order above the 0.05 s read period,
/// and well inside the touch-read budget (A11yActivationProbeUITests
/// `touchBudget`) — 2.
enum ProbeTapCountDelay {
    static let seconds: Double =
        Double(ProcessInfo.processInfo.environment["CONFORMANCE_TAP_COUNT_DELAY"] ?? "") ?? 0
}

final class A11yActivationProbeData: ObservableObject {
    @Published var counts: [String: Int] = [:]
    /// The last run's entries, its walk census, and its number.
    @Published var act = ""
    @Published var walk = ""
    @Published var ran = 0 { didSet { walking = false } }

    /// True while the app's own walk is activating elements (from the run
    /// button to the run's number being written): its counts are read 0.25 s
    /// after each activation and are never held back.
    var walking = false

    /// A count the walk did not cause — the touch the test sends VoiceOver's
    /// way — lands now, or `ProbeTapCountDelay.seconds` later when the run
    /// declares a delay (the specimen for the test's read of the touch).
    func bump(_ name: String) {
        guard !walking, ProbeTapCountDelay.seconds > 0 else { counts[name, default: 0] += 1; return }
        DispatchQueue.main.asyncAfter(deadline: .now() + ProbeTapCountDelay.seconds) { [weak self] in
            self?.counts[name, default: 0] += 1
        }
    }

    // The codegen rows' data is the generated host's (ProbeHostLink.swift):
    // the handlers and the controls' changes count through the link, and the
    // bound stop and the cell rows are written into it. `gateOpen` is the
    // probe's, read by the Dynamic rows and the hand-written cell contrast
    // too, and written through to the generated rows on every change.
    @Published var gateOpen: Bool? = true { didSet { link.write(["gateOpen": gateOpen ?? false]) } }
    lazy var link = ProbeHostLink(
        values: ["gateOpen": gateOpen ?? false, "rows": cellRows("cgCellEq")],
        count: { [weak self] name in self?.bump(name) }
    )
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
    lazy var rowsNoEq: CollectionDataSource? = cellRows("cgCellNoEq")

    private func cellRows(_ name: String) -> CollectionDataSource {
        let onRow: (() -> Void)? = { [weak self] in self?.bump(name) }
        var section = CollectionDataSection()
        section.setCells(viewName: "A11yActivationCell", data: [["cellId": name, "onRow": onRow as Any]])
        return CollectionDataSource(sections: [section])
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
        data.walking = true
        if Self.wrappersOnly { runWrappers(); return }
        if Self.textFieldsOnly { runTextFields(); return }
        // The wrapper controls with no stop start each run on their first
        // item, so the item a run operates ("b", an unselected glyph) moves
        // the selection again (the generated rows' through the link).
        data.link.write(["segPlain": 0, "radPlain": "a"])
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

    /// `-textFields`: for each TextField row, what a screen reader is offered
    /// and what it does — its named actions, and the value before and after
    /// performing the clear one when it is there. One entry each:
    /// `name=via/responds/actions/before/after` (`actions` joined by `|`,
    /// `-` for none; `after` is `-` when nothing was performed).
    private func runTextFields() {
        let phase = data.ran + 1
        func clean(_ s: String?) -> String {
            (s ?? "").replacingOccurrences(of: "/", with: "|").replacingOccurrences(of: ";", with: ",")
                .replacingOccurrences(of: "=", with: ":").replacingOccurrences(of: "]", with: ")")
        }
        var entries: [String] = []
        var pending: [(String, NSObject, String, String, String)] = []
        for id in TextFieldStopRows.ids {
            let (found, via, _) = A11yActivator.target(id, scope: nil)
            guard let element = found else { entries.append("\(id)=\(via)/-/-/-/-"); continue }
            let actions = element.accessibilityCustomActions ?? []
            let names = actions.isEmpty ? "-" : actions.map { clean($0.name) }.joined(separator: "|")
            let before = clean(element.accessibilityValue)
            let responds = element.accessibilityRespondsToUserInteraction ? "1" : "0"
            if let clear = actions.first(where: { $0.name == "Clear text" }) {
                _ = clear.actionHandler?(clear)
                pending.append((id, element, "\(via)/\(responds)/\(names)", before, ""))
            } else {
                entries.append("\(id)=\(via)/\(responds)/\(names)/\(before)/-")
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            for (id, element, head, before, _) in pending {
                entries.append("\(id)=\(head)/\(before)/\(clean(element.accessibilityValue))")
            }
            data.act = entries.joined(separator: ";")
            data.ran = phase
        }
    }

    // Lets and one interpolated literal (see InteractionGateProbeView): the
    // counts are live, so the UI test reads what a touch moved as well.
    private var readout: String {
        let counts = data.counts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
        let gate = (data.gateOpen ?? false) ? "open" : "closed"
        return "ran=\(data.ran) gate=\(gate) host=\(Self.hostMode) cg=\(Self.generated == nil ? 0 : 1) "
            + "walk=\(data.walk) act[\(data.act)] counts[\(counts)]"
    }


    @FocusState private var focus: String?

    /// The generated rows: present only in the codegen host's build.
    static var generated: AnyView? { CodegenFixtureRegistry.probeView(named: "probe_a11y_activation") }
    /// The host the test says this is, as it reached the app (the test's
    /// TEST_RUNNER_ environment does not: it is passed as launchEnvironment).
    /// The test compares it, and `cg`, with its own — a build without the
    /// generated rows under a codegen run reads as such, not as a pass.
    static let hostMode = ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] ?? "dynamic"

    /// `-candidates`: the candidate fixes alone, on a screen of their own (the
    /// probe's two columns fill the screen).
    static let candidatesOnly = ProcessInfo.processInfo.arguments.contains("-candidates")
    /// `-wrappers`: the wrapper controls' candidates (WrapperStopCandidates).
    static let wrappersOnly = ProcessInfo.processInfo.arguments.contains("-wrappers")
    /// `-textFields`: TextFields inside a stop and not (TextFieldStopRows).
    static let textFieldsOnly = ProcessInfo.processInfo.arguments.contains("-textFields")

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
            } else if Self.textFieldsOnly {
                TextFieldStopRows()
            } else if Self.candidatesOnly {
                ScrollView { VStack(alignment: .leading, spacing: 4) { candidatesBlock } }
            } else {
            HStack(alignment: .top, spacing: 16) {
                // The codegen rows (codegen host only): the generated view
                // with the link to this probe's data, then the hand-written
                // contrast for its cell. Nothing around the generated view:
                // an identifier on it would replace the ids inside it.
                if let generated = Self.generated {
                    VStack(alignment: .leading, spacing: 4) {
                        generated.environment(\.probeHostLink, data.link)
                        A11yActivationCellNoEq(data: data)
                    }
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

// MARK: - TextFields inside a stop (`-textFields`)

/// A TextField with a clear button, with no stop, inside
/// `userInteractionEnabled: false`, and with false of its own — on both
/// routes. The clear button is the field's NAMED accessibility action, which
/// the stopped control's treatment did not remove: a screen reader emptied a
/// field the layout stopped (ticket sjui-dynamic-radio-item-operable-inside-a-stop).
/// The codegen rows are what sjui generated from
/// ProbeLayouts/probe_a11y_text_fields.json (codegen host only), put here
/// with nothing around them — an identifier on the generated view would
/// replace the ids inside it.
struct TextFieldStopRows: View {
    static let dynamicIds = ["dynTfPlain", "dynTfInFalse", "dynTfSelfFalse"]
    static let codegenIds = ["cg_tf_plain", "cg_tf_infalse", "cg_tf_selffalse"]
    static let ids = dynamicIds + codegenIds

    static let layout: DynamicComponent? = {
        let field = { (id: String, extra: String) in
            ##"{"type": "TextField", "id": "\##(id)", "width": 160, "height": 36, "text": "abc", "clearButtonMode": "always"\##(extra)}"##
        }
        let json = #"{"type": "View", "orientation": "vertical", "spacing": 6, "child": ["#
            + field("dynTfPlain", "") + ", "
            + #"{"type": "View", "id": "dynTfParFalse", "orientation": "vertical", "userInteractionEnabled": false, "child": ["#
            + field("dynTfInFalse", "") + "]}, "
            + field("dynTfSelfFalse", #", "userInteractionEnabled": false"#) + "]}"
        return try? JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let generated = CodegenFixtureRegistry.probeView(named: "probe_a11y_text_fields") {
                generated
            }
            if let layout = Self.layout {
                DynamicComponentBuilder(component: layout, data: [:])
            } else {
                Text("layout did not decode").accessibilityIdentifier("a11y_decode_failed")
            }
        }
    }
}
