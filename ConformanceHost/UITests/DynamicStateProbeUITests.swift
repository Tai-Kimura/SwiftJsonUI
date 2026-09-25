import XCTest
import UIKit

/// Does what the user chose in a Dynamic control survive a data change that
/// does not concern it, and does a bound control follow the view model
/// (DynamicStateProbeView; ticket kjui-dynamic-stateful-components-reset-on-
/// unrelated-data)? Each form — static, plain, binding — in its own launch:
/// read every control; for the bound forms the model first sets every bound
/// value to the chosen one and back (read after each); choose in every
/// control, read, change a key no control reads, read; for the bound forms
/// the model again sets the chosen values and the declared ones, read after
/// each.
///
/// Two readings of each control: its pixels (a crop of the screen, compared
/// with the crops taken before and after the choice — the one reading every
/// control has) and what accessibility says, where it says anything (a
/// Switch's value, a Segment's or a tab's selected button, a Slider's value,
/// a SelectBox's label). A CheckBox and a Radio say nothing about their state.
///
/// Opt-in, like the other probes: TEST_RUNNER_DYNAMIC_STATE_PROBE=1;
/// TEST_RUNNER_DYNAMIC_STATE_FORMS=static,plain,binding picks the forms.
final class DynamicStateProbeUITests: XCTestCase {
    static let controls = ["sw", "tg", "cb", "rv", "seg", "tab", "sl", "sb", "sbi"]

    struct Crop { let width: Int; let height: Int; let bytes: [UInt8] }
    struct Reading { var crops: [String: Crop] = [:]; var a11y: [String: String] = [:] }

    private var app: XCUIApplication!

    func testAChoiceSurvivesAnUnrelatedDataChangeAndTheModelIsFollowed() throws {
        let env = ProcessInfo.processInfo.environment
        guard env["DYNAMIC_STATE_PROBE"] == "1" else {
            throw XCTSkip("dynamic state probe: run with the guard lifted, as the other probes are")
        }
        continueAfterFailure = true
        let forms = (env["DYNAMIC_STATE_FORMS"] ?? "static,plain,binding").split(separator: ",").map(String.init)
        for form in forms { run(form) }
    }

    // MARK: - One form

    private func run(_ form: String) {
        app = XCUIApplication()
        app.launchArguments = ["-dynamicStateProbe", form]
        app.launch()
        XCTAssertTrue(app.staticTexts["dsp_ready"].waitForExistence(timeout: 15), "\(form): probe did not start")
        XCTAssertFalse(app.staticTexts["dsp_decode_failed"].exists, "\(form): the dynamic layout did not decode")
        XCTAssertTrue(app.staticTexts["u0"].waitForExistence(timeout: 5), "\(form): the dynamic tree shows the data")
        sleep(1)
        let bound = form != "static"

        let declared = read()
        // Before the user touches anything: the model moves every bound
        // value to the chosen one and back.
        var modelFirst: (moved: Reading, back: Reading)?
        if bound {
            app.buttons["dsp_vm_chosen"].tap(); sleep(1)
            let moved = read()
            app.buttons["dsp_vm_declared"].tap(); sleep(1)
            modelFirst = (moved, read())
        }
        choose()
        let chosen = read()
        print("DSP \(form) readout_chosen=\(app.staticTexts["dsp_readout"].label)")

        app.buttons["dsp_unrelated"].tap()
        XCTAssertTrue(app.staticTexts["u1"].waitForExistence(timeout: 5), "\(form): the unrelated change reached the dynamic tree")
        sleep(1)
        let afterUnrelated = read()

        // After the user's choice: the model moves every bound value to the
        // chosen one and back to the declared one.
        var modelAfter: (moved: Reading, back: Reading)?
        if bound {
            app.buttons["dsp_vm_chosen"].tap(); sleep(1)
            let moved = read()
            app.buttons["dsp_vm_declared"].tap(); sleep(1)
            modelAfter = (moved, read())
        }
        print("DSP \(form) readout_end=\(app.staticTexts["dsp_readout"].label)")

        for id in Self.controls {
            guard let a = declared.crops[id], let b = chosen.crops[id] else {
                XCTFail("\(form) \(id): no crop"); continue
            }
            var line = "DSP \(form) \(id)"
            if let modelFirst, let moved = modelFirst.moved.crops[id], let back = modelFirst.back.crops[id] {
                let away = diff(a, moved), home = diff(a, back)
                line += " | model_first moved=\(away) a11y=\(modelFirst.moved.a11y[id] ?? "-") back=\(home) a11y=\(modelFirst.back.a11y[id] ?? "-")"
                XCTAssertGreaterThan(away, Self.tolerance, "\(form) \(id): the control follows the model's value")
                XCTAssertLessThanOrEqual(home, Self.tolerance, "\(form) \(id): the control follows the model back to the declared value")
            }
            let tapped = diff(a, b)
            line += " | tap pixels=\(tapped) a11y \(declared.a11y[id] ?? "-")->\(chosen.a11y[id] ?? "-")"
            let changeable = tapped > Self.tolerance
            if !changeable { line += " TAP_DID_NOT_CHANGE_IT" }
            let survived = classify(afterUnrelated.crops[id], a, b)
            line += " | after_an_unrelated_key_changed=\(survived) a11y=\(afterUnrelated.a11y[id] ?? "-")"
            if changeable {
                XCTAssertEqual(survived, "chosen", "\(form) \(id): the choice survives an unrelated data change")
            }
            if let modelAfter, let moved = modelAfter.moved.crops[id], let back = modelAfter.back.crops[id] {
                let home = diff(a, back)
                line += " | model_after moved=\(diff(a, moved)) a11y=\(modelAfter.moved.a11y[id] ?? "-") back=\(home) a11y=\(modelAfter.back.a11y[id] ?? "-")"
                XCTAssertLessThanOrEqual(home, Self.tolerance, "\(form) \(id): after the user's choice the control follows the model back to the declared value")
            }
            print(line)
        }
        app.terminate()
    }

    // MARK: - Choosing

    private func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func choose() {
        app.switches["sw"].tap()
        app.switches["tg"].tap()
        element("cb").tap()
        radioGlyph("rb").tap()
        app.buttons["sy"].tap()
        app.tabBars.buttons["tb"].tap()
        app.sliders["sl"].adjust(toNormalizedSliderPosition: 0.8)
        for id in ["sb", "sbi"] {
            element(id).tap()
            let wheel = app.pickerWheels.firstMatch
            if wheel.waitForExistence(timeout: 5) {
                wheel.adjust(toPickerWheelValue: "qq")
                app.buttons["Done"].tap()
            } else {
                XCTFail("\(id): the picker did not open")
            }
            sleep(1)
        }
        sleep(1)
    }

    /// A Radio row's tap is on its glyph, not its text.
    private func radioGlyph(_ item: String) -> XCUICoordinate {
        let text = app.staticTexts[item].frame
        let origin = app.coordinate(withNormalizedOffset: .zero)
        return origin.withOffset(CGVector(dx: text.minX - 18, dy: text.midY))
    }

    // MARK: - Reading

    private func frames() -> [String: CGRect] {
        let window = app.windows.firstMatch.frame
        let ra = app.staticTexts["ra"].frame, rb = app.staticTexts["rb"].frame
        var rv = ra.union(rb)
        rv = CGRect(x: window.minX, y: rv.minY, width: rv.maxX - window.minX, height: rv.height)
        return [
            "sw": app.switches["sw"].frame,
            "tg": app.switches["tg"].frame,
            "cb": element("cb").frame,
            "rv": rv,
            "seg": app.buttons["sx"].frame.union(app.buttons["sy"].frame),
            "tab": app.tabBars.firstMatch.frame,
            "sl": app.sliders["sl"].frame,
            "sb": element("sb").frame,
            "sbi": element("sbi").frame,
        ]
    }

    private func read() -> Reading {
        var reading = Reading()
        let shot = XCUIScreen.main.screenshot().image
        for (id, frame) in frames() { reading.crops[id] = crop(shot, frame) }
        reading.a11y["sw"] = "\(app.switches["sw"].value ?? "nil")"
        reading.a11y["tg"] = "\(app.switches["tg"].value ?? "nil")"
        let cb = element("cb")
        reading.a11y["cb"] = "sel=\(cb.isSelected),value=\(cb.value ?? "nil")"
        reading.a11y["seg"] = app.buttons["sy"].isSelected ? "sy" : (app.buttons["sx"].isSelected ? "sx" : "none")
        reading.a11y["tab"] = app.tabBars.buttons["tb"].isSelected ? "tb" : (app.tabBars.buttons["ta"].isSelected ? "ta" : "none")
        reading.a11y["sl"] = "\(app.sliders["sl"].value ?? "nil")"
        reading.a11y["sb"] = element("sb").label
        reading.a11y["sbi"] = element("sbi").label
        return reading
    }

    /// The RGBA pixels of *frame* (points, screen coordinates) of *image*.
    private func crop(_ image: UIImage, _ frame: CGRect) -> Crop {
        let scale = image.scale
        let rect = CGRect(x: frame.minX * scale, y: frame.minY * scale, width: frame.width * scale, height: frame.height * scale).integral
        guard let cg = image.cgImage?.cropping(to: rect) else { return Crop(width: 0, height: 0, bytes: []) }
        let width = cg.width, height = cg.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let space = CGColorSpaceCreateDeviceRGB()
        bytes.withUnsafeMutableBytes { raw in
            let context = CGContext(data: raw.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                    bytesPerRow: width * 4, space: space,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            context?.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return Crop(width: width, height: height, bytes: bytes)
    }

    /// Pixels whose colour differs by more than 40 in some channel; -1 when
    /// the crops are not the same size.
    private func diff(_ a: Crop, _ b: Crop) -> Int {
        guard a.width == b.width, a.height == b.height else { return -1 }
        var count = 0
        var i = 0
        while i < a.bytes.count {
            if abs(Int(a.bytes[i]) - Int(b.bytes[i])) > 40 || abs(Int(a.bytes[i + 1]) - Int(b.bytes[i + 1])) > 40
                || abs(Int(a.bytes[i + 2]) - Int(b.bytes[i + 2])) > 40 {
                count += 1
            }
            i += 4
        }
        return count
    }

    /// Pixels two crops of one state may differ by. Every re-read of an
    /// unchanged control measured 0 (iOS 26.5 simulator, 2026-09-26); the
    /// smallest real change, a SelectBox's "pp" -> "qq", measured 662.
    static let tolerance = 16

    /// "declared", "chosen", or neither with both distances.
    private func classify(_ x: Crop?, _ declared: Crop, _ chosen: Crop) -> String {
        guard let x else { return "no_crop" }
        let toDeclared = diff(x, declared), toChosen = diff(x, chosen), tol = Self.tolerance
        if toDeclared >= 0, toDeclared <= tol, toChosen > tol { return "declared" }
        if toChosen >= 0, toChosen <= tol, toDeclared > tol { return "chosen" }
        return "neither(toDeclared=\(toDeclared),toChosen=\(toChosen))"
    }
}
