//
//  AnchorTapProbeUITests.swift
//  ConformanceHostUITests
//
//  A tappable View's tap reaches its handler, by the element tap a driver
//  sends and at the point VoiceOver activates (AnchorTapProbeView). Ticket
//  sjui-a-tappable-elements-anchor-inside-its-tap-target-moves-the-tap-point-
//  off-it. For each button (m, n, q, s), what is printed (`ATP`):
//    - the element's frame and isHittable, as XCUITest reads them;
//    - where `.tap()` landed (the app's window-level touch log) and which
//      handler ran ("hit");
//    - the accessibilityFrame and accessibilityActivationPoint the app reads
//      for it, and which handler a touch at that activation point ran.
//  Judged: the element tap runs the button's own handler; the touch lands
//  inside the button's frame; the activation point is inside the frame and a
//  touch there runs the same handler. Then the card's own tap (m) is run as
//  the control that the card's handler still answers outside the button.
//  The id box is judged too — the button's own 30 x 30, the row g's 56
//  high, the Label h inside its margin (sjui-a-combined-taps-id-box-takes-
//  its-margin-in). A touch in g's and h's margin, and as far outside s, is
//  printed, not judged (a touch that close reaches the view on every emit).
//  The v1.9.17, v1.9.18 and v1.9.19 pastes (cg17, cg18, cg19) are the
//  measured defects, held as strict expected failures per specimen (run's
//  `defect`): if one stops failing, the probe no longer sees it, and a
//  specimen outside `defect` / `alsoMay` must pass. v1.9.17's tap still
//  reached f's button, but its id read the card's box; v1.9.18's ran the
//  card's handler; v1.9.19 put every tap after the margin.
//

import XCTest

final class AnchorTapProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func label(_ app: XCUIApplication, _ id: String) -> String {
        let e = element(app, id)
        return e.exists ? e.label : "<none>"
    }

    private func text(_ r: CGRect) -> String {
        String(format: "(%.2f,%.2f,%.2f,%.2f)", r.minX, r.minY, r.width, r.height)
    }

    /// Waits until the hit label reads `want`, up to 3 s; returns what it read.
    private func hit(_ app: XCUIApplication, _ p: String, want: String) -> String {
        let deadline = Date().addingTimeInterval(3)
        var now = label(app, "\(p)_at_hit")
        while now != want && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
            now = label(app, "\(p)_at_hit")
        }
        return now
    }

    private struct Ax { let frame: CGRect; let activation: CGPoint; let count: Int }

    private func axReads(_ app: XCUIApplication) -> [String: Ax] {
        element(app, "at_measure").tap()
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        var out: [String: Ax] = [:]
        for part in label(app, "at_ax").split(separator: ";") {
            let kv = part.split(separator: "=", maxSplits: 1)
            guard kv.count == 2 else { continue }
            let f = kv[1].split(separator: "/")
            guard f.count == 3 else { continue }
            let r = f[0].split(separator: ",").compactMap { Double($0) }
            let a = f[1].split(separator: ",").compactMap { Double($0) }
            guard r.count == 4, a.count == 2 else { continue }
            out[String(kv[0])] = Ax(frame: CGRect(x: r[0], y: r[1], width: r[2], height: r[3]),
                                    activation: CGPoint(x: a[0], y: a[1]), count: Int(f[2]) ?? 0)
        }
        return out
    }

    private func touch(_ app: XCUIApplication) -> CGPoint? {
        let v = label(app, "at_touch").split(separator: ",").compactMap { Double($0) }
        return v.count == 2 ? CGPoint(x: v[0], y: v[1]) : nil
    }

    /// `defect`: the specimens an emit before a fix must fail on (strict), and
    /// `alsoMay` the ones it may fail on besides; every other specimen passes.
    private func run(variant: String, defect: Set<String> = [], alsoMay: Set<String> = []) {
        let app = XCUIApplication()
        app.launchArguments = ["-anchorTapProbe", "-atVariant", variant]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["at_ready"].waitForExistence(timeout: 15), "probe did not start")
        let p = variant == "dyn" ? "dyn" : "cg"
        let ax = axReads(app)
        XCTAssertEqual(ax.count, 8, "\(variant): the walk read \(ax.count) of 7 buttons and at_ready: \(label(app, "at_ax"))")
        // The app's points (the touch log, the accessibility reads) are in its
        // window's space; XCUITest's frames are not, on an iPad window. The
        // offset between them, from at_ready read both ways.
        let shift: CGVector = {
            guard let r = ax["at_ready"] else { return CGVector(dx: 0, dy: 0) }
            let x = app.staticTexts["at_ready"].frame
            return CGVector(dx: x.minX - r.frame.minX, dy: x.minY - r.frame.minY)
        }()
        func moved(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x + shift.dx, y: p.y + shift.dy) }
        func moved(_ r: CGRect) -> CGRect { r.offsetBy(dx: shift.dx, dy: shift.dy) }
        var lines: [String] = []
        // Per specimen, so a contrast paste fails on the specimen its defect is.
        var failures: [String: [String]] = [:]
        var k = ""
        func judge(_ ok: Bool, _ why: String) { if !ok { failures[k, default: []].append(why) } }

        for key in ["m", "n", "q", "s", "f", "g", "h"] {
            k = key
            let id = "\(p)_at_btn_\(k)"
            let e = element(app, id)
            guard e.waitForExistence(timeout: 5) else { judge(false, "\(id) does not exist"); continue }
            let frame = e.frame
            let hittable = e.isHittable
            // Every element XCUITest finds under the id, as a driver's
            // resolver sees them (type and frame).
            let all = app.descendants(matching: .any).matching(identifier: id)
            let seen = (0..<all.count).map { i -> String in
                let m = all.element(boundBy: i)
                return "\(m.elementType.rawValue)\(text(m.frame))"
            }.joined(separator: " ")
            e.tap()
            let byTap = hit(app, p, want: "btn_\(k)")
            let landed = touch(app).map(moved)
            var line = "\(variant) \(id): frame \(text(frame)) hittable \(hittable) tap→\(landed.map { String(format: "%.2f,%.2f", $0.x, $0.y) } ?? "none") hit \(byTap) matches \(all.count) [\(seen)]"
            // The id box is the button's own layout box, its margin outside:
            // 30 x 30; the row g 56 high; the Label h starting 11 / 12 inside
            // its parent's box (sjui-a-combined-taps-id-box-takes-its-margin-in).
            switch k {
            case "g":
                judge(abs(frame.height - 56) <= 0.5, "\(id): the id box \(text(frame)) is not the row's 56 high")
            case "h":
                let box = element(app, "\(p)_at_box_h").frame
                judge(abs(frame.minX - box.minX - 11) <= 0.5 && abs(frame.minY - box.minY - 12) <= 0.5,
                      "\(id): the id box \(text(frame)) does not start 11 / 12 inside its parent \(text(box))")
            default:
                judge(abs(frame.width - 30) <= 0.5 && abs(frame.height - 30) <= 0.5,
                      "\(id): the id box \(text(frame)) is not the button's 30 x 30")
            }
            judge(byTap == "btn_\(k)", "\(id): the element tap ran '\(byTap)', not btn_\(k)")
            if let landed { judge(frame.insetBy(dx: -0.5, dy: -0.5).contains(landed), "\(id): the tap landed at \(landed), outside the frame \(text(frame))") }
            // Away from the button, so the activation tap has to change it.
            element(app, "\(p)_at_card_n").coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.7)).tap()
            _ = hit(app, p, want: "card_n")
            if let raw = ax[id] {
                let a = Ax(frame: moved(raw.frame), activation: moved(raw.activation), count: raw.count)
                let origin = app.coordinate(withNormalizedOffset: .zero)
                let zero = origin.screenPoint
                origin.withOffset(CGVector(dx: a.activation.x - zero.x, dy: a.activation.y - zero.y)).tap()
                let byActivation = hit(app, p, want: "btn_\(k)")
                line += " | ax frame \(text(a.frame)) activation \(String(format: "%.2f,%.2f", a.activation.x, a.activation.y)) elements \(a.count) → hit \(byActivation)"
                judge(frame.insetBy(dx: -0.5, dy: -0.5).contains(a.activation), "\(id): activation point \(a.activation) outside the frame \(text(frame))")
                judge(byActivation == "btn_\(k)", "\(id): a touch at the activation point ran '\(byActivation)', not btn_\(k)")
                element(app, "\(p)_at_card_n").coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.7)).tap()
                _ = hit(app, p, want: "card_n")
            } else {
                judge(false, "\(id): no accessibility element read in the app")
            }
            // Where a touch in the margin lands. Where the margin is comes from
            // the layout, not from the id box under test: above the row g's
            // bottom 56, and the top 12 of the Label h's parent.
            // s has no margin: the same distances outside it are the control
            // for how far a touch reaches past a view's edge at all.
            let marginPoint: CGPoint? = {
                switch k {
                case "g": return CGPoint(x: frame.midX, y: frame.maxY - 56 - 12)
                case "h":
                    let box = element(app, "\(p)_at_box_h").frame
                    return CGPoint(x: box.minX + 11 + 5, y: box.minY + 6)
                case "s": return CGPoint(x: frame.maxX + 12, y: frame.midY)
                default: return nil
                }
            }()
            if let m = marginPoint {
                let origin = app.coordinate(withNormalizedOffset: .zero)
                let zero = origin.screenPoint
                origin.withOffset(CGVector(dx: m.x - zero.x, dy: m.y - zero.y)).tap()
                RunLoop.current.run(until: Date().addingTimeInterval(0.8))
                let byMargin = label(app, "\(p)_at_hit")
                line += String(format: " | outside tap %.1f,%.1f → hit ", m.x, m.y) + byMargin
                // Printed, not judged: measured on iPhone 17 / iOS 27, a touch
                // 6 or 12 pt into the margin ran the button on every emit,
                // before and after the fix, so it does not tell them apart.
            }
            lines.append(line)
        }
        // Control: the card m still answers its own tap away from the button.
        element(app, "\(p)_at_card_m").coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.7)).tap()
        let card = hit(app, p, want: "card_m")
        lines.append("\(variant) control card_m → hit \(card)")
        XCTAssertEqual(card, "card_m", "\(variant): the card's own tap ran '\(card)'")

        lines.insert("\(variant) shift \(shift.dx),\(shift.dy) app \(text(app.frame))", at: 0)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "anchor_tap_\(variant)"
        shot.lifetime = .keepAlways
        add(shot)

        let failed = Set(failures.keys)
        lines.append("\(variant) failed specimens: \(failed.sorted())")
        lines.forEach { print("ATP \($0)") }
        // Strict both ways: the defect's specimens must fail (else the probe no
        // longer sees it), and nothing outside defect + alsoMay may.
        for s in defect.subtracting(failed).sorted() {
            XCTFail("\(variant): specimen \(s) passed — the probe no longer sees this emit's defect")
        }
        for s in failed.sorted() {
            let reasons = failures[s] ?? []
            if defect.contains(s) || alsoMay.contains(s) {
                XCTExpectFailure("\(variant): specimen \(s), an emit before the fix", strict: true) {
                    for r in reasons { XCTFail("\(variant): \(r)") }
                }
            } else {
                for r in reasons { XCTFail("\(variant): \(r)") }
            }
        }
    }

    func testTheTapReachesTheButtonDynamic() throws {
        run(variant: "dyn")
    }

    func testTheTapReachesTheButtonGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(variant: "cg")
    }

    /// v1.9.17's emit: the tap reached f's button, but its id read the card's box.
    func testTheTapReachesTheButtonPasteV1917() throws {
        run(variant: "cg17", defect: ["f"], alsoMay: ["g", "h"])
    }

    /// v1.9.18's emit: f's id read the card's box and its tap ran the card's handler.
    func testTheTapReachesTheButtonPasteV1918() throws {
        run(variant: "cg18", defect: ["f"], alsoMay: ["g", "h"])
    }

    /// v1.9.19's emit: every tap after the margin — the row g's id and both
    /// taps take the margin in (sjui-a-combined-taps-id-box-takes-its-margin-in).
    func testTheTapReachesTheButtonPasteV1919() throws {
        run(variant: "cg19", defect: ["g", "h"])
    }
}
