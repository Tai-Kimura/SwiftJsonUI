//
//  UnstyledLabelKeepsBodyTests.swift
//  SwiftJsonUITests
//
//  A Label that writes no font attribute, in an app with no fontProvider, keeps the environment's `.body`, as it did
//  before the text size rule (the orchestrator's ruling 2026-11-14). The rule drew it at the configured size's system
//  font: the same 17 pt SF, but lines 20.3 high where `.body`'s are 22, so every multi-line Label shortened (2.5.36's
//  last conformance run moved 16 iOS Label pictures; SwiftJsonUI 10.36.0 drew them as the baseline).
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

final class UnstyledLabelKeepsBodyTests: XCTestCase {
    private let text = "Sample text long enough to wrap onto several lines inside the two hundred point wide conformance hosts"
    private var savedProvider: ((FontSpec) -> Font?)?

    override func setUp() {
        super.setUp()
        savedProvider = SwiftJsonUIConfiguration.shared.fontProvider
        SwiftJsonUIConfiguration.shared.fontProvider = nil
    }

    override func tearDown() {
        SwiftJsonUIConfiguration.shared.fontProvider = savedProvider
        super.tearDown()
    }

    private func height<V: View>(_ view: V, typeSize: DynamicTypeSize = .large) -> CGFloat {
        let host = UIHostingController(rootView: view.frame(width: 200, alignment: .leading)
            .environment(\.dynamicTypeSize, typeSize))
        return host.sizeThatFits(in: CGSize(width: 200, height: 10_000)).height
    }

    func testAnUnstyledMultiLineLabelIsAsTallAsBody() {
        let body = height(Text(text).font(.body))
        let label = height(PartialAttributedText(text))
        XCTAssertGreaterThan(body, 66, "the text wraps onto several lines (\(body))")
        XCTAssertEqual(label, body, accuracy: 0.5, "an unstyled Label draws as .body")
    }

    func testAnUnstyledLinkableLabelIsAsTallAsBody() {
        let linked = "See https://example.com/conformance for details, wrapping onto a second and a third line here"
        let body = height(Text(linked).font(.body))
        let label = height(PartialAttributedText(linked, linkable: true))
        XCTAssertEqual(label, body, accuracy: 0.5, "the attributed path keeps .body too")
    }

    func testAFontSizeStillDrawsTheSizedSystemFont() {
        // Control: a written fontSize is the configured path, not .body.
        let sized = height(PartialAttributedText(text, fontSize: 17))
        let system = height(Text(text).font(.system(size: 17)))
        XCTAssertEqual(sized, system, accuracy: 0.5)
    }

    /// The unstyled text grows as `.body` does, by the text style's own table (the orchestrator's ruling (A),
    /// 2026-11-14), and maxFontScale is held by that table: under a 1.1 cap xLarge's `.body` (19 / 17 = 1.118) is too
    /// large, so the standard size is the step. The rule's ratios (UIFontMetrics, 18.67 at xLarge) would pick xLarge.
    func testTheBodyCapHoldsAtTheEdgeOfAStep() {
        XCTAssertGreaterThan(FontScaling.bodyRatio(.xLarge), 1.1, "xLarge's .body is over a 1.1 cap")
        XCTAssertLessThanOrEqual(FontScaling.ratio(.xLarge), 1.1, "the rule's ratio would have let xLarge through")
        let capped = FontScaling.bodyTypeSize(system: .accessibility5, declaration: FontScalingDeclaration(maxFontScale: 1.1))
        XCTAssertEqual(capped, .large)
        XCTAssertLessThanOrEqual(FontScaling.bodyRatio(capped), 1.1)
        // drawn: an unstyled Label capped at 1.1 under accessibility5 is as tall as .body at the standard size
        let label = height(PartialAttributedText(text)
            .environment(\.fontScalingDeclaration, FontScalingDeclaration(maxFontScale: 1.1)), typeSize: .accessibility5)
        let body = height(Text(text).font(.body))
        XCTAssertEqual(label, body, accuracy: 0.5, "capped at 1.1: .body's standard size")
    }

    func testTheBodyTableIsTheTextStyles() {
        // 17, 19, 21, 23, 28, 33 pt: .body's own sizes (the rule's ratios give 18.67, 20, 22.33, 26.33, 31)
        for (size, points) in [(DynamicTypeSize.xLarge, 19.0), (.xxLarge, 21), (.xxxLarge, 23), (.accessibility1, 28), (.accessibility2, 33)] {
            XCTAssertEqual(FontScaling.bodyRatio(size) * 17, points, accuracy: 0.01, "\(size)")
        }
    }

    func testAProviderStillTakesTheUnstyledText() {
        SwiftJsonUIConfiguration.shared.fontProvider = { _ in .system(size: 30) }
        let provided = height(PartialAttributedText(text))
        let body = height(Text(text).font(.body))
        XCTAssertGreaterThan(provided, body + 20, "with a provider the unstyled text is the provider's (P1)")
    }
}
