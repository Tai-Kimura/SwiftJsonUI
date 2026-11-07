import XCTest
import SwiftUI
import UIKit
@testable import SwiftJsonUI

#if DEBUG
/// An Indicator's bound `color` draws as the same colour written (jsonui-cli
/// ticket 2026-11-08-ios-dynamic-colours-resolved-without-data): `color` is
/// declared string|binding, and the converter read it without data, so "@{c}"
/// fell to the default tint. Drawn with `layer.render`.
final class DynamicIndicatorBoundColourTests: XCTestCase {
    @MainActor
    private func reds(_ json: String) throws -> Int {
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        let host = UIHostingController(rootView: AnyView(ZStack { DynamicComponentBuilder(component: component, data: ["c": "#FF0000"]) }
            .frame(width: 160, height: 160).background(Color.white)))
        if #available(iOS 16.4, *) { host.safeAreaRegions = [] }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 160, height: 160))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: host.view.bounds, format: format).image { host.view.layer.render(in: $0.cgContext) }
        window.isHidden = true
        let cg = try XCTUnwrap(image.cgImage)
        var buf = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
        let ctx = try XCTUnwrap(CGContext(data: &buf, width: cg.width, height: cg.height, bitsPerComponent: 8,
                                          bytesPerRow: cg.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
        var n = 0, i = 0
        while i < buf.count { if buf[i] > 180 && buf[i + 1] < 90 && buf[i + 2] < 90 { n += 1 }; i += 4 }
        return n
    }

    @MainActor
    func testABoundColourDrawsAsTheSameColourWritten() throws {
        let head = "{\"type\": \"Indicator\", \"id\": \"p\", \"width\": 60, \"height\": 60"
        let written = try reds(head + ", \"color\": \"#FF0000\"}")
        XCTAssertGreaterThan(written, 0, "the written red drew no red: the measurement sees nothing")
        XCTAssertEqual(try reds(head + "}"), 0, "the default tint drew red")
        XCTAssertEqual(try reds(head + ", \"color\": \"@{c}\"}"), written, "the bound red drew differently from the same red written")
    }
}
#endif
