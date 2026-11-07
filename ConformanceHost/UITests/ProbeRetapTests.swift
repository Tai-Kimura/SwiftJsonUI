import XCTest

/// ProbeRetap, without the app: a lost touch is sent once more and said, one per test.
final class ProbeRetapTests: XCTestCase {
    private func make() -> (ProbeRetap, () -> [String]) {
        var said: [String] = []
        return (ProbeRetap("Unit", log: { said.append($0) }), { said })
    }

    func testALostTouchIsSentOnceMoreAndSaid() {
        let (retap, said) = make()
        var touches = 0, on = false
        XCTAssertTrue(retap.tap("sw", until: { on }, wait: 0.05) { touches += 1; if touches == 2 { on = true } })
        XCTAssertEqual(touches, 2)
        XCTAssertEqual(said().count, 1)
        XCTAssertTrue(said()[0].hasPrefix("PROBE_RETAP Unit sw: no effect"), "\(said())")
    }

    func testATouchThatLandsIsNotRepeated() {
        let (retap, said) = make()
        var touches = 0, on = false
        XCTAssertFalse(retap.tap("sw", until: { on }, wait: 0.05) { touches += 1; on = true })
        XCTAssertEqual(touches, 1)
        XCTAssertEqual(said(), [])
    }

    func testOnlyOneRetapInATest() {
        let (retap, said) = make()
        var touches = 0
        XCTAssertTrue(retap.tap("a", until: { touches == 2 }, wait: 0.05) { touches += 1 })
        touches = 0
        XCTAssertFalse(retap.tap("b", until: { false }, wait: 0.05) { touches += 1 })
        XCTAssertEqual(touches, 1, "the second lost touch is not sent again")
        XCTAssertTrue(said().last?.contains("already retapped a") == true, "\(said())")
    }

    func testASecondTouchThatShowsNothingIsSaid() {
        let (retap, said) = make()
        var touches = 0
        XCTAssertTrue(retap.tap("a", until: { false }, wait: 0.05) { touches += 1 })
        XCTAssertEqual(touches, 2, "and no third")
        XCTAssertTrue(said().last?.contains("the second touch showed nothing either") == true, "\(said())")
    }

    func testTheWindowsLogSaysATouchWasNotDelivered() {
        let (retap, said) = make()
        var touches = 0
        let log = "120.00,300.00 #4"
        XCTAssertTrue(retap.tap("a", until: { touches == 2 }, wait: 0.05, window: { log }) { touches += 1 })
        XCTAssertEqual(touches, 2, "the retap is the same with the window read")
        XCTAssertTrue(said()[0].hasSuffix("— touched once more; the app's window saw no touch either: not delivered"), "\(said())")
    }

    func testTheWindowsLogSaysATouchArrivedLate() {
        let (retap, said) = make()
        var touches = 0, log = "120.00,300.00 #4"
        XCTAssertTrue(retap.tap("a", until: { touches == 2 }, wait: 0.05, window: { log }) { touches += 1; log = "10.00,20.00 #\(4 + touches)" })
        XCTAssertTrue(said()[0].hasSuffix("; the app's window saw that touch (10.00,20.00 #5): delivered, its effect late or elsewhere"), "\(said())")
    }

    func testAWindowLogNeverInstalledSaysNothingOfTheTouch() {
        let (retap, said) = make()
        var touches = 0
        XCTAssertTrue(retap.tap("a", until: { touches == 2 }, wait: 0.05, window: { ProbeRetap.unread }) { touches += 1 })
        XCTAssertTrue(said()[0].hasSuffix("; the app's window logs no touches (its log was not installed): delivery unknown"), "\(said())")
    }

    func testAWindowLogInstalledBetweenTheReadsSaysNothingOfTheTouch() {
        XCTAssertEqual(ProbeRetap.saw(before: ProbeRetap.unread, after: "no touch yet"),
                       "; the app's window logs no touches (its log was not installed): delivery unknown")
    }

    func testARefusedRetapSaysTheWindowToo() {
        let (retap, said) = make()
        var touches = 0
        XCTAssertTrue(retap.tap("a", until: { touches == 2 }, wait: 0.05) { touches += 1 })
        XCTAssertFalse(retap.tap("b", until: { false }, wait: 0.05, window: { "1.00,1.00 #1" }) { touches += 1 })
        XCTAssertTrue(said().last?.hasSuffix("— not tapped again; the app's window saw no touch either: not delivered") == true, "\(said())")
        XCTAssertFalse(said()[0].contains("window"), "no window, no word of it: \(said())")
    }

    func testSpendSaysOnceThenRefuses() {
        let (retap, said) = make()
        XCTAssertTrue(retap.spend("x"))
        XCTAssertFalse(retap.spend("y"))
        XCTAssertEqual(retap.spentOn, "x")
        XCTAssertEqual(said().count, 2)
    }
}
