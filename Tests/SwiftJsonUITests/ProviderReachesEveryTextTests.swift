//
//  ProviderReachesEveryTextTests.swift
//  SwiftJsonUITests
//
//  P1 (ruling 2026-11-13, ticket sjui-label-font-size-ignores-dynamic-type): every text goes through the app's
//  fontProvider, a component with no fontSize included. TextField, Radio, Switch and CheckBox set no font of their
//  own then and drew SwiftUI's .body, whatever the provider said. A provider that answers a 48pt font makes the
//  difference a height: the old components stayed at .body's line.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

final class ProviderReachesEveryTextTests: XCTestCase {
    private var savedProvider: ((FontSpec) -> Font?)?

    override func setUp() {
        super.setUp()
        savedProvider = SwiftJsonUIConfiguration.shared.fontProvider
        SwiftJsonUIConfiguration.shared.fontProvider = { _ in Font.custom("Courier", size: 48) }
    }

    override func tearDown() {
        SwiftJsonUIConfiguration.shared.fontProvider = savedProvider
        super.tearDown()
    }

    private func height(_ json: String) throws -> CGFloat {
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        let host = UIHostingController(rootView: DynamicComponentBuilder(component: component, data: ["t": "Sample"]))
        return host.sizeThatFits(in: CGSize(width: 320, height: 600)).height
    }

    func testATextFieldWithNoFontSizeIsTheProvidersFont() throws {
        XCTAssertGreaterThan(try height(#"{ "type": "TextField", "id": "f", "width": 300, "text": "@{t}" }"#), 40)
    }

    func testARadioWithNoFontSizeIsTheProvidersFont() throws {
        XCTAssertGreaterThan(try height(#"{ "type": "Radio", "id": "r", "width": 300, "text": "Sample", "group": "g" }"#), 40)
    }

    func testASwitchWithNoFontSizeIsTheProvidersFont() throws {
        XCTAssertGreaterThan(try height(#"{ "type": "Switch", "id": "s", "width": 300, "text": "Sample" }"#), 40)
    }

    func testACheckBoxWithNoFontSizeIsTheProvidersFont() throws {
        XCTAssertGreaterThan(try height(#"{ "type": "CheckBox", "id": "c", "width": 300, "text": "Sample" }"#), 40)
    }

    func testALabelWithNoFontSizeWasAlreadyTheProvidersFont() throws {
        XCTAssertGreaterThan(try height(#"{ "type": "Label", "id": "l", "width": 300, "text": "Sample" }"#), 40)
    }
}
