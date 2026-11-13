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

    private func height<V: View>(_ view: V) -> CGFloat {
        let host = UIHostingController(rootView: view.frame(width: 200, alignment: .leading)
            .environment(\.dynamicTypeSize, .large))
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

    func testAProviderStillTakesTheUnstyledText() {
        SwiftJsonUIConfiguration.shared.fontProvider = { _ in .system(size: 30) }
        let provided = height(PartialAttributedText(text))
        let body = height(Text(text).font(.body))
        XCTAssertGreaterThan(provided, body + 20, "with a provider the unstyled text is the provider's (P1)")
    }
}
