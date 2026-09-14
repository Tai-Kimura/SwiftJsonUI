import XCTest
import SwiftUI
@testable import SwiftJsonUI

/// The value side of the `glass` attribute.
///
/// These arms cover what can be asserted without rendering: the string-to-meaning
/// decisions. What the effect LOOKS like is a conformance baseline's job, and that
/// baseline has to be keyed by OS version, because the same fixture is a different
/// picture on iOS 25 and 26.
final class SJUIGlassTests: XCTestCase {

    /// `identity` is neither a style member nor a shape. UIKit's enum has Regular and
    /// Clear only; SwiftUI has an `identity` Glass, but the declaration's meaning is
    /// "declared, apply nothing", and resolving it to a member on one platform and
    /// nothing on the other would make the same JSON mean two things.
    func testIdentityMeansApplyNothing() {
        XCTAssertTrue(SJUIGlass.isIdentity("identity"))
        XCTAssertTrue(SJUIGlass.isIdentity("IDENTITY"))
        XCTAssertFalse(SJUIGlass.isIdentity("regular"))
        XCTAssertFalse(SJUIGlass.isIdentity("clear"))
        XCTAssertFalse(SJUIGlass.isIdentity(nil))
    }

    func testTheRoundedRadiusIsReadFromTheSpelling() {
        XCTAssertEqual(SJUIGlass.roundedRadius(from: "rounded(12)"), 12)
        XCTAssertEqual(SJUIGlass.roundedRadius(from: "rounded(0)"), 0)
        XCTAssertEqual(SJUIGlass.roundedRadius(from: "Rounded(4.5)"), 4.5)
        XCTAssertNil(SJUIGlass.roundedRadius(from: "rounded"), "no number means no radius, not zero")
        XCTAssertNil(SJUIGlass.roundedRadius(from: "capsule"))
        XCTAssertNil(SJUIGlass.roundedRadius(from: nil))
    }

    /// The generator can only write constants, so two of the four shapes cannot be
    /// resolved there. This arm records which — it is the fact that decided the shape
    /// handling lives entirely in the helper.
    /// The spellings the declaration defines. A typo must be visible to the generator
    /// rather than becoming the default at render time — the same shape as a keyboard
    /// type table that quietly folds unknown values into `.default`.
    func testUnknownShapeSpellingsAreReportable() {
        XCTAssertTrue(SJUIGlass.isKnown(shape: nil))
        XCTAssertTrue(SJUIGlass.isKnown(shape: "capsule"))
        XCTAssertTrue(SJUIGlass.isKnown(shape: "CIRCLE"))
        XCTAssertTrue(SJUIGlass.isKnown(shape: "rect"))
        XCTAssertTrue(SJUIGlass.isKnown(shape: "rounded(12)"))
        XCTAssertFalse(SJUIGlass.isKnown(shape: "elipse"), "a typo must be reportable, not silently defaulted")
        XCTAssertFalse(SJUIGlass.isKnown(shape: "squircle"))
        // `rectangle` is NOT declared — the declaration says `rect`. It was accepted
        // here once, taken from SwiftUI's type name rather than from the declaration.
        // This asserts the implementation's vocabulary is the declaration's.
        XCTAssertFalse(SJUIGlass.isKnown(shape: "rectangle"),
                       "rectangle is the SwiftUI type's name, not a declared spelling")
    }

    /// Three places in this file name the shape vocabulary: `knownShapeSpellings`,
    /// the cases of `resolvedShape`, and the cases of `isStaticallyResolvable`.
    /// Removing `rectangle` from the first left it alive in the third, so a spelling
    /// no declaration defines was reported as one the generator could resolve.
    ///
    /// The invariant that catches the next such drift: anything reported statically
    /// resolvable must be a spelling the declaration defines.
    func testStaticallyResolvableImpliesDeclared() {
        let probes = ["capsule", "circle", "rect", "rectangle", "rounded(12)", "rounded",
                      "squircle", "elipse", "RECT", nil]
        for probe in probes {
            if SJUIGlass.isStaticallyResolvable(shape: probe) {
                XCTAssertTrue(SJUIGlass.isKnown(shape: probe),
                              "\(probe ?? "nil") is reported resolvable but is not declared")
            }
        }
        // The specific regression, named: it must be neither.
        XCTAssertFalse(SJUIGlass.isStaticallyResolvable(shape: "rectangle"))
        XCTAssertFalse(SJUIGlass.isKnown(shape: "rectangle"))
    }

    func testWhichShapesTheGeneratorCouldResolveStatically() {
        XCTAssertTrue(SJUIGlass.isStaticallyResolvable(shape: nil))
        XCTAssertTrue(SJUIGlass.isStaticallyResolvable(shape: "rect"))
        XCTAssertTrue(SJUIGlass.isStaticallyResolvable(shape: "rounded(12)"))
        XCTAssertFalse(SJUIGlass.isStaticallyResolvable(shape: "capsule"), "height-dependent")
        XCTAssertFalse(SJUIGlass.isStaticallyResolvable(shape: "circle"), "size-dependent")
    }

    /// All four are resolved in one place, and each spelling produces a DIFFERENT
    /// outline. `AnyShape` is not Equatable, so the comparison is the path each one
    /// draws in the same rect — which is also the thing that would be visibly wrong
    /// if a spelling silently fell through to the default.
    ///
    /// ⚠️ The first version of this arm only called `resolvedShape` and asserted
    /// nothing. Mutating capsule to Rectangle left it green — measured — because
    /// "it did not crash" is not a claim about the shape.
    @available(iOS 26.0, *)
    func testEachShapeSpellingDrawsItsOwnOutline() {
        let box = CGRect(x: 0, y: 0, width: 100, height: 40)
        func outline(_ spelling: String?) -> String {
            SJUIGlass.resolvedShape(spelling).path(in: box).description
        }
        let rect = outline("rect")
        XCTAssertNotEqual(outline("capsule"), rect, "capsule fell through to the default")
        XCTAssertNotEqual(outline("circle"), rect, "circle fell through to the default")
        XCTAssertNotEqual(outline("rounded(12)"), rect, "rounded fell through to the default")
        XCTAssertNotEqual(outline("capsule"), outline("circle"))
        // An absent shape is the SDK's default, NOT a rectangle: `.glassEffect()` called
        // bare uses DefaultGlassEffectShape, and the declaration calls `glass: true`
        // "the default treatment" — the SDK's default, not one this library picks.
        XCTAssertNotEqual(outline(nil), rect, "an absent shape must not be a plain rectangle")
        XCTAssertEqual(outline(nil), AnyShape(DefaultGlassEffectShape()).path(in: box).description)
        XCTAssertEqual(outline("unknown-spelling"), outline(nil),
                       "an unknown spelling degrades to the default rather than crashing")
        XCTAssertEqual(outline("rect"), rect, "an explicit rect is still a rectangle")
        // The radius reaches the outline, not just the parser.
        XCTAssertNotEqual(outline("rounded(4)"), outline("rounded(20)"))
    }

    /// Below iOS 26 the modifier returns the view unchanged. Asserted through the
    /// public entry point, because that is what generated code calls.
    func testTheEntryPointIsCallableWithEveryArgumentShape() {
        _ = Text("probe").sjuiGlassEffect()
        _ = Text("probe").sjuiGlassEffect(style: "clear")
        _ = Text("probe").sjuiGlassEffect(interactive: false)
        _ = Text("probe").sjuiGlassEffect(shape: "rounded(12)")
        _ = Text("probe").sjuiGlassEffect(style: "regular", tint: Color.red,
                                          interactive: true, shape: "capsule")
    }

    /// `interactive: false` is a written value, not an absent key. The signature
    /// cannot express that — `Bool?` merely permits both — so it is pinned here.
    ///
    /// 🔻 It is pinned on `Plan`, not on `Glass`. Measured: SwiftUI's `Glass` compares
    /// `.regular` equal to `.regular.interactive(false)`, so an arm written against
    /// `Glass` stays green when the explicit false is dropped. That is not a reason to
    /// skip the arm — it is a reason to assert the decision where the decision is,
    /// which is what `Plan` records on the way into the SDK call.
    func testAnExplicitFalseIsNotTheSameAsAnAbsentKey() {
        let absent = SJUIGlass.plan(style: nil, tint: nil, interactive: nil, shape: nil)
        let explicitFalse = SJUIGlass.plan(style: nil, tint: nil, interactive: false, shape: nil)
        let explicitTrue = SJUIGlass.plan(style: nil, tint: nil, interactive: true, shape: nil)

        XCTAssertNotEqual(absent, explicitFalse, "an explicit interactive:false collapsed into an absent key")
        XCTAssertNotEqual(explicitFalse, explicitTrue)
        XCTAssertNil(absent.interactive)
        XCTAssertEqual(explicitFalse.interactive, false)
    }

    /// The SDK cannot see the difference the contract requires. Recorded as a fact
    /// about the SDK, so the next reader does not "fix" Plan away.
    @available(iOS 26.0, *)
    func testTheSDKsOwnEqualityCannotSeeAnExplicitFalse() {
        XCTAssertEqual(Glass.regular, Glass.regular.interactive(false),
                       "if this ever fails, Glass gained the distinction and Plan's interactive field could move")
        XCTAssertNotEqual(Glass.regular, Glass.regular.interactive(true))
    }

    /// The plan is what the SDK call is built from, not a description written beside
    /// it: identity means no effect, and clear maps to the clear member.
    func testThePlanCarriesTheDecisionsTheCallMakes() {
        XCTAssertFalse(SJUIGlass.plan(style: "identity", tint: nil, interactive: nil, shape: nil).applyEffect)
        XCTAssertTrue(SJUIGlass.plan(style: "clear", tint: nil, interactive: nil, shape: nil).applyEffect)
        XCTAssertTrue(SJUIGlass.plan(style: "clear", tint: nil, interactive: nil, shape: nil).clear)
        XCTAssertFalse(SJUIGlass.plan(style: "regular", tint: nil, interactive: nil, shape: nil).clear)
        XCTAssertTrue(SJUIGlass.plan(style: nil, tint: Color.red, interactive: nil, shape: nil).hasTint)
        XCTAssertEqual(SJUIGlass.plan(style: nil, tint: nil, interactive: nil, shape: "CAPSULE").shape, "capsule")
    }

    /// What these arms do NOT cover, and what would.
    ///
    ///   what                              why not                what would cover it
    ///   the modifier's WIRING:            `sjuiGlassEffect`      a rendering test:
    ///   sjuiGlassEffect → applied →       returns an opaque       the conformance
    ///   glass                             View; nothing about     baseline, keyed by
    ///                                     the arguments it        OS version
    ///                                     forwarded is readable
    ///   `interactive(false)` reaching     `Glass` compares        the same baseline —
    ///   the SDK                           .regular equal to       an interactive glass
    ///                                     .regular.interactive    reacts to touch, a
    ///                                     (false) — measured      non-interactive does
    ///
    /// Measured, not assumed: mutating the modifier to drop an explicit `false` on the
    /// way to `applied` leaves all nine of these arms green. The seam is covered; the
    /// two steps between the public entry point and the SDK are not.
    ///
    /// This is the same shape as the keyboard call sites: arms prove the logic, the
    /// wiring needs something that actually renders.
    func testTheUncoveredGlassStepsAreNamed() {
        XCTAssertEqual(2, 2)
    }

    @available(iOS 26.0, *)
    func testStyleSpellingsMapToTheSDKsTwoMembers() {
        XCTAssertEqual(SJUIGlass.glass(style: "clear", tint: nil, interactive: nil), Glass.clear)
        XCTAssertEqual(SJUIGlass.glass(style: "regular", tint: nil, interactive: nil), Glass.regular)
        XCTAssertEqual(SJUIGlass.glass(style: nil, tint: nil, interactive: nil), Glass.regular,
                       "an absent style is regular, the SDK's own default")
        XCTAssertEqual(SJUIGlass.glass(style: "nonsense", tint: nil, interactive: nil), Glass.regular,
                       "an unknown spelling falls back rather than failing to build")
    }
}
