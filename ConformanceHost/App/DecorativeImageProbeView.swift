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
      {"type": "Image", "id": "dyn_empty_alt", "srcName": "conformance_sample", "width": 40, "height": 40, "alt": ""},
      {"type": "View", "orientation": "horizontal", "child": [
        {"type": "View", "id": "dyn_wrap_deco", "child": [
          {"type": "Image", "srcName": "conformance_sample", "width": 24, "height": 24}
        ]},
        {"type": "View", "id": "dyn_wrap_text", "orientation": "horizontal", "child": [
          {"type": "Label", "text": "caption"},
          {"type": "Image", "srcName": "conformance_sample", "width": 24, "height": 24}
        ]},
        {"type": "Label", "id": "dyn_text", "text": "caption"},
        {"type": "View", "id": "dyn_tap_wrap", "onClick": "@{onProbe}", "child": [
          {"type": "Label", "text": "open"}
        ]}
      ]},
      {"type": "View", "orientation": "horizontal", "child": [
        {"type": "View", "id": "dyn_wrap_one_text", "child": [{"type": "Label", "text": "caption"}]},
        {"type": "View", "id": "dyn_wrap_two_text", "orientation": "vertical", "child": [
          {"type": "Label", "text": "first"}, {"type": "Label", "text": "second"}
        ]},
        {"type": "View", "id": "dyn_wrap_labelled", "child": [
          {"type": "Image", "srcName": "conformance_sample", "width": 24, "height": 24, "alt": "Sample"}
        ]}
      ]}
    ]}
    """)

    /// What `jui build` emits for the same four shapes, pasted as sjui_tools
    /// (jsonui-cli b295ce24) wrote it, with the image-role and tap-shape
    /// passes it runs first — an id on a container makes it an accessibility
    /// container (`.contain`, with the 0.5 pt anchor when it could collapse
    /// into one child); a Label keeps its own element; a tappable holding
    /// only text is combined into one button.
    private var codegenShapes: some View {
        HStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                Group {
                    Image("conformance_sample")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .accessibilityHidden(true)
                        .frame(width: 24, height: 24)
                }
            }
                .overlay(alignment: .topLeading) {
                    Color.clear
                        .frame(width: 0.5, height: 0.5)
                        .accessibilityElement(children: .ignore)
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("cg_wrap_deco")
            HStack(alignment: .top, spacing: 0) {
                    PartialAttributedText(
                        "caption".localized(),
                        textAlignment: .leading
                    )
                    Image("conformance_sample")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .accessibilityHidden(true)
                        .frame(width: 24, height: 24)
            }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("cg_wrap_text")
            PartialAttributedText(
                "caption".localized(),
                textAlignment: .leading
            )
                .accessibilityIdentifier("cg_text")
            ZStack(alignment: .topLeading) {
                Group {
                    PartialAttributedText(
                        "open".localized(),
                        textAlignment: .leading
                    )
                }
            }
                .contentShape(Rectangle())
                .onTapGesture {
                }
                .overlay(alignment: .topLeading) {
                    Color.clear
                        .frame(width: 0.5, height: 0.5)
                        .accessibilityElement(children: .ignore)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("cg_tap_wrap")
        }
    }

    /// Containers whose centre lands on an element of their own: one text,
    /// two texts, an image with an alt — emitted the same way.
    private var codegenContainersOverElements: some View {
        HStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                Group {
                    PartialAttributedText(
                        "caption".localized(),
                        textAlignment: .leading
                    )
                }
            }
                .overlay(alignment: .topLeading) {
                    Color.clear
                        .frame(width: 0.5, height: 0.5)
                        .accessibilityElement(children: .ignore)
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("cg_wrap_one_text")
            VStack(alignment: .leading, spacing: 0) {
                    PartialAttributedText(
                        "first".localized(),
                        textAlignment: .leading
                    )
                    PartialAttributedText(
                        "second".localized(),
                        textAlignment: .leading
                    )
            }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("cg_wrap_two_text")
            ZStack(alignment: .topLeading) {
                Group {
                    Image("conformance_sample")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .accessibilityLabel(Text("Sample"))
                        .frame(width: 24, height: 24)
                }
            }
                .overlay(alignment: .topLeading) {
                    Color.clear
                        .frame(width: 0.5, height: 0.5)
                        .accessibilityElement(children: .ignore)
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("cg_wrap_labelled")
        }
    }

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
            codegenShapes
            codegenContainersOverElements
            if let dynamic = Self.dynamicLayout {
                DynamicComponentBuilder(component: dynamic, data: ["onProbe": { () -> Void in }])
            } else {
                Text("dynamic layout did not decode").accessibilityIdentifier("deco_probe_decode_failed")
            }
        }
    }
}
