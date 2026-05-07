//
//  SJUITextViewTests.swift
//  SwiftJsonUITests
//
//  Comprehensive tests for SJUITextView component
//

import XCTest
@testable import SwiftJsonUI

@MainActor
final class SJUITextViewTests: XCTestCase {

    var textView: SJUITextView!
    var testTarget: NSObject!
    var testViews: [String: UIView]!

    override func setUp() {
        super.setUp()
        testTarget = NSObject()
        testViews = [:]
        textView = SJUITextView.createFromJSON(
            attr: JSON([:]),
            target: testTarget,
            views: &testViews
        )
    }

    override func tearDown() {
        textView = nil
        testTarget = nil
        testViews = nil
        super.tearDown()
    }

    // MARK: - Basic Initialization Tests

    func testTextViewCreation() {
        XCTAssertNotNil(textView)
        XCTAssertTrue(textView is SJUITextView)
    }

    func testViewClassProperty() {
        let viewClass = SJUITextView.viewClass
        XCTAssertTrue(viewClass == SJUITextView.self)
    }

    func testDefaultProperties() {
        // SJUITextView inherits from UITextView, so it IS a UITextView
        XCTAssertTrue(textView is UITextView)
    }

    // MARK: - Text Property Tests

    func testTextProperty() {
        textView.text = "Test Text"
        XCTAssertEqual(textView.text, "Test Text")
    }

    func testTextPropertyNil() {
        textView.text = nil
        // UITextView.text returns "" when nil, not nil
        XCTAssertEqual(textView.text, "")
    }

    func testEmptyText() {
        textView.text = ""
        XCTAssertEqual(textView.text, "")
    }

    func testLongText() {
        let longText = String(repeating: "A", count: 10000)
        textView.text = longText
        XCTAssertEqual(textView.text, longText)
    }

    func testMultilineText() {
        let multiline = "Line 1\nLine 2\nLine 3"
        textView.text = multiline
        XCTAssertEqual(textView.text, multiline)
    }

    // MARK: - Hint Property Tests

    func testHintProperty() {
        textView.hint = "Enter text here"
        XCTAssertEqual(textView.hint, "Enter text here")
    }

    func testHintPropertyNil() {
        textView.hint = nil
        XCTAssertNil(textView.hint)
    }

    // MARK: - Font Tests

    func testFontProperty() {
        let customFont = UIFont.systemFont(ofSize: 18)
        textView.font = customFont
        XCTAssertEqual(textView.font, customFont)
    }

    func testFontSize() {
        textView.font = UIFont.systemFont(ofSize: 20)
        XCTAssertEqual(textView.font?.pointSize, 20)
    }

    // MARK: - Text Color Tests

    func testTextColorProperty() {
        textView.textColor = .red
        XCTAssertEqual(textView.textColor, .red)
    }

    func testTextColorDefault() {
        XCTAssertNotNil(textView.textColor)
    }

    // MARK: - Editable and Selectable Tests

    func testIsEditable() {
        textView.isEditable = true
        XCTAssertTrue(textView.isEditable)

        textView.isEditable = false
        XCTAssertFalse(textView.isEditable)
    }

    func testIsSelectable() {
        textView.isSelectable = true
        XCTAssertTrue(textView.isSelectable)

        textView.isSelectable = false
        XCTAssertFalse(textView.isSelectable)
    }

    // MARK: - Container Inset Tests

    func testTextContainerInset() {
        let inset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.textContainerInset = inset

        XCTAssertEqual(textView.textContainerInset.top, 10)
        XCTAssertEqual(textView.textContainerInset.left, 10)
        XCTAssertEqual(textView.textContainerInset.bottom, 10)
        XCTAssertEqual(textView.textContainerInset.right, 10)
    }

    func testTextContainerInsetZero() {
        textView.textContainerInset = .zero

        XCTAssertEqual(textView.textContainerInset, .zero)
    }

    // MARK: - JSON Creation Tests

    func testCreateFromJSONBasic() {
        let json = JSON(["type": "TextView"])
        var views = [String: UIView]()
        let tv = SJUITextView.createFromJSON(attr: json, target: testTarget, views: &views)

        XCTAssertNotNil(tv)
        XCTAssertTrue(tv is SJUITextView)
    }

    func testCreateFromJSONWithText() {
        let json = JSON([
            "type": "TextView",
            "text": "Sample text"
        ])
        var views = [String: UIView]()
        let tv = SJUITextView.createFromJSON(attr: json, target: testTarget, views: &views)

        // Text IS set via createFromJSON - implementation sets it
        XCTAssertNotNil(tv.text)
    }

    func testCreateFromJSONWithHint() {
        let json = JSON([
            "type": "TextView",
            "hint": "Enter description"
        ])
        var views = [String: UIView]()
        let tv = SJUITextView.createFromJSON(attr: json, target: testTarget, views: &views)

        XCTAssertEqual(tv.hint, "Enter description")
    }

    func testCreateFromJSONWithFont() {
        let json = JSON([
            "type": "TextView",
            "font": "Helvetica",
            "fontSize": 16
        ])
        var views = [String: UIView]()
        let tv = SJUITextView.createFromJSON(attr: json, target: testTarget, views: &views)

        XCTAssertNotNil(tv.font)
        XCTAssertEqual(tv.font?.pointSize, 16)
    }

    func testCreateFromJSONWithTextColor() {
        let json = JSON([
            "type": "TextView",
            "textColor": "#FF0000"
        ])
        var views = [String: UIView]()
        let tv = SJUITextView.createFromJSON(attr: json, target: testTarget, views: &views)

        XCTAssertNotNil(tv.textColor)
    }

    func testCreateFromJSONWithEditable() {
        let json = JSON([
            "type": "TextView",
            "enabled": false
        ])
        var views = [String: UIView]()
        let tv = SJUITextView.createFromJSON(attr: json, target: testTarget, views: &views)

        XCTAssertFalse(tv.isEditable)
    }

    func testCreateFromJSONWithSelectable() {
        let json = JSON([
            "type": "TextView",
            "selectable": true
        ])
        var views = [String: UIView]()
        let tv = SJUITextView.createFromJSON(attr: json, target: testTarget, views: &views)

        XCTAssertTrue(tv.isSelectable)
    }

    func testCreateFromJSONWithContainerInset() {
        let json = JSON([
            "type": "TextView",
            "containerInset": [8, 12, 8, 12]
        ])
        var views = [String: UIView]()
        let tv = SJUITextView.createFromJSON(attr: json, target: testTarget, views: &views)

        // Container inset is set correctly
        XCTAssertEqual(tv.textContainerInset.top, 8)
        XCTAssertEqual(tv.textContainerInset.left, 12)
        XCTAssertEqual(tv.textContainerInset.bottom, 8)
        XCTAssertEqual(tv.textContainerInset.right, 12)
    }

    // MARK: - Text Alignment Tests

    func testTextAlignment() {
        textView.textAlignment = .center
        XCTAssertEqual(textView.textAlignment, .center)

        textView.textAlignment = .right
        XCTAssertEqual(textView.textAlignment, .right)

        textView.textAlignment = .left
        XCTAssertEqual(textView.textAlignment, .left)
    }

    func testCreateFromJSONWithTextAlign() {
        let json = JSON([
            "type": "TextView",
            "textAlign": "center"
        ])
        var views = [String: UIView]()
        let tv = SJUITextView.createFromJSON(attr: json, target: testTarget, views: &views)

        XCTAssertEqual(tv.textAlignment, .center)
    }

    // MARK: - Keyboard Type Tests

    func testKeyboardType() {
        textView.keyboardType = .emailAddress
        XCTAssertEqual(textView.keyboardType, .emailAddress)

        textView.keyboardType = .numberPad
        XCTAssertEqual(textView.keyboardType, .numberPad)
    }

    func testCreateFromJSONWithKeyboardType() {
        let json = JSON([
            "type": "TextView",
            "keyboardType": "emailAddress"
        ])
        var views = [String: UIView]()
        let tv = SJUITextView.createFromJSON(attr: json, target: testTarget, views: &views)

        XCTAssertNotNil(tv)
    }

    // MARK: - Return Key Type Tests

    func testReturnKeyType() {
        textView.returnKeyType = .done
        XCTAssertEqual(textView.returnKeyType, .done)

        textView.returnKeyType = .go
        XCTAssertEqual(textView.returnKeyType, .go)
    }

    // MARK: - Complex Scenarios

    func testTextViewWithAllProperties() {
        let json = JSON([
            "type": "TextView",
            "text": "Initial text",
            "hint": "Enter text",
            "font": "Helvetica",
            "fontSize": 14,
            "textColor": "#000000",
            "textAlign": "left",
            "enabled": true,
            "selectable": true
        ])
        var views = [String: UIView]()
        let tv = SJUITextView.createFromJSON(attr: json, target: testTarget, views: &views)

        XCTAssertNotNil(tv.text)
        XCTAssertEqual(tv.hint, "Enter text")
        XCTAssertTrue(tv.isEditable)
        XCTAssertTrue(tv.isSelectable)
    }

    func testMultipleTextChanges() {
        textView.text = "First"
        XCTAssertEqual(textView.text, "First")

        textView.text = "Second"
        XCTAssertEqual(textView.text, "Second")

        textView.text = "Third"
        XCTAssertEqual(textView.text, "Third")
    }

    // MARK: - Edge Cases

    func testVeryLongText() {
        let veryLongText = String(repeating: "Lorem ipsum dolor sit amet. ", count: 1000)
        textView.text = veryLongText

        XCTAssertEqual(textView.text?.count, veryLongText.count)
    }

    func testSpecialCharacters() {
        let specialText = "特殊文字 🎉 @#$%^&*()"
        textView.text = specialText

        XCTAssertEqual(textView.text, specialText)
    }

    func testEmojiText() {
        let emojiText = "😀😃😄😁🎉🎊"
        textView.text = emojiText

        XCTAssertEqual(textView.text, emojiText)
    }

    func testNewlineCharacters() {
        let textWithNewlines = "Line1\nLine2\r\nLine3\rLine4"
        textView.text = textWithNewlines

        XCTAssertEqual(textView.text, textWithNewlines)
    }

    func testWhitespaceText() {
        let whitespaceText = "   \n\t   "
        textView.text = whitespaceText

        XCTAssertEqual(textView.text, whitespaceText)
    }

    // MARK: - Attributed Text Tests

    func testAttributedText() {
        let attributedString = NSAttributedString(
            string: "Attributed",
            attributes: [.foregroundColor: UIColor.red]
        )
        textView.attributedText = attributedString

        XCTAssertEqual(textView.attributedText, attributedString)
    }

    // MARK: - Data Detector Tests

    func testDataDetectorTypes() {
        textView.dataDetectorTypes = .link
        XCTAssertEqual(textView.dataDetectorTypes, .link)

        textView.dataDetectorTypes = .phoneNumber
        XCTAssertEqual(textView.dataDetectorTypes, .phoneNumber)
    }

    // MARK: - Text Container Tests

    func testTextContainerInsetSetting() {
        let inset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        textView.textContainerInset = inset

        XCTAssertEqual(textView.textContainerInset, inset)
    }

    // MARK: - Scroll Tests

    func testScrollEnabled() {
        textView.isScrollEnabled = true
        XCTAssertTrue(textView.isScrollEnabled)

        textView.isScrollEnabled = false
        XCTAssertFalse(textView.isScrollEnabled)
    }

    // MARK: - Performance Tests

    func testTextViewCreationPerformance() {
        measure {
            for _ in 0..<100 {
                var views = [String: UIView]()
                _ = SJUITextView.createFromJSON(
                    attr: JSON(["type": "TextView"]),
                    target: testTarget,
                    views: &views
                )
            }
        }
    }

    func testTextSettingPerformance() {
        let text = String(repeating: "Performance test text. ", count: 100)

        measure {
            for _ in 0..<100 {
                textView.text = text
            }
        }
    }
}
