//
//  ScrollWrapKeyboardProbeView.swift
//  ConformanceHost
//
//  Launched with `-scrollWrapKeyboardProbe wrap|match`: a Dynamic vertical
//  ScrollView of height wrapContent (or matchParent, the control) filling a
//  matchParent View — a form sheet's shape — whose content is a 500pt block
//  and a text field (`swk_field`) under it, so the keyboard covers the field
//  until the scroll brings it up. ScrollWrapKeyboardProbeUITests reads where
//  the focused field settles against the keyboard: a wrapContent ScrollView
//  is framed at its content's height (jsonui-cli ticket
//  sjui-vertical-scrollview-wrapcontent-height-is-10pt) and must still keep
//  the field above the keyboard as the matchParent one does.
//

import SwiftUI
import SwiftJsonUI

#if DEBUG

struct ScrollWrapKeyboardProbeView: View {
    let height: String

    var layout: String {
        ##"{"type": "View", "id": "swk_root", "orientation": "vertical", "width": "matchParent", "height": "matchParent", "child": [{"type": "ScrollView", "id": "swk_scroll", "width": "matchParent", "height": "\##(height)", "child": [{"type": "View", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "View", "id": "swk_block", "width": "matchParent", "height": 500, "background": "#DDDDDD"}, {"type": "TextField", "id": "swk_field", "width": "matchParent", "height": 44, "hint": "field", "background": "#EEEEEE"}]}]}]}"##
    }

    var body: some View {
        if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(layout.utf8)) {
            DynamicComponentBuilder(component: component, data: [:])
        } else {
            Text("did not decode").accessibilityIdentifier("swk_decode_failed")
        }
    }
}
#endif
