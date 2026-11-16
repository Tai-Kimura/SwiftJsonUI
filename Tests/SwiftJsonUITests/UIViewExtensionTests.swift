//
//  UIViewExtensionTests.swift
//  SwiftJsonUITests
//
//  Tests for UIView extension methods
//

import XCTest
@testable import SwiftJsonUI

final class UIViewExtensionTests: XCTestCase {

    // MARK: - View ID Tests

    func testViewIdSetAndGet() {
        let view = UIView()
        view.viewId = "testView"

        XCTAssertEqual(view.viewId, "testView")
    }

    func testViewIdDefaultNil() {
        let view = UIView()
        XCTAssertNil(view.viewId)
    }

    func testViewIdOverwrite() {
        let view = UIView()
        view.viewId = "first"
        view.viewId = "second"

        XCTAssertEqual(view.viewId, "second")
    }

    // MARK: - Background Color Tests

    func testDefaultBackgroundColorSetAndGet() {
        let view = UIView()
        let color = UIColor.red
        view.defaultBackgroundColor = color

        XCTAssertNotNil(view.defaultBackgroundColor)
    }

    func testDefaultBackgroundColorGeneratesTapColor() {
        let view = UIView()
        view.defaultBackgroundColor = UIColor.red

        XCTAssertNotNil(view.tapBackgroundColor)
    }

    func testDefaultBackgroundColorWhite() {
        let view = UIView()
        view.defaultBackgroundColor = UIColor.white

        XCTAssertNotNil(view.tapBackgroundColor)
    }

    func testTapBackgroundColorSetAndGet() {
        let view = UIView()
        let color = UIColor.blue
        view.tapBackgroundColor = color

        XCTAssertEqual(view.tapBackgroundColor, color)
    }

    // MARK: - Control State Tests

    func testControlStateDefault() {
        let view = UIView()
        XCTAssertEqual(view.controlState, .normal)
    }

    func testControlStateHighlighted() {
        let view = UIView()
        view.defaultBackgroundColor = UIColor.white
        view.controlState = .highlighted

        XCTAssertEqual(view.controlState, .highlighted)
        XCTAssertEqual(view.backgroundColor, view.tapBackgroundColor)
    }

    func testControlStateNormalRestoresBackground() {
        let view = UIView()
        view.defaultBackgroundColor = UIColor.white
        view.controlState = .highlighted
        view.controlState = .normal

        XCTAssertEqual(view.controlState, .normal)
        XCTAssertEqual(view.backgroundColor, view.defaultBackgroundColor)
    }

    // MARK: - Property Name Tests

    func testPropertyNameSetAndGet() {
        let view = UIView()
        view.propertyName = "testProperty"

        XCTAssertEqual(view.propertyName, "testProperty")
    }

    func testPropertyNameDefaultNil() {
        let view = UIView()
        XCTAssertNil(view.propertyName)
    }

    // MARK: - Binding Tests

    func testBindingSetAndGet() {
        let view = UIView()
        view.binding = "@{userName}"

        XCTAssertEqual(view.binding, "@{userName}")
    }

    func testBindingDefaultNil() {
        let view = UIView()
        XCTAssertNil(view.binding)
    }

    func testBindingSetSetAndGet() {
        let view = UIView()
        let bindingSet = ["text": "@{userName}", "visible": "@{isVisible}"]
        view.bindingSet = bindingSet

        XCTAssertNotNil(view.bindingSet)
        XCTAssertEqual(view.bindingSet?["text"], "@{userName}")
        XCTAssertEqual(view.bindingSet?["visible"], "@{isVisible}")
    }

    func testBindingSetDefaultNil() {
        let view = UIView()
        XCTAssertNil(view.bindingSet)
    }

    // MARK: - Scripts Tests

    func testScriptsSetAndGet() {
        let view = UIView()
        let script = ScriptModel(type: .string, value: "handleClick()")
        var scripts = [ScriptModel.EventType: ScriptModel]()
        scripts[.onclick] = script
        view.scripts = scripts

        XCTAssertEqual(view.scripts.count, 1)
        XCTAssertNotNil(view.scripts[.onclick])
    }

    func testScriptsDefaultEmpty() {
        let view = UIView()
        let scripts = view.scripts

        XCTAssertEqual(scripts.count, 0)
    }

    // MARK: - Multiple Views Independence Tests

    func testMultipleViewsIndependentViewIds() {
        let view1 = UIView()
        let view2 = UIView()

        view1.viewId = "view1"
        view2.viewId = "view2"

        XCTAssertEqual(view1.viewId, "view1")
        XCTAssertEqual(view2.viewId, "view2")
    }

    func testMultipleViewsIndependentBindings() {
        let view1 = UIView()
        let view2 = UIView()

        view1.binding = "@{property1}"
        view2.binding = "@{property2}"

        XCTAssertEqual(view1.binding, "@{property1}")
        XCTAssertEqual(view2.binding, "@{property2}")
    }

    func testMultipleViewsIndependentBackgroundColors() {
        let view1 = UIView()
        let view2 = UIView()

        view1.defaultBackgroundColor = UIColor.red
        view2.defaultBackgroundColor = UIColor.blue

        XCTAssertNotEqual(view1.defaultBackgroundColor, view2.defaultBackgroundColor)
    }
}
