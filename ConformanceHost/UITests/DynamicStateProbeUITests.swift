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
/// TEST_RUNNER_DYNAMIC_STATE_FORMS=static,plain,binding,codegen picks the forms and
/// TEST_RUNNER_DYNAMIC_STATE_GROUPS=controls,inputs the screens
/// (`codegen`: what sjui build emits for the static layout, pasted — ticket
/// static-valued-controls-do-not-change-on-a-users-tap).
final class DynamicStateProbeUITests: XCTestCase {
    static let groups = [
        "controls": ["sw", "tg", "cb", "rv", "rg", "seg", "tab", "sl", "sb", "sbi"],
        "inputs": ["tf", "tv", "sbv", "sbd", "sln"],
        // SelectBoxes bound to the data by selectedItem / selectedValue /
        // selectedDate / selectedIndex (codegen form only).
        "bound": ["sbi", "sbv", "sbd", "sb"],
    ]

    struct Crop { let width: Int; let height: Int; let bytes: [UInt8] }
    struct Reading { var crops: [String: Crop] = [:]; var a11y: [String: String] = [:] }

    private var app: XCUIApplication!
    private var group = "controls"

    func testAChoiceSurvivesAnUnrelatedDataChangeAndTheModelIsFollowed() throws {
        let env = ProcessInfo.processInfo.environment
        guard env["DYNAMIC_STATE_PROBE"] == "1" else {
            throw XCTSkip("dynamic state probe: run with the guard lifted, as the other probes are")
        }
        continueAfterFailure = true
        let forms = (env["DYNAMIC_STATE_FORMS"] ?? "static,plain,binding,codegen").split(separator: ",").map(String.init)
        let groups = (env["DYNAMIC_STATE_GROUPS"] ?? "controls,inputs").split(separator: ",").map(String.init)
        for group in groups { for form in forms { run(form, group) } }
    }

    // MARK: - One form

    private func run(_ form: String, _ group: String) {
        // The bound screen is sjui build's output only; the dynamic path's bound
        // SelectBoxes are on the other two screens' plain / binding forms.
        if group == "bound" && form != "codegen" { return }
        app = XCUIApplication()
        app.launchArguments = ["-dynamicStateProbe", form, "-dspGroup", group]
        app.launch()
        XCTAssertTrue(app.staticTexts["dsp_ready"].waitForExistence(timeout: 15), "\(form): probe did not start")
        XCTAssertFalse(app.staticTexts["dsp_decode_failed"].exists, "\(form): the dynamic layout did not decode")
        XCTAssertTrue(app.staticTexts["u0"].waitForExistence(timeout: 5), "\(form): the dynamic tree shows the data")
        sleep(1)
        let bound = form == "plain" || form == "binding" || group == "bound"
        let controls = Self.groups[group] ?? []
        self.group = group

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
        let readoutChosen = app.staticTexts["dsp_readout"].label
        print("DSP \(group) \(form) readout_chosen=\(readoutChosen)")
        // Written back: where the model holds a two-way binding, the user's
        // choice reaches it (ticket selectbox-selected-item-binding-is-read-once).
        if form == "binding" || group == "bound" {
            let model = modelValues(readoutChosen, group == "bound" ? "bound" : "values")
            for id in controls {
                guard let key = Self.modelKey[group == "bound" ? "bound:\(id)" : id], let declaredValue = Self.modelDeclared[key] else { continue }
                print("DSP \(group) \(form) \(id) model_after_the_choice \(key)=\(model[key] ?? "-")")
                XCTAssertNotEqual(model[key], declaredValue, "\(group) \(form) \(id): the user's choice reaches the model (\(key))")
            }
        }

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
        print("DSP \(group) \(form) readout_end=\(app.staticTexts["dsp_readout"].label)")

        for id in controls {
            guard let a = declared.crops[id], let b = chosen.crops[id] else {
                XCTFail("\(group) \(form) \(id): no crop"); continue
            }
            var line = "DSP \(group) \(form) \(id)"
            if !Self.neverBound.contains(id), let modelFirst, let moved = modelFirst.moved.crops[id], let back = modelFirst.back.crops[id] {
                let away = diff(a, moved), home = diff(a, back)
                line += " | model_first moved=\(away) a11y=\(modelFirst.moved.a11y[id] ?? "-") back=\(home) a11y=\(modelFirst.back.a11y[id] ?? "-")"
                XCTAssertGreaterThan(away, Self.tolerance, "\(group) \(form) \(id): the control follows the model's value")
                XCTAssertLessThanOrEqual(home, Self.tolerance, "\(group) \(form) \(id): the control follows the model back to the declared value")
            }
            let tapped = diff(a, b)
            line += " | tap pixels=\(tapped) a11y \(declared.a11y[id] ?? "-")->\(chosen.a11y[id] ?? "-")"
            let changeable = tapped > Self.tolerance
            if !changeable { line += " TAP_DID_NOT_CHANGE_IT" }
            // A static value (or a plain one) is where the control starts, and
            // the user changes it (ticket static-valued-controls-do-not-change-
            // on-a-users-tap).
            XCTAssertTrue(changeable, "\(group) \(form) \(id): the user's tap / pick / key moves it")
            let survived = classify(afterUnrelated.crops[id], a, b)
            line += " | after_an_unrelated_key_changed=\(survived) a11y=\(afterUnrelated.a11y[id] ?? "-")"
            if changeable {
                XCTAssertEqual(survived, "chosen", "\(group) \(form) \(id): the choice survives an unrelated data change")
            }
            if !Self.neverBound.contains(id), let modelAfter, let moved = modelAfter.moved.crops[id], let back = modelAfter.back.crops[id] {
                let home = diff(a, back)
                line += " | model_after moved=\(diff(a, moved)) a11y=\(modelAfter.moved.a11y[id] ?? "-") back=\(home) a11y=\(modelAfter.back.a11y[id] ?? "-")"
                XCTAssertLessThanOrEqual(home, Self.tolerance, "\(group) \(form) \(id): after the user's choice the control follows the model back to the declared value")
            }
            print(line)
        }
        app.terminate()
    }

    /// The model's key for each control (the binding form's `values`, the bound
    /// screen's `bound`) and its declared value as the readout prints it.
    static let modelKey: [String: String] = [
        "sw": "sw_on", "tg": "tg_on", "cb": "cb_on", "rv": "rv_sel", "rg": "grp", "seg": "seg_sel", "tab": "tab_sel",
        "sl": "sl_val", "sb": "sb_idx", "sbi": "sbi_sel", "tf": "tf_text", "tv": "tv_text", "sbv": "sbv_sel", "sbd": "sbd_date",
        "bound:sbi": "sbiSel", "bound:sbv": "sbvSel", "bound:sbd": "sbdDate", "bound:sb": "sbIdx",
    ]
    static let modelDeclared: [String: String] = [
        "sw_on": "false", "tg_on": "false", "cb_on": "false", "rv_sel": "ra", "grp": "", "seg_sel": "0", "tab_sel": "0",
        "sl_val": "0.2", "sb_idx": "0", "sbi_sel": "pp", "tf_text": "t0", "tv_text": "v0", "sbv_sel": "pp", "sbd_date": "2026-01-02",
        "sbiSel": "pp", "sbvSel": "pp", "sbdDate": "2026-01-02", "sbIdx": "0",
    ]

    /// `key=value` pairs inside `section[...]` of the readout.
    private func modelValues(_ readout: String, _ section: String) -> [String: String] {
        guard let start = readout.range(of: "\(section)[")?.upperBound,
              let end = readout[start...].firstIndex(of: "]") else { return [:] }
        return Dictionary(readout[start..<end].split(separator: ",").compactMap { part -> (String, String)? in
            let kv = part.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            return kv.count == 2 ? (String(kv[0]), String(kv[1])) : nil
        }, uniquingKeysWith: { a, _ in a })
    }

    // MARK: - Choosing

    private func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func choose() {
        if group == "inputs" { chooseInputs(); return }
        if group == "bound" { chooseBound(); return }
        app.switches["sw"].tap()
        app.switches["tg"].tap()
        element("cb").tap()
        radioGlyph("rb").tap()
        // A group of single Radios (rg1 checked): the rows are leading-aligned
        // at the probe's 12 pt padding, the glyph their first 20-odd points.
        let row = element("rg2").frame
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 22, dy: row.midY)).tap()
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

    /// The SelectBoxes first (a sheet each), then the TextView, then the
    /// TextField, whose return key ends the editing and puts the keyboard away.
    private func chooseInputs() {
        element("sbv").tap()
        let wheel = app.pickerWheels.firstMatch
        if wheel.waitForExistence(timeout: 5) {
            wheel.adjust(toPickerWheelValue: "qq")
            app.buttons["Done"].tap()
        } else {
            XCTFail("sbv: the picker did not open")
        }
        sleep(1)
        element("sbd").tap()
        let day = app.pickerWheels.element(boundBy: 1)
        if day.waitForExistence(timeout: 5) {
            print("DSP \(group) sbd wheels=\(app.pickerWheels.allElementsBoundByIndex.map { $0.value as? String ?? "?" })")
            day.adjust(toPickerWheelValue: "3")
            app.buttons["Done"].tap()
        } else {
            XCTFail("sbd: the date picker did not open")
        }
        sleep(1)
        // The slider with no value: its start is read, then it is moved to 30%.
        app.sliders["sln"].adjust(toNormalizedSliderPosition: 0.3)
        let tv = element("tv")
        tv.tap()
        tv.typeText("x")
        let tf = element("tf")
        tf.tap()
        tf.typeText("x\n")
        sleep(1)
    }

    /// The bound SelectBoxes: qq in the three lists, the 3rd in the date.
    private func chooseBound() {
        for id in ["sbi", "sbv", "sb"] {
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
        element("sbd").tap()
        let day = app.pickerWheels.element(boundBy: 1)
        if day.waitForExistence(timeout: 5) {
            day.adjust(toPickerWheelValue: "3")
            app.buttons["Done"].tap()
        } else {
            XCTFail("sbd: the date picker did not open")
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
        if group == "inputs" || group == "bound" {
            return Dictionary(uniqueKeysWithValues: (Self.groups[group] ?? []).map { ($0, element($0).frame) })
        }
        let window = app.windows.firstMatch.frame
        let ra = app.staticTexts["ra"].frame, rb = app.staticTexts["rb"].frame
        var rv = ra.union(rb)
        rv = CGRect(x: window.minX, y: rv.minY, width: rv.maxX - window.minX, height: rv.height)
        let rg1 = element("rg1"), rg2 = element("rg2")
        let rg = rg1.exists && rg2.exists ? rg1.frame.union(rg2.frame) : CGRect.null
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
            "rg": rg.isEmpty ? .zero : CGRect(x: window.minX, y: rg.minY, width: window.width, height: rg.height),
        ]
    }

    private func read() -> Reading {
        var reading = Reading()
        let shot = XCUIScreen.main.screenshot().image
        for (id, frame) in frames() { reading.crops[id] = crop(shot, frame) }
        if group == "inputs" || group == "bound" {
            for id in Self.groups[group] ?? [] {
                let e = element(id)
                reading.a11y[id] = "\(e.value ?? "nil")|\(e.label)"
            }
            return reading
        }
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
    /// Controls no form binds — the model's steps pass them by.
    static let neverBound: Set<String> = ["sln"]

    /// "declared", "chosen", or neither with both distances.
    private func classify(_ x: Crop?, _ declared: Crop, _ chosen: Crop) -> String {
        guard let x else { return "no_crop" }
        let toDeclared = diff(x, declared), toChosen = diff(x, chosen), tol = Self.tolerance
        if toDeclared >= 0, toDeclared <= tol, toChosen > tol { return "declared" }
        if toChosen >= 0, toChosen <= tol, toDeclared > tol { return "chosen" }
        return "neither(toDeclared=\(toDeclared),toChosen=\(toChosen))"
    }
}
