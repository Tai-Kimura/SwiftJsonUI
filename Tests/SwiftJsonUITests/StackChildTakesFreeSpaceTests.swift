//
//  StackChildTakesFreeSpaceTests.swift
//  SwiftJsonUITests
//
//  A stack child that takes the free space along the main axis with a Spacer
//  of its own (alignRight / alignLeft / centerHorizontal in a row, alignBottom
//  / alignTop / centerVertical in a column) has it all: the stack's gravity
//  Spacer stands down, as flexbox's justify-content does for an auto margin.
//  Beside the gravity Spacer the two split the free space — in a matchParent
//  row alignRight drew in the middle and centerHorizontal a third of the way
//  along; a column did the same to alignBottom (ticket sjui-hstack-alignright-
//  centred-by-trailing-spacer). Dynamic route; sjui_tools' codegen has its
//  own arm. The blue child's box is read from the rendered pixels in a
//  375-wide host; the row is 60 high, the column 120.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
@available(iOS 16.0, *)
final class StackChildTakesFreeSpaceTests: XCTestCase {

    private let width: CGFloat = 375
    private let height: CGFloat = 600

    private func row(_ child: String, gravity: String? = nil, width: String = #""matchParent""#) -> String {
        let g = gravity.map { #""gravity": "\#($0)", "# } ?? ""
        return #"{"type": "View", "orientation": "horizontal", \#(g)"width": \#(width), "height": 60, "child": [\#(child)]}"#
    }

    private func column(_ child: String, gravity: String? = nil) -> String {
        let g = gravity.map { #""gravity": "\#($0)", "# } ?? ""
        return #"{"type": "View", "orientation": "vertical", "width": "matchParent", "height": 120, "child": [{"type": "View", "orientation": "vertical", \#(g)"width": "matchParent", "height": "matchParent", "child": [\#(child)]}]}"#
    }

    private func blue(_ attrs: String = "") -> String {
        ##"{"type": "View", "id": "blue", "width": 40, "height": 40, "background": "#0000FF"\##(attrs.isEmpty ? "" : ", " + attrs)}"##
    }

    private let gray = ##"{"type": "View", "id": "gray", "width": 40, "height": 40, "background": "#888888"}"##

    @MainActor
    func testTheChildsOwnSpacerHasAllTheFreeSpace() throws {
        let cases: [(String, String, CGPoint)] = [
            ("row alignRight", row(blue(#""alignRight": true"#)), CGPoint(x: 335, y: 0)),
            ("row centerHorizontal", row(blue(#""centerHorizontal": true"#)), CGPoint(x: 167.5, y: 0)),
            ("row centerInParent", row(blue(#""centerInParent": true"#)), CGPoint(x: 167.5, y: 10)),
            ("row a box then alignRight", row(gray + ", " + blue(#""alignRight": true"#)), CGPoint(x: 335, y: 0)),
            ("row alignLeft then a box", row(blue(#""alignLeft": true"#) + ", " + gray), CGPoint(x: 0, y: 0)),
            ("row gravity right, alignLeft", row(blue(#""alignLeft": true"#), gravity: "right"), CGPoint(x: 0, y: 0)),
            ("row gravity right, centerHorizontal", row(blue(#""centerHorizontal": true"#), gravity: "right"), CGPoint(x: 167.5, y: 0)),
            ("row 300 wide, alignRight", row(blue(#""alignRight": true"#), width: "300"), CGPoint(x: 260, y: 0)),
            ("row, no alignment", row(blue()), CGPoint(x: 0, y: 0)),
            ("row gravity right, no alignment", row(blue(), gravity: "right"), CGPoint(x: 335, y: 0)),
            ("column alignBottom", column(blue(#""alignBottom": true"#)), CGPoint(x: 0, y: 80)),
            ("column centerVertical", column(blue(#""centerVertical": true"#)), CGPoint(x: 0, y: 40)),
            ("column gravity bottom, alignTop", column(blue(#""alignTop": true"#), gravity: "bottom"), CGPoint(x: 0, y: 0)),
            ("column, no alignment", column(blue()), CGPoint(x: 0, y: 0)),
        ]
        var wrong: [String] = []
        for (name, json, want) in cases {
            let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
            let got = try blueBox(of: AnyView(DynamicComponentBuilder(component: component, data: [:], viewId: nil)))
            let ok = abs(got.minX - want.x) < 1 && abs(got.minY - want.y) < 1
            print("STACK_FREE_SPACE \(name): \(got) want \(want) \(ok ? "ok" : "WRONG")")
            if !ok { wrong.append("\(name): blue at \(got.origin), want \(want)") }
        }
        XCTAssertEqual(wrong, [], wrong.joined(separator: "\n"))
    }

    /// The box after the alignLeft child is pushed to the far end, as an auto
    /// margin pushes it on the web: its own Spacer takes all the free space.
    @MainActor
    func testTheBoxAfterAnAlignLeftChildIsPushedToTheEnd() throws {
        let json = row(##"{"type": "View", "width": 40, "height": 40, "background": "#888888", "alignLeft": true}, "## + blue())
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        let got = try blueBox(of: AnyView(DynamicComponentBuilder(component: component, data: [:], viewId: nil)))
        XCTAssertEqual(got.minX, 335, accuracy: 1, "the box after an alignLeft child")
    }

    // MARK: hosting

    /// The box (in points) of the pure blue pixels.
    @MainActor
    private func blueBox(of content: AnyView) throws -> CGRect {
        let host = UIHostingController(rootView: content.frame(width: width, height: height, alignment: .topLeading).background(Color.white))
        if #available(iOS 16.4, *) { host.safeAreaRegions = [] }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: host.view.bounds, format: format).image { context in
            host.view.layer.render(in: context.cgContext)
        }
        window.isHidden = true
        let cg = try XCTUnwrap(image.cgImage)
        let w = cg.width, h = cg.height
        var buffer = [UInt8](repeating: 0, count: w * h * 4)
        let ctx = CGContext(data: &buffer, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        var minX = Int.max, minY = Int.max, maxX = -1, maxY = -1
        for y in 0..<h {
            for x in 0..<w {
                let i = (y * w + x) * 4
                if buffer[i] < 10 && buffer[i + 1] < 10 && buffer[i + 2] > 245 {
                    minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
                }
            }
        }
        guard maxX >= 0 else { return .null }
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }
}
#endif // DEBUG
