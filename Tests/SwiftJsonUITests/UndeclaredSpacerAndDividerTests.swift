//
//  UndeclaredSpacerAndDividerTests.swift
//  SwiftJsonUITests
//
//  Spacer, Space, Divider and Separator are not component types: neither
//  attribute_definitions.json nor component_metadata.json declares any of
//  them. sjui codegen sends all four spellings to DefaultConverter — the red
//  "Unsupported component" Text, the same as any undeclared type; rjui warns
//  and draws a plain View; KotlinJsonUI's Dynamic has no case for them. The
//  Dynamic runtime here was the one face that drew them (a SwiftUI Spacer, a
//  Divider), so DEBUG showed a screen the release build does not.
//
//  They now go where an undeclared type goes: a registered custom adapter,
//  else the "Unknown component type" box — the order codegen resolves a type
//  in (custom converters first, then DefaultConverter).
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class UndeclaredSpacerAndDividerTests: XCTestCase {

    /// What the builder builds for `type`, as `dump` prints it, with object
    /// numbers and addresses taken off.
    private func built(_ type: String) throws -> String {
        let json = ##"{"type": "\##(type)", "id": "probe", "width": 40, "height": 1, "background": "#CCCCCC"}"##
        let c = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        var out = ""
        dump(DynamicComponentBuilder(component: c, data: [:]).buildView(from: c), to: &out)
        return out
            .replacingOccurrences(of: #"#\d+"#, with: "#", options: .regularExpression)
            .replacingOccurrences(of: #"0x[0-9a-f]+"#, with: "0x", options: .regularExpression)
    }

    func testEachSpellingBuildsWhatAnUndeclaredTypeBuilds() throws {
        let undeclared = try built("Bogus")
        XCTAssertTrue(undeclared.contains("Unknown component type 'Bogus'"),
                      "control: an undeclared type no longer builds the unknown-type box")
        // Control: a declared type builds something else, so the comparison
        // below can tell two sources apart.
        XCTAssertNotEqual(try built("Label").replacingOccurrences(of: "Label", with: "Bogus"), undeclared,
                          "control: Label builds the same as an undeclared type — this comparison cannot see a difference")

        for spelling in ["Spacer", "Space", "Divider", "Separator", "spacer", "divider"] {
            XCTAssertEqual(try built(spelling).replacingOccurrences(of: spelling, with: "Bogus"), undeclared,
                           "\(spelling) builds something an undeclared type does not — codegen draws it as an unsupported component")
        }
    }
}
#endif
