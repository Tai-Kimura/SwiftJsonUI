import XCTest
import UIKit

/// Two stateful controls with no id keep a state each, on both paths
/// (StateNamesProbeView; ticket sjui-codegen-state-declarations-collide-by-name).
/// Each pair is operated on its first member only, and the second must not
/// move: two Switches, two CheckBoxes, two Segments, two Sliders, two
/// TextFields, two Radios over items. A Radio group of two id-less Radios
/// selects the one tapped and not the other (h), and a group whose first Radio
/// is `checked` hands the selection to the second when it is tapped (g) — it
/// did not compile through sjui build, the checked seed beside the other's "".
/// Every glyph and control is read where it is, before and after: moved or
/// not.
///
/// Opt-in, like the other probes: TEST_RUNNER_STATE_NAMES_PROBE=1.
final class StateNamesProbeUITests: XCTestCase {
    private var app: XCUIApplication!

    func testIdlessControlsKeepAStateEach() throws {
        guard ProcessInfo.processInfo.environment["STATE_NAMES_PROBE"] == "1" else {
            throw XCTSkip("state names probe: run with the guard lifted, as the other probes are")
        }
        continueAfterFailure = true
        let paths = (ProcessInfo.processInfo.environment["STATE_NAMES_PATHS"] ?? "dynamic,component,codegen").split(separator: ",").map(String.init)
        for path in paths { run(path) }
    }

    private func labelled(_ label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    /// The glyph of a Radio: the first 24 pt of a group Radio's row (the row
    /// is its element), or the 24 pt left of an item's text.
    private func glyph(_ label: String, row: Bool) -> CGRect {
        let f = labelled(label).frame
        return row ? CGRect(x: f.minX, y: f.minY, width: 24, height: f.height)
                   : CGRect(x: f.minX - 26, y: f.minY, width: 24, height: f.height)
    }

    private func run(_ path: String) {
        app = XCUIApplication()
        app.launchArguments = ["-stateNamesProbe", path]
        app.launch()
        XCTAssertTrue(app.staticTexts["sn_ready"].waitForExistence(timeout: 15), "\(path): probe did not start")
        XCTAssertFalse(app.staticTexts["sn_decode_failed"].exists, "\(path): the layout did not decode")
        XCTAssertTrue(app.switches.element(boundBy: 1).waitForExistence(timeout: 5), "\(path): the controls are there")
        sleep(1)

        // Each Radio's glyph is read before and after, where it is: a glyph
        // moved or it did not (rows at different heights do not draw one
        // glyph to the same pixels, so glyphs are not compared across rows).
        let radios: [(String, Bool)] = [("h1", true), ("h2", true), ("g1", true), ("g2", true),
                                        ("i1", false), ("i2", false), ("j1", false), ("j2", false)]
        var shot = XCUIScreen.main.screenshot().image
        let glyphsBefore = Dictionary(uniqueKeysWithValues: radios.map { ($0.0, digest(shot, glyph($0.0, row: $0.1))) })
        let sw = (0...1).map { "\(app.switches.element(boundBy: $0).value ?? "nil")" }
        let cb = (0...1).map { digest(shot, labelled("c\($0 + 1)").frame) }
        let sl = (0...1).map { "\(app.sliders.element(boundBy: $0).value ?? "nil")" }

        app.switches.element(boundBy: 0).tap()
        labelled("c1").tap()
        app.buttons["a2"].tap()
        app.sliders.element(boundBy: 0).adjust(toNormalizedSliderPosition: 0.8)
        // A Radio is tapped on its glyph — the one place both paths take it.
        for label in ["h2", "g2", "j2"] {
            let g = glyph(label, row: label != "j2")
            app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: g.midX, dy: g.midY)).tap()
        }
        sleep(1)

        shot = XCUIScreen.main.screenshot().image
        let sw2 = (0...1).map { "\(app.switches.element(boundBy: $0).value ?? "nil")" }
        let cb2 = (0...1).map { digest(shot, labelled("c\($0 + 1)").frame) }
        let sl2 = (0...1).map { "\(app.sliders.element(boundBy: $0).value ?? "nil")" }
        let moved = Dictionary(uniqueKeysWithValues: radios.map { ($0.0, digest(shot, glyph($0.0, row: $0.1)) != glyphsBefore[$0.0]) })
        print("STATENAMES \(path) sw \(sw) -> \(sw2); sl \(sl) -> \(sl2)")
        print("STATENAMES \(path) seg a2=\(app.buttons["a2"].isSelected) b2=\(app.buttons["b2"].isSelected) cb moved=\(cb[0] != cb2[0]),\(cb[1] != cb2[1])")
        print("STATENAMES \(path) radio glyphs moved: " + radios.map { "\($0.0)=\(moved[$0.0]!)" }.joined(separator: " "))

        XCTAssertNotEqual(sw[0], sw2[0], "\(path): the first Switch moved")
        XCTAssertEqual(sw[1], sw2[1], "\(path): the second Switch did not")
        XCTAssertNotEqual(cb[0], cb2[0], "\(path): the first CheckBox moved")
        XCTAssertEqual(cb[1], cb2[1], "\(path): the second CheckBox did not")
        XCTAssertTrue(app.buttons["a2"].isSelected, "\(path): the first Segment moved")
        XCTAssertFalse(app.buttons["b2"].isSelected, "\(path): the second Segment did not")
        XCTAssertNotEqual(sl[0], sl2[0], "\(path): the first Slider moved")
        XCTAssertEqual(sl[1], sl2[1], "\(path): the second Slider did not")
        // h: nothing selected; h2 tapped — h2 alone moves.
        XCTAssertEqual([moved["h1"]!, moved["h2"]!], [false, true], "\(path) h: tapping h2 selects h2 alone")
        // g: g1 checked; g2 tapped — g1 lets go and g2 takes it.
        XCTAssertEqual([moved["g1"]!, moved["g2"]!], [true, true], "\(path) g: tapping g2 moves the selection from g1 to g2")
        // Radios over items: j2 tapped — the j row moves, the i row does not.
        XCTAssertEqual([moved["i1"]!, moved["i2"]!, moved["j1"]!, moved["j2"]!], [false, false, true, true],
                       "\(path): tapping j2 moves the j row alone")

        // The text fields last: their keyboard covers what is below them.
        let tf = app.textFields.element(boundBy: 0)
        tf.tap()
        tf.typeText("x")
        sleep(1)
        let tfs = (0...1).map { "\(app.textFields.element(boundBy: $0).value ?? "nil")" }
        print("STATENAMES \(path) tf \(tfs)")
        XCTAssertEqual(tfs, ["tx", "t"], "\(path): only the first TextField took the key")
        app.terminate()
    }

    /// A coarse fingerprint of a region's pixels: the channel sum of each of
    /// eight horizontal bands (as OnClickProbeUITests reads a control).
    private func digest(_ image: UIImage, _ frame: CGRect) -> String {
        let scale = image.scale
        let rect = CGRect(x: frame.minX * scale, y: frame.minY * scale, width: frame.width * scale, height: frame.height * scale).integral
        guard rect.width > 0, rect.height > 0, let cg = image.cgImage?.cropping(to: rect) else { return "none" }
        let w = cg.width, h = cg.height
        var bytes = [UInt8](repeating: 0, count: w * h * 4)
        bytes.withUnsafeMutableBytes { raw in
            let ctx = CGContext(data: raw.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            ctx?.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        var bands = [Int](repeating: 0, count: 8)
        for i in stride(from: 0, to: bytes.count, by: 4) {
            let row = (i / 4) / w
            bands[min(7, row * 8 / max(h, 1))] += (Int(bytes[i]) + Int(bytes[i + 1]) + Int(bytes[i + 2])) / 64
        }
        return bands.map(String.init).joined(separator: ".")
    }
}
