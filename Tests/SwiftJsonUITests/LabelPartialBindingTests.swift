import XCTest
import SwiftUI
@testable import SwiftJsonUI

/// partialAttributes value slots are binding-capable, and the dynamic path
/// reads them from raw JSON maps — so every slot must resolve `@{...}`
/// before use. The raw spelling went to the pattern match and the colour
/// parser untouched, which made a bound `range` never match (the partial
/// silently vanished) and a bound fontColor style nothing, while the
/// codegen path interpolates at render time
/// (a downstream hour-row cell, 2026-08-08).
final class LabelPartialBindingTests: XCTestCase {
    private let data: [String: Any] = [
        "overrideBoldRange": "(本日)",
        "overrideBoldColor": "gold",
        "emphasis": ""
    ]

    func testBoundSlotResolvesToTheDataValue() {
        XCTAssertEqual(
            LabelConverter.resolvePartialString("@{overrideBoldRange}", data: data),
            "(本日)"
        )
        XCTAssertEqual(
            LabelConverter.resolvePartialString("@{overrideBoldColor}", data: data),
            "gold"
        )
    }

    func testStaticSlotPassesThrough() {
        XCTAssertEqual(LabelConverter.resolvePartialString("#FF0000", data: data), "#FF0000")
    }

    func testUnresolvableBindingYieldsNilNeverTheSpelling() {
        XCTAssertNil(LabelConverter.resolvePartialString("@{missing}", data: data))
    }

    func testPartialLineReaderHonoursTheObjectFace() {
        // Same textDecoration contract as the Label body: the object face
        // draws unless lineStyle is None; `as? Bool` alone forced every
        // styled object to false (the android mirror fixed this in 4a4a810).
        XCTAssertTrue(LabelConverter.drawsLine(true))
        XCTAssertFalse(LabelConverter.drawsLine(false))
        XCTAssertTrue(LabelConverter.drawsLine(["lineStyle": "Single", "color": "#FF0000"]))
        XCTAssertFalse(LabelConverter.drawsLine(["lineStyle": "None"]))
        XCTAssertFalse(LabelConverter.drawsLine(nil))
    }
}
