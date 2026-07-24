//
//  DynamicShadowTests.swift
//  SwiftJsonUI
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class DynamicShadowTests: XCTestCase {

    // MARK: - String Shadow Tests

    func testDefaultShadow() throws {
        let json = """
        "default"
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let shadow = try decoder.decode(DynamicShadow.self, from: json)

        XCTAssertEqual(shadow.shadowRadius, 4)
        XCTAssertEqual(shadow.shadowOffset, CGSize(width: 0, height: 2))
    }

    func testLightShadow() throws {
        let json = """
        "light"
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let shadow = try decoder.decode(DynamicShadow.self, from: json)

        XCTAssertEqual(shadow.shadowRadius, 4)
        XCTAssertEqual(shadow.shadowOffset, CGSize(width: 0, height: 2))
    }

    func testDarkShadow() throws {
        let json = """
        "dark"
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let shadow = try decoder.decode(DynamicShadow.self, from: json)

        XCTAssertEqual(shadow.shadowRadius, 8)
        XCTAssertEqual(shadow.shadowOffset, CGSize(width: 0, height: 2))
    }

    func testNoneShadow() throws {
        let json = """
        "none"
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let shadow = try decoder.decode(DynamicShadow.self, from: json)

        XCTAssertEqual(shadow.shadowRadius, 0)
        XCTAssertEqual(shadow.shadowOffset, CGSize.zero)
    }

    func testCustomColorStringShadow() throws {
        let json = """
        "#FF0000"
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let shadow = try decoder.decode(DynamicShadow.self, from: json)

        XCTAssertEqual(shadow.shadowRadius, 4)
        XCTAssertEqual(shadow.shadowOffset, CGSize(width: 0, height: 2))
    }

    // MARK: - Config Shadow Tests

    func testConfigShadowWithAllProperties() throws {
        let json = """
        {
            "color": "#FF0000",
            "opacity": 0.5,
            "radius": 10,
            "x": 5,
            "y": 5
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let shadow = try decoder.decode(DynamicShadow.self, from: json)

        XCTAssertEqual(shadow.shadowRadius, 10)
        XCTAssertEqual(shadow.shadowOffset, CGSize(width: 5, height: 5))
    }

    func testConfigShadowWithDefaultValues() throws {
        let json = """
        {}
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let shadow = try decoder.decode(DynamicShadow.self, from: json)

        XCTAssertEqual(shadow.shadowRadius, 4)
        XCTAssertEqual(shadow.shadowOffset, CGSize(width: 0, height: 2))
    }

    func testConfigShadowWithPartialProperties() throws {
        let json = """
        {
            "radius": 6,
            "x": 3
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let shadow = try decoder.decode(DynamicShadow.self, from: json)

        XCTAssertEqual(shadow.shadowRadius, 6)
        XCTAssertEqual(shadow.shadowOffset, CGSize(width: 3, height: 2))
    }

    func testConfigShadowWithNullValues() throws {
        let json = """
        {
            "color": null,
            "opacity": null,
            "radius": null,
            "x": null,
            "y": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let shadow = try decoder.decode(DynamicShadow.self, from: json)

        XCTAssertEqual(shadow.shadowRadius, 4)
        XCTAssertEqual(shadow.shadowOffset, CGSize(width: 0, height: 2))
    }

    // MARK: - ShadowConfig Tests

    func testShadowConfigInitialization() {
        let config = ShadowConfig()

        XCTAssertEqual(config.color, "#000000")
        XCTAssertEqual(config.opacity, 0.1)
        XCTAssertEqual(config.radius, 4)
        XCTAssertEqual(config.x, 0)
        XCTAssertEqual(config.y, 2)
    }

    func testShadowConfigCustomInitialization() {
        let config = ShadowConfig(
            color: "#FF0000",
            opacity: 0.5,
            radius: 8,
            x: 2,
            y: 4
        )

        XCTAssertEqual(config.color, "#FF0000")
        XCTAssertEqual(config.opacity, 0.5)
        XCTAssertEqual(config.radius, 8)
        XCTAssertEqual(config.x, 2)
        XCTAssertEqual(config.y, 4)
    }

    // MARK: - Edge Cases

    func testConfigShadowWithZeroOpacity() throws {
        let json = """
        {
            "opacity": 0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let shadow = try decoder.decode(DynamicShadow.self, from: json)

        XCTAssertEqual(shadow.shadowRadius, 4)
    }

    func testConfigShadowWithNegativeOffset() throws {
        let json = """
        {
            "x": -5,
            "y": -10
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let shadow = try decoder.decode(DynamicShadow.self, from: json)

        XCTAssertEqual(shadow.shadowOffset, CGSize(width: -5, height: -10))
    }

    func testConfigShadowWithLargeRadius() throws {
        let json = """
        {
            "radius": 100
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let shadow = try decoder.decode(DynamicShadow.self, from: json)

        XCTAssertEqual(shadow.shadowRadius, 100)
    }

    func testCaseInsensitiveStringShadow() throws {
        let json = """
        "DEFAULT"
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let shadow = try decoder.decode(DynamicShadow.self, from: json)

        XCTAssertEqual(shadow.shadowRadius, 4)
    }

    func testUnknownStringShadow() throws {
        let json = """
        "unknown"
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let shadow = try decoder.decode(DynamicShadow.self, from: json)

        // Should fall back to default values
        XCTAssertEqual(shadow.shadowRadius, 4)
        XCTAssertEqual(shadow.shadowOffset, CGSize(width: 0, height: 2))
    }
}
#endif
