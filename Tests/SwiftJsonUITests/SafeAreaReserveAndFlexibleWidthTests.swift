//
//  SafeAreaReserveAndFlexibleWidthTests.swift
//  SwiftJsonUITests
//
//  Two iOS-only boxes the frame-parity inventory found away from their
//  declaration (2026-10-05), both measured on Android and web:
//
//  - safeAreaInsetPositions reserves the safe area (the SSoT: "Which edges
//    reserve the safe area"; rjui pads by env(safe-area-inset-*)). A box that
//    touches no screen edge has nothing to reserve, and one that does reserves
//    the inset and nothing more. `.safeAreaPadding(edges)` without a length
//    adds SwiftUI's default padding (16) on top: the children of a 200 x 200
//    box in the middle of the page drew 16 down where Android and web drew 0.
//  - flexible is about the height. A 200-wide flexible TextView drew the
//    whole 402 of its parent where Android and web drew 200.
//
//  The box's red child is looked for in the rendered layer tree, as
//  HorizontalScrollCrossAxisTests does, and measured from the top of the
//  grey box itself: the attribute must not move the box's content by
//  anything of its own. Measured without the fix: 16 in the middle of the
//  page, and 16 at the top edge of a page drawn to the window's edge.
//  Not measured here: that a box against a real safe area reserves exactly
//  that inset. In this test host the 30-pt additionalSafeAreaInsets did not
//  move the page (the box drew at row 0), so the inset itself has no reading
//  here; SwiftUI lays a page that does not ignore the safe area out below
//  it.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class SafeAreaReserveAndFlexibleWidthTests: XCTestCase {

    private func safeAreaLayout(topMargin: Int) -> String {
        """
        {
          "type": "View", "id": "root", "width": "matchParent", "height": "matchParent",
          "child": [
            { "type": "View", "id": "target", "width": 200, "height": 200, "topMargin": \(topMargin),
              "background": "#DDDDDD", "safeAreaInsetPositions": ["top"],
              "child": [ { "type": "View", "id": "box", "width": 40, "height": 40, "background": "#FF0000" } ] }
          ]
        }
        """
    }

    /// 100 down the page: no screen edge, so nothing to reserve.
    @MainActor
    func testABoxThatTouchesNoEdgeReservesNothing() throws {
        let drawn = try render(safeAreaLayout(topMargin: 100), safeAreaTop: 30)
        let inside = try childBelowBoxTop(drawn)
        XCTAssertEqual(inside, 0, "the child is \(inside) below the box's top; 16 is SwiftUI's default padding added")
    }

    /// At the top edge of a page drawn to the window's edge: no 16 of its own.
    @MainActor
    func testABoxAtTheEdgeAddsNoPaddingOfItsOwn() throws {
        let drawn = try render(safeAreaLayout(topMargin: 0), safeAreaTop: 30, toTheEdge: true)
        let inside = try childBelowBoxTop(drawn)
        XCTAssertEqual(inside, 0, "the child is \(inside) below the box's top; 16 is SwiftUI's default padding")
    }

    private func childBelowBoxTop(_ drawn: (red: (rows: [Int], columns: [Int]), grey: (rows: [Int], columns: [Int]))) throws -> Int {
        let red = try XCTUnwrap(drawn.red.rows.first, "the child did not draw — the measurement would say nothing")
        let grey = try XCTUnwrap(drawn.grey.rows.first, "the box did not draw — the measurement would say nothing")
        return red - grey
    }

    @MainActor
    func testAFlexibleTextViewKeepsItsDeclaredWidth() throws {
        let layout = """
        {
          "type": "View", "id": "root", "width": "matchParent", "height": "matchParent",
          "child": [
            { "type": "TextView", "id": "target", "width": 200, "height": 100, "hint": "Sample",
              "flexible": true, "background": "#FF0000" }
          ]
        }
        """
        let columns = try render(layout, safeAreaTop: 0).red.columns
        XCTAssertFalse(columns.isEmpty, "the TextView did not draw — the measurement would say nothing")
        XCTAssertEqual(columns.count, 200, "the TextView is \(columns.count) wide, declared 200")
    }

    // MARK: - drawing

    @MainActor
    private func render(_ json: String, safeAreaTop: CGFloat, toTheEdge: Bool = false) throws
        -> (red: (rows: [Int], columns: [Int]), grey: (rows: [Int], columns: [Int])) {
        let component = try JSONDecoder().decode(DynamicComponent.self, from: json.data(using: .utf8)!)
        let page = DynamicComponentBuilder(component: component, data: [:], viewId: nil)
            .frame(width: 390, height: 500, alignment: .topLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.white)
        let host = UIHostingController(rootView: toTheEdge ? AnyView(page.ignoresSafeArea()) : AnyView(page))
        if #available(iOS 16.4, *) { host.safeAreaRegions = safeAreaTop > 0 ? .all : [] }
        host.additionalSafeAreaInsets = UIEdgeInsets(top: safeAreaTop, left: 0, bottom: 0, right: 0)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 600))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: host.view.bounds, format: format).image { context in
            host.view.layer.render(in: context.cgContext)
        }
        window.isHidden = true
        guard let cg = image.cgImage else {
            XCTFail("render produced no image")
            return (([], []), ([], []))
        }
        return (extent(cg, rgb: (255, 0, 0)), extent(cg, rgb: (0xDD, 0xDD, 0xDD)))
    }

    /// The rows and the columns holding at least one pixel within ±2 of the RGB.
    private func extent(_ image: CGImage, rgb: (Int, Int, Int)) -> (rows: [Int], columns: [Int]) {
        let width = image.width, height = image.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let ctx = CGContext(data: &buffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        var rows = Set<Int>(), columns = Set<Int>()
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                if abs(Int(buffer[i]) - rgb.0) <= 2 && abs(Int(buffer[i + 1]) - rgb.1) <= 2 && abs(Int(buffer[i + 2]) - rgb.2) <= 2 {
                    rows.insert(y); columns.insert(x)
                }
            }
        }
        return (rows.sorted(), columns.sorted())
    }
}
#endif // DEBUG
