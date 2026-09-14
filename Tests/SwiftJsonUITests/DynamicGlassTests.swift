//
//  DynamicGlassTests.swift
//  SwiftJsonUITests
//
//  The Dynamic face of `common.glass`.
//
//  🔻 WHY THIS FILE EXISTS AT ALL, WRITTEN DOWN SO THE SHAPE IS RECOGNISABLE
//  NEXT TIME. `glass` shipped with a codegen implementation and NO Dynamic
//  one, and the conformance suite compared the two faces and agreed — because
//  on iOS 18 neither face draws glass, so "identical picture" was true for a
//  reason that had nothing to do with either implementation. The gap became
//  visible only when the iOS lane moved to an SDK that has Liquid Glass
//  (run 34849471695: `common_glass__true.png`, hamming distance 151).
//
//  ⚠️ So a cross-face comparison is not, by itself, coverage of either face:
//  two empty implementations agree perfectly. These arms are written against
//  the VALUE CONTRACT rather than against the other face, so they keep
//  answering on an OS where the material itself is invisible.
//
//  The contract is read from the emitter (`base_view_converter.rb#apply_glass`
//  in jsonui-cli), not from the declaration prose, because the emitter is what
//  the other face actually does — and the two are not the same document.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class DynamicGlassTests: XCTestCase {

    private func component(_ dict: [String: Any]) -> DynamicComponent {
        var raw = dict
        raw["type"] = raw["type"] ?? "View"
        let data = try! JSONSerialization.data(withJSONObject: raw)
        return try! JSONDecoder().decode(DynamicComponent.self, from: data)
    }

    private func call(_ dict: [String: Any], data: [String: Any] = [:]) -> DynamicModifierHelper.GlassCall {
        DynamicModifierHelper.glassCall(component: component(dict), data: data)
    }

    // MARK: - The three spellings that mean "emit nothing"

    /// The emitter's guard is `return if value.nil? || value == false ||
    /// value == 'false'`. All three are separate arms because they are three
    /// different values, and a reader that handled only the first two would
    /// still pass a test that only checked absence.
    func testAbsentMakesNoCall() {
        XCTAssertEqual(call([:]), .none)
    }

    func testBooleanFalseMakesNoCall() {
        XCTAssertEqual(call(["glass": false]), .none)
    }

    func testTheStringFalseMakesNoCall() {
        XCTAssertEqual(call(["glass": "false"]), .none)
        // Case is not part of the value: the emitter compares against the JSON
        // literal, and a layout written by hand can say either.
        XCTAssertEqual(call(["glass": "False"]), .none)
    }

    // MARK: - The scalar-truthy form

    /// `glass: true` is "the default treatment", which on the emitter side is
    /// `.sjuiGlassEffect()` with NO arguments. Every field must therefore be
    /// nil — passing a style of "regular" here would look equivalent and is
    /// not: it would stop the helper from using the SDK's own default.
    func testTrueIsTheBareDefaultTreatment() {
        XCTAssertEqual(
            call(["glass": true]),
            DynamicModifierHelper.GlassCall(applies: true, style: nil, tint: nil, interactive: nil, shape: nil)
        )
    }

    // MARK: - The object form

    func testTheObjectFormCarriesEachKey() {
        let result = call(["glass": ["style": "clear", "tint": "#FF0000", "interactive": true, "shape": "capsule"]])
        XCTAssertTrue(result.applies)
        XCTAssertEqual(result.style, "clear")
        XCTAssertNotNil(result.tint, "a declared tint must resolve, not be dropped")
        XCTAssertEqual(result.interactive, true)
        XCTAssertEqual(result.shape, "capsule")
    }

    func testAnEmptyObjectStillApplies() {
        // `{}` is not `false`. It declares the attribute with no options, which
        // is the same call `true` produces.
        XCTAssertEqual(
            call(["glass": [String: Any]()]),
            DynamicModifierHelper.GlassCall(applies: true, style: nil, tint: nil, interactive: nil, shape: nil)
        )
    }

    /// 🔑 THE ARM THE WHOLE `GlassCall` TYPE EXISTS FOR.
    ///
    /// `interactive: false` and an absent `interactive` key produce DIFFERENT
    /// calls — `interactive(false)` vs never calling it. `Glass`'s own
    /// Equatable cannot tell them apart (measured: `.regular` ==
    /// `.regular.interactive(false)`), so an arm written one layer down
    /// against the SDK type could not fail when the distinction is lost.
    /// Defaulting the optional in the reader is exactly the plausible edit
    /// that would erase it, and this is the only arm that goes red for it.
    func testExplicitInteractiveFalseIsNotTheSameAsAbsent() {
        let explicit = call(["glass": ["interactive": false]])
        let absent = call(["glass": ["style": "regular"]])
        XCTAssertEqual(explicit.interactive, false)
        XCTAssertNil(absent.interactive)
        XCTAssertNotEqual(explicit.interactive, absent.interactive)
    }

    /// The emitter coerces with `value['interactive'] == true ||
    /// value['interactive'] == 'true'`, so the string spelling is truthy and
    /// anything else present is false-but-present.
    func testTheStringSpellingOfInteractiveFollowsTheEmitter() {
        XCTAssertEqual(call(["glass": ["interactive": "true"]]).interactive, true)
        XCTAssertEqual(call(["glass": ["interactive": "no"]]).interactive, false,
                       "present-but-not-true is false, NOT absent — the key was written")
    }

    // MARK: - Shapes

    /// Derived from the vocabulary constant rather than a list retyped here.
    /// A hardcoded list would keep passing after a spelling is added to or
    /// removed from the declaration — the failure mode that put `rectangle`
    /// in this library with nothing declaring it.
    func testEveryDeclaredShapeSpellingReachesTheHelperVerbatim() {
        for spelling in SJUIGlass.knownShapeSpellings + ["rounded(12)"] {
            XCTAssertTrue(SJUIGlass.isKnown(shape: spelling), "test input is not a declared spelling: \(spelling)")
            XCTAssertEqual(call(["glass": ["shape": spelling]]).shape, spelling,
                           "the shape spelling must reach the helper unchanged")
        }
    }

    /// Dynamic deliberately does NOT reject an unknown spelling. Codegen sees
    /// it statically and can refuse at build time; here the equivalent of
    /// refusing is crashing a screen at runtime, so it passes through and
    /// `resolvedShape` degrades it to the SDK default.
    func testAnUndeclaredShapeIsPassedThroughRatherThanRejected() {
        let spelling = "rectangle" // declared nowhere; was once accepted by this library
        XCTAssertFalse(SJUIGlass.isKnown(shape: spelling), "control: this spelling must be undeclared")
        XCTAssertEqual(call(["glass": ["shape": spelling]]).shape, spelling)
    }

    // MARK: - Binding

    func testATintBindingResolvesFromData() {
        let bound = call(["glass": ["tint": "@{accent}"]], data: ["accent": "#00FF00"])
        XCTAssertNotNil(bound.tint, "a bound tint must resolve through the same registry a literal does")
        // Control: the same expression with nothing to resolve against must
        // NOT invent a colour, or the arm above would pass on any input.
        XCTAssertNil(call(["glass": ["tint": "@{accent}"]]).tint)
    }
}
#endif
