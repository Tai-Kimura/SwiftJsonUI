//
//  DisabledColoursProbeUITests.swift
//  ConformanceHostUITests
//
//  A bound `enabled` turned false shows the disabled colours (DisabledColoursProbeView):
//  the bound-background View and the fixed-background View paint #999999, the
//  Label's text #555555; while `on` is true they paint #0000FF and #123456. Read
//  from screenshots (no accessibility property names a colour). Codegen host only.
//  NOT opt-in.
//

import XCTest

final class DisabledColoursProbeUITests: XCTestCase {
    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func pixels(_ image: CGImage) -> [UInt8]? {
        let width = image.width, height = image.height
        var data = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(data: &data, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return data
    }

    /// The colour at the middle of `rect` (points), as "#RRGGBB".
    private func middle(of rect: CGRect, _ image: CGImage, _ data: [UInt8], scale: CGFloat) -> String {
        let x = Int(rect.midX * scale), y = Int(rect.midY * scale), i = (y * image.width + x) * 4
        return String(format: "#%02X%02X%02X", data[i], data[i + 1], data[i + 2])
    }

    /// How many pixels inside `rect` are within 24 of `hex` on each channel.
    private func count(_ hex: String, in rect: CGRect, _ image: CGImage, _ data: [UInt8], scale: CGFloat) -> Int {
        let v = Int(hex.dropFirst(), radix: 16)!, want = [(v >> 16) & 255, (v >> 8) & 255, v & 255]
        var n = 0
        for y in max(0, Int(rect.minY * scale))..<min(image.height, Int(rect.maxY * scale)) {
            for x in max(0, Int(rect.minX * scale))..<min(image.width, Int(rect.maxX * scale)) {
                let i = (y * image.width + x) * 4
                if (0..<3).allSatisfy({ abs(Int(data[i + $0]) - want[$0]) <= 24 }) { n += 1 }
            }
        }
        return n
    }

    private func read(_ app: XCUIApplication, _ name: String) -> [String: Any] {
        let screenshot = XCUIScreen.main.screenshot()
        let shot = XCTAttachment(screenshot: screenshot)
        shot.name = "disabled_colours_\(name)"
        shot.lifetime = .keepAlways
        add(shot)
        guard let image = screenshot.image.cgImage, let data = pixels(image) else { XCTFail("no screenshot"); return [:] }
        let scale = CGFloat(image.width) / app.frame.width
        let label = element(app, "cg_dc_label").frame
        return ["view": middle(of: element(app, "cg_dc_view").frame, image, data, scale: scale),
                "viewFixed": middle(of: element(app, "cg_dc_view_fixed").frame, image, data, scale: scale),
                "labelBase": count("#123456", in: label, image, data, scale: scale),
                "labelDisabled": count("#555555", in: label, image, data, scale: scale)]
    }

    func testABoundEnabledTurnedFalseShowsTheDisabledColoursGenerated() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-disabledColoursProbeCodegen"]
        app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen"
        app.launch()
        XCTAssertTrue(app.staticTexts["dc_ready"].waitForExistence(timeout: 15), "probe did not start")
        XCTAssertTrue(element(app, "cg_dc_view").waitForExistence(timeout: 10), "cg_dc_view is not there")
        let on = read(app, "on")
        element(app, "cg_dc_off").tap()
        sleep(1)
        let off = read(app, "off")
        print("DCP on \(on)")
        print("DCP off \(off)")
        XCTAssertEqual(on["view"] as? String, "#0000FF", "enabled: the bound background")
        XCTAssertEqual(on["viewFixed"] as? String, "#0000FF", "enabled: the fixed background")
        XCTAssertGreaterThan(on["labelBase"] as? Int ?? 0, 40, "enabled: the label in its base colour")
        XCTAssertEqual(on["labelDisabled"] as? Int ?? -1, 0, "enabled: no disabled colour on the label")
        XCTAssertEqual(off["view"] as? String, "#999999", "disabled: the bound-background view's disabledBackground")
        XCTAssertEqual(off["viewFixed"] as? String, "#999999", "disabled: the fixed-background view's disabledBackground")
        XCTAssertGreaterThan(off["labelDisabled"] as? Int ?? 0, 40, "disabled: the label's disabledFontColor")
        XCTAssertEqual(off["labelBase"] as? Int ?? -1, 0, "disabled: no base colour left on the label")
    }
}
