import XCTest
import SwiftUI
import UIKit
@testable import SwiftJsonUI

#if DEBUG
/// A declared shadow and opacity draw on every Dynamic leaf, written or bound
/// (jsonui-cli ticket 2026-11-07-declared-binding-slots-and-dynamic-shadow):
///   - Button, Label, SelectBox and TextView run their own modifier chains, and
///     none had the shadow stage: a declared shadow drew nothing; Button had no
///     opacity stage either;
///   - the shadow stage took no data, so a bound field fell to its default;
///   - a whole number ("radius": 8) read as absent, as 5.
/// Drawn with `layer.render` (`drawHierarchy` draws nothing inside a test).
final class DynamicShadowOpacityDrawTests: XCTestCase {
    private let data: [String: Any] = ["r": 8.5, "x": 6.5, "y": 6.5, "o": 0.5, "c": "#0000FF", "ri": 8, "v": 0.3]
    private let leaves: [String: String] = [
        "View": "", "Label": ", \"text\": \"xxxx\"", "Button": ", \"text\": \"xxxx\"",
        "TextField": ", \"text\": \"xxxx\"", "TextView": ", \"text\": \"xxxx\"",
        "SelectBox": ", \"items\": [\"a\"]", "Switch": "", "Image": ", \"srcName\": \"star\""
    ]

    @MainActor
    private func pixels(_ type: String, _ attrs: String) throws -> [UInt8] {
        let json = "{\"type\": \"\(type)\", \"id\": \"p\", \"width\": 60, \"height\": 60, \"background\": \"#FF0000\"\(leaves[type] ?? "")\(attrs)}"
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        let content = ZStack { DynamicComponentBuilder(component: component, data: data) }
        let host = UIHostingController(rootView: AnyView(content.frame(width: 160, height: 160).background(Color.white)))
        if #available(iOS 16.4, *) { host.safeAreaRegions = [] }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 160, height: 160))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.15))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: host.view.bounds, format: format).image { context in
            host.view.layer.render(in: context.cgContext)
        }
        window.isHidden = true
        let cg = try XCTUnwrap(image.cgImage)
        var buffer = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
        let ctx = try XCTUnwrap(CGContext(data: &buffer, width: cg.width, height: cg.height, bitsPerComponent: 8,
                                          bytesPerRow: cg.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
        return buffer
    }

    private func differing(_ a: [UInt8], _ b: [UInt8]) -> Int {
        guard a.count == b.count else { return -1 }
        return zip(a, b).reduce(0) { $0 + ($1.0 != $1.1 ? 1 : 0) }
    }

    private func shadow(r: String = "2.5", x: String = "0.5", y: String = "0.5", o: String = "0.9", c: String = "\"#0000FF\"") -> String {
        ", \"shadow\": {\"color\": \(c), \"radius\": \(r), \"offsetX\": \(x), \"offsetY\": \(y), \"opacity\": \(o)}"
    }

    @MainActor
    func testAWrittenShadowDrawsOnEveryLeaf() throws {
        for type in leaves.keys.sorted() {
            let none = try pixels(type, "")
            XCTAssertNotEqual(differing(none, try pixels(type, shadow(r: "8.5", x: "6.5", y: "6.5"))), 0, "\(type): an object shadow drew nothing")
            XCTAssertNotEqual(differing(none, try pixels(type, ", \"shadow\": \"#0000FF|6|6|0.5|8\"")), 0, "\(type): a pipe shadow drew nothing")
        }
    }

    @MainActor
    func testAWholeNumberIsReadAsDeclared() throws {
        for type in leaves.keys.sorted() {
            // A field read as absent falls to radius 5, offset 0.
            let defaults = try pixels(type, shadow(r: "5", x: "0", y: "0"))
            XCTAssertNotEqual(differing(defaults, try pixels(type, shadow(r: "8", x: "6", y: "6"))), 0,
                              "\(type): radius 8 / offset 6 drew as the defaults")
        }
    }

    @MainActor
    func testABoundFieldDrawsAsTheSameValueWritten() throws {
        let fields: [(String, String, String)] = [
            ("radius", shadow(r: "8.5"), shadow(r: "\"@{r}\"")),
            ("radius (a whole number in data)", shadow(r: "8"), shadow(r: "\"@{ri}\"")),
            ("offsetX", shadow(x: "6.5"), shadow(x: "\"@{x}\"")),
            ("offsetY", shadow(y: "6.5"), shadow(y: "\"@{y}\"")),
            ("opacity", shadow(o: "0.5"), shadow(o: "\"@{o}\"")),
            ("color", shadow(), shadow(c: "\"@{c}\"")),
        ]
        for type in leaves.keys.sorted() {
            let base = try pixels(type, shadow(c: "\"#00FF00\""))
            for (field, written, bound) in fields {
                let w = try pixels(type, written)
                XCTAssertNotEqual(differing(base, w), 0, "\(type) \(field): the written value drew as the base")
                XCTAssertEqual(differing(w, try pixels(type, bound)), 0, "\(type) \(field): the bound value drew differently from the same value written")
            }
        }
    }

    @MainActor
    func testABoundColourThatDoesNotResolveCastsNoShadow() throws {
        // codegen's `?? Color.clear` for a bound colour.
        for type in ["View", "Label", "Button"] {
            XCTAssertEqual(differing(try pixels(type, ""), try pixels(type, shadow(c: "\"@{nope}\""))), 0, "\(type): an unset bound colour cast a shadow")
        }
    }

    @MainActor
    func testOpacityDrawsOnEveryLeaf() throws {
        for type in leaves.keys.sorted() {
            let none = try pixels(type, "")
            let written = try pixels(type, ", \"opacity\": 0.3")
            XCTAssertNotEqual(differing(none, written), 0, "\(type): opacity 0.3 drew as opaque")
            XCTAssertEqual(differing(written, try pixels(type, ", \"opacity\": \"@{v}\"")), 0, "\(type): a bound opacity drew differently")
        }
    }
}
#endif
