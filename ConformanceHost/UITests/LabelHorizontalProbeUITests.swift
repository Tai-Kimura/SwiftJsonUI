//
//  LabelHorizontalProbeUITests.swift
//  ConformanceHostUITests
//
//  A Label's text across a frame wider than it, and the lines of a
//  multi-line one, by the Label rule: textAlign, else the horizontal part of
//  its gravity, else the start (LabelHorizontalProbeView). Read from the
//  row's pixels: each line's dark (text) pixels, their margin from the
//  row's leading and trailing edges.
//  Changed rows: w50_none, w70_none, w110_none and w200h44_none at the start
//  (they were centred); w32_right, mw_right and weighted_right at the end
//  (they were at the start); w200_center, w200_chz centred (at the start);
//  ml_center's lines centred and ml_right's at the end (at the start).
//  Controls: w200_left at the start, w200_tac centred, w200_tar_gleft at the
//  end (textAlign over gravity), ml_none's lines at the start, ml_tac's
//  centred. The Dynamic half always; the generated half in the codegen host
//  only. NOT opt-in.
//

import XCTest

final class LabelHorizontalProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    /// Each line of dark pixels in an element's screenshot, top to bottom:
    /// its margins (in points) from the element's leading and trailing edges.
    private func inkLines(_ element: XCUIElement) -> (lines: [(leading: CGFloat, trailing: CGFloat)], width: CGFloat) {
        guard let cg = element.screenshot().image.cgImage else { return ([], 0) }
        let w = cg.width, h = cg.height
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return ([], 0) }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        let scale = CGFloat(w) / element.frame.width
        var lines: [(leading: CGFloat, trailing: CGFloat)] = []
        var first = w, last = -1, inLine = false
        for y in 0...h {
            var rowFirst = w, rowLast = -1
            if y < h {
                for x in 0..<w {
                    let i = (y * w + x) * 4
                    if Int(pixels[i]) + Int(pixels[i + 1]) + Int(pixels[i + 2]) < 200 { rowFirst = min(rowFirst, x); rowLast = max(rowLast, x) }
                }
            }
            if rowLast >= 0 {
                inLine = true; first = min(first, rowFirst); last = max(last, rowLast)
            } else if inLine {
                lines.append((CGFloat(first) / scale, CGFloat(w - 1 - last) / scale))
                first = w; last = -1; inLine = false
            }
        }
        return (lines, element.frame.width)
    }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["lh_ready"].waitForExistence(timeout: 15), "probe did not start")
        var out: [String] = []
        for (row, want) in [
            ("w50_none", "start"),
            ("w70_none", "start"),
            ("w110_none", "start"),
            ("w32_right", "end"),
            ("w200h44_none", "start"),
            ("w200_center", "center"),
            ("w200_chz", "center"),
            ("mw_right", "end"),
            ("weighted_right", "end"),
            ("w200_left", "start"),
            ("w200_tac", "center"),
            ("w200_tar_gleft", "end"),
            ("ml_none", "lines_start"),
            ("ml_center", "lines_center"),
            ("ml_right", "lines_end"),
            ("ml_tac", "lines_center")
        ] {
            let box = app.descendants(matching: .any).matching(identifier: "\(p)_lh_\(row)").firstMatch
            XCTAssertTrue(box.waitForExistence(timeout: 5), "\(p)_lh_\(row) is not drawn")
            let ink = inkLines(box)
            out.append("\(p)_lh_\(row): row \(Int(ink.width))pt, " + ink.lines.map { String(format: "line L%.1f R%.1f", $0.leading, $0.trailing) }.joined(separator: ", "))
            guard let line = ink.lines.first else { XCTFail("\(p)_lh_\(row): no text drawn"); continue }
            switch want {
            case "start": XCTAssertLessThan(line.leading, 2.5, "\(p)_lh_\(row): the text is not at the start")
            case "end": XCTAssertLessThan(line.trailing, 2.5, "\(p)_lh_\(row): the text is not at the end")
            case "center":
                XCTAssertGreaterThan(line.leading, 5, "\(p)_lh_\(row): the text is at the start")
                XCTAssertEqual(line.leading, line.trailing, accuracy: 2.5, "\(p)_lh_\(row): the text is not centred")
            default:
                // Two lines, the first ("Go") shorter than the second.
                guard ink.lines.count == 2 else { XCTFail("\(p)_lh_\(row): \(ink.lines.count) lines, not 2"); continue }
                let short = ink.lines[0], long = ink.lines[1]
                XCTAssertGreaterThan(short.leading + short.trailing - long.leading - long.trailing, 20, "\(p)_lh_\(row): the first line is not the shorter")
                switch want {
                case "lines_start": XCTAssertEqual(short.leading, long.leading, accuracy: 1.5, "\(p)_lh_\(row): the lines are not at the start")
                case "lines_end": XCTAssertEqual(short.trailing, long.trailing, accuracy: 1.5, "\(p)_lh_\(row): the lines are not at the end")
                default: XCTAssertEqual(short.leading - long.leading, short.trailing - long.trailing, accuracy: 2.5, "\(p)_lh_\(row): the lines are not centred")
                }
            }
        }
        out.forEach { print("LHP \($0)") }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "label_horizontal_\(p)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testALabelsTextSitsAtTextAlignElseItsGravityElseTheStartDynamic() throws {
        run(prefix: "dyn", argument: "-labelHorizontalProbe")
    }

    func testALabelsTextSitsAtTextAlignElseItsGravityElseTheStartGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(prefix: "cg", argument: "-labelHorizontalProbeCodegen")
    }
}
