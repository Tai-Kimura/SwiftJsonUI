import XCTest
import UIKit

/// How many times a control's onClick is called, and from what
/// (OnClickProbeView; ticket control-onclick-is-called-differently-on-every-path).
/// The ruling: once, from the control's own operation, after its update — a
/// Switch's value change, a CheckBox's check, a Radio's selection, a Segment's
/// tab, a Slider's value, a SelectBox's pick; never from a plain tap; never for
/// a TextField / TextView. `canTap: false` stops the call and not the operation;
/// `enabled: false` stops the operation and so the call.
///
/// Both paths — DynamicView and what sjui build emits — under each gate: every
/// control operated once, the handlers' counts read from the readout, the
/// operation read off the control (its accessibility value, or its pixels
/// where it has none), and each control's element type printed (a plain tap
/// adds a button to what VoiceOver sees).
///
/// Opt-in, like the other probes: TEST_RUNNER_ON_CLICK_PROBE=1.
final class OnClickProbeUITests: XCTestCase {
    private var app: XCUIApplication!
    private var gate = "N"

    private let controls = ["sw", "cb", "rv", "rgb", "seg", "sl", "sb", "tf", "tv", "swl"]
    /// Controls whose operation the ruling says calls onClick.
    private let calling: Set<String> = ["sw", "cb", "rv", "rgb", "seg", "sl", "sb"]

    func testAControlCallsItsOnClickOnceFromItsOwnOperation() throws {
        guard ProcessInfo.processInfo.environment["ON_CLICK_PROBE"] == "1" else {
            throw XCTSkip("onClick probe: run with the guard lifted, as the other probes are")
        }
        continueAfterFailure = true
        let paths = (ProcessInfo.processInfo.environment["ON_CLICK_PATHS"] ?? "dynamic,codegen").split(separator: ",").map(String.init)
        for path in paths {
            for gate in ["N", "C", "E"] { run(path, gate) }
        }
    }

    private func id(_ base: String) -> String { base + gate }
    private func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func run(_ path: String, _ gate: String) {
        self.gate = gate
        app = XCUIApplication()
        app.launchArguments = ["-onClickProbe", gate, "-ocPath", path]
        app.launch()
        XCTAssertTrue(app.staticTexts["oc_ready"].waitForExistence(timeout: 15), "\(path) \(gate): probe did not start")
        XCTAssertFalse(app.staticTexts["oc_decode_failed"].exists, "\(path) \(gate): the layout did not decode")
        XCTAssertTrue(element(id("sw")).waitForExistence(timeout: 5), "\(path) \(gate): the controls are there")
        sleep(1)

        var types: [String: String] = [:]
        for c in controls { types[c] = "\(element(id(c)).elementType.rawValue)" }
        let before = read()
        operate()
        let after = read()
        let readout = app.staticTexts["oc_readout"].label
        print("ONCLICK \(path) \(gate) readout=\(readout)")
        let counts = self.counts(readout)

        for c in controls {
            let handler = "on" + c.prefix(1).uppercased() + c.dropFirst() + gate
            let calls = counts[handler] ?? 0
            let moved = before[c] != after[c]
            print("ONCLICK \(path) \(gate) \(c) calls=\(calls) operated=\(moved) type=\(types[c] ?? "?") \(before[c] ?? "-") -> \(after[c] ?? "-")")
            // The labelled switch is tapped on its label, which is not the
            // switch: whatever the platform makes of that tap, a call follows
            // an operation and nothing else — a plain tap around the control
            // is the only thing that calls it without a flip.
            let want = c == "swl" ? (gate == "N" && moved ? 1 : 0) : (gate == "N" && calling.contains(c) ? 1 : 0)
            XCTAssertEqual(calls, want, "\(path) \(gate) \(c): onClick calls")
            if ["sw", "cb", "rv", "rgb", "seg", "sl", "sb"].contains(c) || (c == "swl" && gate == "E") {
                XCTAssertEqual(moved, gate != "E", "\(path) \(gate) \(c): the operation \(gate == "E" ? "is stopped" : "happens")")
            }
        }
        app.terminate()
    }

    // MARK: - Operating

    private func operate() {
        // First: the labelled switch sits below the text inputs, which the
        // keyboard covers once they are tapped. Its element is the whole row;
        // the tap lands on its middle, between the label and the switch.
        let swl = element(id("swl"))
        print("ONCLICK swl frame=\(swl.frame) sw frame=\(element(id("sw")).frame)")
        swl.tap()
        element(id("sw")).tap()
        element(id("cb")).tap()
        radioGlyph(app.staticTexts["rb"].frame).tap()
        radioGlyph(app.staticTexts["rg2"].exists ? app.staticTexts["rg2"].frame : element(id("rgb")).frame, rowStart: true).tap()
        app.buttons["sy"].tap()
        app.sliders[id("sl")].adjust(toNormalizedSliderPosition: 0.8)
        element(id("sb")).tap()
        let wheel = app.pickerWheels.firstMatch
        if wheel.waitForExistence(timeout: 3) {
            wheel.adjust(toPickerWheelValue: "qq")
            app.buttons["Done"].tap()
        }
        sleep(1)
        // The text inputs last: their keyboard covers what is below them.
        element(id("tv")).tap()
        element(id("tf")).tap()
        sleep(1)
    }

    /// A Radio's tap is on its glyph: 18 pt left of its text, or — for a
    /// row whose text is not its own element — its first 20-odd points.
    private func radioGlyph(_ frame: CGRect, rowStart: Bool = false) -> XCUICoordinate {
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let x = rowStart && frame.minX < 30 ? 22 : frame.minX - 18
        return origin.withOffset(CGVector(dx: x, dy: frame.midY))
    }

    // MARK: - Reading

    private func read() -> [String: String] {
        sleep(1)
        var out: [String: String] = [:]
        out["sw"] = "\(element(id("sw")).value ?? "nil")"
        out["swl"] = "\(element(id("swl")).value ?? "nil")"
        out["seg"] = app.buttons["sy"].isSelected ? "sy" : "sx"
        out["sl"] = "\(app.sliders[id("sl")].value ?? "nil")"
        out["sb"] = element(id("sb")).label
        out["tf"] = "\(element(id("tf")).value ?? "nil")"
        out["tv"] = "\(element(id("tv")).value ?? "nil")"
        // No accessibility value for these: a digest of their pixels.
        let shot = XCUIScreen.main.screenshot().image
        out["cb"] = digest(shot, element(id("cb")).frame)
        let ra = app.staticTexts["ra"].frame, rb = app.staticTexts["rb"].frame
        out["rv"] = digest(shot, CGRect(x: 0, y: ra.minY, width: rb.maxX, height: rb.maxY - ra.minY))
        let rg1 = app.staticTexts["rg1"].exists ? app.staticTexts["rg1"].frame : element(id("rga")).frame
        let rg2 = app.staticTexts["rg2"].exists ? app.staticTexts["rg2"].frame : element(id("rgb")).frame
        out["rgb"] = digest(shot, CGRect(x: 0, y: rg1.minY, width: max(rg1.maxX, rg2.maxX), height: rg2.maxY - rg1.minY))
        return out
    }

    /// A coarse fingerprint of a region's pixels: the channel sum of each of eight horizontal
    /// bands. A plain sum would not see a selection move from one row to the next (the
    /// same two glyphs, swapped); the bands do.
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

    private func counts(_ readout: String) -> [String: Int] {
        guard let start = readout.range(of: "counts[")?.upperBound,
              let end = readout[start...].firstIndex(of: "]") else { return [:] }
        return Dictionary(readout[start..<end].split(separator: ",").compactMap { part -> (String, Int)? in
            let kv = part.split(separator: "=")
            return kv.count == 2 ? (String(kv[0]), Int(kv[1]) ?? -1) : nil
        }, uniquingKeysWith: { a, _ in a })
    }
}
