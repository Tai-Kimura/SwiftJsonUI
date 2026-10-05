//
//  WrapCapTests.swift
//  SwiftJsonUITests
//
//  A wrapContent box stops at its parent's size (WrapCap; user ruling
//  2026-10-05, attribute_semantics wrapContentCap). In a 150x100 parent, a
//  wrapContent box (green, 150 wide) holding a 100x168 child (red) was 168
//  high on iOS — stacked or overlaid alike — where Android stops the box at
//  100 and lets the content run past it (conformance host pixels, both
//  routes; ticket sjui-wrap-content-box-exceeds-a-sized-parent).
//
//  The arms: the stacked and overlaid boxes stop at 100 while the content
//  still runs to 168. The neutral shapes — the ones a cap could break —
//  draw exactly what they drew before: a box smaller than its parent, a box
//  holding a Spacer, a weighted child, a child placed by gravity, a fixed
//  child larger than its parent (ruling S), and a ScrollView's content (no
//  offer along its axis, so no cap).
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class WrapCapTests: XCTestCase {

    // MARK: - Drawing

    private struct Spans {
        let green: Range<Int>?
        let red: Range<Int>?
        let blue: Range<Int>?
    }

    /// Rows holding the colour, read in the box's right strip (x 105..<148),
    /// which the 100-wide red child never covers — and red read at x 0..<95.
    @MainActor
    private func draw(_ content: AnyView) throws -> Spans {
        let host = UIHostingController(rootView: content
            .frame(width: 390, height: 500, alignment: .topLeading)
            .background(Color.white))
        if #available(iOS 16.4, *) { host.safeAreaRegions = [] }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 500))
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
        let width = cg.width, height = cg.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let ctx = CGContext(data: &buffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        func rows(_ rgb: (Int, Int, Int), _ xs: Range<Int>) -> Range<Int>? {
            var ys: [Int] = []
            for y in 0..<height {
                for x in xs {
                    let i = (y * width + x) * 4
                    if abs(Int(buffer[i]) - rgb.0) <= 2 && abs(Int(buffer[i + 1]) - rgb.1) <= 2 && abs(Int(buffer[i + 2]) - rgb.2) <= 2 {
                        ys.append(y); break
                    }
                }
            }
            guard let lo = ys.min(), let hi = ys.max() else { return nil }
            return lo..<(hi + 1)
        }
        return Spans(green: rows((0, 255, 0), 105..<148), red: rows((255, 0, 0), 0..<95), blue: rows((0, 0, 255), 0..<148))
    }

    @MainActor
    private func dynamic(_ json: String) throws -> Spans {
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        return try draw(AnyView(DynamicComponentBuilder(component: component, data: [:], viewId: nil)))
    }

    /// A 150x100 parent (orientation as given) holding a 150-wide wrapContent
    /// box whose child is 100 x `child` high.
    private func shape(parent orientation: String?, child: Int, boxExtra: String = "") -> String {
        let o = orientation.map { #""orientation": "\#($0)", "# } ?? ""
        return #"""
        { "type": "View", "id": "root", \#(o)"width": 150, "height": 100, "background": "#FFFFFF",
          "child": [ { "type": "View", "id": "box", "orientation": "vertical", "width": 150, \#(boxExtra)"background": "#00FF00",
            "child": [ { "type": "View", "id": "inner", "width": 100, "height": \#(child), "background": "#FF0000" } ] } ] }
        """#
    }

    // MARK: - Arms

    @MainActor
    func testAStackedWrapBoxStopsAtItsParent() throws {
        let s = try dynamic(shape(parent: "vertical", child: 168))
        XCTAssertEqual(s.green, 0..<100, "the box")
        XCTAssertEqual(s.red, 0..<168, "the content still runs past the box")
    }

    @MainActor
    func testAnOverlaidWrapBoxStopsAtItsParent() throws {
        let s = try dynamic(shape(parent: nil, child: 168))
        XCTAssertEqual(s.green, 0..<100, "the box")
        XCTAssertEqual(s.red, 0..<168, "the content still runs past the box")
    }

    /// The codegen shape: a VStack with a fixed child, `.wrapCap` in its fixed_size slot.
    @MainActor
    func testTheCodegenShapeStopsAtItsParent() throws {
        let view = VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Rectangle().fill(Color(red: 1, green: 0, blue: 0)).frame(width: 100, height: 168)
            }
            .frame(width: 150, alignment: .topLeading)
            .wrapCap(width: false, height: true)
            .background(Color(red: 0, green: 1, blue: 0))
        }
        .frame(width: 150, height: 100, alignment: .topLeading)
        let s = try draw(AnyView(view))
        XCTAssertEqual(s.green, 0..<100)
        XCTAssertEqual(s.red, 0..<168)
    }

    // MARK: - Neutral shapes

    @MainActor
    func testABoxSmallerThanItsParentIsUnchanged() throws {
        let s = try dynamic(shape(parent: "vertical", child: 60))
        XCTAssertEqual(s.green, 0..<60)
    }

    /// A box holding a Spacer takes the offer it is given; the cap gives the
    /// same — a content-fit cap (ideal size) would shrink it to 40.
    @MainActor
    func testABoxHoldingASpacerIsUnchanged() throws {
        func page(_ capped: Bool) -> some View {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle().fill(Color(red: 1, green: 0, blue: 0)).frame(width: 100, height: 40)
                    Spacer(minLength: 0)
                }
                .frame(width: 150)
                .wrapCap(width: false, height: capped)
                .background(Color(red: 0, green: 1, blue: 0))
            }
            .frame(width: 150, height: 100, alignment: .topLeading)
        }
        let before = try draw(AnyView(page(false))), after = try draw(AnyView(page(true)))
        XCTAssertEqual(after.green, before.green)
        XCTAssertEqual(after.green, 0..<100)
    }

    @MainActor
    func testAWeightedChildIsUnchanged() throws {
        let s = try dynamic(#"""
        { "type": "View", "id": "root", "orientation": "vertical", "width": 150, "height": 100, "background": "#FFFFFF",
          "child": [
            { "type": "View", "id": "box", "orientation": "vertical", "width": 150, "weight": 1, "background": "#00FF00",
              "child": [ { "type": "View", "id": "inner", "width": 100, "height": 30, "background": "#FF0000" } ] },
            { "type": "View", "id": "foot", "width": 150, "height": 20, "background": "#0000FF" } ] }
        """#)
        XCTAssertEqual(s.green, 0..<80, "the weighted box fills what the 20 leaves")
        XCTAssertEqual(s.blue, 80..<100)
    }

    @MainActor
    func testAChildPlacedByGravityIsUnchanged() throws {
        let s = try dynamic(#"""
        { "type": "View", "id": "root", "orientation": "vertical", "gravity": "bottom", "width": 150, "height": 100, "background": "#FFFFFF",
          "child": [ { "type": "View", "id": "box", "orientation": "vertical", "width": 150, "background": "#00FF00",
            "child": [ { "type": "View", "id": "inner", "width": 100, "height": 40, "background": "#FF0000" } ] } ] }
        """#)
        XCTAssertEqual(s.green, 60..<100, "a 40 box at the bottom of 100")
    }

    /// Ruling S: a FIXED child larger than its parent keeps its size.
    @MainActor
    func testAFixedChildLargerThanItsParentKeepsItsSize() throws {
        let s = try dynamic(shape(parent: "vertical", child: 168, boxExtra: #""height": 168, "#))
        XCTAssertEqual(s.green, 0..<168)
    }

    /// A ScrollView's content has no offer along its axis: no cap.
    @MainActor
    func testAScrollViewContentIsNotCapped() throws {
        let content = VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(Color(red: 1, green: 0, blue: 0)).frame(width: 100, height: 168)
        }
        .frame(width: 150, alignment: .topLeading)
        .wrapCap(width: true, height: true)
        let size = UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: 150, height: CGFloat.infinity))
        XCTAssertEqual(size.height, 168, accuracy: 0.5)
    }

    /// The cross axis of a vertical ScrollView is offered its width: a box
    /// wider than that stops at it (a 200-wide content in a 150-wide scroll).
    @MainActor
    func testAScrollViewContentIsCappedAcrossItsAxis() throws {
        let size = UIHostingController(rootView: VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(Color.red).frame(width: 200, height: 40)
        }.wrapCap(width: true, height: true)).sizeThatFits(in: CGSize(width: 150, height: CGFloat.infinity))
        XCTAssertEqual(size.width, 150, accuracy: 0.5, "the offered width caps the box")
        XCTAssertEqual(size.height, 40, accuracy: 0.5, "no offer along the scroll axis: the content's height")
    }
}
#endif // DEBUG
