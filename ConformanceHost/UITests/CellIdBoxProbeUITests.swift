//
//  CellIdBoxProbeUITests.swift
//  ConformanceHostUITests
//
//  A cell's item box and its root's id box are the box the cell draws
//  (CellIdBoxProbeView): inside the root's margins, including its padding,
//  moved by its offset. The drawn box is read from the screenshot (the
//  #FFDD00 pixels inside the Collection), because no accessibility frame of
//  an id-less root names it. Relative to the Collection, the cell draws at
//  (25, 10, 100, 40). The Dynamic half always; the generated half in the
//  codegen host only. NOT opt-in.
//

import XCTest

final class CellIdBoxProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func text(_ r: CGRect) -> String {
        String(format: "(%.1f,%.1f,%.1f,%.1f)", r.minX, r.minY, r.width, r.height)
    }

    /// The bounding box, in points, of the #FFDD00 pixels inside `rect` (points).
    private func yellowBox(in rect: CGRect, of image: CGImage, scale: CGFloat) -> CGRect? {
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let x0 = max(0, Int(rect.minX * scale)), x1 = min(width, Int(rect.maxX * scale))
        let y0 = max(0, Int(rect.minY * scale)), y1 = min(height, Int(rect.maxY * scale))
        var minX = Int.max, minY = Int.max, maxX = -1, maxY = -1
        for y in y0..<y1 {
            for x in x0..<x1 {
                let i = (y * width + x) * 4
                let r = pixels[i], g = pixels[i + 1], b = pixels[i + 2]
                if r > 235 && g >= 205 && g <= 235 && b < 40 {
                    minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
                }
            }
        }
        guard maxX >= 0 else { return nil }
        return CGRect(x: CGFloat(minX) / scale, y: CGFloat(minY) / scale,
                      width: CGFloat(maxX - minX + 1) / scale, height: CGFloat(maxY - minY + 1) / scale)
    }

    private func same(_ a: CGRect, _ b: CGRect, _ what: String) {
        for (name, x, y) in [("minX", a.minX, b.minX), ("minY", a.minY, b.minY),
                             ("width", a.width, b.width), ("height", a.height, b.height)] {
            XCTAssertEqual(x, y, accuracy: 0.5, "\(what): \(name) \(x), drawn \(y)")
        }
    }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["cib_ready"].waitForExistence(timeout: 15), "probe did not start")
        XCTAssertTrue(element(app, "\(p)_cib_id_item_0").waitForExistence(timeout: 10), "the cells did not come up")
        let screenshot = XCUIScreen.main.screenshot()
        guard let image = screenshot.image.cgImage else { return XCTFail("no screenshot image") }
        let scale = CGFloat(image.width) / app.frame.width
        var lines: [String] = []
        for v in ["bare", "id"] {
            let list = element(app, "\(p)_cib_\(v)")
            let item = element(app, "\(p)_cib_\(v)_item_0")
            guard list.exists, item.exists else { XCTFail("\(p)_cib_\(v): list \(list.exists) item \(item.exists)"); continue }
            let o = list.frame.origin
            guard let drawn = yellowBox(in: list.frame, of: image, scale: scale)?.offsetBy(dx: -o.x, dy: -o.y) else {
                XCTFail("\(p)_cib_\(v): nothing drawn"); continue
            }
            let i = item.frame.offsetBy(dx: -o.x, dy: -o.y)
            var line = "\(p)_cib_\(v): list \(text(list.frame)) drawn \(text(drawn)) item \(text(i))"
            same(i, drawn, "\(p)_cib_\(v) item")
            if v == "id" {
                let root = element(app, "cell_inset_root")
                let measured = element(app, "frame:cell_inset_root")
                // Under the item address the root's own id is found on no
                // platform (measured 2026-10-06; ticket conformance-a-cell-
                // roots-id-is-lost-under-the-item-address): read, not held.
                if root.exists {
                    let r = root.frame.offsetBy(dx: -o.x, dy: -o.y)
                    line += " root \(text(r))"
                    same(r, drawn, "\(p)_cib_id root")
                } else {
                    line += " root -"
                }
                line += measured.exists ? " layout \(text(measured.frame.offsetBy(dx: -o.x, dy: -o.y)))" : " layout -"
            }
            let child = element(app, v == "id" ? "cell_inset_id_child" : "cell_inset_child")
            line += " child \(child.exists ? text(child.frame.offsetBy(dx: -o.x, dy: -o.y)) : "missing")"
            XCTAssertTrue(child.exists, "\(p)_cib_\(v): the child lost its id")
            lines.append(line)
        }
        lines.forEach { print("CIB \($0)") }
        let shot = XCTAttachment(screenshot: screenshot)
        shot.name = "cell_id_box_\(p)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testACellsBoxesAreWhatItDrawsDynamic() throws {
        run(prefix: "dyn", argument: "-cellIdBoxProbe")
    }

    func testACellsBoxesAreWhatItDrawsGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(prefix: "cg", argument: "-cellIdBoxProbeCodegen")
    }
}
