import XCTest
import SwiftUI
import UIKit
@testable import SwiftJsonUI

#if DEBUG
/// An empty View's background paints, written or bound, and an empty
/// SafeAreaView paints like one (jsonui-cli ticket
/// 2026-11-08-ios-dynamic-empty-view-bound-background):
///   - the empty View's fill read its colour without data, so "@{c}" painted
///     clear, while a View with a child and codegen painted it;
///   - an empty SafeAreaView was EmptyView, which lays out nothing, so a sized
///     one with a background drew nothing while Android and the web drew it.
/// Drawn with `layer.render` (`drawHierarchy` draws nothing inside a test).
final class DynamicEmptyViewBackgroundTests: XCTestCase {
    private let data: [String: Any] = ["c6": "#FF0000", "c8": "#80FF0000"]
    private let red: [UInt8] = [255, 0, 0]
    private let halfRed: [UInt8] = [255, 127, 127]   // #80FF0000 (alpha first) over white

    @MainActor
    private func pixel(_ json: String) throws -> [UInt8] {
        let raw = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        let component = try JSONDecoder().decode(DynamicComponent.self,
                                                 from: JSONSerialization.data(withJSONObject: StyleProcessor.processStyles(raw)))
        let host = UIHostingController(rootView: AnyView(ZStack { DynamicComponentBuilder(component: component, data: data) }
            .frame(width: 160, height: 160).background(Color.white)))
        if #available(iOS 16.4, *) { host.safeAreaRegions = [] }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 160, height: 160))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.15))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: host.view.bounds, format: format).image { host.view.layer.render(in: $0.cgContext) }
        window.isHidden = true
        let cg = try XCTUnwrap(image.cgImage)
        var px = [UInt8](repeating: 0, count: 4)
        let ctx = try XCTUnwrap(CGContext(data: &px, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                          space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        ctx.draw(cg, in: CGRect(x: -80, y: -80, width: cg.width, height: cg.height))
        return Array(px.prefix(3))
    }

    private func near(_ a: [UInt8], _ b: [UInt8]) -> Bool { zip(a, b).allSatisfy { abs(Int($0) - Int($1)) <= 3 } }

    private func writeStyle(_ name: String, _ json: String) throws {
        let dir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] + "/Styles/"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try json.write(toFile: dir + name + ".json", atomically: true, encoding: .utf8)
        StyleProcessor.clearCache()
    }

    @MainActor
    func testAnEmptyViewPaintsItsBoundBackground() throws {
        try writeStyle("empty_view_bg_bound", "{\"background\": \"@{c6}\"}")
        let cases: [(String, String, [UInt8])] = [
            ("bound", ", \"background\": \"@{c6}\"", red),
            ("bound, 8-digit", ", \"background\": \"@{c8}\"", halfRed),
            ("bound through a style", ", \"style\": \"empty_view_bg_bound\"", red),
            ("written (control)", ", \"background\": \"#FF0000\"", red),
        ]
        for (name, attr, want) in cases {
            let got = try pixel("{\"type\": \"View\", \"id\": \"p\", \"width\": 120, \"height\": 120\(attr)}")
            XCTAssertTrue(near(got, want), "an empty View, \(name): painted \(got), not \(want)")
        }
    }

    @MainActor
    func testAnEmptySafeAreaViewPaintsLikeAnEmptyView() throws {
        for (name, attr, want) in [("written", ", \"background\": \"#FF0000\"", red), ("bound", ", \"background\": \"@{c6}\"", red),
                                   ("written, 8-digit", ", \"background\": \"#80FF0000\"", halfRed)] {
            let got = try pixel("{\"type\": \"SafeAreaView\", \"id\": \"p\", \"width\": 120, \"height\": 120\(attr)}")
            XCTAssertTrue(near(got, want), "an empty SafeAreaView, \(name): painted \(got), not \(want)")
        }
        // Unsized and without a background it still takes no room, as an empty View.
        let nothing = try pixel("{\"type\": \"SafeAreaView\", \"id\": \"p\"}")
        XCTAssertTrue(near(nothing, [255, 255, 255]), "an unsized empty SafeAreaView painted \(nothing)")
    }
}
#endif
