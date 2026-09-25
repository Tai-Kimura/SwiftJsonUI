//
//  TapIdentifierOnceView.swift
//  ConformanceHost
//
//  Every identifier inside a tap that TapAccessibility combines into one
//  button is found exactly once. NOT part of the conformance suite; launch
//  with `-tapIdentifierOnce`. Its test (TapIdentifierOnceUITests) is NOT
//  opt-in: it runs wherever this host's UI tests run.
//
//  An id-less combined tap took its children's identifiers as its own
//  (XCUITest, iOS 26.5 and 18.6, 2026-09-25): with one child, that child's id
//  was found twice — on the button and on the child — and two children's
//  were joined ("a-b") on the button. A driver that finds by identifier and
//  counts matches read two where the layout has one.
//
//  Each shape sits in a `.contain` wrapper of its own so the test can count
//  the buttons inside it. `dup` is the instrument's positive control: the
//  same id on two plain views, which must count 2.
//

import SwiftUI
import SwiftJsonUI

struct TapIdentifierOnceView: View {
    /// (wrapper id, layout). The ids a shape declares are what the test counts.
    static let shapes: [(String, String)] = [
        ("wrap_one_label", #"{"type": "View", "onClick": "@{onTap}", "child": [{"type": "Label", "id": "tio_one_label", "text": "One label"}]}"#),
        ("wrap_one_image", #"{"type": "View", "onClick": "@{onTap}", "child": [{"type": "Image", "id": "tio_one_image", "srcName": "conformance_sample", "width": 40, "height": 40}]}"#),
        ("wrap_one_plain", #"{"type": "View", "onClick": "@{onTap}", "child": [{"type": "Label", "text": "One plain"}]}"#),
        ("wrap_two", #"{"type": "View", "onClick": "@{onTap}", "child": [{"type": "Label", "id": "tio_two_a", "text": "Two a"}, {"type": "Label", "id": "tio_two_b", "text": "Two b"}]}"#),
        ("wrap_own_one", #"{"type": "View", "id": "tio_own_one", "onClick": "@{onTap}", "child": [{"type": "Label", "id": "tio_own_one_label", "text": "Own one"}]}"#),
        ("wrap_own_image", #"{"type": "View", "id": "tio_own_image", "onClick": "@{onTap}", "child": [{"type": "Image", "id": "tio_own_image_child", "srcName": "conformance_sample", "width": 40, "height": 40}]}"#),
        ("wrap_own_plain", #"{"type": "View", "id": "tio_own_plain", "onClick": "@{onTap}", "child": [{"type": "Label", "text": "Own plain"}]}"#),
        ("wrap_own_two", #"{"type": "View", "id": "tio_own_two", "onClick": "@{onTap}", "child": [{"type": "Label", "id": "tio_own_two_a", "text": "Own two a"}, {"type": "Label", "id": "tio_own_two_b", "text": "Own two b"}]}"#),
    ]

    private static func component(_ json: String) -> DynamicComponent? {
        try? JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                Text("tap identifier probe").accessibilityIdentifier("tio_ready")
                ForEach(Self.shapes, id: \.0) { shape in
                    Group {
                        if let component = Self.component(shape.1) {
                            DynamicComponentBuilder(component: component, data: ["onTap": { () -> Void in }])
                        } else {
                            Text("did not decode").accessibilityIdentifier("tio_decode_failed")
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(shape.0)
                }
                // The positive control: two elements, one id.
                Text("dup one").accessibilityIdentifier("tio_dup")
                Text("dup two").accessibilityIdentifier("tio_dup")
            }
            .padding(.horizontal)
        }
    }
}
