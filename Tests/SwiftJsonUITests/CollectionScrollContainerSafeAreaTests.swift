//
//  CollectionScrollContainerSafeAreaTests.swift
//  SwiftJsonUITests
//
//  `contentInsetAdjustmentBehavior` and `keyboardAvoidance` on a Collection,
//  as sjui's SwiftUI codegen draws them (collection_converter.rb
//  apply_scroll_container_attrs, every route): `never` → `.ignoresSafeArea()`,
//  `scrollableAxes` → `.ignoresSafeArea(edges: .horizontal)`, any other value
//  → nothing; `keyboardAvoidance: false` → `.ignoresSafeArea(.keyboard)`, true
//  or absent → nothing. Dynamic read neither on a Collection (only its
//  ScrollView read the first).
//
//  Asserted on what the converter builds: the modifier values found in the
//  view it returns, compared with the values SwiftUI itself builds for the
//  three reference modifiers — no SwiftUI type name is written here.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class CollectionScrollContainerSafeAreaTests: XCTestCase {

    // MARK: - reading a built view

    /// Every value in `root`'s tree whose type is `modifierType`, as SwiftUI
    /// prints it (the printout carries the modifier's fields). Dictionaries
    /// and the component are not views and are skipped; classes are visited
    /// once.
    private func values(in root: Any, ofType modifierType: Any.Type) -> [String] {
        var found: [String] = []
        var visited = Set<ObjectIdentifier>()
        let wanted = ObjectIdentifier(modifierType)
        func walk(_ value: Any, _ depth: Int) {
            guard depth < 200 else { return }
            if value is DynamicComponent || value is [String: Any] { return }
            if type(of: value) is AnyClass {
                guard visited.insert(ObjectIdentifier(value as AnyObject)).inserted else { return }
            }
            if ObjectIdentifier(type(of: value)) == wanted {
                found.append(String(describing: value))
            }
            let mirror = Mirror(reflecting: value)
            for child in mirror.children { walk(child.value, depth + 1) }
            var superMirror = mirror.superclassMirror
            while let m = superMirror {
                for child in m.children { walk(child.value, depth + 1) }
                superMirror = m.superclassMirror
            }
        }
        walk(root, 0)
        return found
    }

    /// The modifier a one-modifier reference view carries: the value under
    /// the `modifier` label, found by walking the reference itself — so the
    /// modifier's type is whatever SwiftUI builds for it, not a name.
    private func modifierValue(of reference: AnyView) -> Any? {
        var result: Any?
        func walk(_ value: Any, _ depth: Int) {
            guard result == nil, depth < 20 else { return }
            let mirror = Mirror(reflecting: value)
            for child in mirror.children {
                if child.label == "modifier" { result = child.value; return }
                walk(child.value, depth + 1)
            }
        }
        walk(reference, 0)
        return result
    }

    private let referenceViews: [String: AnyView] = [
        "all": AnyView(Color.clear.ignoresSafeArea()),
        "horizontal": AnyView(Color.clear.ignoresSafeArea(edges: .horizontal)),
        "keyboard": AnyView(Color.clear.ignoresSafeArea(.keyboard)),
    ]

    /// The type SwiftUI builds for `.ignoresSafeArea(...)`, and the three
    /// printouts the arms expect.
    private var safeAreaType: Any.Type {
        type(of: modifierValue(of: referenceViews["all"]!)!)
    }
    private func reference(_ key: String) -> String {
        let found = values(in: referenceViews[key]!, ofType: safeAreaType)
        XCTAssertEqual(found.count, 1, "reference \(key): \(found)")
        return found.first ?? "<none>"
    }
    private var ignoresAll: String { reference("all") }
    private var ignoresHorizontal: String { reference("horizontal") }
    private var ignoresKeyboard: String { reference("keyboard") }

    private func safeAreaModifiers(in root: Any) -> [String] {
        values(in: root, ofType: safeAreaType)
    }

    /// The three references are one modifier type with three different
    /// values, or the arms below could not tell them apart.
    func testTheReferencesAreDistinct() {
        for key in referenceViews.keys {
            XCTAssertEqual(ObjectIdentifier(type(of: modifierValue(of: referenceViews[key]!)!)),
                           ObjectIdentifier(safeAreaType), key)
        }
        XCTAssertEqual(Set([ignoresAll, ignoresHorizontal, ignoresKeyboard]).count, 3)
    }

    // MARK: - converting

    /// Routes a Collection can take; each draws cells from a data source.
    /// A wrapping flow is built twice — for under a scrolling ancestor and
    /// for not — and the environment picks one (ScrollingAncestorSwitch), so
    /// its modifiers are found twice.
    private let routes: [(String, String)] = [
        ("sections", ", \"sections\": [{\"cell\": \"c\"}]"),
        ("sections + listStyle", ", \"sections\": [{\"cell\": \"c\"}], \"listStyle\": \"grouped\""),
        ("legacy List", ", \"cellClasses\": [\"c\"]"),
        ("horizontal", ", \"sections\": [{\"cell\": \"c\"}], \"layout\": \"horizontal\""),
        ("paging", ", \"sections\": [{\"cell\": \"c\"}], \"layout\": \"horizontal\", \"paging\": true"),
        ("grid", ", \"sections\": [{\"cell\": \"c\"}], \"columns\": 2"),
        ("flow", ", \"sections\": [{\"cell\": \"c\"}], \"layout\": \"flow\", \"height\": 200"),
        ("flow under a scrolling ancestor", ", \"sections\": [{\"cell\": \"c\"}], \"layout\": \"flow\""),
        ("lazy none", ", \"sections\": [{\"cell\": \"c\"}], \"lazy\": \"none\""),
        ("no data source", ""),
    ]

    private func renders(_ name: String) -> Int {
        name == "flow under a scrolling ancestor" ? 2 : 1
    }

    private func converted(_ attrs: String, route: String) throws -> [String] {
        let items = route.isEmpty ? "" : ", \"items\": \"@{items}\""
        let json = "{\"type\": \"Collection\", \"id\": \"k\"\(items)\(route)\(attrs)}"
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        let source = CollectionDataSource(sections: [
            CollectionDataSection(cells: (viewName: "c", data: [["t": "a"]]))
        ])
        return safeAreaModifiers(in: CollectionConverter.convert(component: component, data: ["items": source]))
    }

    func testNeverIgnoresTheSafeAreaOnEveryRoute() throws {
        let expected = ignoresAll
        for (name, route) in routes {
            XCTAssertEqual(try converted(", \"contentInsetAdjustmentBehavior\": \"never\"", route: route),
                           Array(repeating: expected, count: renders(name)), name)
        }
    }

    func testScrollableAxesIgnoresTheHorizontalSafeAreaOnEveryRoute() throws {
        let expected = ignoresHorizontal
        for (name, route) in routes {
            XCTAssertEqual(try converted(", \"contentInsetAdjustmentBehavior\": \"scrollableAxes\"", route: route),
                           Array(repeating: expected, count: renders(name)), name)
        }
    }

    /// The system behaviour: nothing is applied.
    func testTheOtherBehavioursApplyNothing() throws {
        for value in ["always", "automatic"] {
            for (name, route) in routes {
                XCTAssertEqual(try converted(", \"contentInsetAdjustmentBehavior\": \"\(value)\"", route: route),
                               [], "\(value) / \(name)")
            }
        }
        for (name, route) in routes {
            XCTAssertEqual(try converted("", route: route), [], "undeclared / \(name)")
        }
    }

    func testKeyboardAvoidanceFalseIgnoresTheKeyboardOnEveryRoute() throws {
        let expected = ignoresKeyboard
        for (name, route) in routes {
            XCTAssertEqual(try converted(", \"keyboardAvoidance\": false", route: route),
                           Array(repeating: expected, count: renders(name)), name)
        }
    }

    func testKeyboardAvoidanceTrueAppliesNothing() throws {
        for (name, route) in routes {
            XCTAssertEqual(try converted(", \"keyboardAvoidance\": true", route: route), [], name)
        }
    }

    /// Both declared: the codegen's order, the behaviour first (inner).
    func testBothAreAppliedBehaviourFirst() throws {
        let found = try converted(
            ", \"contentInsetAdjustmentBehavior\": \"never\", \"keyboardAvoidance\": false",
            route: routes[0].1
        )
        // A modified view's content is visited before its modifier, so the
        // walk meets the inner modifier first.
        XCTAssertEqual(found, [ignoresAll, ignoresKeyboard])
    }
}
#endif
