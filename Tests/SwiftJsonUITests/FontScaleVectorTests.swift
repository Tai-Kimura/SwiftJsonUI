//
//  FontScaleVectorTests.swift
//  SwiftJsonUITests
//
//  The text size rule's vectors (jsonui-cli shared/core/font_scale_vectors.json, vendored byte-identical in Fixtures
//  and checked against JSONUI_CLI_MANIFEST_REF by ci.yml), run against the library's own reading of it
//  (FontScaleRule, FontScaling). KotlinJsonUI and rjui read the same file; jui_tools tests it against the reference
//  implementation, shared/core/font_scale_rule.py.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

final class FontScaleVectorTests: XCTestCase {
    private var vectors: [String: Any] = [:]

    override func setUpWithError() throws {
        let data = try TestFixtures.loadJSON(named: "font_scale_vectors")
        vectors = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func num(_ value: Any?) -> CGFloat? { (value as? NSNumber).map { CGFloat($0.doubleValue) } }

    func testDrawn() throws {
        let cases = try XCTUnwrap(vectors["drawn"] as? [[String: Any]])
        XCTAssertFalse(cases.isEmpty)
        for c in cases {
            let name = c["name"] as? String ?? "?"
            let got = FontScaleRule.drawn(size: num(c["size"])!, scale: num(c["scale"])!, declared: c["declared"] as? Bool,
                                          maxScale: num(c["max"]), appDefault: c["appDefault"] as? Bool ?? true)
            XCTAssertEqual(got, num(c["drawn"])!, accuracy: 0.0001, name)
        }
    }

    func testIOSCapStep() throws {
        let section = try XCTUnwrap(vectors["iosCap"] as? [String: Any])
        let ratios = try XCTUnwrap(section["ratios"] as? [String: Any])
        let names = ["large", "xLarge", "xxLarge", "xxxLarge", "accessibility1", "accessibility2", "accessibility3",
                     "accessibility4", "accessibility5"]
        XCTAssertEqual(Set(ratios.keys), Set(names))
        let steps = names.map { ($0, num(ratios[$0])!) }
        for c in try XCTUnwrap(section["cases"] as? [[String: Any]]) {
            let got = FontScaleRule.capStep(num(c["max"]), steps: steps)
            XCTAssertEqual(got, c["step"] as? String, c["name"] as? String ?? "?")
        }
    }

    /// The step ratios this OS's UIFontMetrics gives are the vectors' measured ones (iOS 27.2), within a hair; on
    /// another OS they may differ, which the rule allows (it reads the running OS).
    func testTheStepRatiosAreTheRunningOSOnes() throws {
        let ratios = try XCTUnwrap((vectors["iosCap"] as? [String: Any])?["ratios"] as? [String: Any])
        let measured = FontScaling.steps.map { FontScaling.ratio($0) }
        XCTAssertEqual(measured.first ?? 0, 1, accuracy: 0.0001)
        XCTAssertEqual(measured, measured.sorted(), "the steps grow")
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27 {
            XCTAssertEqual(FontScaling.ratio(.accessibility5), num(ratios["accessibility5"])!, accuracy: 0.001)
        }
    }

    /// The factor the components draw at, through the app default and a component's declaration.
    func testFactorFollowsTheDeclarationAndTheAppDefault() {
        let config = SwiftJsonUIConfiguration.shared.font
        let saved = (config.scaling, config.maxScale)
        defer { config.scaling = saved.0; config.maxScale = saved.1 }
        config.scaling = true; config.maxScale = nil
        let ax5 = FontScaling.ratio(.accessibility5)
        XCTAssertEqual(FontScaling.factor(system: .accessibility5, declaration: .init()), ax5, accuracy: 0.0001)
        XCTAssertEqual(FontScaling.factor(system: .accessibility5, declaration: .init(scaling: false)), 1)
        XCTAssertEqual(FontScaling.factor(system: .large, declaration: .init()), 1, accuracy: 0.0001)
        // a cap rounds down to the step: 1.5 → xxxLarge
        XCTAssertEqual(FontScaling.factor(system: .accessibility5, declaration: .init(maxFontScale: 1.5)),
                       FontScaling.ratio(.xxxLarge), accuracy: 0.0001)
        // below the cap the system's own step
        XCTAssertEqual(FontScaling.factor(system: .xLarge, declaration: .init(maxFontScale: 2)),
                       FontScaling.ratio(.xLarge), accuracy: 0.0001)
        config.scaling = false
        XCTAssertEqual(FontScaling.factor(system: .accessibility5, declaration: .init()), 1)
        XCTAssertEqual(FontScaling.factor(system: .accessibility5, declaration: .init(scaling: true)), ax5, accuracy: 0.0001)
        config.scaling = true; config.maxScale = 2
        XCTAssertEqual(FontScaling.factor(system: .accessibility5, declaration: .init()),
                       FontScaling.ratio(.accessibility2), accuracy: 0.0001)
        XCTAssertEqual(FontScaling.factor(system: .accessibility5, declaration: .init(maxFontScale: 1.5)),
                       FontScaling.ratio(.xxxLarge), accuracy: 0.0001, "the component's cap overrides the app's")
    }
}
