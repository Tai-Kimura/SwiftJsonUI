import XCTest

/// InteractionGateProbeUITests.tapControl, without the app: a lost first tap is tapped again and said; a
/// tap that switched is not.
final class InteractionGateRetapTests: XCTestCase {
    func testALostTapOnAControlIsTappedOnceMoreAndSaid() {
        var value = "0", taps = 0, said: [String] = []
        let again = InteractionGateProbeUITests.tapControl(
            "swUiePlain", read: { value }, tap: { taps += 1; if taps == 2 { value = "1" } }, wait: 0.05,
            log: { said.append($0) })
        XCTAssertTrue(again)
        XCTAssertEqual(taps, 2)
        XCTAssertEqual(value, "1")
        XCTAssertEqual(said.count, 1)
        XCTAssertTrue(said.first?.hasPrefix("GATE_PROBE retap swUiePlain: its value stayed 0") == true, "\(said)")
    }

    func testATapThatSwitchesIsNotRepeated() {
        var value = "0", taps = 0, said: [String] = []
        let again = InteractionGateProbeUITests.tapControl(
            "dynSwPlain", read: { value }, tap: { taps += 1; value = "1" }, wait: 0.05, log: { said.append($0) })
        XCTAssertFalse(again)
        XCTAssertEqual(taps, 1)
        XCTAssertEqual(said, [])
    }
}
