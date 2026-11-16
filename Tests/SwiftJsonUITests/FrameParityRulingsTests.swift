//
//  FrameParityRulingsTests.swift
//  SwiftJsonUITests
//
//  Five families the 3-face frame-parity inventory of 2026-10-05 found on
//  iOS only, drawn by the Dynamic renderer:
//  1. `alignment` places a View's children as the gravity it names does
//     (every value drew them at 0, 0).
//  2. `distribution: fill` grows each child from its content (the children
//     split the axis equally, which is fillEqually).
//  3. A styled Indicator lays out at its scaled size (large and small took
//     medium's 20).
//  4. A reversed SafeAreaView starts at its start edge (it reversed the
//     children and stacked them from the top / left).
//  5. A showing hint is drawn in `hintAttributes.font` (bold drew regular)
//     and its `lineHeightMultiple` (read by nothing).
//  The sjui codegen arms are jsonui-cli
//  sjui_tools/spec/swiftui/views/frame_parity_ios_rulings_spec.rb.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class FrameParityRulingsTests: XCTestCase {

    // MARK: 1. alignment

    private func aligned(_ alignment: String, gravity: String = "") -> String {
        return """
        { "type": "View", "id": "root", "width": "matchParent", "height": "matchParent",
          "child": [
            { "type": "View", "id": "box", "alignment": "\(alignment)", \(gravity)"width": 200, "height": 200, "background": "#FFFFFF",
              "child": [ { "type": "View", "id": "a", "width": 40, "height": 40, "background": "#FF0000" } ] }
          ] }
        """
    }

    @MainActor
    func testAlignmentBottomPlacesTheChildBottomCentre() throws {
        let image = try draw(aligned("bottom"))
        XCTAssertEqual(span(image, rgb: (255, 0, 0), vertical: true), 160..<200)
        XCTAssertEqual(span(image, rgb: (255, 0, 0), vertical: false), 80..<120)
    }

    @MainActor
    func testAlignmentTrailingPlacesTheChildTrailingCentre() throws {
        let image = try draw(aligned("trailing"))
        XCTAssertEqual(span(image, rgb: (255, 0, 0), vertical: true), 80..<120)
        XCTAssertEqual(span(image, rgb: (255, 0, 0), vertical: false), 160..<200)
    }

    /// A declared gravity wins over alignment (control).
    @MainActor
    func testAGravityWinsOverAlignment() throws {
        let image = try draw(aligned("bottom", gravity: #""gravity": "top", "#))
        XCTAssertEqual(span(image, rgb: (255, 0, 0), vertical: true), 0..<40)
    }

    func testAlignmentReadsAsTheGravityItNames() {
        XCTAssertEqual(DynamicDecodingHelper.alignmentAsGravity("bottomTrailing"), ["bottom", "right"])
        XCTAssertEqual(DynamicDecodingHelper.alignmentAsGravity("top"), ["top", "centerHorizontal"])
        XCTAssertNil(DynamicDecodingHelper.alignmentAsGravity("BottomTrailing"), "a spelling declared in no case")
    }

    // MARK: 2. distribution fill

    func testFillAddsAnEqualShareOfWhatIsLeftToTheContent() {
        // 300 wide: a fixed 60, contents 37 and 83 -> 60 / 97 / 143.
        XCTAssertEqual(DistributionFillLayout.grow([60, 37, 83], grows: [false, true, true], available: 300, spacing: 0),
                       [60, 97, 143])
        // Nothing left: the contents stand; fill never shrinks.
        XCTAssertEqual(DistributionFillLayout.grow([200, 150], grows: [true, true], available: 300, spacing: 0),
                       [200, 150])
    }

    @MainActor
    func testFillGivesTheLongerLabelMoreWidth() throws {
        let image = try draw("""
        { "type": "View", "id": "root", "width": "matchParent", "height": "matchParent",
          "child": [
            { "type": "View", "id": "row", "width": 300, "height": 100, "orientation": "horizontal", "distribution": "fill",
              "background": "#FFFFFF",
              "child": [
                { "type": "View", "id": "a", "width": 60, "height": 40, "background": "#FF0000" },
                { "type": "Label", "id": "b", "text": "BBBB", "background": "#0000FF" },
                { "type": "Label", "id": "c", "text": "CCCCCCCC", "background": "#00AA00" }
              ] }
          ] }
        """)
        let red = try XCTUnwrap(span(image, rgb: (255, 0, 0), vertical: false))
        let blue = try XCTUnwrap(span(image, rgb: (0, 0, 255), vertical: false))
        let green = try XCTUnwrap(span(image, rgb: (0, 170, 0), vertical: false))
        XCTAssertEqual(red, 0..<60, "a declared child keeps its size")
        XCTAssertGreaterThan(green.count, blue.count + 20, "the longer label is not wider: the children were split equally")
        XCTAssertEqual(green.upperBound, 300, "the row is not filled")
    }

    // MARK: 3. Indicator

    @MainActor
    func testALargeIndicatorTakesItsScaledSpace() throws {
        let medium = try size("""
        { "type": "Indicator", "id": "i", "indicatorStyle": "medium" }
        """)
        let large = try size("""
        { "type": "Indicator", "id": "i", "indicatorStyle": "large" }
        """)
        let small = try size("""
        { "type": "Indicator", "id": "i", "indicatorStyle": "small" }
        """)
        XCTAssertEqual(large.width, medium.width * 1.5, accuracy: 0.5)
        XCTAssertEqual(small.width, medium.width * 0.8, accuracy: 0.5)
    }

    // MARK: 4. SafeAreaView

    @MainActor
    func testABottomToTopSafeAreaViewStartsAtTheBottom() throws {
        let image = try draw("""
        { "type": "View", "id": "root", "width": "matchParent", "height": "matchParent",
          "child": [
            { "type": "View", "id": "frame", "width": 200, "height": 200, "background": "#FFFFFF",
              "child": [
                { "type": "SafeAreaView", "id": "sa", "width": "matchParent", "height": "matchParent",
                  "orientation": "vertical", "direction": "bottomToTop",
                  "child": [
                    { "type": "View", "id": "a", "width": 40, "height": 40, "background": "#FF0000" },
                    { "type": "View", "id": "b", "width": 40, "height": 40, "background": "#0000FF" }
                  ] }
              ] }
          ] }
        """)
        XCTAssertEqual(span(image, rgb: (255, 0, 0), vertical: true), 160..<200, "the first child is not at the bottom")
        XCTAssertEqual(span(image, rgb: (0, 0, 255), vertical: true), 120..<160)
    }

    // MARK: 5. hint font

    @MainActor
    func testAShowingHintIsDrawnInItsFont() throws {
        func hint(_ font: String) -> String {
            return """
            { "type": "View", "id": "root", "width": "matchParent", "height": "matchParent",
              "child": [ { "type": "Label", "id": "l", "width": 380, "hint": "Conformance Hint",
                           "hintAttributes": { \(font)"fontSize": 24, "fontColor": "#FF0000" } } ] }
            """
        }
        let bold = try XCTUnwrap(span(try draw(hint(#""font": "bold", "#)), rgb: (255, 0, 0), vertical: false, tolerance: 60))
        let regular = try XCTUnwrap(span(try draw(hint("")), rgb: (255, 0, 0), vertical: false, tolerance: 60))
        XCTAssertGreaterThan(bold.count, regular.count + 5, "the bold hint is drawn at the regular weight")
    }

    /// The hint's lineHeightMultiple is applied while it shows: a bold 24
    /// hint wraps to two lines in 200, and 1.5 opens the gap between them.
    @MainActor
    func testAShowingHintTakesItsLineHeightMultiple() throws {
        func hint(_ multiple: String) -> String {
            return """
            { "type": "Label", "id": "l", "width": 200, "hint": "Conformance Hint",
              "hintAttributes": { "font": "bold", "fontSize": 24, \(multiple)"fontColor": "#FF0000" } }
            """
        }
        let plain = try size(hint(""))
        let spaced = try size(hint(#""lineHeightMultiple": 1.5, "#))
        XCTAssertGreaterThan(spaced.height, plain.height + 5, "the hint's lineHeightMultiple is not applied")
    }

    // MARK: - Drawing

    @MainActor
    private func host(_ json: String) throws -> UIHostingController<AnyView> {
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        return UIHostingController(rootView: AnyView(DynamicComponentBuilder(component: component, data: [:], viewId: nil)))
    }

    @MainActor
    private func size(_ json: String) throws -> CGSize {
        try host(json).sizeThatFits(in: CGSize(width: 390, height: 500))
    }

    @MainActor
    private func draw(_ json: String) throws -> CGImage {
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        let host = UIHostingController(rootView: DynamicComponentBuilder(component: component, data: [:], viewId: nil)
            .frame(width: 390, height: 500, alignment: .topLeading)
            .background(Color.white))
        // The window's safe area would push the drawing down.
        if #available(iOS 16.4, *) { host.safeAreaRegions = [] }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 500))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: host.view.bounds, format: format).image { context in
            host.view.layer.render(in: context.cgContext)
        }
        window.isHidden = true
        return try XCTUnwrap(image.cgImage)
    }

    /// The rows (vertical) or columns holding a pixel within `tolerance` of the RGB.
    private func span(_ image: CGImage, rgb: (Int, Int, Int), vertical: Bool, tolerance: Int = 2) -> Range<Int>? {
        let width = image.width, height = image.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let ctx = CGContext(data: &buffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        var hits: [Int] = []
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                if abs(Int(buffer[i]) - rgb.0) <= tolerance && abs(Int(buffer[i + 1]) - rgb.1) <= tolerance
                    && abs(Int(buffer[i + 2]) - rgb.2) <= tolerance {
                    hits.append(vertical ? y : x)
                }
            }
        }
        guard let lo = hits.min(), let hi = hits.max() else { return nil }
        return lo..<(hi + 1)
    }
}
#endif // DEBUG
