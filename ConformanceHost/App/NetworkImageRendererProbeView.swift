//
//  NetworkImageRendererProbeView.swift
//  ConformanceHost
//
//  Launched with `-networkImageRendererProbe <base url>`: NetworkImage frames
//  with a test loading renderer — a box filled from the bottom, its level the
//  bytes received over the expected (FillBoxRenderer) — against a local
//  server: slow images (the renderer rises after loadingDelay, the image
//  fades in over T), a fast one (done inside the delay: no renderer, T/2), a
//  failing one (the error image after T/6 over 5T/6), two frames of one URL
//  (one read) and, on the second screen, the same URLs from the memory cache
//  (no renderer, no fade). Ticket jui-networkimage-load-listener; the
//  requester sees this before integration. NetworkImageRendererProbeUITests
//  drives it (opt-in, CONFORMANCE_NW_RENDERER_URL).
//

import SwiftUI
import SwiftJsonUI
import QuartzCore

/// The test renderer: a pale box with a blue fill rising to the bytes read.
@MainActor
final class FillBoxRenderer: NetworkImageLoadingRenderer {
    private let box = CALayer()
    private let fill = CALayer()
    private var observation: NetworkImageObservation?
    private weak var load: NetworkImageLoad?
    private var size: CGSize = .zero

    func attach(to layer: CALayer, load: NetworkImageLoad, size: CGSize, context: NetworkImageRendererContext) {
        self.load = load
        self.size = size
        box.backgroundColor = UIColor(white: 0.9, alpha: 1).cgColor
        fill.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.6).cgColor
        box.frame = CGRect(origin: .zero, size: size)
        box.addSublayer(fill)
        layer.addSublayer(box)
        // Rises in unless the load is long past its delay (a frame that joined).
        if context.elapsedSinceStart < 0.5 {
            let rise = CABasicAnimation(keyPath: "opacity")
            rise.fromValue = 0; rise.toValue = 1; rise.duration = 0.16
            box.add(rise, forKey: "rise")
        }
        level(load.displayLevel, animated: false)
        observation = load.observe { [weak self] event in
            guard let self, let load = self.load else { return }
            if case .progress(let received, let expected) = event, let expected, expected > 0 {
                let level = CGFloat(received) / CGFloat(expected)
                load.displayLevel = level
                self.level(level, animated: true)
            }
        }
    }

    private func level(_ level: CGFloat, animated: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        let h = size.height * max(0, min(1, level))
        fill.frame = CGRect(x: 0, y: size.height - h, width: size.width, height: h)
        CATransaction.commit()
    }

    func resize(to size: CGSize) {
        self.size = size
        box.frame = CGRect(origin: .zero, size: size)
        level(load?.displayLevel ?? 0, animated: false)
    }

    /// The box stays under the image until the fade ends and the renderer is
    /// taken off: faded out with the image, it let the ground show through.
    func finish(source: NetworkImageSource, transition: CFTimeInterval) {}

    func fail(transition: CFTimeInterval) {
        let out = CABasicAnimation(keyPath: "opacity")
        out.fromValue = 1; out.toValue = 0; out.duration = 0.16
        box.add(out, forKey: "out")
        box.opacity = 0
    }

    func detach() {
        observation?.cancel()
        observation = nil
        box.removeFromSuperlayer()
    }
}

struct NetworkImageRendererProbeView: View {
    let base: String
    @State private var states: [String] = []
    @State private var second = false
    @State private var started = false
    private let run = String(Int(Date().timeIntervalSince1970))

    init(base: String) {
        self.base = base
        NetworkImageLoadingRenderers.register("fillBox") { FillBoxRenderer() }
    }

    private func frame(_ id: String, _ path: String, label: String) -> some View {
        VStack(spacing: 2) {
            NetworkImage(url: "\(base)/\(path)", contentMode: .fill, loadingRenderer: "fillBox",
                         onLoadStateChange: { state in states.append("\(id):\(state)") })
                .frame(width: 110, height: 110)
                .clipped()
                .accessibilityLabel(Text("\(label) photo"))
                .accessibilityIdentifier(id)
            Text(label).font(.caption2)
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(second ? "second screen: memory cache" : "first screen").accessibilityIdentifier("nwr_ready")
            if !started {
                Button("load") { started = true }
                    .accessibilityIdentifier("nwr_start")
                    .frame(height: 230)
            } else if !second {
                LazyVGrid(columns: [GridItem(.fixed(110)), GridItem(.fixed(110)), GridItem(.fixed(110))], spacing: 10) {
                    frame("nwr_slow_a", "slow/a-\(run).png", label: "slow A")
                    frame("nwr_slow_a2", "slow/a-\(run).png", label: "slow A again")
                    frame("nwr_slow_b", "slow/b-\(run).png", label: "slow B")
                    frame("nwr_fast", "fast/c-\(run).png", label: "fast")
                    frame("nwr_fail", "fail/d-\(run).png", label: "fails")
                    frame("nwr_slow_e", "slower/e-\(run).png", label: "slower")
                }
            } else {
                LazyVGrid(columns: [GridItem(.fixed(110)), GridItem(.fixed(110)), GridItem(.fixed(110))], spacing: 10) {
                    frame("nwr_mem_a", "slow/a-\(run).png", label: "A (memory)")
                    frame("nwr_mem_b", "slow/b-\(run).png", label: "B (memory)")
                    frame("nwr_mem_fast", "fast/c-\(run).png", label: "fast (memory)")
                }
            }
            Button(second ? "back" : "next screen") { second.toggle() }
                .opacity(started ? 1 : 0)
                .accessibilityIdentifier("nwr_toggle")
            Text(states.joined(separator: " ")).font(.system(size: 9)).accessibilityIdentifier("nwr_states")
        }
        .padding()
    }
}
