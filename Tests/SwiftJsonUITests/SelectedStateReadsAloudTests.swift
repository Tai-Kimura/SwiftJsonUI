//
//  SelectedStateReadsAloudTests.swift
//  SwiftJsonUITests
//
//  A chosen Radio and a checked CheckBox read "selected" to a screen reader
//  (ticket sjui-radio-checkbox-selected-state-not-read). The state was only
//  the glyph's picture: the element carried its label and `.isButton`, the
//  same whether it was chosen or not. Not chosen adds nothing, as the
//  accessibilitySelected attribute's `false` does.
//
//  The walk is the one VoiceOver takes (ConformanceHost
//  A11yActivationProbeView's A11yActivator): the hosted view's accessibility
//  elements, found by label, and their traits.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class SelectedStateReadsAloudTests: XCTestCase {
    private var window: UIWindow?

    /// SwiftUI forms its accessibility tree only when something reads it
    /// (VoiceOver, XCUITest). A unit test is neither: switch automation
    /// accessibility on, as XCUITest does, so the hosted view answers.
    override class func setUp() {
        super.setUp()
        guard let lib = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW),
              let sym = dlsym(lib, "_AXSSetAutomationEnabled") else { return }
        typealias Set = @convention(c) (Int32) -> Void
        unsafeBitCast(sym, to: Set.self)(1)
    }

    override func tearDown() {
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    private func host<V: View>(_ view: V) -> UIView {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        self.window = window
        return host.view
    }

    private func dynamic(_ json: String, data: [String: Any] = [:]) throws -> UIView {
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        return host(DynamicComponentBuilder(component: component, data: data))
    }

    private func children(_ node: NSObject) -> [NSObject] {
        var out: [NSObject] = []
        if let elements = node.accessibilityElements {
            out += elements.compactMap { $0 as? NSObject }
        } else {
            let n = node.accessibilityElementCount()
            if n != NSNotFound && n > 0 {
                for i in 0..<n {
                    if let e = node.accessibilityElement(at: i) as? NSObject { out.append(e) }
                }
            }
        }
        if let view = node as? UIView { out += view.subviews }
        return out
    }

    /// The traits of the element a screen reader reaches by `label`; nil when
    /// no element carries it.
    private func traits(_ label: String, in root: UIView) -> UIAccessibilityTraits? {
        var queue: [NSObject] = [root]
        var seen = Set<ObjectIdentifier>()
        while !queue.isEmpty {
            let node = queue.removeFirst()
            guard seen.insert(ObjectIdentifier(node)).inserted else { continue }
            if node.isAccessibilityElement, node.accessibilityLabel == label {
                return node.accessibilityTraits
            }
            queue += children(node)
        }
        return nil
    }

    private func assertSelected(_ label: String, _ root: UIView, _ want: Bool, _ what: String,
                                file: StaticString = #filePath, line: UInt = #line) {
        guard let t = traits(label, in: root) else {
            return XCTFail("\(what): no element reads \"\(label)\"", file: file, line: line)
        }
        XCTAssertEqual(t.contains(.selected), want, "\(what): traits \(t.rawValue)", file: file, line: line)
    }

    // MARK: - CheckBox (CheckBoxView: the codegen's and the dynamic face's)

    func testACheckedBoxReadsSelectedAndAnUncheckedOneDoesNot() {
        let on = host(CheckBoxView(isOn: .constant(true), label: "Agree"))
        assertSelected("Agree", on, true, "CheckBoxView checked")
        XCTAssertTrue(traits("Agree", in: on)?.contains(.button) == true, "still a button")
        let off = host(CheckBoxView(isOn: .constant(false), label: "Agree"))
        assertSelected("Agree", off, false, "CheckBoxView unchecked")
        XCTAssertTrue(traits("Agree", in: off)?.contains(.button) == true, "still a button")
    }

    func testADynamicCheckBoxReadsItsCheckedState() throws {
        let on = try dynamic(#"{"type": "CheckBox", "id": "c", "label": "Agree", "isOn": true}"#)
        assertSelected("Agree", on, true, "dynamic CheckBox isOn true")
        let off = try dynamic(#"{"type": "CheckBox", "id": "c", "label": "Agree", "isOn": false}"#)
        assertSelected("Agree", off, false, "dynamic CheckBox isOn false")
    }

    // MARK: - Radio (dynamic)

    func testTheChosenSingleRadioReadsSelected() throws {
        let on = try dynamic(#"{"type": "Radio", "id": "r", "text": "One", "group": "g", "checked": true}"#)
        assertSelected("One", on, true, "single radio checked")
        let off = try dynamic(#"{"type": "Radio", "id": "r", "text": "One", "group": "g"}"#)
        assertSelected("One", off, false, "single radio not checked")
    }

    func testOnlyTheChosenOptionOfAGroupReadsSelected() throws {
        let root = try dynamic(#"{"type": "Radio", "id": "r", "items": ["Alpha", "Beta"], "selectedValue": "Beta"}"#)
        assertSelected("Beta", root, true, "chosen option")
        assertSelected("Alpha", root, false, "the other option")
    }
}
#endif
