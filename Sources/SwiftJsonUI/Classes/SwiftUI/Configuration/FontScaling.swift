//
//  FontScaling.swift
//  SwiftJsonUI
//
//  The text size a component's text is drawn at (ticket sjui-label-font-size-ignores-dynamic-type, ruling 2026-11-13):
//  every text follows Dynamic Type unless it (or the app default, `SwiftJsonUIConfiguration.shared.font.scaling`)
//  says `fontScaling: false`; `maxFontScale` caps the drawn size at fontSize × maxFontScale, rounded down to a Dynamic
//  Type step. The same rule as shared/core/font_scale_vectors.json, which the tests read.
//
//  Every text component sets its font through `sjuiFont(_:scaling:maxFontScale:)`: the size is worked out here from
//  the environment's Dynamic Type size, the font comes from `resolveFont` (the app's `fontProvider` when it has one),
//  and the component is then pinned to the standard size so a provider's `Font.custom(_:size:)` does not grow it a
//  second time.
//

import SwiftUI
import UIKit

/// The rule, free of SwiftUI: which text follows the text size and how large it is drawn.
public enum FontScaleRule {
    /// Whether the text follows the text size: its own declaration, else the app default.
    public static func follows(_ declared: Bool?, appDefault: Bool) -> Bool {
        declared ?? appDefault
    }

    /// The size drawn: `size` when it does not follow; size × scale, at most size × maxScale.
    public static func drawn(size: CGFloat, scale: CGFloat, declared: Bool?, maxScale: CGFloat?,
                             appDefault: Bool) -> CGFloat {
        guard follows(declared, appDefault: appDefault) else { return size }
        guard let maxScale else { return size * scale }
        return size * min(scale, maxScale)
    }

    /// The step a cap rounds down to: the largest step (in order from the standard size up) whose ratio is at most
    /// `maxScale`; none: the largest step; below every step above the standard one: the standard step.
    public static func capStep<Step>(_ maxScale: CGFloat?, steps: [(step: Step, ratio: CGFloat)]) -> Step? {
        guard let last = steps.last else { return nil }
        guard let maxScale else { return last.step }
        return steps.last(where: { $0.ratio <= maxScale + 0.0001 })?.step ?? steps.first?.step
    }
}

/// Dynamic Type on iOS: each step's ratio to the standard size, as UIFontMetrics(.body) scales 17pt on this OS.
public enum FontScaling {
    public static let steps: [DynamicTypeSize] = [.large, .xLarge, .xxLarge, .xxxLarge, .accessibility1,
                                                  .accessibility2, .accessibility3, .accessibility4, .accessibility5]

    /// The step's ratio to the standard size (.large), from UIFontMetrics(.body). Steps below .large are below 1.
    public static func ratio(_ size: DynamicTypeSize) -> CGFloat {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(size))
        return UIFontMetrics(forTextStyle: .body).scaledValue(for: 17, compatibleWith: traits) / 17
    }

    /// The step `maxScale` rounds down to.
    public static func capStep(_ maxScale: CGFloat?) -> DynamicTypeSize {
        FontScaleRule.capStep(maxScale, steps: steps.map { ($0, ratio($0)) }) ?? .large
    }

    /// The multiple a declared size is drawn at under the system's `dynamicTypeSize`, for a component that declares
    /// `declaration` (each half nil: the app default).
    public static func factor(system: DynamicTypeSize, declaration: FontScalingDeclaration) -> CGFloat {
        ratio(typeSize(system: system, declaration: declaration))
    }

    /// The Dynamic Type size a text is drawn at under `declaration`: the system's when it follows, capped at
    /// maxFontScale's step, the standard size when it does not follow.
    public static func typeSize(system: DynamicTypeSize, declaration: FontScalingDeclaration) -> DynamicTypeSize {
        let config = SwiftJsonUIConfiguration.shared.font
        guard FontScaleRule.follows(declaration.scaling, appDefault: config.scaling) else { return .large }
        let cap = declaration.maxFontScale ?? config.maxScale
        return cap == nil ? system : min(system, capStep(cap))
    }

    /// A text whose spec says nothing (no family, size, weight or italic) and that no fontProvider answers keeps the
    /// environment's font — `.body` unless the app sets one — as it did before the text size rule: that rule drew
    /// it at the configured size's system font, whose lines are 20.3 high where `.body`'s are 22, and an app with no
    /// provider saw every multi-line Label shorten (the orchestrator's ruling 2026-11-14). Its size still follows
    /// the declaration, through the Dynamic Type size the text style reads (typeSize).
    public static func keepsEnvironmentFont(_ spec: FontSpec) -> Bool {
        guard spec.family == nil, spec.size == nil, spec.weight == nil, !spec.italic else { return false }
        return SwiftJsonUIConfiguration.shared.fontProvider?(spec) == nil
    }
}

/// What a component declares: `fontScaling` and `maxFontScale`, each nil when the layout does not say.
public struct FontScalingDeclaration: Equatable {
    public var scaling: Bool?
    public var maxFontScale: CGFloat?
    public init(scaling: Bool? = nil, maxFontScale: CGFloat? = nil) {
        self.scaling = scaling
        self.maxFontScale = maxFontScale
    }

    /// Whether the component declares either. A component that does and has no fontSize still has its text held to
    /// the rule, at its own default size (font_scale_vectors.json rule.noFontSize, ruling 2026-11-13).
    public var isDeclared: Bool { scaling != nil || maxFontScale != nil }
}

private struct FontScalingDeclarationKey: EnvironmentKey {
    static let defaultValue = FontScalingDeclaration()
}

extension EnvironmentValues {
    /// The `fontScaling` / `maxFontScale` the component around declares (generated code and Dynamic put it on the
    /// component with `.fontScaling(_:maxFontScale:)`); every font the component sets reads it.
    public var fontScalingDeclaration: FontScalingDeclaration {
        get { self[FontScalingDeclarationKey.self] }
        set { self[FontScalingDeclarationKey.self] = newValue }
    }
}

/// The font of a text component: its spec's size drawn at the size the rule gives under the environment's Dynamic
/// Type size, resolved through `resolveFont` (the provider). The component is then pinned to the standard size, so a
/// provider's `Font.custom(_:size:)` keeps the size worked out here.
public struct SJUIFontModifier: ViewModifier {
    let spec: FontSpec
    @Environment(\.dynamicTypeSize) private var pinned
    @Environment(\.sjuiSystemTypeSize) private var outer
    @Environment(\.fontScalingDeclaration) private var declaration

    /// The system's Dynamic Type size: the one an enclosing sjuiFont saw before it pinned its subtree to the
    /// standard size, else the environment's. A text inside another (a TextField's placeholder) scales by it too.
    private var system: DynamicTypeSize { outer ?? pinned }

    public init(spec: FontSpec) {
        self.spec = spec
    }

    @ViewBuilder
    public func body(content: Content) -> some View {
        let factor = FontScaling.factor(system: system, declaration: declaration)
        if FontScaling.keepsEnvironmentFont(spec) {
            // No font of its own: the environment's text style, at the declaration's Dynamic Type size.
            content
                .environment(\.fontScalingFactor, factor)
                .environment(\.sjuiSystemTypeSize, system)
                .environment(\.dynamicTypeSize, FontScaling.typeSize(system: system, declaration: declaration))
        } else {
            let size = spec.size ?? SwiftJsonUIConfiguration.shared.font.size
            let drawn = FontSpec(family: spec.family, weight: spec.weight, size: size * factor, italic: spec.italic)
            content
                .font(SwiftJsonUIConfiguration.shared.resolveFont(drawn))
                .environment(\.fontScalingFactor, factor)
                .environment(\.sjuiSystemTypeSize, system)
                .environment(\.dynamicTypeSize, .large)
        }
    }
}

private struct SJUISystemTypeSizeKey: EnvironmentKey {
    static let defaultValue: DynamicTypeSize? = nil
}

extension EnvironmentValues {
    /// The system's Dynamic Type size, kept by the outermost sjuiFont when it pins its subtree to the standard size
    /// (nil outside one). Every font inside reads it, so a nested text is sized by the system's size, not the pin.
    public var sjuiSystemTypeSize: DynamicTypeSize? {
        get { self[SJUISystemTypeSizeKey.self] }
        set { self[SJUISystemTypeSizeKey.self] = newValue }
    }
}

private struct FontScalingFactorKey: EnvironmentKey {
    static let defaultValue: CGFloat? = nil
}

extension EnvironmentValues {
    /// The factor the enclosing `sjuiFont` drew its text at, for the parts of a component that set sizes of their
    /// own (partialAttributes): nil outside one.
    public var fontScalingFactor: CGFloat? {
        get { self[FontScalingFactorKey.self] }
        set { self[FontScalingFactorKey.self] = newValue }
    }
}

public extension View {
    /// The font every text component sets: `spec` through `resolveFont`, drawn at the size the component's
    /// `fontScaling` / `maxFontScale` (else the app defaults) give under the current Dynamic Type size.
    func sjuiFont(_ spec: FontSpec) -> some View {
        modifier(SJUIFontModifier(spec: spec))
    }

    /// The font of a component's text when the layout gave it no fontSize: through `sjuiFont` at the configured
    /// size (`font.size`, 17 — SwiftUI's .body at the standard size), so it is the provider's typeface and held to
    /// the text size rule whether or not the component declares fontScaling (ruling 2026-11-13, P1).
    func sjuiDeclaredFont(weight: Font.Weight? = nil) -> some View {
        modifier(SJUIDeclaredFontModifier(weight: weight))
    }

    /// A component's `fontScaling` / `maxFontScale`, for the fonts inside it. Nil for either: the app default.
    func fontScaling(_ scaling: Bool?, maxFontScale: CGFloat? = nil) -> some View {
        environment(\.fontScalingDeclaration, FontScalingDeclaration(scaling: scaling, maxFontScale: maxFontScale))
    }
}

struct SJUIDeclaredFontModifier: ViewModifier {
    let weight: Font.Weight?

    func body(content: Content) -> some View {
        content.sjuiFont(FontSpec(weight: weight))
    }
}
