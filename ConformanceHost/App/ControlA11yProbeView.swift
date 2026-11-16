//
//  ControlA11yProbeView.swift
//  ConformanceHost
//
//  What VoiceOver reads off Dynamic controls (jsonui-cli tickets
//  jui-view-accessibility-selected-state-missing,
//  sjui-dynamic-button-textfield-skip-control-accessibility): a Button and a
//  TextField named by their accessibilityLabel, and a Button, a tappable View
//  and a tappable IconLabel told selected by accessibilitySelected — while the
//  bound value is true, and not once the "toggle" button sets it false.
//  ControlA11yProbeUITests reads XCUIElement.label and .isSelected. NOT part of
//  the conformance suite; launch with `-controlA11yProbe`.
//
import SwiftUI
import SwiftJsonUI

#if DEBUG
struct ControlA11yProbeView: View {
    @State private var isMust = true
    @State private var query = ""

    static let layout = ##"{"type": "View", "id": "ca_root", "width": "matchParent", "height": "wrapContent", "orientation": "vertical", "child": [{"type": "Button", "id": "ca_named", "width": 240, "height": 44, "text": "Open", "onClick": "@{onTap}", "accessibilityLabel": "Open the second image"}, {"type": "TextField", "id": "ca_field", "width": 240, "height": 44, "text": "@{query}", "hint": "Search", "accessibilityLabel": "Search the catalog"}, {"type": "Button", "id": "ca_must", "width": 240, "height": 44, "text": "Must", "onClick": "@{onTap}", "accessibilitySelected": "@{isMust}"}, {"type": "View", "id": "ca_maybe", "width": 240, "height": 44, "onClick": "@{onTap}", "accessibilitySelected": "@{isMust}", "child": [{"type": "Label", "text": "Maybe"}]}, {"type": "IconLabel", "id": "ca_icon", "width": 240, "height": 44, "text": "Icon", "onClick": "@{onTap}", "accessibilitySelected": "@{isMust}"}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("control a11y probe").accessibilityIdentifier("ca_ready")
            Button("toggle") { isMust.toggle() }.accessibilityIdentifier("ca_toggle")
            if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [
                    "isMust": isMust,
                    "query": $query,
                    "onTap": { () -> Void in },
                ])
            } else {
                Text("did not decode").accessibilityIdentifier("ca_decode_failed")
            }
        }
    }
}
#endif
