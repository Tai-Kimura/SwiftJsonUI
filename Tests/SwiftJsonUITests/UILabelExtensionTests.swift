//
//  UILabelExtensionTests.swift
//  SwiftJsonUITests
//
//  Tests for UILabel extension methods
//

import XCTest
@testable import SwiftJsonUI

final class UILabelExtensionTests: XCTestCase {

    // MARK: - Line Number Tests

    func testLineNumberSingleLine() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 50))
        label.text = "Hello"
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0

        let lineCount = label.lineNumber()
        XCTAssertEqual(lineCount, 1)
    }

    func testLineNumberMultipleLines() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 200))
        label.text = "This is a very long text that will wrap to multiple lines when displayed in a narrow label"
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0

        let lineCount = label.lineNumber()
        XCTAssertGreaterThan(lineCount, 1)
    }

    func testLineNumberEmptyText() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 50))
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0

        let lineCount = label.lineNumber()
        XCTAssertGreaterThanOrEqual(lineCount, 0)
    }

    func testLineNumberShortText() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 50))
        label.text = "Short"
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0

        let lineCount = label.lineNumber()
        XCTAssertEqual(lineCount, 1)
    }

    func testLineNumberDifferentFonts() {
        let label1 = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 200))
        label1.text = "This is a long text"
        label1.font = UIFont.systemFont(ofSize: 12)
        label1.numberOfLines = 0

        let label2 = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 200))
        label2.text = "This is a long text"
        label2.font = UIFont.systemFont(ofSize: 24)
        label2.numberOfLines = 0

        let lineCount1 = label1.lineNumber()
        let lineCount2 = label2.lineNumber()

        // Larger font should result in more lines with same width
        XCTAssertGreaterThanOrEqual(lineCount2, lineCount1)
    }

    func testLineNumberWideLabel() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 500, height: 100))
        label.text = "This text fits in one line"
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0

        let lineCount = label.lineNumber()
        XCTAssertEqual(lineCount, 1)
    }

    func testLineNumberNarrowLabel() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 200))
        label.text = "This text will wrap to many lines"
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0

        let lineCount = label.lineNumber()
        XCTAssertGreaterThan(lineCount, 3)
    }
}
