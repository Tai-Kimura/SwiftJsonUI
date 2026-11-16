//
//  SJUITextFieldTests.swift
//  SwiftJsonUITests
//
//  Tests for the SJUITextField class
//

import XCTest
@testable import SwiftJsonUI

final class SJUITextFieldTests: XCTestCase {

    // MARK: - Basic Tests

    func testTextFieldInitialization() {
        let textField = SJUITextField()

        XCTAssertNotNil(textField)
        XCTAssertNil(textField.placeholderAttributes)
    }

    func testViewClassProperty() {
        let viewClass = SJUITextField.viewClass
        XCTAssertTrue(viewClass == SJUITextField.self)
    }

    // MARK: - Static Properties Tests

    func testAccessoryBackgroundColor() {
        XCTAssertEqual(SJUITextField.accessoryBackgroundColor, .gray)
    }

    func testAccessoryTextColor() {
        XCTAssertEqual(SJUITextField.accessoryTextColor, .blue)
    }

    func testDefaultBorderColor() {
        XCTAssertEqual(SJUITextField.defaultBorderColor, .lightGray)
    }

    func testDefaultAccessoryCornerRadius() {
        XCTAssertEqual(SJUITextField.defaultAccessoryCornerRadius, 16.0)
    }

    func testDefaultGlassEffectStyle() {
        XCTAssertEqual(SJUITextField.defaultGlassEffectStyle, "systemMaterial")
    }

    func testCanModifyStaticProperties() {
        SJUITextField.accessoryBackgroundColor = .red
        XCTAssertEqual(SJUITextField.accessoryBackgroundColor, .red)

        // Reset
        SJUITextField.accessoryBackgroundColor = .gray
    }

    // MARK: - Delegate Tests

    func testDelegateProperty() {
        let textField = SJUITextField()

        class TestDelegate: NSObject, UITextFieldDelegate {}
        let delegate = TestDelegate()

        textField.delegate = delegate

        XCTAssertNotNil(textField.delegate)
        XCTAssertTrue(textField.delegate === delegate)
    }

    func testSJUITextFieldDelegateAssignment() {
        let textField = SJUITextField()

        class TestDelegate: NSObject, UITextFieldDelegate, SJUITextFieldDelegate {
            var deleteBackwardCalled = false

            func textFieldDidDeleteBackward(textField: UITextField) {
                deleteBackwardCalled = true
            }
        }

        let delegate = TestDelegate()
        textField.delegate = delegate

        textField.deleteBackward()

        XCTAssertTrue(delegate.deleteBackwardCalled)
    }

    // MARK: - CreateFromJSON Tests

    func testCreateFromJSONBasic() {
        let json = JSON([:])

        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNotNil(textField)
        XCTAssertNotNil(textField.font)
    }

    func testCreateFromJSONWithFontSize() {
        let json = JSON([
            "fontSize": 20
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(textField.font?.pointSize, 20.0)
    }

    func testCreateFromJSONDefaultFontSize() {
        let json = JSON([:])

        let target = NSObject()
        var views = [String: UIView]()

        SJUIViewCreator.defaultFontSize = 16.0
        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(textField.font?.pointSize, 16.0)
    }

    func testCreateFromJSONWithTextVerticalAlignCenter() {
        let json = JSON([
            "textVerticalAlign": "Center"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(textField.contentVerticalAlignment, .center)
    }

    func testCreateFromJSONWithTextVerticalAlignTop() {
        let json = JSON([
            "textVerticalAlign": "Top"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(textField.contentVerticalAlignment, .top)
    }

    func testCreateFromJSONWithTextVerticalAlignBottom() {
        let json = JSON([
            "textVerticalAlign": "Bottom"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(textField.contentVerticalAlignment, .bottom)
    }

    func testCreateFromJSONDefaultTextVerticalAlign() {
        let json = JSON([:])

        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(textField.contentVerticalAlignment, .center)
    }

    func testCreateFromJSONWithCornerRadius() {
        let json = JSON([
            "cornerRadius": 8
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(textField.layer.cornerRadius, 8.0)
    }

    func testCreateFromJSONDefaultCornerRadius() {
        let json = JSON([:])

        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(textField.layer.cornerRadius, 0.0)
    }

    func testCreateFromJSONWithBorderWidth() {
        let json = JSON([
            "borderWidth": 2.0
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(textField.layer.borderWidth, 2.0)
    }

    func testCreateFromJSONDefaultBorderWidth() {
        let json = JSON([:])

        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(textField.layer.borderWidth, 0.3)
    }

    func testCreateFromJSONWithBorderStyleRoundedRect() {
        let json = JSON([
            "borderStyle": "RoundedRect"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(textField.borderStyle, .roundedRect)
    }

    func testCreateFromJSONWithBorderStyleLine() {
        let json = JSON([
            "borderStyle": "Line"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(textField.borderStyle, .line)
    }

    func testCreateFromJSONWithBorderStyleBezel() {
        let json = JSON([
            "borderStyle": "Bezel"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(textField.borderStyle, .bezel)
    }

    func testCreateFromJSONDefaultBorderStyle() {
        let json = JSON([:])

        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(textField.borderStyle, .none)
    }

    func testCreateFromJSONWithLeftView() {
        let json = JSON([
            "textPaddingLeft": 15.0
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNotNil(textField.leftView)
        XCTAssertEqual(textField.leftViewMode, .always)
        XCTAssertEqual(textField.leftView?.frame.width, 15.0)
    }

    func testCreateFromJSONDefaultLeftPadding() {
        let json = JSON([:])

        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNotNil(textField.leftView)
        XCTAssertEqual(textField.leftView?.frame.width, 10.0)
    }

    func testCreateFromJSONWithRightView() {
        let json = JSON([
            "fieldPadding": 8.0
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNotNil(textField.rightView)
        XCTAssertEqual(textField.rightViewMode, .always)
        XCTAssertEqual(textField.rightView?.frame.width, 8.0)
    }

    func testCreateFromJSONDefaultRightPadding() {
        let json = JSON([:])

        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNotNil(textField.rightView)
        XCTAssertEqual(textField.rightView?.frame.width, 5.0)
    }

    // MARK: - Placeholder Attributes Tests

    func testPlaceholderAttributesProperty() {
        let textField = SJUITextField()

        XCTAssertNil(textField.placeholderAttributes)

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.red,
            .font: UIFont.systemFont(ofSize: 12)
        ]
        textField.placeholderAttributes = attributes

        XCTAssertNotNil(textField.placeholderAttributes)
        XCTAssertEqual(textField.placeholderAttributes?.count, 2)
    }

    // MARK: - Edge Cases

    func testDeleteBackwardWithoutDelegate() {
        let textField = SJUITextField()

        // Should not crash
        textField.deleteBackward()

        XCTAssertTrue(true)
    }

    func testLeftViewConfiguration() {
        let json = JSON([:])
        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNotNil(textField.leftView)
        XCTAssertFalse(textField.leftView!.isOpaque)
        XCTAssertEqual(textField.leftView!.backgroundColor, .clear)
    }

    func testRightViewConfiguration() {
        let json = JSON([:])
        let target = NSObject()
        var views = [String: UIView]()

        let textField = SJUITextField.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNotNil(textField.rightView)
        XCTAssertFalse(textField.rightView!.isOpaque)
        XCTAssertEqual(textField.rightView!.backgroundColor, .clear)
        XCTAssertFalse(textField.rightView!.isUserInteractionEnabled)
    }
}
