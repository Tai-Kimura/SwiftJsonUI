//
//  AnchorTapProbeView.swift
//  ConformanceHost
//
//  A tappable View's tap must reach its handler where XCUITest aims and
//  where VoiceOver activates. Ticket sjui-a-tappable-elements-anchor-inside-
//  its-tap-target-moves-the-tap-point-off-it: jsonui-cli 1.9.18 / SwiftJsonUI
//  10.29.7 moved the 0.5pt accessibility anchor of a combined tap inside the
//  tap gesture, and a consumer's tap on a 30x30 View stopped arriving.
//
//  The specimen (ProbeLayouts/probe_anchor_tap.json): four tappable 30x30
//  Views, cornerRadius 15, gravity center, one Label child (so the tap is
//  combined and takes the anchor):
//    - m: top-right of a 100-high card that has an onClick of its own,
//         topMargin 8 / rightMargin 8 (a RelativePositionContainer child);
//    - n: the same without the margins;
//    - q: the same margins, a card with no onClick;
//    - s: the only child of a plain 300 x 40 View;
//    - f: an app's shape — in a ScrollView, a 200-high card with topMargin
//         24, a bound visibility and an onClick, an AspectFill NetworkImage
//         under the button, the button's background translucent;
//    - g: a tappable row of a decorative Image and a Label, topMargin 24 —
//         the shape whose combined element takes the anchor with the fix.
//  "hit" shows the last handler that ran (btn_m, card_m, ...).
//
//  Launch with `-anchorTapProbe` and `-atVariant <v>`:
//    dyn  — the Dynamic runtime (this library);
//    cg   — the generated half (codegen host only: CodegenFixtureRegistry);
//    cg17 / cg18 — what jsonui-cli v1.9.17 / v1.9.18 emit, pasted
//           (AnchorTapCodegenPaste.swift): the measured contrast.
//  NOT part of the conformance suite; its test is AnchorTapProbeUITests.
//
//  Two reads besides the tap's effect, both from inside the app:
//    - where a touch landed: a window-level recognizer that cancels and
//      delays nothing ("at_touch", window points);
//    - at_ready's accessibilityFrame, so the test can move both reads into
//      XCUITest's space (an iPad app's window is not at the screen's origin);
//    - what VoiceOver would use: each button's accessibilityFrame and
//      accessibilityActivationPoint, read by walking the key window's
//      accessibility tree when "at_measure" is pressed ("at_ax").
//

import SwiftUI
import SwiftJsonUI
import UIKit

final class AnchorTapStore: ObservableObject {
    @Published var paste = AnchorTapPasteData()
    @Published var hit = ""

    init() {
        let names = ["Card_m", "Btn_m", "Card_n", "Btn_n", "Btn_q", "Btn_s", "Card_f", "Btn_f", "Btn_g"]
        for name in names {
            let value = name.lowercased()
            let call: () -> Void = { [weak self] in
                self?.hit = value
                self?.paste.hit = value
            }
            switch name {
            case "Card_m": paste.onCard_m = call
            case "Btn_m": paste.onBtn_m = call
            case "Card_n": paste.onCard_n = call
            case "Btn_n": paste.onBtn_n = call
            case "Btn_q": paste.onBtn_q = call
            case "Card_f": paste.onCard_f = call
            case "Btn_f": paste.onBtn_f = call
            case "Btn_g": paste.onBtn_g = call
            default: paste.onBtn_s = call
            }
        }
        paste.fUrl = Self.sampleImageURL
    }

    /// The image under the f button: the host's sample asset, written once to
    /// a file so NetworkImage loads it the way an app's picked photo is.
    static let sampleImageURL: String? = {
        guard let image = UIImage(named: "conformance_sample"), let png = image.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("anchor_tap_sample.png")
        try? png.write(to: url)
        return url.absoluteString
    }()

    func dynamicData() -> [String: Any] {
        var data: [String: Any] = ["hit": hit, "fVisibility": "visible", "fUrl": Self.sampleImageURL as Any]
        for name in ["Card_m", "Btn_m", "Card_n", "Btn_n", "Btn_q", "Btn_s", "Card_f", "Btn_f", "Btn_g"] {
            let value = name.lowercased()
            data["on\(name)"] = { [weak self] in self?.hit = value } as () -> Void
        }
        return data
    }
}

/// Where the last touch landed, in window points.
final class AnchorTapTouchLog: NSObject, ObservableObject, UIGestureRecognizerDelegate {
    @Published var last = "none"
    private var installed = false

    func install() {
        guard !installed, let window = A11yActivator.keyWindow() else { return }
        installed = true
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        recognizer.delegate = self
        window.addGestureRecognizer(recognizer)
    }

    @objc private func tapped(_ recognizer: UITapGestureRecognizer) {
        let p = recognizer.location(in: recognizer.view)
        last = String(format: "%.2f,%.2f", p.x, p.y)
    }

    func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
}

struct AnchorTapProbeView: View {
    let variant: String
    @StateObject private var store = AnchorTapStore()
    @StateObject private var touches = AnchorTapTouchLog()
    @State private var ax = ""

    static let layout = ##"{"type": "View", "id": "dyn_at_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "spacing": 6, "child": [{"type": "Label", "id": "dyn_at_hit", "text": "@{hit}", "width": "wrapContent", "height": "wrapContent"}, {"type": "View", "id": "dyn_at_card_m", "width": "matchParent", "height": 100, "cornerRadius": 12, "child": [{"type": "View", "id": "dyn_at_fill_m", "width": "matchParent", "height": "matchParent", "background": "#BBCCDD"}, {"type": "View", "id": "dyn_at_btn_m", "width": 30, "height": 30, "cornerRadius": 15, "background": "#333333", "gravity": "center", "onClick": "@{onBtn_m}", "child": [{"type": "Label", "id": "dyn_at_icon_m", "text": "x", "fontSize": 14, "fontColor": "#FFFFFF", "width": "wrapContent", "height": "wrapContent"}], "alignTop": true, "alignRight": true, "topMargin": 8, "rightMargin": 8}], "onClick": "@{onCard_m}"}, {"type": "View", "id": "dyn_at_card_n", "width": "matchParent", "height": 100, "cornerRadius": 12, "child": [{"type": "View", "id": "dyn_at_fill_n", "width": "matchParent", "height": "matchParent", "background": "#BBCCDD"}, {"type": "View", "id": "dyn_at_btn_n", "width": 30, "height": 30, "cornerRadius": 15, "background": "#333333", "gravity": "center", "onClick": "@{onBtn_n}", "child": [{"type": "Label", "id": "dyn_at_icon_n", "text": "x", "fontSize": 14, "fontColor": "#FFFFFF", "width": "wrapContent", "height": "wrapContent"}], "alignTop": true, "alignRight": true}], "onClick": "@{onCard_n}"}, {"type": "View", "id": "dyn_at_card_q", "width": "matchParent", "height": 100, "cornerRadius": 12, "child": [{"type": "View", "id": "dyn_at_fill_q", "width": "matchParent", "height": "matchParent", "background": "#BBCCDD"}, {"type": "View", "id": "dyn_at_btn_q", "width": 30, "height": 30, "cornerRadius": 15, "background": "#333333", "gravity": "center", "onClick": "@{onBtn_q}", "child": [{"type": "Label", "id": "dyn_at_icon_q", "text": "x", "fontSize": 14, "fontColor": "#FFFFFF", "width": "wrapContent", "height": "wrapContent"}], "alignTop": true, "alignRight": true, "topMargin": 8, "rightMargin": 8}]}, {"type": "View", "id": "dyn_at_box_s", "width": 300, "height": 40, "child": [{"type": "View", "id": "dyn_at_btn_s", "width": 30, "height": 30, "cornerRadius": 15, "background": "#333333", "gravity": "center", "onClick": "@{onBtn_s}", "child": [{"type": "Label", "id": "dyn_at_icon_s", "text": "x", "fontSize": 14, "fontColor": "#FFFFFF", "width": "wrapContent", "height": "wrapContent"}]}]}, {"type": "View", "id": "dyn_at_btn_g", "orientation": "horizontal", "width": "matchParent", "height": 56, "topMargin": 24, "gravity": "center", "background": "#DDEEFF", "cornerRadius": 4, "onClick": "@{onBtn_g}", "child": [{"type": "Image", "id": "dyn_at_icon_g", "srcName": "conformance_sample", "width": 24, "height": 24, "rightMargin": 10}, {"type": "Label", "id": "dyn_at_label_g", "text": "Sign in", "width": "wrapContent", "height": "wrapContent"}]}, {"type": "ScrollView", "id": "dyn_at_scroll_f", "width": "matchParent", "height": 230, "child": [{"type": "View", "id": "dyn_at_content_f", "width": "matchParent", "height": "wrapContent", "orientation": "vertical", "child": [{"type": "View", "id": "dyn_at_card_f", "width": "matchParent", "height": 200, "topMargin": 24, "cornerRadius": 12, "visibility": "@{fVisibility}", "onClick": "@{onCard_f}", "child": [{"type": "NetworkImage", "id": "dyn_at_image_f", "width": "matchParent", "height": "matchParent", "src": "@{fUrl}", "contentMode": "AspectFill", "cornerRadius": 12}, {"type": "View", "id": "dyn_at_btn_f", "width": 30, "height": 30, "cornerRadius": 15, "background": "#00000080", "gravity": "center", "alignTop": true, "alignRight": true, "topMargin": 8, "rightMargin": 8, "onClick": "@{onBtn_f}", "child": [{"type": "Label", "id": "dyn_at_icon_f", "width": "wrapContent", "height": "wrapContent", "text": "x", "fontSize": 14, "fontColor": "#FFFFFF"}]}]}]}]}], "data": [{"class": "String", "name": "hit", "defaultValue": ""}, {"class": "(() -> Void)?", "name": "onCard_m"}, {"class": "(() -> Void)?", "name": "onBtn_m"}, {"class": "(() -> Void)?", "name": "onCard_n"}, {"class": "(() -> Void)?", "name": "onBtn_n"}, {"class": "(() -> Void)?", "name": "onBtn_q"}, {"class": "(() -> Void)?", "name": "onBtn_s"}, {"class": "(() -> Void)?", "name": "onCard_f"}, {"class": "(() -> Void)?", "name": "onBtn_f"}, {"class": "String", "name": "fVisibility", "defaultValue": "visible"}, {"class": "String?", "name": "fUrl"}, {"class": "(() -> Void)?", "name": "onBtn_g"}]}"##

    private var prefix: String { variant == "dyn" ? "dyn" : "cg" }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("anchor tap probe (\(variant))").accessibilityIdentifier("at_ready")
            Text(touches.last).accessibilityIdentifier("at_touch")
            Button("measure") { ax = measure() }.accessibilityIdentifier("at_measure")
            Text(ax).font(.system(size: 6)).lineLimit(3).frame(height: 24, alignment: .topLeading).accessibilityIdentifier("at_ax")
            Group {
                switch variant {
                case "cg17": AnchorTapPaste17(data: $store.paste)
                case "cg18": AnchorTapPaste18(data: $store.paste)
                case "cg19": AnchorTapPaste19(data: $store.paste)
                case "cg":
                    if let generated = CodegenFixtureRegistry.probeView(named: "probe_anchor_tap") {
                        generated
                    } else {
                        Text("no generated half").accessibilityIdentifier("at_no_generated")
                    }
                default:
                    if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                        DynamicComponentBuilder(component: component, data: store.dynamicData())
                    } else {
                        Text("did not decode").accessibilityIdentifier("at_decode_failed")
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .onAppear { touches.install() }
    }

    /// id=frame x,y,w,h/activation x,y/elements n per button, screen points.
    private func measure() -> String {
        guard let window = A11yActivator.keyWindow() else { return "nowindow" }
        // The space these points are in is the app's (its window's); on an
        // iPad window that is not where XCUITest's frames are. at_ready,
        // read both ways, gives the test the offset between the two.
        let ready = A11yActivator.matches("at_ready", under: window).first { $0.isAccessibilityElement }
        let r = ready?.accessibilityFrame ?? .null
        let reference = String(format: "at_ready=%.2f,%.2f,%.2f,%.2f/0,0/1", r.minX, r.minY, r.width, r.height)
        return ([reference] + ["m", "n", "q", "s", "f", "g"].map { k -> String in
            let id = "\(prefix)_at_btn_\(k)"
            let nodes = A11yActivator.matches(id, under: window).filter { $0.isAccessibilityElement }
            guard let node = nodes.first else { return "\(id)=none" }
            let f = node.accessibilityFrame
            let a = node.accessibilityActivationPoint
            return String(format: "%@=%.2f,%.2f,%.2f,%.2f/%.2f,%.2f/%d", id, f.minX, f.minY, f.width, f.height, a.x, a.y, nodes.count)
        }).joined(separator: ";")
    }
}
