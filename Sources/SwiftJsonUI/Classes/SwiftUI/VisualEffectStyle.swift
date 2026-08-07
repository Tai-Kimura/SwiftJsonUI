//
//  VisualEffectStyle.swift
//  SwiftJsonUI
//
//  `effectStyle` — the UIKit visual-effect material, as ONE table.
//
//  The attribute is declared on `common` (fourteen spellings: the UIKit
//  appearances, the five SwiftUI material names, and the aliases that
//  normalise onto them), not just on Blur. android and web each grew a full
//  table for it in plan 49 (kjui `EffectStyleHelper`, rjui
//  `EFFECT_STYLE_BACKGROUND` / `EFFECT_STYLE_BLUR_PX`); ios grew none, and
//  both ios paths hardcoded `.ultraThinMaterial` — so every declared value
//  except `dark` (which also flipped the colour scheme) rendered the same
//  picture. That is what `common/effectStyle__*` measured: ios inert on eight
//  of the nine appearances.
//
//  The table lives in the library rather than in either ios path so the
//  dynamic renderer and the sjui_tools emit cannot answer differently — the
//  shape kjui settled on for `DistributionFillRow` after two paths growing
//  children separately collapsed distribution's size half.
//
//  Distinctness is a REQUIREMENT, not a nicety: two declared values that draw
//  the same picture are a `value_discrimination` collapsedPair. SwiftUI ships
//  five materials and the vocabulary needs nine appearances, so the four
//  spellings that share a material carry a tint that separates them.
//

import SwiftUI

public enum VisualEffectStyle: String, CaseIterable {
    case ultraThin
    case thin
    case regular
    case thick
    case chrome
    case light
    case extraLight
    case dark
    case prominent

    /// The declared default — the fallback all three platforms already used
    /// for an absent or unrecognised value.
    public static let `default` = VisualEffectStyle.regular

    /// Normalise a declared spelling. Case-insensitive and alias-aware: the
    /// `system*Material` names are declared `valueAliases` of the appearance
    /// names in shared/core/attribute_definitions.json.
    public static func from(_ declared: String?) -> VisualEffectStyle {
        guard let key = declared?.trimmingCharacters(in: .whitespaces).lowercased(),
              !key.isEmpty else {
            return .default
        }
        switch key {
        case "ultrathin", "systemultrathinmaterial": return .ultraThin
        case "thin", "systemthinmaterial": return .thin
        case "regular", "systemmaterial": return .regular
        case "thick", "systemthickmaterial": return .thick
        case "chrome", "systemchromematerial": return .chrome
        case "light": return .light
        case "extralight": return .extraLight
        case "dark": return .dark
        case "prominent": return .prominent
        default: return .default
        }
    }

    /// The SwiftUI material this appearance blurs with.
    public var material: Material {
        switch self {
        case .ultraThin, .extraLight: return .ultraThinMaterial
        case .thin, .light: return .thinMaterial
        case .regular, .dark: return .regularMaterial
        case .thick, .prominent: return .thickMaterial
        case .chrome: return .bar
        }
    }

    /// Tint laid over the material for the appearances that share one, so no
    /// two declared values draw the same picture. `nil` for the five that own
    /// their material outright.
    public var tint: Color? {
        switch self {
        case .ultraThin, .thin, .regular, .thick, .chrome: return nil
        case .light: return Color.white.opacity(0.25)
        case .extraLight: return Color.white.opacity(0.45)
        case .dark: return Color.black.opacity(0.40)
        case .prominent: return Color.white.opacity(0.20)
        }
    }

    /// The appearance override this style forces, if any. Unchanged from the
    /// behaviour the two ios paths already shipped for these three.
    public var colorScheme: ColorScheme? {
        switch self {
        case .light, .extraLight: return .light
        case .dark: return .dark
        default: return nil
        }
    }
}

public extension View {
    /// Apply a declared `effectStyle` — material, tint and colour scheme in
    /// the one order both ios paths use.
    ///
    /// The tint sits ON the material but still BEHIND the content: a Blur's
    /// children are drawn over its effect, never washed by it, which is what
    /// `.background(.ultraThinMaterial)` alone already meant.
    func jsonUIVisualEffect(_ declared: String?) -> some View {
        let style = VisualEffectStyle.from(declared)
        return self
            .background {
                ZStack {
                    Rectangle().fill(style.material)
                    if let tint = style.tint {
                        tint
                    }
                }
            }
            .preferredColorScheme(style.colorScheme)
    }
}
