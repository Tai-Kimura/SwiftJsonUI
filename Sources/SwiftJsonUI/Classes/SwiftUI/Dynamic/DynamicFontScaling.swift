//
//  DynamicFontScaling.swift
//  SwiftJsonUI
//
//  Dynamic's half of `fontScaling` / `maxFontScale` (ticket sjui-label-font-size-ignores-dynamic-type): the
//  declaration each text component carries, put on it as the generated code puts it (`.fontScaling(_:maxFontScale:)`),
//  so every font inside reads it. Read from the component's own typed table; a component that is not text is left as
//  it is.
//

#if DEBUG
import SwiftUI

enum DynamicFontScaling {
    /// The text component's declaration (each half nil when the layout does not say), or nil for a component that
    /// has no text of its own. Types are the canonical sections (aliases are resolved before the builder's switch).
    static func declaration(_ component: DynamicComponent) -> FontScalingDeclaration? {
        func make(_ scaling: Bool?, _ max: Double?) -> FontScalingDeclaration {
            FontScalingDeclaration(scaling: scaling, maxFontScale: max.map { CGFloat($0) })
        }
        switch component.type {
        case "Label":
            let a = component.typedAttributes(LabelAttributes.self); return make(a.fontScaling, a.maxFontScale)
        case "Button":
            let a = component.typedAttributes(ButtonAttributes.self); return make(a.fontScaling, a.maxFontScale)
        case "TextField":
            let a = component.typedAttributes(TextFieldAttributes.self); return make(a.fontScaling, a.maxFontScale)
        case "TextView":
            let a = component.typedAttributes(TextViewAttributes.self); return make(a.fontScaling, a.maxFontScale)
        case "SelectBox":
            let a = component.typedAttributes(SelectBoxAttributes.self); return make(a.fontScaling, a.maxFontScale)
        case "Switch":
            let a = component.typedAttributes(SwitchAttributes.self); return make(a.fontScaling, a.maxFontScale)
        case "CheckBox":
            let a = component.typedAttributes(CheckBoxAttributes.self); return make(a.fontScaling, a.maxFontScale)
        case "Radio":
            let a = component.typedAttributes(RadioAttributes.self); return make(a.fontScaling, a.maxFontScale)
        case "IconLabel":
            let a = component.typedAttributes(IconLabelAttributes.self); return make(a.fontScaling, a.maxFontScale)
        default:
            return nil
        }
    }
}

/// Puts a text component's declaration on it; a component without text keeps the one around it.
struct DynamicFontScalingMark: ViewModifier {
    let declaration: FontScalingDeclaration?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let declaration {
            content.fontScaling(declaration.scaling, maxFontScale: declaration.maxFontScale)
        } else {
            content
        }
    }
}

#endif // DEBUG
