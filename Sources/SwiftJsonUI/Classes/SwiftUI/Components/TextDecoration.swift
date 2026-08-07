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
