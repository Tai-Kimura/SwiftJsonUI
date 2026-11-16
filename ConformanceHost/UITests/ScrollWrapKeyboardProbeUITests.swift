//
//  ScrollWrapKeyboardProbeUITests.swift
//  ConformanceHostUITests
//
//  A focused text field at the bottom of a vertical ScrollView of height
//  wrapContent still settles above the keyboard, as it does in a matchParent
//  one (ScrollWrapKeyboardProbeView). The ScrollView of height wrapContent
//  is framed at its content's height, less when its parent offers less
//  (jsonui-cli ticket sjui-vertical-scrollview-wrapcontent-height-is-10pt):
//  with the keyboard up its parent offers less and it must scroll the field
//  up. NOT opt-in; it needs the software keyboard (no hardware keyboard on
//  the simulator).
//

import XCTest

final class ScrollWrapKeyboardProbeUITests: XCTestCase {
    private func settledBottom(_ field: XCUIElement) -> CGFloat {
        var last = field.frame.maxY
        var still = 0
        for _ in 0..<60 {
            usleep(250_000)
            let now = field.frame.maxY
            still = abs(now - last) <= 0.5 ? still + 1 : 0
            last = now
            if still >= 4 { break }
        }
        return last
    }

    private func measure(_ variant: String) -> (fieldBottom: CGFloat, keyboardTop: CGFloat) {
        let app = XCUIApplication()
        app.launchArguments = ["-scrollWrapKeyboardProbe", variant]
        app.launch()
        XCTAssertFalse(app.staticTexts["swk_decode_failed"].exists, "the layout did not decode")
        let field = app.textFields["swk_field"]
        XCTAssertTrue(field.waitForExistence(timeout: 15), "\(variant): the field is not drawn")
        let keyboard = app.keyboards.firstMatch
        for _ in 0..<3 where !keyboard.exists {
            field.tap()
            _ = keyboard.waitForExistence(timeout: 5)
        }
        XCTAssertTrue(keyboard.exists, "no software keyboard — a hardware keyboard is attached to the simulator")
        let bottom = settledBottom(field)
        let top = keyboard.frame.minY
        print("SWK \(variant) fieldBottom=\(Int(bottom.rounded())) keyboardTop=\(Int(top.rounded()))")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "scroll_wrap_keyboard_\(variant)"
        shot.lifetime = .keepAlways
        add(shot)
        app.terminate()
        return (bottom, top)
    }

    func testAFocusedFieldInAWrapContentScrollViewSettlesAboveTheKeyboard() {
        let wrap = measure("wrap")
        let match = measure("match")
        XCTAssertLessThanOrEqual(wrap.fieldBottom, wrap.keyboardTop, "wrapContent: the field is under the keyboard")
        XCTAssertLessThanOrEqual(match.fieldBottom, match.keyboardTop, "matchParent: the field is under the keyboard")
        XCTAssertEqual(wrap.fieldBottom, match.fieldBottom, accuracy: 1, "the field settles where the matchParent one does")
    }
}
