//
//  SJUIGlass.swift
//  SwiftJsonUI
//
//  Added 2026-09-14 for the iOS 26 Liquid Glass attributes.
//

import SwiftUI

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
    @ViewBuilder
    func sjuiGlassEffect(style: String? = nil,
                         tint: Color? = nil,
                         interactive: Bool? = nil,
                         shape: String? = nil) -> some View {
        if #available(iOS 26.0, *) {
            SJUIGlass.applied(to: self, style: style, tint: tint, interactive: interactive, shape: shape)
        } else {
            self
        }
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
    public static func isStaticallyResolvable(shape: String?) -> Bool {
        switch shape?.lowercased() {
        case nil, "rect", "rectangle": return true
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

    /// All four spellings are resolved here, including the two the generator cannot
    /// write statically. Splitting them — rect/rounded in codegen, capsule/circle at
    /// render time — would break one value set across two layers on the accident of
    /// which ones happen to be constant-foldable.
    ///
    /// `AnyShape` rather than `some Shape`: a `@ViewBuilder` builds views, and the
    /// branches here are four different `Shape` types, so the erasure is what lets
    /// one function answer for all of them.
    @available(iOS 26.0, *)
    static func resolvedShape(_ shape: String?) -> AnyShape {
        switch shape?.lowercased() {
        case "capsule": return AnyShape(Capsule())
        case "circle": return AnyShape(Circle())
        case let s? where s.hasPrefix("rounded"):
            return AnyShape(RoundedRectangle(cornerRadius: roundedRadius(from: s) ?? 8))
        default: return AnyShape(Rectangle())
        }
    }
}
