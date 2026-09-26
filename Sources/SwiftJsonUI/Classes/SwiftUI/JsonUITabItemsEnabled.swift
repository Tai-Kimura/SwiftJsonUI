//
//  JsonUITabItemsEnabled.swift
//  SwiftJsonUI
//
//  A TabView's `enabled` stops its tab items, not the tab view (4f's ruling,
//  jsonui-cli 1.9.0 — the Compose form, NavigationBarItem's `enabled`, and
//  web's, each tab's `<button disabled>`). The tab view's control is its row
//  of tabs; what a tab shows is a layout of its own, which a user who means
//  to stop it stops with `userInteractionEnabled`. SwiftUI's `.disabled` on
//  the TabView stopped the tabs and disabled every control in the tab shown
//  as well (measured, ConformanceHost `-tabEnabledProbe`, iOS 26.5: a Button
//  in the first tab read disabled and did not call).
//
//  SwiftUI has no modifier for a `.tabItem`'s enabled state before iOS 18.4
//  (`TabContent.disabled`, the `Tab` API), and a selection binding that
//  drops the change let the tab bar move while the selection did not (the
//  second tab drawn, the selection still the first — measured). The tab bar
//  is UIKit's: this sets its items' `isEnabled`, from a view placed in each
//  tab's content — the one on screen finds the tab bar controller above it.
//  A tap on a stopped tab does nothing, and VoiceOver's activation, which
//  returns false and sends a touch, does nothing either (measured); the
//  shown tab's controls still work. A tab item still reads as enabled to a
//  screen reader: the iOS 26.5 tab buttons read the same with the items'
//  `isEnabled` false, with their accessibility traits set, and with the
//  whole TabView `.disabled` (measured, each).
//

import SwiftUI
import UIKit

public extension View {
    /// Sets the `isEnabled` of the tab bar items of the TabView this view is
    /// a tab's content of. Placed on every tab's content: only the one on
    /// screen is in the window.
    func jsonuiTabItemsEnabled(_ enabled: Bool) -> some View {
        background(JsonUITabItemsEnabler(enabled: enabled))
    }
}

struct JsonUITabItemsEnabler: UIViewRepresentable {
    let enabled: Bool

    func makeUIView(context: Context) -> Finder {
        let view = Finder()
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = false
        return view
    }

    func updateUIView(_ view: Finder, context: Context) {
        view.enabled = enabled
        view.apply()
    }

    final class Finder: UIView {
        var enabled = true

        override func didMoveToWindow() {
            super.didMoveToWindow()
            apply()
        }

        /// After the pass that placed the view: the tab bar controller is
        /// above it in the responder chain once it is in the window.
        func apply() {
            DispatchQueue.main.async { [weak self] in
                guard let self, self.window != nil else { return }
                var responder: UIResponder? = self
                while let current = responder {
                    if let controller = current as? UITabBarController {
                        controller.tabBar.items?.forEach { $0.isEnabled = self.enabled }
                        return
                    }
                    responder = current.next
                }
            }
        }
    }
}
