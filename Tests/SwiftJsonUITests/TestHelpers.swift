//
//  TestHelpers.swift
//  SwiftJsonUITests
//
//  Helper utilities for testing
//

import Foundation
import XCTest

/// Helper class for loading test fixtures
class TestFixtures {

    /// Load JSON data from the Fixtures directory
    static func loadJSON(named name: String) throws -> Data {
        let bundle = Bundle(for: TestFixtures.self)

        // Try to find the file in the bundle
        if let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") {
            return try Data(contentsOf: url)
        }

        // Fallback: try to find the file directly in the test sources
        let testDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
        let fixtureURL = testDir.appendingPathComponent("Fixtures/\(name).json")

        if FileManager.default.fileExists(atPath: fixtureURL.path) {
            return try Data(contentsOf: fixtureURL)
        }

        throw TestError.fixtureNotFound(name)
    }

    /// Load JSON and decode to specified type
    static func loadAndDecode<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
        let data = try loadJSON(named: name)
        return try JSONDecoder().decode(type, from: data)
    }
}

/// Test-specific errors
enum TestError: Error, LocalizedError {
    case fixtureNotFound(String)

    var errorDescription: String? {
        switch self {
        case .fixtureNotFound(let name):
            return "Test fixture not found: \(name).json"
        }
    }
}

/// Extension for testing color equality
extension XCTestCase {

    /// Assert two colors are equal within a tolerance
    func assertColorsEqual(_ color1: UIColor?, _ color2: UIColor?, accuracy: CGFloat = 0.01, file: StaticString = #file, line: UInt = #line) {
        guard let c1 = color1, let c2 = color2 else {
            if color1 == nil && color2 == nil {
                return
            }
            XCTFail("One color is nil: \(String(describing: color1)) vs \(String(describing: color2))", file: file, line: line)
            return
        }

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        XCTAssertEqual(r1, r2, accuracy: accuracy, "Red component mismatch", file: file, line: line)
        XCTAssertEqual(g1, g2, accuracy: accuracy, "Green component mismatch", file: file, line: line)
        XCTAssertEqual(b1, b2, accuracy: accuracy, "Blue component mismatch", file: file, line: line)
        XCTAssertEqual(a1, a2, accuracy: accuracy, "Alpha component mismatch", file: file, line: line)
    }
}
