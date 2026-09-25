//
//  DecorativeImageProbeView.swift
//  ConformanceHost
//
//  What the iOS driver can still find once an image is made decorative for
//  VoiceOver. NOT part of the conformance suite. Launch with
//  `-decorativeImageProbe`.
//
//  The driver finds an element by accessibilityIdentifier through the same
//  accessibility tree VoiceOver reads (AssertionExecutor:
//  `descendants(matching: .any).matching(identifier:)`), so a decoration
//  taken out of that tree may also be taken away from the test that asserts
//  it is on screen. Each spelling of "decorative" sits here beside the plain
//  image it would replace, and the dynamic path renders the rule itself.
//

import SwiftUI
import SwiftJsonUI

struct DecorativeImageProbeView: View {
    private static func component(_ json: String) -> DynamicComponent? {
        try? JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }

    /// Rendered through this branch's DynamicComponentBuilder, so the roles
    /// come from ImageAccessibility: no alt and no tappable is decorative, the
    /// only image of a tappable with no text is a control, an alt is a label.
    private static let dynamicLayout = component("""
    {"type": "View", "orientation": "vertical", "child": [
      {"type": "Image", "id": "dyn_decorative", "srcName": "conformance_sample", "width": 40, "height": 40},
      {"type": "View", "onClick": "@{onProbe}", "child": [
        {"type": "Image", "id": "dyn_control", "srcName": "conformance_sample", "width": 40, "height": 40}
      ]},
      {"type": "Image", "id": "dyn_labelled", "srcName": "conformance_sample", "width": 40, "height": 40, "alt": "Sample"},
      {"type": "Image", "id": "dyn_empty_alt", "srcName": "conformance_sample", "width": 40, "height": 40, "alt": ""}
    ]}
    """)

    var body: some View {
        VStack(spacing: 8) {
            Text("decorative image probe").accessibilityIdentifier("deco_probe_ready")
            Image(systemName: "star.fill").resizable().frame(width: 40, height: 40)
                .accessibilityIdentifier("img_plain")
            Image(systemName: "star.fill").resizable().frame(width: 40, height: 40)
                .accessibilityHidden(true)
                .accessibilityIdentifier("img_hidden")
            Image(systemName: "star.fill").resizable().frame(width: 40, height: 40)
                .accessibilityLabel(Text(""))
                .accessibilityIdentifier("img_empty_label")
            Image(systemName: "star.fill").resizable().frame(width: 40, height: 40)
                .accessibilityLabel(Text("Star"))
                .accessibilityIdentifier("img_labelled")
            // The `hidden` attribute's mechanism (VisibilityWrapper .invisible):
            // not drawn, keeps its space, out of VoiceOver.
            Text("hidden by the attribute")
                .opacity(0)
                .accessibilityElement(children: .ignore)
                .accessibilityHidden(true)
                .accessibilityIdentifier("hidden_attr")
            if let dynamic = Self.dynamicLayout {
                DynamicComponentBuilder(component: dynamic, data: ["onProbe": { () -> Void in }])
            } else {
                Text("dynamic layout did not decode").accessibilityIdentifier("deco_probe_decode_failed")
            }
        }
    }
}
