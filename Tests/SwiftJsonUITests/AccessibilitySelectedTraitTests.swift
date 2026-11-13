//
//  AccessibilitySelectedTraitTests.swift
//  SwiftJsonUITests
//
//  accessibilitySelected as VoiceOver is handed it: a Dynamic layout drawn in
//  a window, its accessibility elements walked as the screen reader walks
//  them (UIAccessibilityContainer), and each one's traits read. A Button, a
//  tappable View and a tappable IconLabel bound to `isMust` carry `.selected`
//  — which VoiceOver speaks as "Selected" — while it is true, and nothing when
//  it is false; a View that taps nothing is never told.
//

import XCTest
import SwiftUI
import UIKit
@testable import SwiftJsonUI

#if DEBUG
final class AccessibilitySelectedTraitTests: XCTestCase {

    /// SwiftUI builds its accessibility elements only while an assistive technology is attached: turn the
    /// automation switch on (libAccessibility's _AXSSetAutomationEnabled, as accessibility snapshot tools do).
    override class func setUp() {
        super.setUp()
        guard let handle = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW),
              let symbol = dlsym(handle, "_AXSSetAutomationEnabled") else { return }
        typealias SetEnabled = @convention(c) (Int32) -> Void
        unsafeBitCast(symbol, to: SetEnabled.self)(1)
    }

    private let layout: [String: Any] = [
        "type": "View", "id": "root", "orientation": "vertical",
        "child": [
            ["type": "Button", "id": "must", "text": "Must", "onClick": "@{onTap}", "accessibilitySelected": "@{isMust}"],
            ["type": "View", "id": "maybe", "onClick": "@{onTap}", "accessibilitySelected": "@{isMust}",
             "child": [["type": "Label", "id": "maybe_label", "text": "Maybe"]]],
            ["type": "IconLabel", "id": "icon", "text": "Icon", "onClick": "@{onTap}", "accessibilitySelected": "@{isMust}"],
            ["type": "View", "id": "still", "accessibilitySelected": true,
             "child": [["type": "Label", "id": "still_label", "text": "Still"]]],
        ],
    ]

    /// Every accessibility element under `node`, as VoiceOver walks them.
    private func elements(_ node: NSObject) -> [NSObject] {
        var out: [NSObject] = []
        if node.isAccessibilityElement { out.append(node) }
        let children: [Any]
        if let list = node.accessibilityElements {
            children = list
        } else {
            let count = node.accessibilityElementCount()
            children = count == NSNotFound || count <= 0 ? [] : (0..<count).compactMap { node.accessibilityElement(at: $0) }
        }
        // A UIKit control a SwiftUI view hosts (a TextField's UITextField) sits in the view tree, not in the
        // SwiftUI node list: walk the subviews too.
        if let view = node as? UIView {
            for sub in view.subviews { out += elements(sub) }
        }
        for child in children { if let c = child as? NSObject { out += elements(c) } }
        return out
    }

    /// The labels of the elements carrying `.selected`, with `isMust` as given.
    private func selectedLabels(isMust: Bool) throws -> Set<String> {
        let all = try drawnElements(layout, data: ["isMust": isMust, "onTap": { () -> Void in }])
        return Set(all.filter { $0.accessibilityTraits.contains(.selected) }.map { $0.accessibilityLabel ?? "" })
    }

    /// The accessibility elements of `json` drawn by Dynamic in a window.
    private func drawnElements(_ json: [String: Any], data: [String: Any]) throws -> [NSObject] {
        let component = try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: json))
        let host = UIHostingController(rootView: DynamicComponentBuilder(component: component, data: data))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 600))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        defer { window.isHidden = true }
        let all = elements(host.view)
        XCTAssertFalse(all.isEmpty, "no accessibility element was found")
        return all
    }

    /// A Dynamic Button ran a hand-built chain without the controlAccessibility stage, so its accessibilityLabel
    /// never reached VoiceOver either (the same family, found by the selected arm). TextField's hand-built chain
    /// takes the same stage; its UIKit field is not in the node list this walk reads, so it is not measured here.
    func testAButtonIsNamedByItsAccessibilityLabel() throws {
        let named: [String: Any] = [
            "type": "View", "id": "root", "orientation": "vertical",
            "child": [["type": "Button", "id": "b", "text": "Open", "onClick": "@{onTap}", "accessibilityLabel": "Open the second image"]],
        ]
        let labels = Set(try drawnElements(named, data: ["onTap": { () -> Void in }]).compactMap { $0.accessibilityLabel })
        XCTAssertTrue(labels.contains("Open the second image"), "\(labels)")
        XCTAssertFalse(labels.contains("Open"), "\(labels)")
    }

    func testSelectedFollowsTheBindingOnEveryOneButtonNode() throws {
        XCTAssertEqual(try selectedLabels(isMust: true), ["Must", "Maybe", "Icon"])
        XCTAssertEqual(try selectedLabels(isMust: false), [])
    }
}
#endif
