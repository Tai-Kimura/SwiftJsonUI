//
//  SJUIGlass.swift
//  SwiftJsonUI
//
//  Added 2026-09-14 for the iOS 26 Liquid Glass attributes.
//

import SwiftUI

// 🔻 TWO DIFFERENT VERSION QUESTIONS, AND `@available` ONLY ANSWERS ONE.
//
//   "will the DEVICE running this binary have Liquid Glass?"  -> `#available`
//   "did the COMPILER that built it have `Glass` at all?"     -> `#if`, below
//
// Every iOS-26 member in this file already carried `@available(iOS 26.0, *)`,
// and that is a runtime annotation: it defers the CALL, it does not defer name
// resolution. Built against the iOS 18.5 SDK (Xcode 16.4, which is the DEFAULT
// on GitHub's macos-15 image) the type `Glass` does not exist and the file
// fails to compile -- measured, run 34841647809:
//
//     Cannot find type 'Glass' in scope
//     Command SwiftCompile failed with a nonzero exit code   (exit 65)
//
// README declares "iOS 17 or later / Swift 5.8+" and Package.swift asks for
// tools 5.10, so a consumer on Xcode 16.4 is inside the supported range. The
// answer is therefore a compile-time guard here, NOT an Xcode floor.
//
// ⚠️ `compiler(>=6.2)` IS A PROXY, AND ITS KNOWN FAILURE DIRECTION IS RECORDED.
// It keys the TOOLCHAIN (Xcode 16.4 ships Swift 6.1; Xcode 26 ships 6.2+), not
// the SDK, and the two can be separated. swift-argument-parser #827 is the same
// mechanism with the versions the other way round: a Swift 6.2 toolchain aimed
// at the macOS 15 SDK passed `#if compiler(>=6.2)` and still could not find
// `SendableMetatype`. Stock Xcode ships toolchain and SDK as a pair, so that
// combination does not arise in what we ship -- but nothing written here rules
// it out; only the pairing does.
//
// ⇒ THE GUARD'S CORRECTNESS IS AN EMPIRICAL CLAIM, so CI asserts it from both
// sides rather than this comment asserting it once: ci.yml runs the unit tests
// on Xcode 26.3 AND on 16.4, and each leg declares which side it expects via
// SJUI_EXPECT_GLASS_SDK. If Xcode 16.4's Swift were >= 6.2 (transcribed from
// release notes, never compiled here), the 16.4 leg goes red and says so.

public extension View {

    /// The single entry point generated code uses for the `glass` attribute.
    ///
    /// One helper rather than an availability check per call site. `#available` asks
    /// the RUNTIME version, so scattering it would put a device-dependent branch at
    /// every emitted view; contained here, the emitter writes one line and the
    /// version question is answered in exactly one place. (A fallback in this library
    /// was already found doing the device-dependent thing and removed: see
    /// SJUIWindowMetrics.legacyScreenBounds.)
    ///
    /// Below iOS 26 this returns the view unchanged. That is a deliberate difference
    /// from the window-metrics case: there, a version-dependent answer was a WRONG
    /// MEASUREMENT feeding layout. Here the effect is decoration — it returns no value
    /// and nothing computes from it — so "glass where the system has it, plain
    /// elsewhere" is progressive enhancement, not two different truths.
    ///
    /// ⚠️ The conformance baseline must therefore be keyed by OS version: the same
    /// fixture is a different picture on iOS 25 and 26.
    ///
    /// Platform exclusions differ between the two families and must not be collapsed
    /// into one phrase: SwiftUI's `glassEffect` is unavailable on visionOS but
    /// AVAILABLE on watchOS 26; UIKit's `UIGlassEffect` is unavailable on BOTH
    /// visionOS and watchOS.
    ///
    /// Built WITHOUT the Liquid Glass SDK the whole body collapses to `self` --
    /// the same view an iOS 25 device gets at runtime, reached by a different
    /// question (see the file header). One entry point, so this is the only
    /// place either question has to be asked.
    @ViewBuilder
    func sjuiGlassEffect(style: String? = nil,
                         tint: Color? = nil,
                         interactive: Bool? = nil,
                         shape: String? = nil) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            SJUIGlass.applied(to: self, style: style, tint: tint, interactive: interactive, shape: shape)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

/// The value side of the attribute: strings from JSON to the SDK's types.
public enum SJUIGlass {

    /// `identity` is not a `UIGlassEffectStyle` member and not a shape — it means
    /// "declared, but apply nothing". Resolving it to a member would be inventing one;
    /// it is answered here as "no effect" instead.
    public static func isIdentity(_ style: String?) -> Bool {
        style?.lowercased() == "identity"
    }

    /// Which shapes the generator can write statically. `capsule` and `circle` depend
    /// on the laid-out size, so they are resolved at render time rather than emitted
    /// as a constant — the declaration's value set is deliberately NOT 1:1 with what
    /// codegen can spell.
    /// ⚠️ `rectangle` was accepted here too. Dropping it from `knownShapeSpellings`
    /// left this third site alive, so `isKnown("rectangle")` was false while
    /// `isStaticallyResolvable("rectangle")` was true — a spelling that is not
    /// declared yet is reported as one the generator could resolve. One removal, three
    /// places that name the vocabulary.
    ///
    /// The invariant between them is pinned by an arm: anything this answers true for
    /// must also be a spelling `isKnown` accepts.
    ///
    /// The guard is what ENFORCES it rather than merely reporting it, so re-adding a
    /// case below cannot resurrect the bug — measured: with the guard in place,
    /// putting `rectangle` back in the case list changes no answer, and removing the
    /// guard while the case list is clean changes no answer either. Only both
    /// together restore the old behaviour, which is what the arm catches.
    public static func isStaticallyResolvable(shape: String?) -> Bool {
        guard isKnown(shape: shape) else { return false }

        switch shape?.lowercased() {
        case nil, "rect": return true
        case let s? where s.hasPrefix("rounded"): return true
        default: return false
        }
    }

    /// The corner radius inside `rounded(N)`, or nil when the spelling carries none.
    public static func roundedRadius(from shape: String?) -> CGFloat? {
        guard let shape = shape?.lowercased(), shape.hasPrefix("rounded") else { return nil }
        guard let open = shape.firstIndex(of: "("), let close = shape.firstIndex(of: ")"), open < close else { return nil }
        return Double(shape[shape.index(after: open)..<close]).map { CGFloat($0) }
    }

    // ---- Everything below this line needs the Liquid Glass SDK to compile. ----
    // See the file header for why `@available` cannot stand in for this.
    #if compiler(>=6.2)

    /// Whether the compiler that built this binary could see `Glass` at all.
    ///
    /// 🔑 DECLARED INSIDE THE GUARD ON PURPOSE. A build is green only if every
    /// member in these `#if` blocks compiled, so reading `true` here means the
    /// `Glass` / `glassEffect` / `DefaultGlassEffectShape` code really was put
    /// in front of a compiler. Declared OUTSIDE with its own `#if` it would
    /// merely restate the condition and could not fail -- the shape this train
    /// hit three times today, where a claim and the thing it claims about were
    /// broken together and the suite stayed green.
    ///
    /// It is also what stops the cheap "fix": pinning CI back to an SDK-less
    /// Xcode makes the glass path compile out, and a path nothing compiles is
    /// not a path anything checks.
    /// Internal, not public: the tests reach it through `@testable import`, and
    /// a new public symbol would make this a minor rather than the patch it is.
    static let isCompiledAgainstGlassSDK = true

    @available(iOS 26.0, *)
    @ViewBuilder
    static func applied<V: View>(to view: V,
                                 style: String?,
                                 tint: Color?,
                                 interactive: Bool?,
                                 shape: String?) -> some View {
        if isIdentity(style) {
            view
        } else {
            view.glassEffect(glass(style: style, tint: tint, interactive: interactive),
                             in: resolvedShape(shape))
        }
    }

    #else
    /// No Liquid Glass SDK: `sjuiGlassEffect` returns the view untouched, and the
    /// three members that name SDK-only types are not declared at all.
    static let isCompiledAgainstGlassSDK = false
    #endif

    /// What the helper decided, before the SDK sees it.
    ///
    /// ⚠️ This exists because `Glass` is Equatable but does NOT distinguish
    /// `.regular` from `.regular.interactive(false)` — measured: the two compare
    /// equal. So an arm written against `Glass` cannot tell whether an explicit
    /// `interactive: false` was honoured or silently dropped, and the generator's
    /// contract says it must be honoured (`false` is a written value, not an absent
    /// key; codegen does not omit it).
    ///
    /// The decision is therefore recorded in a value the test can read. The SDK call
    /// is built from this plan, so the plan is not a parallel description that can
    /// drift from it.
    public struct Plan: Equatable {
        public let applyEffect: Bool
        public let clear: Bool
        public let hasTint: Bool
        public let interactive: Bool?
        public let shape: String?
    }

    public static func plan(style: String?, tint: Color?, interactive: Bool?, shape: String?) -> Plan {
        Plan(applyEffect: !isIdentity(style),
             clear: style?.lowercased() == "clear",
             hasTint: tint != nil,
             interactive: interactive,
             shape: shape?.lowercased())
    }

    #if compiler(>=6.2) // names `Glass`
    @available(iOS 26.0, *)
    static func glass(style: String?, tint: Color?, interactive: Bool?) -> Glass {
        let plan = plan(style: style, tint: tint, interactive: interactive, shape: nil)
        var glass: Glass = plan.clear ? .clear : .regular
        if let tint { glass = glass.tint(tint) }
        // ⚠️ `interactive: false` is not the same as the key being absent, so the
        // optional is unwrapped rather than defaulted: an explicit false must call
        // `interactive(false)`, not skip the call. `Glass`'s own Equatable cannot see
        // the difference, which is why `Plan` carries it for the arms.
        if let value = plan.interactive { glass = glass.interactive(value) }
        return glass
    }
    #endif

    /// All four spellings are resolved here, including the two the generator cannot
    /// write statically. Splitting them — rect/rounded in codegen, capsule/circle at
    /// render time — would break one value set across two layers on the accident of
    /// which ones happen to be constant-foldable.
    ///
    /// `AnyShape` rather than `some Shape`: a `@ViewBuilder` builds views, and the
    /// branches here are four different `Shape` types, so the erasure is what lets
    /// one function answer for all of them.
    /// The spellings the declaration defines, verbatim: `capsule|rect|circle|rounded(N)`.
    ///
    /// ⚠️ `rectangle` was in this list. Nothing declared it — it was added here because
    /// SwiftUI's type is named `Rectangle`, which is the implementation's vocabulary,
    /// not the declaration's. An undeclared spelling that the implementation accepts
    /// is worse than one it rejects: `isKnown` answered true for it, so a generator
    /// built on this predicate would have let the typo through as well. Removed
    /// 2026-09-14 after measuring that no consumer layout uses `glass` at all (642
    /// layout files scanned, 0 hits), so nothing could break.
    ///
    /// Anything outside this set is not silently accepted: `resolvedShape` still
    /// answers with the SDK default so a typo cannot crash a screen, but `isKnown`
    /// lets the generator reject it while the spelling is still visible statically.
    static let knownShapeSpellings = ["capsule", "circle", "rect"]

    public static func isKnown(shape: String?) -> Bool {
        guard let shape = shape?.lowercased() else { return true }
        return knownShapeSpellings.contains(shape) || shape.hasPrefix("rounded")
    }

    #if compiler(>=6.2) // names `DefaultGlassEffectShape`
    @available(iOS 26.0, *)
    static func resolvedShape(_ shape: String?) -> AnyShape {
        switch shape?.lowercased() {
        case "capsule": return AnyShape(Capsule())
        case "circle": return AnyShape(Circle())
        case "rect": return AnyShape(Rectangle())
        case let s? where s.hasPrefix("rounded"):
            return AnyShape(RoundedRectangle(cornerRadius: roundedRadius(from: s) ?? 8))
        default:
            // No shape given, or a spelling the declaration does not define: use the
            // SDK's own default, which is what `.glassEffect()` uses when called bare.
            //
            // ⚠️ This was `Rectangle()`. The declaration calls `glass: true` "the
            // default treatment", and the default is the SDK's — `glassEffect(_:in:)`
            // defaults its shape to `DefaultGlassEffectShape()`, which is public and
            // writable here. Choosing a rectangle instead would have been a different
            // look from the bare call, decided by this library rather than by the SDK.
            //
            // An unknown spelling lands here too, so a typo degrades to the default
            // rather than failing to build. It should not reach this point: the
            // generator can see the spelling statically and reject it (`isKnown`).
            return AnyShape(DefaultGlassEffectShape())
        }
    }
    #endif
}
