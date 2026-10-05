//
//  LabelLineHeightMultipleTests.swift
//  SwiftJsonUITests
//
//  `lineHeightMultiple` puts (m - 1) x L between lines, L being the line of a
//  Label with no line height (2026-10-05 ruling B): every line after the
//  first is m x L. The first stays L — SwiftUI's Text has no per-line height,
//  an iOS limit kept by the 2026-10-05 user instruction (SSoT
//  lineHeightMultipleBase). The base was the font size: (m - 1) x 17 where L
//  is 20.33, 3 lines at 1.8 were 88.33; on L they are 93.5.
//
//  Both routes draw through PartialAttributedText: Dynamic's Label converter
//  and the sjui codegen's emit (`lineHeightMultiple: 1.8,`). A line is h1,
//  the height of the same Label with one line; SwiftUI's own gap between
//  lines (1.67 at 17pt) is what lineSpacing replaces, so n lines at m are
//  n x h1 + (n - 1) x (m - 1) x L, L the font's lineHeight (support lane 2's
//  table: 93.52 for 3 lines; the size base gave 88.33).
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class LabelLineHeightMultipleTests: XCTestCase {

    private let text = "one\ntwo\nthree"
    private let line = UIFont.systemFont(ofSize: 17).lineHeight

    @MainActor
    private func height(_ view: some View) -> CGFloat {
        UIHostingController(rootView: view.fixedSize())
            .sizeThatFits(in: CGSize(width: 300, height: CGFloat.infinity)).height
    }

    @MainActor
    private func dynamicLabel(_ text: String, _ extra: String) throws -> some View {
        let json = #"{"type": "Label", "id": "l", "text": ""# + text + #"", "fontSize": 17"# + extra + "}"
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        return DynamicComponentBuilder(component: component, data: [:], viewId: nil)
    }

    @MainActor
    func testDynamicSpacingIsOnTheLine() throws {
        let h1 = height(try dynamicLabel("one", ""))
        let multiple = height(try dynamicLabel(#"one\ntwo\nthree"#, #", "lineHeightMultiple": 1.8"#))
        XCTAssertEqual(multiple, 3 * h1 + 2 * 0.8 * line, accuracy: 0.5,
                       "Dynamic: 3 lines at 1.8 are \(multiple), want 3 x \(h1) + 2 x 0.8 x \(line)")
    }

    /// The shape label_converter.rb emits for `lineHeightMultiple: 1.8`.
    @MainActor
    func testCodegenSpacingIsOnTheLine() {
        let h1 = height(PartialAttributedText("one", fontSize: 17))
        let multiple = height(PartialAttributedText(text, fontSize: 17, lineHeightMultiple: 1.8))
        XCTAssertEqual(multiple, 3 * h1 + 2 * 0.8 * line, accuracy: 0.5,
                       "codegen: 3 lines at 1.8 are \(multiple), want 3 x \(h1) + 2 x 0.8 x \(line)")
    }

    /// The first line stays one line (the iOS limit), and a Label with no
    /// line height is unchanged.
    @MainActor
    func testOneLineStaysOneLine() {
        let h1 = height(PartialAttributedText("one", fontSize: 17))
        XCTAssertEqual(h1, line, accuracy: 0.5)
        XCTAssertEqual(height(PartialAttributedText("one", fontSize: 17, lineHeightMultiple: 1.8)), h1, accuracy: 0.5)
    }
}
#endif // DEBUG
