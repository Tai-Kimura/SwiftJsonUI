//
//  EmptyLabelLineTests.swift
//  SwiftJsonUITests
//
//  An empty Label is one line high (2026-10-05 user ruling 2): an empty Text
//  drew 14 where a line of the default font is 20.33 (conformance host
//  pixels; ticket sjui-an-empty-label-is-shorter-than-a-line). Measured on
//  PartialAttributedText, which Dynamic and the sjui codegen both draw a
//  Label through.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class EmptyLabelLineTests: XCTestCase {

    @MainActor
    private func height(_ view: some View) -> CGFloat {
        UIHostingController(rootView: view.fixedSize())
            .sizeThatFits(in: CGSize(width: 300, height: CGFloat.infinity)).height
    }

    @MainActor
    func testAnEmptyLabelIsOneLine() {
        let line = height(PartialAttributedText("A"))
        let empty = height(PartialAttributedText(""))
        XCTAssertEqual(empty, line, accuracy: 0.5, "an empty Label is \(empty) high, a line is \(line)")
    }
}
#endif // DEBUG
