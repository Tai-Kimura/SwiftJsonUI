//
//  SelectBoxContentHeightTests.swift
//  SwiftJsonUITests
//
//  A SelectBox of no height, or wrapContent with no min / max, takes its content's height (ticket
//  kjui-selectbox-fixed-56dp-ignores-wrap-content-height, ruling 2026-11-13): SelectBoxView fills the height it is
//  offered, so before the fix it took all the height a stack offered it. Its default insets are 0 above and below
//  on every face (ruling 2026-11-13), so the three draw the same height.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

final class SelectBoxContentHeightTests: XCTestCase {

    private func height(of json: String, offered: CGFloat = 600) throws -> CGFloat {
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        let host = UIHostingController(rootView: DynamicComponentBuilder(component: component, data: [:]))
        return host.sizeThatFits(in: CGSize(width: 300, height: offered)).height
    }

    func testANoHeightSelectBoxTakesItsContentHeight() throws {
        let h = try height(of: #"{ "type": "SelectBox", "width": 240, "items": ["One"], "selectedIndex": 0 }"#)
        XCTAssertLessThan(h, 100, "it took the offered height: \(h)")
        XCTAssertGreaterThanOrEqual(h, 12, "a line, nothing above or below by default: \(h)")
    }

    func testAWrapContentSelectBoxTakesItsContentHeight() throws {
        let h = try height(of: #"{ "type": "SelectBox", "width": 240, "height": "wrapContent", "items": ["One"], "selectedIndex": 0 }"#)
        XCTAssertLessThan(h, 100, "it took the offered height: \(h)")
    }

    func testAFixedHeightIsKept() throws {
        let h = try height(of: #"{ "type": "SelectBox", "width": 240, "height": 48, "items": ["One"], "selectedIndex": 0 }"#)
        XCTAssertEqual(h, 48, accuracy: 0.5)
    }

    func testAMinHeightIsTheFloor() throws {
        let h = try height(of: #"{ "type": "SelectBox", "width": 240, "height": "wrapContent", "minHeight": 56, "items": ["One"], "selectedIndex": 0 }"#)
        XCTAssertEqual(h, 56, accuracy: 0.5)
    }

    func testTheDefaultInsetsAreZeroAboveAndBelow() {
        let insets = SelectBoxView().contentInsets
        XCTAssertEqual(insets.top, 0)
        XCTAssertEqual(insets.bottom, 0)
        XCTAssertEqual(insets.leading, 12)
    }

    /// The insets side by side: the default, then `padding`, then `paddings`, then each side's key; a side nothing
    /// names keeps the default (selectbox_converter.rb the same).
    func testTheInsetsAreWorkedOutSideBySide() throws {
        func insets(_ json: String) throws -> EdgeInsets? {
            let c = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
            return SelectBoxConverter.padding(c, data: [:])
        }
        XCTAssertNil(try insets(#"{ "type": "SelectBox" }"#))
        XCTAssertEqual(try insets(#"{ "type": "SelectBox", "padding": 10 }"#), EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
        XCTAssertEqual(try insets(#"{ "type": "SelectBox", "paddings": [4, 6] }"#), EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
        XCTAssertEqual(try insets(#"{ "type": "SelectBox", "paddingTop": 2 }"#), EdgeInsets(top: 2, leading: 12, bottom: 0, trailing: 12))
        XCTAssertEqual(try insets(#"{ "type": "SelectBox", "padding": 10, "paddingLeft": 3 }"#), EdgeInsets(top: 10, leading: 3, bottom: 10, trailing: 10))
    }

    /// The caret's box (16, or the declared width / height) sits the trailing inset from the edge, 8 after the text.
    func testTheCaretBoxAndGap() {
        XCTAssertEqual(SelectBoxView.caretBox, 16)
        XCTAssertEqual(SelectBoxView.caretGap, 8)
        XCTAssertEqual(SelectBoxView(caret: .init(rightMargin: 20)).contentInsets.trailing, 20)
    }
}
