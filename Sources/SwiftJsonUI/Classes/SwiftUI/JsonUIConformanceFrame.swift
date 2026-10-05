//
//  JsonUIConformanceFrame.swift
//  SwiftJsonUI
//
//  A measuring element over each id's layout box, for the conformance
//  frame-parity gate only.
//
//  XCUIElement.frame is the extent of what was drawn as accessibility
//  elements, not a view's layout box. Measured on ConformanceHost
//  (iOS 26.5, 2026-10-05), on a 200 x 200 View at the canvas top holding
//  one 40 x 40 child:
//    - with a background, the frame was (0, −62, 200 × 262): the background
//      paints into the top safe area;
//    - with none, (0, 0, 40 × 40): the union of the children;
//    - clipped, (0, 0, 200 × 200), and the child read 200 × 200 too;
//    - 10 below the top, (0, 10, 200 × 200).
//  So the gate cannot read the layout box from the element the id is on.
//
//  Each id hands its bounds up as an anchor preference, at its place in the
//  chain: inside the offset and the margins, the same box Android's
//  testTag tags. The host draws one clear element per anchor, named
//  `frame:<id>`, at its own top level (`jsonUIConformanceFrames()`). The
//  elements are not drawn inside the view: there the view's own
//  accessibilityIdentifier took them over (a leaf's identifier goes to every
//  element inside it), and a tap's `.combine` merged them away, 20 of the 178
//  common fixtures on 2026-10-05. They are drawn behind the content, not over
//  it: over it, the accessibility hit test found them first, every tapped
//  element read hittable = false, and a Button's tap did not fire.
//
//  Nothing is handed up unless the host sets `jsonuiConformanceFrameProbe`.
//  In an app the modifier reads the environment and returns its content
//  unchanged.
//

import SwiftUI

private struct JsonUIConformanceFrameProbeKey: EnvironmentKey {
    static var defaultValue: Bool { false }
}

public extension EnvironmentValues {
    /// Set by a conformance host to measure each id's layout box
    /// (see `jsonUIConformanceFrame(_:)`). False everywhere else.
    var jsonuiConformanceFrameProbe: Bool {
        get { self[JsonUIConformanceFrameProbeKey.self] }
        set { self[JsonUIConformanceFrameProbeKey.self] = newValue }
    }
}

/// The identifier prefix of the measuring element. The frames reader asks
/// for `frame:<id>` first.
public let jsonUIConformanceFramePrefix = "frame:"

struct JsonUIConformanceFrameAnchor {
    let id: String
    let bounds: Anchor<CGRect>
}

struct JsonUIConformanceFrameKey: PreferenceKey {
    static var defaultValue: [JsonUIConformanceFrameAnchor] { [] }
    static func reduce(value: inout [JsonUIConformanceFrameAnchor],
                       nextValue: () -> [JsonUIConformanceFrameAnchor]) {
        value.append(contentsOf: nextValue())
    }
}

struct JsonUIConformanceFrameModifier: ViewModifier {
    let id: String
    @Environment(\.jsonuiConformanceFrameProbe) private var probe

    func body(content: Content) -> some View {
        if probe {
            // transform, not set: the ids inside this view keep theirs.
            content.transformAnchorPreference(key: JsonUIConformanceFrameKey.self, value: .bounds) {
                $0.append(JsonUIConformanceFrameAnchor(id: id, bounds: $1))
            }
        } else {
            content
        }
    }
}

public extension View {
    /// Hands this view's layout box up as `frame:<id>`, only while
    /// `jsonuiConformanceFrameProbe` is set (a conformance host).
    /// sjui codegen emits it at the same place in the chain as Dynamic's
    /// `conformanceFrame` stage (modifier_order.json `conformance_frame`).
    func jsonUIConformanceFrame(_ id: String?) -> some View {
        Group {
            if let id, !id.isEmpty {
                self.modifier(JsonUIConformanceFrameModifier(id: id))
            } else {
                self
            }
        }
    }

    /// For a conformance host: draws a clear, untappable element named
    /// `frame:<id>` at the layout box of every id inside this view that
    /// handed one up, behind the content. Nothing is handed up unless the
    /// host also sets `jsonuiConformanceFrameProbe`.
    func jsonUIConformanceFrames() -> some View {
        backgroundPreferenceValue(JsonUIConformanceFrameKey.self) { anchors in
            GeometryReader { proxy in
                ForEach(anchors.indices, id: \.self) { i in
                    let box = proxy[anchors[i].bounds]
                    SwiftUI.Color.clear
                        .frame(width: box.width, height: box.height)
                        .accessibilityElement(children: .ignore)
                        .accessibilityIdentifier(jsonUIConformanceFramePrefix + anchors[i].id)
                        .position(x: box.midX, y: box.midY)
                }
            }
            .allowsHitTesting(false)
        }
    }
}
