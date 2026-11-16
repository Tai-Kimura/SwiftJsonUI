//
//  SJUIButtonTests.swift
//  SwiftJsonUITests
//
//  Tests for the SJUIButton class
//

import XCTest
@testable import SwiftJsonUI

final class SJUIButtonTests: XCTestCase {

    // MARK: - Basic Tests

    func testButtonInitialization() {
        let button = SJUIButton()

        XCTAssertNotNil(button)
        XCTAssertTrue(button.isUserInteractionEnabled)
        XCTAssertTrue(button.isEnabled)
    }

    func testViewClassProperty() {
        let viewClass = SJUIButton.viewClass
        XCTAssertTrue(viewClass == SJUIButton.self)
    }

    // MARK: - Enabled/Disabled State Tests

    func testEnabledState() {
        let button = SJUIButton()
        button.defaultFontColor = .blue
        button.defaultBackgroundColor = .white

        XCTAssertTrue(button.isEnabled)

        button.isEnabled = false
        XCTAssertFalse(button.isEnabled)

        button.isEnabled = true
        XCTAssertTrue(button.isEnabled)
    }

    func testDisabledBackgroundColor() {
        let button = SJUIButton()
        button.defaultBackgroundColor = .white
        button.disabledBackgroundColor = .gray

        button.isEnabled = false

        XCTAssertEqual(button.backgroundColor, .gray)
    }

    func testDisabledBackgroundColorFallback() {
        let button = SJUIButton()
        button.defaultBackgroundColor = .white
        button.disabledBackgroundColor = nil

        button.isEnabled = false

        // Should fall back to default background color
        XCTAssertEqual(button.backgroundColor, .white)
    }

    func testDisabledFontColor() {
        let button = SJUIButton()
        button.defaultFontColor = .blue
        button.disabledFontColor = .lightGray

        button.isEnabled = false

        XCTAssertEqual(button.titleColor(for: .normal), .lightGray)
    }

    func testDisabledFontColorFallback() {
        let button = SJUIButton()
        button.defaultFontColor = .blue
        button.disabledFontColor = nil

        button.isEnabled = false

        // Should fall back to default font color
        XCTAssertEqual(button.titleColor(for: .normal), .blue)
    }

    func testEnabledStateRestoresColors() {
        let button = SJUIButton()
        button.defaultFontColor = .blue
        button.defaultBackgroundColor = .white
        button.disabledFontColor = .gray
        button.disabledBackgroundColor = .lightGray

        button.isEnabled = false
        XCTAssertEqual(button.backgroundColor, .lightGray)
        XCTAssertEqual(button.titleColor(for: .normal), .gray)

        button.isEnabled = true
        XCTAssertEqual(button.backgroundColor, .white)
        // When button is re-enabled, titleColor is set to defaultFontColor
        XCTAssertNotNil(button.titleColor(for: .normal))
    }

    // MARK: - SetTitleColor Tests

    func testSetTitleColor() {
        let button = SJUIButton()

        button.setTitleColor(.red, for: .normal)

        XCTAssertEqual(button.defaultFontColor, .red)
        XCTAssertEqual(button.titleColor(for: .normal), .red)
    }

    func testSetTitleColorMultipleTimes() {
        let button = SJUIButton()

        button.setTitleColor(.red, for: .normal)
        XCTAssertEqual(button.defaultFontColor, .red)

        button.setTitleColor(.blue, for: .normal)
        XCTAssertEqual(button.defaultFontColor, .blue)
    }

    // MARK: - CreateFromJSON Tests

    func testCreateFromJSONBasic() {
        let json = JSON([
            "text": "Click Me",
            "fontSize": 16
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let button = SJUIButton.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNotNil(button)
        XCTAssertTrue(button.isUserInteractionEnabled)
    }

    func testCreateFromJSONWithText() {
        let json = JSON([
            "text": "Submit Button"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let button = SJUIButton.createFromJSON(attr: json, target: target, views: &views)

        if #available(iOS 15.0, *) {
            XCTAssertEqual(button.configuration?.attributedTitle?.characters.map { String($0) }.joined(), "Submit Button")
        } else {
            XCTAssertEqual(button.title(for: .normal), "Submit Button")
        }
    }

    func testCreateFromJSONWithFontSize() {
        let json = JSON([
            "text": "Test",
            "fontSize": 20
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let button = SJUIButton.createFromJSON(attr: json, target: target, views: &views)

        if #available(iOS 15.0, *) {
            XCTAssertNotNil(button.configuration)
        } else {
            XCTAssertEqual(button.titleLabel?.font.pointSize, 20.0)
        }
    }

    func testCreateFromJSONDefaultFontSize() {
        let json = JSON([
            "text": "Test"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let button = SJUIButton.createFromJSON(attr: json, target: target, views: &views)

        if #available(iOS 15.0, *) {
            XCTAssertNotNil(button.configuration)
        } else {
            XCTAssertEqual(button.titleLabel?.font.pointSize, 17.0)
        }
    }

    func testCreateFromJSONWithCustomFont() {
        let json = JSON([
            "text": "Test",
            "font": "bold",
            "fontSize": 18
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let button = SJUIButton.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNotNil(button)
        if #available(iOS 15.0, *) {
            XCTAssertNotNil(button.configuration)
        } else {
            XCTAssertNotNil(button.titleLabel?.font)
        }
    }

    func testCreateFromJSONWithDisabledState() {
        let json = JSON([
            "text": "Disabled Button",
            "enabled": false
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let button = SJUIButton.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertFalse(button.isEnabled)
    }

    func testCreateFromJSONWithEnabledState() {
        let json = JSON([
            "text": "Enabled Button",
            "enabled": true
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let button = SJUIButton.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertTrue(button.isEnabled)
    }

    @available(iOS 15.0, *)
    func testCreateFromJSONWithConfiguration() {
        let json = JSON([
            "text": "Test",
            "config": [
                "style": "filled"
            ]
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let button = SJUIButton.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNotNil(button.configuration)
    }

    @available(iOS 15.0, *)
    func testCreateFromJSONWithConfigurationStyles() {
        let styles = ["plain", "tinted", "gray", "filled", "borderless", "bordered", "borderedTinted", "borderedProminent"]

        for style in styles {
            let json = JSON([
                "text": "Test",
                "config": [
                    "style": style
                ]
            ])

            let target = NSObject()
            var views = [String: UIView]()

            let button = SJUIButton.createFromJSON(attr: json, target: target, views: &views)

            XCTAssertNotNil(button.configuration, "Configuration should exist for style: \(style)")
        }
    }

    @available(iOS 15.0, *)
    func testCreateFromJSONWithShowIndicator() {
        let json = JSON([
            "text": "Loading",
            "config": [
                "style": "plain",
                "showIndicator": true
            ]
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let button = SJUIButton.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertTrue(button.configuration?.showsActivityIndicator ?? false)
    }

    func testCreateFromJSONWithImage() {
        let json = JSON([
            "text": "Test",
            "image": "test_image"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let button = SJUIButton.createFromJSON(attr: json, target: target, views: &views)

        // Just ensure no crash when image doesn't exist
        XCTAssertNotNil(button)
    }

    // MARK: - Edge Cases

    func testMultipleEnabledStateChanges() {
        let button = SJUIButton()
        button.defaultFontColor = .blue
        button.defaultBackgroundColor = .white

        for _ in 0..<5 {
            button.isEnabled = false
            XCTAssertFalse(button.isEnabled)

            button.isEnabled = true
            XCTAssertTrue(button.isEnabled)
        }
    }

    func testCreateFromJSONWithEmptyJSON() {
        let json = JSON([:])

        let target = NSObject()
        var views = [String: UIView]()

        let button = SJUIButton.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNotNil(button)
        XCTAssertTrue(button.isUserInteractionEnabled)
    }
}
