//
//  LoggerTests.swift
//  SwiftJsonUI
//

import XCTest
@testable import SwiftJsonUI

final class LoggerTests: XCTestCase {

    func testLogFunctionDoesNotThrow() {
        XCTAssertNoThrow(Logger.log("Test message"))
        XCTAssertNoThrow(Logger.log("Multiple", "arguments"))
        XCTAssertNoThrow(Logger.log(1, 2, 3))
    }

    func testDebugFunctionDoesNotThrow() {
        XCTAssertNoThrow(Logger.debug("Debug message"))
        XCTAssertNoThrow(Logger.debug("Multiple", "debug", "arguments"))
        XCTAssertNoThrow(Logger.debug(100, "test"))
    }

    func testLogWithDifferentTypes() {
        XCTAssertNoThrow(Logger.log("String"))
        XCTAssertNoThrow(Logger.log(42))
        XCTAssertNoThrow(Logger.log(3.14))
        XCTAssertNoThrow(Logger.log(true))
        XCTAssertNoThrow(Logger.log(["array", "of", "strings"]))
        XCTAssertNoThrow(Logger.log(["key": "value"]))
    }

    func testDebugWithDifferentTypes() {
        XCTAssertNoThrow(Logger.debug("String"))
        XCTAssertNoThrow(Logger.debug(42))
        XCTAssertNoThrow(Logger.debug(3.14))
        XCTAssertNoThrow(Logger.debug(false))
        XCTAssertNoThrow(Logger.debug(["array"]))
    }

    func testLogWithNoArguments() {
        XCTAssertNoThrow(Logger.log())
    }

    func testDebugWithNoArguments() {
        XCTAssertNoThrow(Logger.debug())
    }
}
