//
//  ImageEventsProbeView.swift
//  ConformanceHost
//
//  Which events reach an Image and a NetworkImage rendered by the Dynamic
//  runtime. NOT part of the conformance suite. Launch with
//  `-imageEventsProbe`.
//
//  Each handler counts its calls into a label the UI test reads, so a tap
//  that reaches nothing reads 0 rather than failing to find an element. The
//  NetworkImage loads a data: URL: an unreachable one draws the error face,
//  whose Refresh button takes the tap instead of the image.
//

import SwiftUI
import SwiftJsonUI

final class ImageEventsProbeCounts: ObservableObject {
    @Published var counts: [String: Int] = [:]

    func bump(_ name: String) { counts[name, default: 0] += 1 }
}

struct ImageEventsProbeView: View {
    @StateObject private var probe = ImageEventsProbeCounts()

    static let names = [
        "ni_tap", "ni_gated", "ni_long", "ni_appear",
        "img_tap", "img_selector", "img_edge", "img_long", "img_appear",
    ]

    /// A 1x1 PNG.
    private static let pixel = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="

    private static let component: DynamicComponent? = try? JSONDecoder().decode(DynamicComponent.self, from: Data("""
    {"type": "View", "orientation": "vertical", "child": [
      {"type": "NetworkImage", "id": "ni_tap", "url": "\(pixel)", "width": 60, "height": 40, "onClick": "@{on_ni_tap}"},
      {"type": "NetworkImage", "id": "ni_gated", "url": "\(pixel)", "width": 60, "height": 40, "onClick": "@{on_ni_gated}", "canTap": false},
      {"type": "NetworkImage", "id": "ni_long", "url": "\(pixel)", "width": 60, "height": 40, "onLongPress": "@{on_ni_long}"},
      {"type": "NetworkImage", "id": "ni_appear", "url": "\(pixel)", "width": 60, "height": 40, "onAppear": "on_ni_appear"},
      {"type": "Image", "id": "img_tap", "srcName": "conformance_sample", "width": 40, "height": 40, "onClick": "@{on_img_tap}"},
      {"type": "Image", "id": "img_selector", "srcName": "conformance_sample", "width": 40, "height": 40, "onclick": "on_img_selector"},
      {"type": "View", "id": "img_edge_box", "width": 160, "height": 40, "child": [
        {"type": "Image", "id": "img_edge", "srcName": "conformance_sample", "width": 160, "height": 40, "contentMode": "AspectFit", "onClick": "@{on_img_edge}"}
      ]},
      {"type": "Image", "id": "img_long", "srcName": "conformance_sample", "width": 40, "height": 40, "onLongPress": "@{on_img_long}"},
      {"type": "Image", "id": "img_appear", "srcName": "conformance_sample", "width": 40, "height": 40, "onAppear": "on_img_appear"}
    ]}
    """.utf8))

    private var data: [String: Any] {
        var out: [String: Any] = [:]
        for name in Self.names {
            let probe = probe
            out["on_\(name)"] = { () -> Void in probe.bump(name) }
        }
        return out
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("image events probe").accessibilityIdentifier("image_events_ready")
            HStack(spacing: 4) {
                ForEach(Self.names, id: \.self) { name in
                    Text("\(probe.counts[name, default: 0])")
                        .font(.caption2)
                        .accessibilityIdentifier("count_\(name)")
                }
            }
            if let component = Self.component {
                DynamicComponentBuilder(component: component, data: data)
            } else {
                Text("layout did not decode").accessibilityIdentifier("image_events_decode_failed")
            }
        }
    }
}
