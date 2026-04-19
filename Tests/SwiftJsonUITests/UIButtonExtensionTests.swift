//
//  UIButtonExtensionTests.swift
//  SwiftJsonUI
//

import XCTest
@testable import SwiftJsonUI

final class UIButtonExtensionTests: XCTestCase {

    func testHighlightChangesBackgroundColor() {
        let button = UIButton()
        button.defaultBackgroundColor = .blue
        button.tapBackgroundColor = .red

        XCTAssertNil(button.backgroundColor)

        // Simulate highlight
        button.isHighlighted = true
        XCTAssertEqual(button.backgroundColor, .red)

        // Simulate release
        button.isHighlighted = false
        XCTAssertEqual(button.backgroundColor, .blue)
    }

    func testHighlightWithOnlyDefaultBackground() {
        let button = UIButton()
        button.defaultBackgroundColor = .blue

        button.isHighlighted = true
        // When defaultBackgroundColor is set, tapBackgroundColor is auto-generated
        // The implementation creates a darker version of the default color
        XCTAssertNotNil(button.tapBackgroundColor)

        button.isHighlighted = false
        XCTAssertEqual(button.backgroundColor, .blue)
    }

    func testHighlightWithOnlyTapBackground() {
        let button = UIButton()
        button.tapBackgroundColor = .red

        button.isHighlighted = true
        XCTAssertEqual(button.backgroundColor, .red)

        button.isHighlighted = false
        // defaultBackgroundColor is nil, so background should not change
        XCTAssertNil(button.defaultBackgroundColor)
    }

    func testHighlightWithNoBackgrounds() {
        let button = UIButton()

        // Should not crash when both are nil
        button.isHighlighted = true
        button.isHighlighted = false

        XCTAssertNil(button.defaultBackgroundColor)
        XCTAssertNil(button.tapBackgroundColor)
    }

    func testMultipleHighlightToggles() {
        let button = UIButton()
        button.defaultBackgroundColor = .green
        button.tapBackgroundColor = .yellow

        for _ in 0..<5 {
            button.isHighlighted = true
            XCTAssertEqual(button.backgroundColor, .yellow)

            button.isHighlighted = false
            XCTAssertEqual(button.backgroundColor, .green)
        }
    }
}
