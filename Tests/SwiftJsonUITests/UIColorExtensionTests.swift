//
//  UIColorExtensionTests.swift
//  SwiftJsonUITests
//
//  Tests for UIColor hex parsing extension
//

import XCTest
import UIKit
@testable import SwiftJsonUI

final class UIColorExtensionTests: XCTestCase {

    // MARK: - 6-digit Hex Color Tests

    func testHexColor6DigitRed() {
        let color = UIColor.colorWithHexString("#FF0000")
        XCTAssertNotNil(color)

        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 1.0, accuracy: 0.01)
        XCTAssertEqual(green, 0.0, accuracy: 0.01)
        XCTAssertEqual(blue, 0.0, accuracy: 0.01)
        XCTAssertEqual(alpha, 1.0, accuracy: 0.01)
    }

    func testHexColor6DigitGreen() {
        let color = UIColor.colorWithHexString("#00FF00")
        XCTAssertNotNil(color)

        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 0.0, accuracy: 0.01)
        XCTAssertEqual(green, 1.0, accuracy: 0.01)
        XCTAssertEqual(blue, 0.0, accuracy: 0.01)
    }

    func testHexColor6DigitBlue() {
        let color = UIColor.colorWithHexString("#0000FF")
        XCTAssertNotNil(color)

        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 0.0, accuracy: 0.01)
        XCTAssertEqual(green, 0.0, accuracy: 0.01)
        XCTAssertEqual(blue, 1.0, accuracy: 0.01)
    }

    func testHexColor6DigitBlack() {
        let color = UIColor.colorWithHexString("#000000")
        XCTAssertNotNil(color)

        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 0.0, accuracy: 0.01)
        XCTAssertEqual(green, 0.0, accuracy: 0.01)
        XCTAssertEqual(blue, 0.0, accuracy: 0.01)
    }

    func testHexColor6DigitWhite() {
        let color = UIColor.colorWithHexString("#FFFFFF")
        XCTAssertNotNil(color)

        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 1.0, accuracy: 0.01)
        XCTAssertEqual(green, 1.0, accuracy: 0.01)
        XCTAssertEqual(blue, 1.0, accuracy: 0.01)
    }

    func testHexColor6DigitMixedCase() {
        let color = UIColor.colorWithHexString("#aAbBcC")
        XCTAssertNotNil(color)

        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 0xAA / 255.0, accuracy: 0.01)
        XCTAssertEqual(green, 0xBB / 255.0, accuracy: 0.01)
        XCTAssertEqual(blue, 0xCC / 255.0, accuracy: 0.01)
    }

    func testHexColor6DigitWithoutHash() {
        let color = UIColor.colorWithHexString("FF0000")
        XCTAssertNotNil(color)

        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 1.0, accuracy: 0.01)
    }

    // MARK: - 8-digit Hex Color Tests (with Alpha)

    func testHexColor8DigitFullAlpha() {
        let color = UIColor.colorWithHexString("#FFFF0000")
        XCTAssertNotNil(color)

        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(alpha, 1.0, accuracy: 0.01)
        XCTAssertEqual(red, 1.0, accuracy: 0.01)
        XCTAssertEqual(green, 0.0, accuracy: 0.01)
        XCTAssertEqual(blue, 0.0, accuracy: 0.01)
    }

    func testHexColor8DigitHalfAlpha() {
        let color = UIColor.colorWithHexString("#80FF0000")
        XCTAssertNotNil(color)

        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(alpha, 0x80 / 255.0, accuracy: 0.01)
    }

    func testHexColor8DigitZeroAlpha() {
        let color = UIColor.colorWithHexString("#00FF0000")
        XCTAssertNotNil(color)

        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(alpha, 0.0, accuracy: 0.01)
    }

    // MARK: - 3-digit Hex Color Tests

    func testHexColor3DigitRed() {
        let color = UIColor.colorWithHexString("#F00", alpha: 1.0)
        XCTAssertNotNil(color)

        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 1.0, accuracy: 0.01)
        XCTAssertEqual(green, 0.0, accuracy: 0.01)
        XCTAssertEqual(blue, 0.0, accuracy: 0.01)
    }

    func testHexColor3DigitWhite() {
        let color = UIColor.colorWithHexString("#FFF", alpha: 1.0)
        XCTAssertNotNil(color)

        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 1.0, accuracy: 0.01)
        XCTAssertEqual(green, 1.0, accuracy: 0.01)
        XCTAssertEqual(blue, 1.0, accuracy: 0.01)
    }

    // MARK: - Alpha Parameter Tests

    func testHexColorWithCustomAlpha() {
        let color = UIColor.colorWithHexString("#FF0000", alpha: 0.5)

        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(alpha, 0.5, accuracy: 0.01)
    }

    // MARK: - Invalid Input Tests

    func testHexColorInvalidString() {
        let color = UIColor.colorWithHexString("invalid")
        XCTAssertNil(color)
    }

    func testHexColorInvalidLength() {
        let color = UIColor.colorWithHexString("#FF00")
        XCTAssertNil(color)
    }

    func testHexColorEmptyString() {
        let color = UIColor.colorWithHexString("")
        XCTAssertNil(color)
    }

    // MARK: - Whitespace Handling Tests

    func testHexColorWithLeadingWhitespace() {
        let color = UIColor.colorWithHexString("  #FF0000")
        XCTAssertNotNil(color)
    }

    func testHexColorWithTrailingWhitespace() {
        let color = UIColor.colorWithHexString("#FF0000  ")
        XCTAssertNotNil(color)
    }
}
