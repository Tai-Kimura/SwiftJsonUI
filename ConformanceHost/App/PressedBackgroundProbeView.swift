//
//  PressedBackgroundProbeView.swift
//  ConformanceHost
//
//  tapBackground is the background while pressed, on every node with a tap
//  (onClick) and on a Button (jsonui-cli 1.9.0) — ticket tapBackground ruling
//  (a). NOT part of the conformance suite. Launch with
//  `-pressedBackgroundProbe` and `-pbPath <dynamic|codegen>`: DynamicView
//  over the layout below, or what sjui build emits for it (jsonui-cli
//  3b33bc3f, JsonToSwiftUIConverter#convert_json_to_view on this layout,
//  pasted unchanged below).
//
//  A View with padding, a Label, an empty View, a View WITHOUT a tap (the
//  control), and a tappable View inside a ScrollView. What a UI test cannot
//  see — the colour while a finger is down — the probe measures itself: a
//  recogniser on the window that recognises nothing watches each touch, and
//  the probe samples its own window at the touch point 0.5 s into the touch
//  (`d=`, or `d=up` when the touch has already ended) and 0.4 s after it
//  ends (`a=`). The readout lists the samples in order and each handler's
//  calls.
//

import SwiftUI
import UIKit
import UIKit.UIGestureRecognizerSubclass
import SwiftJsonUI

final class PressedProbeState: ObservableObject {
    @Published var counts: [String: Int] = [:]
    @Published var samples: [String] = []
    var touchDown = false
    func bump(_ name: String) { counts[name, default: 0] += 1 }
}

final class PressedProbeCodegenData: ObservableObject {
    var onView: (() -> Void)?
    var onLabel: (() -> Void)?
    var onEmpty: (() -> Void)?
    var onScrollItem: (() -> Void)?
}

/// Watches the window's touches and recognises nothing.
final class PassiveTouchWatcher: UIGestureRecognizer, UIGestureRecognizerDelegate {
    var began: ((CGPoint) -> Void)?
    var ended: ((CGPoint) -> Void)?

    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
        delegate = self
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if let t = touches.first { began?(t.location(in: view)) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if let t = touches.first { ended?(t.location(in: view)) }
        state = .failed
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        if let t = touches.first { ended?(t.location(in: view)) }
        state = .failed
    }

    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool { false }
    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool { false }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
}

struct PressedBackgroundProbeView: View {
    @StateObject private var state = PressedProbeState()
    @StateObject private var data = PressedProbeCodegenData()
    @State private var wired = false
    private let path = OnClickProbeView.arg("-pbPath", "dynamic")

    static let layout = ##"{"type":"View","orientation":"vertical","spacing":12,"width":"matchParent","data":[{"name":"onView","class":"(() -> Void)?"},{"name":"onLabel","class":"(() -> Void)?"},{"name":"onEmpty","class":"(() -> Void)?"},{"name":"onScrollItem","class":"(() -> Void)?"}],"child":[{"type":"View","id":"pbView","width":160,"height":60,"paddings":[14,14,14,14],"background":"#0000FF","tapBackground":"#FF0000","onClick":"@{onView}","child":[{"type":"Label","text":"view","fontColor":"#FFFFFF"}]},{"type":"Label","id":"pbLabel","width":160,"height":60,"text":"label","fontColor":"#FFFFFF","background":"#0000FF","tapBackground":"#FF0000","onClick":"@{onLabel}"},{"type":"View","id":"pbEmpty","width":160,"height":60,"background":"#0000FF","tapBackground":"#FF0000","onClick":"@{onEmpty}"},{"type":"View","id":"pbNoTap","width":160,"height":60,"background":"#0000FF","tapBackground":"#FF0000","child":[{"type":"Label","text":"no tap","fontColor":"#FFFFFF"}]},{"type":"ScrollView","id":"pbScroll","width":160,"height":120,"child":[{"type":"View","orientation":"vertical","child":[{"type":"View","id":"pbScrollItem","width":160,"height":80,"background":"#0000FF","tapBackground":"#FF0000","onClick":"@{onScrollItem}","child":[{"type":"Label","text":"item","fontColor":"#FFFFFF"}]},{"type":"View","width":160,"height":400,"background":"#CCCCCC"}]}]}]}"##

    private var readout: String {
        let counts = state.counts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
        return "counts[\(counts)] samples[\(state.samples.joined(separator: ","))]"
    }

    private var dynamicData: [String: Any] {
        let s = state
        return ["onView": { () -> Void in s.bump("onView") },
                "onLabel": { () -> Void in s.bump("onLabel") },
                "onEmpty": { () -> Void in s.bump("onEmpty") },
                "onScrollItem": { () -> Void in s.bump("onScrollItem") }]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("pressed background probe \(path)").accessibilityIdentifier("pb_ready")
            Text(readout).font(.system(size: 7)).accessibilityIdentifier("pb_readout")
            if path == "codegen" {
                VStack(alignment: .leading, spacing: 12) {
                        ZStack(alignment: .topLeading) {
                            Group {
                                PartialAttributedText(
                                    "view".localized(),
                                    fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "#FFFFFF") ?? Color.black,
                                    textAlignment: .leading
                                )
                            }
                        }
                            .padding(.top, 14)
                            .padding(.leading, 14)
                            .padding(.bottom, 14)
                            .padding(.trailing, 14)
                            .frame(width: 160, height: 60, alignment: .topLeading)
                            .pressedBackground(SwiftJsonUIConfiguration.shared.getColor(for: "#FF0000") ?? Color.black, base: SwiftJsonUIConfiguration.shared.getColor(for: "#0000FF") ?? Color.black)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                    data.onView?()
                                }
                            .overlay(alignment: .topLeading) {
                                    Color.clear
                                        .frame(width: 0.5, height: 0.5)
                                        .accessibilityElement(children: .ignore)
                                }
                            .accessibilityElement(children: .combine)
                            .accessibilityAddTraits(.isButton)
                            .tracksPress()
                            .accessibilityIdentifier("pbView")
                        PartialAttributedText(
                            "label".localized(),
                            fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "#FFFFFF") ?? Color.black,
                            textAlignment: .leading
                        )
                            .frame(width: 160, height: 60)
                            .pressedBackground(SwiftJsonUIConfiguration.shared.getColor(for: "#FF0000") ?? Color.black, base: SwiftJsonUIConfiguration.shared.getColor(for: "#0000FF") ?? Color.black)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                    data.onLabel?()
                                }
                            .accessibilityAddTraits(.isButton)
                            .tracksPress()
                            .accessibilityIdentifier("pbLabel")
                        PressedFill(pressed: SwiftJsonUIConfiguration.shared.getColor(for: "#FF0000") ?? Color.black, base: SwiftJsonUIConfiguration.shared.getColor(for: "#0000FF") ?? Color.black)
                            .frame(width: 160, height: 60)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                    data.onEmpty?()
                                }
                            .accessibilityAddTraits(.isButton)
                            .tracksPress()
                            .overlay(alignment: .topLeading) {
                                Color.clear
                                    .frame(width: 0.5, height: 0.5)
                                    .accessibilityElement(children: .ignore)
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("pbEmpty")
                        ZStack(alignment: .topLeading) {
                            Group {
                                PartialAttributedText(
                                    "no tap",
                                    fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "#FFFFFF") ?? Color.black,
                                    textAlignment: .leading
                                )
                            }
                        }
                            .frame(width: 160, height: 60, alignment: .topLeading)
                            .background(SwiftJsonUIConfiguration.shared.getColor(for: "#0000FF") ?? Color.black)
                            .overlay(alignment: .topLeading) {
                                Color.clear
                                    .frame(width: 0.5, height: 0.5)
                                    .accessibilityElement(children: .ignore)
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("pbNoTap")
                        AdvancedKeyboardAvoidingScrollView(.vertical, showsIndicators: true) {
                            VStack(alignment: .leading, spacing: 0) {
                                VStack(alignment: .leading, spacing: 0) {
                                        ZStack(alignment: .topLeading) {
                                            Group {
                                                PartialAttributedText(
                                                    "item".localized(),
                                                    fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "#FFFFFF") ?? Color.black,
                                                    textAlignment: .leading
                                                )
                                            }
                                        }
                                            .frame(width: 160, height: 80, alignment: .topLeading)
                                            .pressedBackground(SwiftJsonUIConfiguration.shared.getColor(for: "#FF0000") ?? Color.black, base: SwiftJsonUIConfiguration.shared.getColor(for: "#0000FF") ?? Color.black)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                                    data.onScrollItem?()
                                                                }
                                            .overlay(alignment: .topLeading) {
                                                                    Color.clear
                                                                        .frame(width: 0.5, height: 0.5)
                                                                        .accessibilityElement(children: .ignore)
                                                                }
                                            .accessibilityElement(children: .combine)
                                            .accessibilityAddTraits(.isButton)
                                            .tracksPress()
                                            .accessibilityIdentifier("pbScrollItem")
                                        Rectangle()
                                            .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#CCCCCC") ?? Color.black)
                                            .frame(width: 160, height: 400)
                                }
                                Spacer(minLength: 0)
                            }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                            .frame(width: 160, height: 120, alignment: .topLeading)
                            .overlay(alignment: .topLeading) {
                                Color.clear
                                    .frame(width: 0.5, height: 0.5)
                                    .accessibilityElement(children: .ignore)
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("pbScroll")
                }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            } else if let layout = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicView(component: layout, viewId: "pb", data: dynamicData)
            } else {
                Text("decode failed").accessibilityIdentifier("pb_decode_failed")
            }
            Spacer(minLength: 0)
        }
        .onAppear { wire() }
    }

    private func wire() {
        guard !wired else { return }
        wired = true
        let s = state
        data.onView = { s.bump("onView") }
        data.onLabel = { s.bump("onLabel") }
        data.onEmpty = { s.bump("onEmpty") }
        data.onScrollItem = { s.bump("onScrollItem") }
        DispatchQueue.main.async { installWatcher() }
    }

    private func installWatcher() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { installWatcher() }
            return
        }
        let s = state
        let watcher = PassiveTouchWatcher(target: nil, action: nil)
        watcher.began = { p in
            s.touchDown = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                s.samples.append(s.touchDown ? "d=\(Self.sample(at: p, in: window))" : "d=up")
            }
        }
        watcher.ended = { p in
            s.touchDown = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                s.samples.append("a=\(Self.sample(at: p, in: window))")
            }
        }
        window.addGestureRecognizer(watcher)
    }

    /// The colour of the window's pixel at `p`, as drawn now.
    static func sample(at p: CGPoint, in window: UIWindow) -> String {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1), format: format).image { ctx in
            ctx.cgContext.translateBy(x: -p.x, y: -p.y)
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
        guard let cg = image.cgImage else { return "none" }
        var px = [UInt8](repeating: 0, count: 4)
        let context = CGContext(data: &px, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(cg, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        let (r, g, b) = (px[0], px[1], px[2])
        if r > 200 && g < 80 && b < 80 { return "red" }
        if b > 200 && r < 80 && g < 80 { return "blue" }
        return "other(\(r) \(g) \(b))"
    }
}
