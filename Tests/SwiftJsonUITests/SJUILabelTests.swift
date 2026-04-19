//
//  SJUILabelTests.swift
//  SwiftJsonUITests
//
//  Tests for the SJUILabel class
//

import XCTest
@testable import SwiftJsonUI

final class SJUILabelTests: XCTestCase {

    // MARK: - Basic Tests

    func testLabelInitialization() {
        let label = SJUILabel()

        XCTAssertNotNil(label)
        XCTAssertFalse(label.selected)
        XCTAssertFalse(label.linkable)
        XCTAssertNil(label.hint)
        XCTAssertNil(label.touchedURL)
    }

    func testViewClassProperty() {
        let viewClass = SJUILabel.viewClass
        XCTAssertTrue(viewClass == SJUILabel.self)
    }

    func testDefaultLinkColor() {
        XCTAssertEqual(SJUILabel.defaultLinkColor, .blue)
    }

    // MARK: - Padding Tests

    func testDefaultPadding() {
        let label = SJUILabel()

        XCTAssertEqual(label.padding.top, 0)
        XCTAssertEqual(label.padding.left, 0)
        XCTAssertEqual(label.padding.bottom, 0)
        XCTAssertEqual(label.padding.right, 0)
    }

    func testSetPadding() {
        let label = SJUILabel()
        label.padding = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)

        XCTAssertEqual(label.padding.top, 10)
        XCTAssertEqual(label.padding.left, 20)
        XCTAssertEqual(label.padding.bottom, 10)
        XCTAssertEqual(label.padding.right, 20)
    }

    func testPaddingAffectsIntrinsicContentSize() {
        let label = SJUILabel()
        label.text = "Test"

        let sizeWithoutPadding = label.intrinsicContentSize
        label.padding = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        let sizeWithPadding = label.intrinsicContentSize

        XCTAssertGreaterThan(sizeWithPadding.height, sizeWithoutPadding.height)
        XCTAssertGreaterThan(sizeWithPadding.width, sizeWithoutPadding.width)
    }

    // MARK: - Attributed Text Tests

    func testApplyAttributedText() {
        let label = SJUILabel()
        let attrs: [NSAttributedString.Key: NSObject] = [
            .font: UIFont.systemFont(ofSize: 14) as NSObject,
            .foregroundColor: UIColor.black
        ]
        label.attributes = attrs

        label.applyAttributedText("Test Text")

        XCTAssertEqual(label.attributedText?.string, "Test Text")
    }

    func testApplyAttributedTextWithEmptyString() {
        let label = SJUILabel()
        let attrs: [NSAttributedString.Key: NSObject] = [
            .font: UIFont.systemFont(ofSize: 14) as NSObject
        ]
        label.attributes = attrs

        label.applyAttributedText("")

        XCTAssertEqual(label.attributedText?.string, "")
    }

    func testApplyAttributedTextWithNil() {
        let label = SJUILabel()
        let attrs: [NSAttributedString.Key: NSObject] = [
            .font: UIFont.systemFont(ofSize: 14) as NSObject
        ]
        label.attributes = attrs

        label.applyAttributedText(nil)

        XCTAssertEqual(label.attributedText?.string, "")
    }

    func testApplyAttributedTextWithHint() {
        let label = SJUILabel()
        let attrs: [NSAttributedString.Key: NSObject] = [
            .font: UIFont.systemFont(ofSize: 14) as NSObject
        ]
        let hintAttrs: [NSAttributedString.Key: NSObject] = [
            .font: UIFont.systemFont(ofSize: 12) as NSObject,
            .foregroundColor: UIColor.gray
        ]
        label.attributes = attrs
        label.hint = "Hint Text"
        label.hintAttributes = hintAttrs

        label.applyAttributedText("")

        XCTAssertEqual(label.attributedText?.string, "Hint Text")
    }

    func testApplyAttributedTextWithSelection() {
        let label = SJUILabel()
        let normalAttrs: [NSAttributedString.Key: NSObject] = [
            .foregroundColor: UIColor.black
        ]
        let highlightAttrs: [NSAttributedString.Key: NSObject] = [
            .foregroundColor: UIColor.blue
        ]
        label.attributes = normalAttrs
        label.highlightAttributes = highlightAttrs
        label.selected = false

        label.applyAttributedText("Test")

        // Color should be from normal attributes
        var attributesAtStart: [NSAttributedString.Key: Any] = [:]
        if let text = label.attributedText, text.length > 0 {
            attributesAtStart = text.attributes(at: 0, effectiveRange: nil)
        }
        XCTAssertEqual(attributesAtStart[.foregroundColor] as? UIColor, UIColor.black)

        label.selected = true

        // After selection, color should change
        if let text = label.attributedText, text.length > 0 {
            attributesAtStart = text.attributes(at: 0, effectiveRange: nil)
        }
        XCTAssertEqual(attributesAtStart[.foregroundColor] as? UIColor, UIColor.blue)
    }

    // MARK: - Linkable Text Tests

    func testApplyLinkableAttributedTextWithURL() {
        let label = SJUILabel()
        let attrs: [NSAttributedString.Key: NSObject] = [
            .font: UIFont.systemFont(ofSize: 14) as NSObject,
            .foregroundColor: UIColor.black
        ]
        label.attributes = attrs

        label.applyLinkableAttributedText("Visit https://example.com for more info")

        XCTAssertTrue(label.linkable)
        XCTAssertTrue(label.isUserInteractionEnabled)
        XCTAssertNotNil(label.attributedText)
    }

    func testApplyLinkableAttributedTextWithoutURL() {
        let label = SJUILabel()
        let attrs: [NSAttributedString.Key: NSObject] = [
            .font: UIFont.systemFont(ofSize: 14) as NSObject
        ]
        label.attributes = attrs

        label.applyLinkableAttributedText("Plain text without links")

        XCTAssertFalse(label.linkable)
        XCTAssertTrue(label.isUserInteractionEnabled)
    }

    func testApplyLinkableAttributedTextWithCustomColor() {
        let label = SJUILabel()
        let attrs: [NSAttributedString.Key: NSObject] = [
            .font: UIFont.systemFont(ofSize: 14) as NSObject,
            .foregroundColor: UIColor.black
        ]
        label.attributes = attrs

        label.applyLinkableAttributedText("Visit https://example.com", withColor: .red)

        XCTAssertTrue(label.linkable)
    }

    // MARK: - Selected State Tests

    func testSelectedState() {
        let label = SJUILabel()
        let attrs: [NSAttributedString.Key: NSObject] = [
            .foregroundColor: UIColor.black
        ]
        let highlightAttrs: [NSAttributedString.Key: NSObject] = [
            .foregroundColor: UIColor.red
        ]
        label.attributes = attrs
        label.highlightAttributes = highlightAttrs

        XCTAssertFalse(label.selected)

        label.selected = true

        XCTAssertTrue(label.selected)
    }

    // MARK: - Vertical Adjustment Tests

    func testVerticalAdjustmentByFonts() {
        SJUILabel.verticalAdjustmentByFonts["TestFont"] = 10.0

        XCTAssertEqual(SJUILabel.verticalAdjustmentByFonts["TestFont"], 10.0)

        // Cleanup
        SJUILabel.verticalAdjustmentByFonts.removeValue(forKey: "TestFont")
    }

    func testSizeThatFits() {
        let label = SJUILabel()
        label.text = "Test Text"
        label.padding = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)

        let size = label.sizeThatFits(CGSize(width: 200, height: 100))

        XCTAssertGreaterThan(size.width, 0)
        XCTAssertGreaterThan(size.height, 0)
    }

    // MARK: - Edge Cases

    func testMultipleTextChanges() {
        let label = SJUILabel()
        let attrs: [NSAttributedString.Key: NSObject] = [
            .font: UIFont.systemFont(ofSize: 14) as NSObject
        ]
        label.attributes = attrs

        label.applyAttributedText("First Text")
        XCTAssertEqual(label.attributedText?.string, "First Text")

        label.applyAttributedText("Second Text")
        XCTAssertEqual(label.attributedText?.string, "Second Text")

        label.applyAttributedText("")
        XCTAssertEqual(label.attributedText?.string, "")
    }

    func testLinkableStateReset() {
        let label = SJUILabel()
        let attrs: [NSAttributedString.Key: NSObject] = [
            .font: UIFont.systemFont(ofSize: 14) as NSObject
        ]
        label.attributes = attrs

        label.applyLinkableAttributedText("Visit https://example.com")
        XCTAssertTrue(label.linkable)

        label.applyAttributedText("Plain text")
        XCTAssertFalse(label.linkable)
    }

    func testLinkedRangesCleared() {
        let label = SJUILabel()
        let attrs: [NSAttributedString.Key: NSObject] = [
            .font: UIFont.systemFont(ofSize: 14) as NSObject
        ]
        label.attributes = attrs

        label.linkedRanges = [["key": "value"]]
        XCTAssertEqual(label.linkedRanges.count, 1)

        label.applyAttributedText("New text")
        XCTAssertEqual(label.linkedRanges.count, 0)
    }

    func testHintDisplaysWhenTextIsEmpty() {
        let label = SJUILabel()
        let attrs: [NSAttributedString.Key: NSObject] = [
            .font: UIFont.systemFont(ofSize: 14) as NSObject
        ]
        let hintAttrs: [NSAttributedString.Key: NSObject] = [
            .font: UIFont.systemFont(ofSize: 12) as NSObject,
            .foregroundColor: UIColor.gray
        ]
        label.attributes = attrs
        label.hint = "Enter text"
        label.hintAttributes = hintAttrs

        label.applyAttributedText("")
        XCTAssertEqual(label.attributedText?.string, "Enter text")

        label.applyAttributedText("Actual text")
        XCTAssertEqual(label.attributedText?.string, "Actual text")
    }
}
