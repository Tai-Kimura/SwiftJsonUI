//
//  SelectBoxKeyboardProbeView.swift
//  ConformanceHost
//
//  A SelectBox pressed while a field holds the keyboard: one press opens the
//  sheet. NOT part of the conformance suite. Launch with
//  `-selectBoxKeyboardProbe dyn` (Dynamic) or `-selectBoxKeyboardProbe cg`
//  (generated, in the codegen host).
//
//  The generated half: ProbeLayouts/probe_selectbox_keyboard.json.
//

import SwiftUI
import SwiftJsonUI

#if DEBUG
struct SelectBoxKeyboardProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type":"SafeAreaView","id":"sbk_safe","width":"matchParent","height":"matchParent","data":[{"name":"email","class":"String","defaultValue":""},{"name":"note","class":"String","defaultValue":""},{"name":"dialogShown","class":"Bool","defaultValue":false},{"name":"alertShown","class":"Bool","defaultValue":false},{"name":"onDialog","class":"(() -> Void)?"},{"name":"onAlert","class":"(() -> Void)?"},{"name":"onEmailChange","class":"((String, String) -> Void)?"},{"name":"onFooter","class":"(() -> Void)?"},{"name":"overlayVisibility","class":"String","defaultValue":"gone"}],"child":[{"type":"View","id":"sbk_vertical","width":"matchParent","height":"matchParent","orientation":"vertical","child":[{"type":"ScrollView","id":"sbk_scroll","width":"matchParent","child":[{"type":"View","id":"sbk_content","orientation":"vertical","width":"matchParent","height":"wrapContent","child":[{"type":"Label","id":"sbk_ready","text":"sbk ready","height":24},{"type":"TextField","id":"sbk_tf","text":"@{email}","hint":"field","width":"matchParent","height":44,"background":"#DDEEFF","returnKeyType":"Done","onTextChange":"@{onEmailChange}"},{"type":"TextView","id":"sbk_tv","text":"@{note}","hint":"view","width":"matchParent","height":70,"background":"#DDFFEE"},{"type":"SelectBox","id":"sbk_near","width":"matchParent","height":44,"prompt":"pick sbk_near","background":"#EEEEEE","items":["One","Two","Three"]},{"type":"View","id":"sbk_filler","width":"matchParent","height":700,"background":"#FAFAFA"},{"type":"SelectBox","id":"sbk_normal","width":"matchParent","height":44,"prompt":"pick sbk_normal","background":"#EEEEEE","items":["One","Two","Three"]},{"type":"SelectBox","id":"sbk_date","width":"matchParent","height":44,"prompt":"pick sbk_date","background":"#EEEEEE","selectItemType":"Date","datePickerMode":"date","datePickerStyle":"wheel","dateStringFormat":"yyyy-MM-dd"},{"type":"SelectBox","id":"sbk_time","width":"matchParent","height":44,"prompt":"pick sbk_time","background":"#EEEEEE","selectItemType":"Date","datePickerMode":"time","datePickerStyle":"wheel","dateStringFormat":"HH:mm"},{"type":"SelectBox","id":"sbk_interval","width":"matchParent","height":44,"prompt":"pick sbk_interval","background":"#EEEEEE","selectItemType":"Date","datePickerMode":"time","datePickerStyle":"wheel","dateStringFormat":"HH:mm","minuteInterval":15},{"type":"SelectBox","id":"sbk_graphical","width":"matchParent","height":44,"prompt":"pick sbk_graphical","background":"#EEEEEE","selectItemType":"Date","datePickerMode":"date","datePickerStyle":"graphical","dateStringFormat":"yyyy-MM-dd"},{"type":"SelectBox","id":"sbk_compact","width":"matchParent","height":44,"prompt":"pick sbk_compact","background":"#EEEEEE","selectItemType":"Date","datePickerMode":"date","datePickerStyle":"compact","dateStringFormat":"yyyy-MM-dd"},{"type":"SelectBox","id":"sbk_automatic","width":"matchParent","height":44,"prompt":"pick sbk_automatic","background":"#EEEEEE","selectItemType":"Date","datePickerMode":"date","datePickerStyle":"automatic","dateStringFormat":"yyyy-MM-dd"},{"type":"Button","id":"sbk_dialog","text":"dialog","width":"matchParent","height":44,"onClick":"@{onDialog}","confirmationDialog":{"isPresented":"@{dialogShown}","title":"sbk dialog","titleVisibility":"visible","actions":"@{dialogActions}"}},{"type":"Button","id":"sbk_alert","text":"alert","width":"matchParent","height":44,"onClick":"@{onAlert}","alert":{"isPresented":"@{alertShown}","title":"sbk alert","actions":"@{alertActions}"}},{"type":"View","id":"sbk_tail","width":"matchParent","height":300}]}],"weight":1},{"type":"View","id":"sbk_footer","width":"matchParent","height":56,"background":"#333333","orientation":"horizontal","onClick":"@{onFooter}","child":[{"type":"Label","text":"footer","id":"sbk_footer_label"}]}]},{"type":"View","id":"sbk_overlay","width":"matchParent","height":"matchParent","visibility":"@{overlayVisibility}","background":"#88000000"}]}"##

    /// `-sbkDismissMode onDrag|interactive` declares the ScrollView's keyboardDismissMode.
    static var resolvedLayout: String {
        let args = ProcessInfo.processInfo.arguments
        var result = layout
        if let i = args.firstIndex(of: "-sbkDismissMode"), i + 1 < args.count, !args[i + 1].isEmpty {
            result = result.replacingOccurrences(
                of: #""id":"sbk_scroll","#,
                with: #""id":"sbk_scroll","keyboardDismissMode":"\#(args[i + 1])","#)
        }
        // `-sbkFiller N`: how far below the fields the box sits; `-sbkTail N`: how much runs on after the last row.
        if let i = args.firstIndex(of: "-sbkFiller"), i + 1 < args.count {
            result = result.replacingOccurrences(of: #""id":"sbk_filler","width":"matchParent","height":700"#,
                                                 with: #""id":"sbk_filler","width":"matchParent","height":\#(args[i + 1])"#)
        }
        if let i = args.firstIndex(of: "-sbkTail"), i + 1 < args.count {
            result = result.replacingOccurrences(of: #""id":"sbk_tail","width":"matchParent","height":300"#,
                                                 with: #""id":"sbk_tail","width":"matchParent","height":\#(args[i + 1])"#)
        }
        return result
    }

    @State private var email = ""
    @State private var note = ""
    @State private var dialogShown = false
    @State private var alertShown = false
    @State private var barItemPressed = false

    private var data: [String: Any] {
        [
            "email": SwiftUI.Binding(get: { email }, set: { email = $0 }),
            "note": SwiftUI.Binding(get: { note }, set: { note = $0 }),
            "dialogShown": SwiftUI.Binding(get: { dialogShown }, set: { dialogShown = $0 }),
            "alertShown": SwiftUI.Binding(get: { alertShown }, set: { alertShown = $0 }),
            "onDialog": { dialogShown = true } as () -> Void,
            "onAlert": { alertShown = true } as () -> Void,
            "onEmailChange": { (_: String, value: String) in email = value } as (String, String) -> Void,
            "onFooter": {} as () -> Void,
            "dialogActions": {
                AnyView(Group {
                    Button("sbk ok", role: .destructive) {}
                    Button("sbk cancel", role: .cancel) {}
                })
            } as () -> AnyView,
            "alertActions": {
                AnyView(Button("sbk cancel", role: .cancel) {})
            } as () -> AnyView,
            "overlayVisibility": "gone",
        ]
    }

    /// `-sbkWindowTap`: a tap recognizer on the window that puts the keyboard
    /// away on any tap outside a text input, alongside whatever the tap lands
    /// on — the usual "tap the background to dismiss" an app adds itself.
    private func installWindowTap() {
        guard ProcessInfo.processInfo.arguments.contains("-sbkWindowTap"),
              let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return }
        let tap = UITapGestureRecognizer(target: SBKWindowTap.shared, action: #selector(SBKWindowTap.handleTap))
        tap.cancelsTouchesInView = false
        tap.delegate = SBKWindowTap.shared
        window.addGestureRecognizer(tap)
    }

    /// `-sbkFull`: the screen is pushed onto a NavigationStack, with the sheets,
    /// dialog, alert and destinations a form screen hangs on its root, none shown.
    private var full: Bool { ProcessInfo.processInfo.arguments.contains("-sbkFull") }

    var body: some View {
        Group {
            if full {
                NavigationStack {
                    NavigationLink("go") {
                        content
                            .navigationTitle("form")
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("item") { barItemPressed = true }
                                        .accessibilityIdentifier("sbk_bar_item")
                                }
                            }
                            .alert("sbk bar item pressed", isPresented: $barItemPressed) { Button("OK") {} }
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationDestination(isPresented: .constant(false)) { Text("a") }
                            .navigationDestination(isPresented: .constant(false)) { Text("b") }
                            .sheet(isPresented: .constant(false)) { Text("c") }
                            .sheet(isPresented: .constant(false)) { Text("d") }
                            .sheet(isPresented: .constant(false)) { Text("e") }
                            .sheet(isPresented: .constant(false)) { Text("f") }
                            .confirmationDialog("g", isPresented: .constant(false)) { Button("h") {} }
                            .alert("i", isPresented: .constant(false)) { Button("j") {} }
                    }
                    .accessibilityIdentifier("sbk_go")
                }
            } else if ProcessInfo.processInfo.arguments.contains("-sbkTabs") {
                TabView {
                    content.tabItem { Text("one") }
                    Text("two").tabItem { Text("two") }
                }
            } else {
                content
            }
        }
        .onAppear { installWindowTap() }
    }

    @ViewBuilder private var content: some View {
        if codegen {
            if let generated = CodegenFixtureRegistry.probeView(named: "probe_selectbox_keyboard") {
                generated
            } else {
                Text("no generated view").accessibilityIdentifier("sbk_no_codegen")
            }
        } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.resolvedLayout.utf8)) {
            NavigationStack {
                DynamicView(component: component, viewId: "sbk", data: data)
            }
        } else {
            Text("did not decode").accessibilityIdentifier("sbk_decode_failed")
        }
    }
}

private final class SBKWindowTap: NSObject, UIGestureRecognizerDelegate {
    static let shared = SBKWindowTap()

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let v = view {
            if v is UITextField || v is UITextView { return false }
            if v.canBecomeFirstResponder && String(describing: type(of: v)).contains("TextField") { return false }
            view = v.superview
        }
        return true
    }

    @objc func handleTap() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }
}
#endif
