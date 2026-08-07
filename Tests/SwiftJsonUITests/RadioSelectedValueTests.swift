//
//  RadioSelectedValueTests.swift
//  SwiftJsonUITests
//
//  A LITERAL `selectedValue` names the group's starting option. Only the bound
//  spelling was read, so the group seeded empty and nothing drew selected —
//  `Radio/selectedValue__gamma`, inert on the ios dynamic path (51-E2 §2).
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class RadioSelectedValueTests: XCTestCase {

    private func radio(_ dict: [String: Any]) -> DynamicComponent {
        var d: [String: Any] = ["type": "Radio", "items": ["alpha", "beta", "gamma"]]
        d.merge(dict) { _, new in new }
        let data = try! JSONSerialization.data(withJSONObject: d)
        return try! JSONDecoder().decode(DynamicComponent.self, from: data)
    }

    func testLiteralSelectedValueIsReadable() {
        let c = radio(["selectedValue": "gamma"])
        XCTAssertEqual(c.typedAttributes(RadioAttributes.self).selectedValue?.value, "gamma")
    }

    // Both rungs of the precedence have to stay distinguishable: a bound
    // spelling carries an expression and no literal, so seeding from `.value`
    // must not pick up "@{…}" as if it were an option name.
    func testBoundSelectedValueCarriesNoLiteral() {
        let c = radio(["selectedValue": "@{chosen}"])
        let attr = c.typedAttributes(RadioAttributes.self).selectedValue
        XCTAssertEqual(attr?.bindingExpression, "chosen")
        XCTAssertNil(attr?.value, "a bound spelling must not seed the group as a literal option")
    }

    func testAbsentSelectedValueSeedsNothing() {
        let c = radio([:])
        XCTAssertNil(c.typedAttributes(RadioAttributes.self).selectedValue)
    }
}
#endif
