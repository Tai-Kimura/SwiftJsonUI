import SwiftUI
import XCTest
@testable import SwiftJsonUI

/// The corner a component draws when its layout writes no cornerRadius
/// (ruling 2026-11-15, ticket jui-button-default-corner-radius-differs):
/// Button, TextField and TextView 0, SelectBox 8, on every face. Read off the
/// drawn picture: along the top-left diagonal of the component's box, how
/// many pixels stay clear before its fill begins (a corner of radius r leaves
/// about r × (1 - 1/√2) of them, 2 for 8 at scale 1).
@MainActor
final class DefaultCornerRadiusTests: XCTestCase {
    private let inset = 10

    /// Clear pixels on the diagonal from the box's top-left corner.
    private func cornerGap<V: View>(_ view: V) throws -> Int {
        let renderer = ImageRenderer(content: view.frame(width: 200, height: 60).padding(CGFloat(inset)))
        renderer.scale = 1
        let cg = try XCTUnwrap(renderer.cgImage)
        let w = cg.width, h = cg.height
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        let ctx = try XCTUnwrap(CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        var d = 0
        while d < 20 {
            let x = inset + d, y = inset + d
            if pixels[(y * w + x) * 4 + 3] > 128 { break }
            d += 1
        }
        XCTAssertLessThan(d, 20, "the component drew no fill at all")
        return d
    }

    private func dynamic(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }

    // MARK: - The measure itself

    func testTheMeasureReadsASquareAndARoundedBox() throws {
        XCTAssertEqual(try cornerGap(Color.red), 0)
        XCTAssertGreaterThanOrEqual(try cornerGap(Color.red.cornerRadius(8)), 2)
        XCTAssertGreaterThanOrEqual(try cornerGap(Color.red.cornerRadius(20)), 5)
    }

    // MARK: - Generated code's components (the static face)

    func testAStaticButtonIsSquare() throws {
        XCTAssertEqual(try cornerGap(StateAwareButtonView(text: "Sample", action: {}, width: 200, height: 60)), 0)
        XCTAssertGreaterThanOrEqual(
            try cornerGap(StateAwareButtonView(text: "Sample", action: {}, cornerRadius: 8, width: 200, height: 60)), 2,
            "a written cornerRadius still rounds it")
    }

    func testAStaticTextViewIsSquare() throws {
        XCTAssertEqual(try cornerGap(TextViewWithPlaceholder(text: .constant(""), backgroundColor: .red)), 0)
    }

    func testAStaticSelectBoxIsRoundedBy8() throws {
        XCTAssertGreaterThanOrEqual(try cornerGap(SelectBoxView(prompt: "Choose", backgroundColor: .red)), 2)
        XCTAssertLessThan(try cornerGap(SelectBoxView(prompt: "Choose", backgroundColor: .red)), 5)
    }

    // MARK: - Dynamic

    func testADynamicButtonIsSquare() throws {
        let c = try dynamic(##"{ "type": "Button", "text": "Sample", "width": 200, "height": 60 }"##)
        XCTAssertEqual(try cornerGap(ButtonConverter.convert(component: c, data: [:])), 0)
    }

    func testADynamicTextFieldIsSquare() throws {
        let c = try dynamic(##"{ "type": "TextField", "text": "Sample", "background": "#FF0000", "width": 200, "height": 60 }"##)
        XCTAssertEqual(try cornerGap(TextFieldConverter.convert(component: c, data: [:])), 0)
    }

    func testADynamicTextViewIsSquare() throws {
        let c = try dynamic(##"{ "type": "TextView", "text": "Sample", "background": "#FF0000", "width": 200, "height": 60 }"##)
        XCTAssertEqual(try cornerGap(TextViewConverter.convert(component: c, data: [:])), 0)
    }

    func testADynamicSelectBoxIsRoundedBy8() throws {
        let c = try dynamic(##"{ "type": "SelectBox", "hint": "Choose", "background": "#FF0000", "width": 200, "height": 60 }"##)
        let gap = try cornerGap(SelectBoxConverter.convert(component: c, data: [:]))
        XCTAssertGreaterThanOrEqual(gap, 2)
        XCTAssertLessThan(gap, 5)
    }
}
