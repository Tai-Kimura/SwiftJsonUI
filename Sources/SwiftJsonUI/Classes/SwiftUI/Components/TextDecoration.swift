//
//  TextDecoration.swift
//  SwiftJsonUI
//
//  The OBJECT face of `underline` / `strikethrough`.
//
//  Both are declared `boolean|object` (`underline` also `array`), where the
//  object carries `lineStyle` (Single / Double / Thick / None), `color`, and —
//  for underline — `lineOffset`. Every platform read the PRESENCE of the
//  object and drew a plain line; none of them read its contents, so a styled
//  declaration and a bare `true` drew the same picture by construction. That
//  is the `presence-only` class in codegen_effect.json and the {styled, true}
//  pair in value_discrimination.json.
//
//  The vocabulary mirrors the UIKit half of this library
//  (`SJUILabel.swift`, `applyAttributedText`), which is the in-repo reference
//  for what these values mean, so the two ios halves cannot answer
//  differently. Two notes on where SwiftUI cannot follow UIKit exactly:
//
//    * `Double` and `Thick` are NSUnderlineStyle values with no SwiftUI
//      counterpart — `Text.LineStyle` offers `single` and a dash/dot pattern,
//      nothing about weight. They draw as a single line here and are recorded
//      as a known non-discriminating pair rather than faked.
//    * `None` maps to a line on BOTH ios halves, because the UIKit switch
//      sends every unrecognised spelling (`None` included) to `.single`.
//      Whether that is canon is E's to rule; mirroring is the choice that
//      keeps the two halves identical while the question is open.
//

import SwiftUI

public struct TextDecoration: Equatable {

    public enum LineStyle: String, CaseIterable {
        case single, double, thick, none

        public static func from(_ declared: String?) -> LineStyle {
            switch declared?.lowercased() {
            case "double": return .double
            case "thick": return .thick
            case "none": return .none
            default: return .single
            }
        }
    }

    public let lineStyle: LineStyle
    public let color: Color?
    /// Baseline offset, underline only. UIKit puts this on
    /// `NSAttributedString.Key.baselineOffset`, so it shifts the TEXT relative
    /// to its line box rather than moving the rule.
    public let lineOffset: CGFloat?

    public init(lineStyle: LineStyle = .single, color: Color? = nil, lineOffset: CGFloat? = nil) {
        self.lineStyle = lineStyle
        self.color = color
        self.lineOffset = lineOffset
    }

    /// True when the declaration says something a bare `true` does not — the
    /// only case worth routing through the styled renderer.
    public var isStyled: Bool {
        color != nil || lineOffset != nil
    }
}

public extension TextDecoration {

    /// Build from a declared `underline` / `strikethrough` value. Nil for the
    /// boolean face (and for a `None` object, which asks for no line, so there
    /// is no style to carry).
    init?(from declared: Any?) {
        guard let dict = declared as? [String: Any] else { return nil }
        let style = LineStyle.from(dict["lineStyle"] as? String)
        guard style != .none else { return nil }
        let offset: CGFloat? = {
            if let n = dict["lineOffset"] as? NSNumber { return CGFloat(truncating: n) }
            if let s = dict["lineOffset"] as? String { return Double(s).map { CGFloat($0) } }
            return nil
        }()
        self.init(
            lineStyle: style,
            color: (dict["color"] as? String).flatMap { Color(hex: $0) },
            lineOffset: offset
        )
    }

    /// Whether a declared value asks for a line at all.
    ///
    /// `true` draws; an object draws UNLESS it declares `lineStyle: None`.
    /// The `None` arm is the ios codegen's convention (51-B: the emit
    /// requests no line for that face), matched here so the two ios paths
    /// cannot answer differently. It also keeps the declared enum value
    /// meaningful — a `None` that drew a line would be pixel-identical to
    /// `Single`, which is a value_discrimination collapsedPair by
    /// construction.
    static func draws(_ declared: Any?) -> Bool {
        guard let declared else { return false }
        // `false` is the one non-nil value that means OFF — Ruby truthiness,
        // which label_converter.rb tests and this half has always matched.
        if let flag = declared as? Bool { return flag }
        if let dict = declared as? [String: Any] {
            return LineStyle.from(dict["lineStyle"] as? String) != .none
        }
        // `underline` is declared `boolean|object|array`; the array face is a
        // declaration, so it draws.
        return true
    }
}
