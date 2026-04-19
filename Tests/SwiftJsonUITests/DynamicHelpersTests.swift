//
//  DynamicHelpersTests.swift
//  SwiftJsonUITests
//
//  Tests for DynamicHelpers utility functions
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class DynamicHelpersTests: XCTestCase {

    // MARK: - Font Weight Tests

    func testFontWeightFromStringBold() {
        XCTAssertEqual(DynamicHelpers.fontWeightFromString("bold"), .bold)
        XCTAssertEqual(DynamicHelpers.fontWeightFromString("Bold"), .bold)
        XCTAssertEqual(DynamicHelpers.fontWeightFromString("BOLD"), .bold)
    }

    func testFontWeightFromStringSemibold() {
        XCTAssertEqual(DynamicHelpers.fontWeightFromString("semibold"), .semibold)
    }

    func testFontWeightFromStringMedium() {
        XCTAssertEqual(DynamicHelpers.fontWeightFromString("medium"), .medium)
    }

    func testFontWeightFromStringLight() {
        XCTAssertEqual(DynamicHelpers.fontWeightFromString("light"), .light)
    }

    func testFontWeightFromStringThin() {
        XCTAssertEqual(DynamicHelpers.fontWeightFromString("thin"), .thin)
    }

    func testFontWeightFromStringUltraLight() {
        XCTAssertEqual(DynamicHelpers.fontWeightFromString("ultralight"), .ultraLight)
    }

    func testFontWeightFromStringHeavy() {
        XCTAssertEqual(DynamicHelpers.fontWeightFromString("heavy"), .heavy)
    }

    func testFontWeightFromStringBlack() {
        XCTAssertEqual(DynamicHelpers.fontWeightFromString("black"), .black)
    }

    func testFontWeightFromStringRegular() {
        XCTAssertEqual(DynamicHelpers.fontWeightFromString("regular"), .regular)
    }

    func testFontWeightFromStringNil() {
        XCTAssertEqual(DynamicHelpers.fontWeightFromString(nil), .regular)
    }

    func testFontWeightFromStringInvalid() {
        XCTAssertEqual(DynamicHelpers.fontWeightFromString("invalid"), .regular)
        XCTAssertEqual(DynamicHelpers.fontWeightFromString(""), .regular)
    }

    // MARK: - Font From Component Tests

    func testFontFromComponentWithWeightName() {
        // Weight names like "bold", "semibold" should return system font with weight
        let boldComponent = createComponentWithFont(font: "bold", fontSize: 16)
        let boldFont = DynamicDecodingHelper.fontFromComponent(boldComponent)
        XCTAssertNotNil(boldFont)

        let semiboldComponent = createComponentWithFont(font: "semibold", fontSize: 16)
        let semiboldFont = DynamicDecodingHelper.fontFromComponent(semiboldComponent)
        XCTAssertNotNil(semiboldFont)

        let mediumComponent = createComponentWithFont(font: "medium", fontSize: 16)
        let mediumFont = DynamicDecodingHelper.fontFromComponent(mediumComponent)
        XCTAssertNotNil(mediumFont)
    }

    func testFontFromComponentWithCustomFontName() {
        // Custom font names should return custom font
        let component = createComponentWithFont(font: "Helvetica", fontSize: 16)
        let font = DynamicDecodingHelper.fontFromComponent(component)
        XCTAssertNotNil(font)
    }

    func testFontFromComponentWithFontSizeOnly() {
        let component = createComponentWithFont(fontSize: 20)
        let font = DynamicDecodingHelper.fontFromComponent(component)
        XCTAssertNotNil(font)
    }

    func testFontFromComponentWithNoFontAttributes() {
        let component = createComponent()
        let font = DynamicDecodingHelper.fontFromComponent(component)
        XCTAssertNil(font)
    }

    // MARK: - Opacity Tests

    func testGetOpacityWithOpacity() {
        let component = createComponent(opacity: 0.5)
        XCTAssertEqual(DynamicHelpers.getOpacity(from: component), 0.5, accuracy: 0.001)
    }

    func testGetOpacityWithAlpha() {
        let component = createComponent(alpha: 0.8)
        XCTAssertEqual(DynamicHelpers.getOpacity(from: component), 0.8, accuracy: 0.001)
    }

    func testGetOpacityDefault() {
        let component = createComponent()
        XCTAssertEqual(DynamicHelpers.getOpacity(from: component), 1.0, accuracy: 0.001)
    }

    func testGetOpacityPrefersOpacityOverAlpha() {
        let component = createComponent(opacity: 0.3, alpha: 0.7)
        XCTAssertEqual(DynamicHelpers.getOpacity(from: component), 0.3, accuracy: 0.001)
    }

    // MARK: - Hidden Tests

    func testIsHiddenTrue() {
        let component = createComponent(hidden: true)
        XCTAssertTrue(DynamicHelpers.isHidden(component))
    }

    func testIsHiddenFalse() {
        let component = createComponent(hidden: false)
        XCTAssertFalse(DynamicHelpers.isHidden(component))
    }

    func testIsHiddenVisibilityGone() {
        let component = createComponent(visibility: "gone")
        XCTAssertTrue(DynamicHelpers.isHidden(component))
    }

    func testIsHiddenVisibilityVisible() {
        let component = createComponent(visibility: "visible")
        XCTAssertFalse(DynamicHelpers.isHidden(component))
    }

    func testIsHiddenDefault() {
        let component = createComponent()
        XCTAssertFalse(DynamicHelpers.isHidden(component))
    }

    // MARK: - Background Tests

    func testGetBackgroundWithColor() {
        let component = createComponent(background: "#FF0000")
        let color = DynamicHelpers.getBackground(from: component)
        XCTAssertNotNil(color)
    }

    func testGetBackgroundWithoutColor() {
        let component = createComponent()
        let color = DynamicHelpers.getBackground(from: component)
        XCTAssertEqual(color, .clear)
    }

    // MARK: - Padding Tests

    func testGetPaddingWithPaddingTop() {
        let component = createComponent(paddingTop: 10)
        let padding = DynamicHelpers.getPadding(from: component)
        XCTAssertEqual(padding.top, 10)
    }

    func testGetPaddingWithPaddingBottom() {
        let component = createComponent(paddingBottom: 15)
        let padding = DynamicHelpers.getPadding(from: component)
        XCTAssertEqual(padding.bottom, 15)
    }

    func testGetPaddingWithPaddingLeft() {
        let component = createComponent(paddingLeft: 20)
        let padding = DynamicHelpers.getPadding(from: component)
        XCTAssertEqual(padding.leading, 20)
    }

    func testGetPaddingWithPaddingRight() {
        let component = createComponent(paddingRight: 25)
        let padding = DynamicHelpers.getPadding(from: component)
        XCTAssertEqual(padding.trailing, 25)
    }

    func testGetPaddingRTLAwarePaddingStart() {
        let component = createComponent(paddingLeft: 10, paddingStart: 30)
        let padding = DynamicHelpers.getPadding(from: component)
        // paddingStart should take precedence over paddingLeft
        XCTAssertEqual(padding.leading, 30)
    }

    func testGetPaddingRTLAwarePaddingEnd() {
        let component = createComponent(paddingRight: 15, paddingEnd: 35)
        let padding = DynamicHelpers.getPadding(from: component)
        // paddingEnd should take precedence over paddingRight
        XCTAssertEqual(padding.trailing, 35)
    }

    func testGetPaddingDefault() {
        let component = createComponent()
        let padding = DynamicHelpers.getPadding(from: component)
        XCTAssertEqual(padding.top, 0)
        XCTAssertEqual(padding.leading, 0)
        XCTAssertEqual(padding.bottom, 0)
        XCTAssertEqual(padding.trailing, 0)
    }

    // MARK: - Margins Tests

    func testGetMarginsWithTopMargin() {
        let component = createComponent(topMargin: 10)
        let margin = DynamicHelpers.getMargins(from: component)
        XCTAssertEqual(margin.top, 10)
    }

    func testGetMarginsWithBottomMargin() {
        let component = createComponent(bottomMargin: 15)
        let margin = DynamicHelpers.getMargins(from: component)
        XCTAssertEqual(margin.bottom, 15)
    }

    func testGetMarginsWithLeftMargin() {
        let component = createComponent(leftMargin: 20)
        let margin = DynamicHelpers.getMargins(from: component)
        XCTAssertEqual(margin.leading, 20)
    }

    func testGetMarginsWithRightMargin() {
        let component = createComponent(rightMargin: 25)
        let margin = DynamicHelpers.getMargins(from: component)
        XCTAssertEqual(margin.trailing, 25)
    }

    func testGetMarginsRTLAwareStartMargin() {
        let component = createComponent(leftMargin: 10, startMargin: 30)
        let margin = DynamicHelpers.getMargins(from: component)
        // startMargin should take precedence over leftMargin
        XCTAssertEqual(margin.leading, 30)
    }

    func testGetMarginsRTLAwareEndMargin() {
        let component = createComponent(rightMargin: 15, endMargin: 35)
        let margin = DynamicHelpers.getMargins(from: component)
        // endMargin should take precedence over rightMargin
        XCTAssertEqual(margin.trailing, 35)
    }

    func testGetMarginsDefault() {
        let component = createComponent()
        let margin = DynamicHelpers.getMargins(from: component)
        XCTAssertEqual(margin.top, 0)
        XCTAssertEqual(margin.leading, 0)
        XCTAssertEqual(margin.bottom, 0)
        XCTAssertEqual(margin.trailing, 0)
    }

    // MARK: - Helper Methods

    private func createComponent(
        opacity: CGFloat? = nil,
        alpha: CGFloat? = nil,
        hidden: Bool? = nil,
        visibility: String? = nil,
        background: String? = nil,
        paddingTop: CGFloat? = nil,
        paddingBottom: CGFloat? = nil,
        paddingLeft: CGFloat? = nil,
        paddingRight: CGFloat? = nil,
        paddingStart: CGFloat? = nil,
        paddingEnd: CGFloat? = nil,
        topMargin: CGFloat? = nil,
        bottomMargin: CGFloat? = nil,
        leftMargin: CGFloat? = nil,
        rightMargin: CGFloat? = nil,
        startMargin: CGFloat? = nil,
        endMargin: CGFloat? = nil
    ) -> DynamicComponent {
        let jsonDict: [String: Any] = [
            "type": "View",
            "opacity": opacity as Any,
            "alpha": alpha as Any,
            "hidden": hidden as Any,
            "visibility": visibility as Any,
            "background": background as Any,
            "paddingTop": paddingTop as Any,
            "paddingBottom": paddingBottom as Any,
            "paddingLeft": paddingLeft as Any,
            "paddingRight": paddingRight as Any,
            "paddingStart": paddingStart as Any,
            "paddingEnd": paddingEnd as Any,
            "topMargin": topMargin as Any,
            "bottomMargin": bottomMargin as Any,
            "leftMargin": leftMargin as Any,
            "rightMargin": rightMargin as Any,
            "startMargin": startMargin as Any,
            "endMargin": endMargin as Any
        ].filter { $0.value is String || $0.value is CGFloat || $0.value is Bool }

        let data = try! JSONSerialization.data(withJSONObject: jsonDict)
        return try! JSONDecoder().decode(DynamicComponent.self, from: data)
    }

    private func createComponentWithFont(
        font: String? = nil,
        fontSize: CGFloat? = nil,
        fontWeight: String? = nil
    ) -> DynamicComponent {
        var jsonDict: [String: Any] = ["type": "Label"]
        if let font = font { jsonDict["font"] = font }
        if let fontSize = fontSize { jsonDict["fontSize"] = fontSize }
        if let fontWeight = fontWeight { jsonDict["fontWeight"] = fontWeight }

        let data = try! JSONSerialization.data(withJSONObject: jsonDict)
        return try! JSONDecoder().decode(DynamicComponent.self, from: data)
    }
}
#endif
