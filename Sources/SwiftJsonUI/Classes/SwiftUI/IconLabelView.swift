//
//  IconLabelView.swift
//  SwiftJsonUI
//
//  SwiftUI implementation of IconLabel
//

import SwiftUI

public struct IconLabelView: View {
    let text: String
    let iconOn: String?
    let iconOff: String?
    let iconPosition: IconPosition
    // nil when the layout declares no `iconSize`: the icon is drawn at its
    // image's own size (2026-10-05 ruling 7; KotlinJsonUI puts no size
    // modifier on it either). The fixed 24 drew a 64pt asset at 24.
    let iconSize: CGFloat?
    // The ARRAY face of `iconSize` ([width, height], declared 51-E) sizes
    // the axes separately; nil falls back to the square `iconSize`.
    let iconWidth: CGFloat?
    let iconHeight: CGFloat?
    let iconMargin: CGFloat
    let fontSize: CGFloat
    // 'font: bold' carries the weight; textShadow the {color,blur,offset}
    // object — both were dropped on the SwiftUI path (33 cross-effect).
    var fontWeight: Font.Weight? = nil
    var textShadowColor: Color? = nil
    var textShadowRadius: CGFloat = 1
    var textShadowOffset: CGSize = CGSize(width: 0, height: 1)
    let fontColor: Color
    let selectedFontColor: Color
    let fontName: String?
    let isSelected: Bool
    
    public enum IconPosition {
        case top
        case left
        case right
        case bottom
    }
    
    public init(
        text: String,
        iconOn: String? = nil,
        iconOff: String? = nil,
        iconPosition: IconPosition = .left,
        iconSize: CGFloat? = nil,
        iconWidth: CGFloat? = nil,
        iconHeight: CGFloat? = nil,
        iconMargin: CGFloat = 5,
        fontSize: CGFloat = 16,
        fontColor: Color = .primary,
        selectedFontColor: Color = .accentColor,
        fontName: String? = nil,
        isSelected: Bool = false,
        fontWeight: Font.Weight? = nil,
        textShadowColor: Color? = nil,
        textShadowRadius: CGFloat = 1,
        textShadowOffset: CGSize = CGSize(width: 0, height: 1)
    ) {
        self.text = text
        self.iconOn = iconOn
        self.iconOff = iconOff
        self.iconPosition = iconPosition
        self.iconSize = iconSize
        self.iconWidth = iconWidth
        self.iconHeight = iconHeight
        self.iconMargin = iconMargin
        self.fontSize = fontSize
        self.fontColor = fontColor
        self.selectedFontColor = selectedFontColor
        self.fontName = fontName
        self.isSelected = isSelected
        self.fontWeight = fontWeight
        self.textShadowColor = textShadowColor
        self.textShadowRadius = textShadowRadius
        self.textShadowOffset = textShadowOffset
    }
    
    public var body: some View {
        Group {
            switch iconPosition {
            case .top:
                VStack(spacing: iconMargin) {
                    iconView
                    textView
                }
            case .bottom:
                VStack(spacing: iconMargin) {
                    textView
                    iconView
                }
            case .left:
                HStack(spacing: iconMargin) {
                    iconView
                    textView
                }
            case .right:
                HStack(spacing: iconMargin) {
                    textView
                    iconView
                }
            }
        }
        // One element, read as its text. The layout id goes on this
        // composite as a whole, and SwiftUI hands an identifier on a
        // non-element to EVERY element inside: the icon Image was a second
        // element carrying the IconLabel's id, so a `text` read returned the
        // image's name (ticket
        // sjui-a-composite-leaf-gives-its-id-to-every-element-inside). The
        // icon is decorative (iconView); combined, the element's label is the
        // text and its frame is the whole IconLabel.
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private var iconView: some View {
        iconImage.accessibilityHidden(true)
    }

    @ViewBuilder
    private var iconImage: some View {
        if let iconName = isSelected ? iconOn : (iconOff ?? iconOn) {
            if iconName.hasPrefix("system:") {
                // System icon. A symbol has no size of its own, so an
                // undeclared size keeps the 24 it always drew at.
                Image(systemName: String(iconName.dropFirst(7)))
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconWidth ?? iconSize ?? 24, height: iconHeight ?? iconSize ?? 24)
                    .foregroundColor(isSelected ? selectedFontColor : fontColor)
            } else if iconWidth != nil || iconHeight != nil || iconSize != nil {
                // Custom image at the declared size
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconWidth ?? iconSize, height: iconHeight ?? iconSize)
                    .foregroundColor(isSelected ? selectedFontColor : fontColor)
            } else {
                // Custom image, no size declared: the image's own size
                Image(iconName)
                    .foregroundColor(isSelected ? selectedFontColor : fontColor)
            }
        }
    }
    
    @ViewBuilder
    private var textView: some View {
        let base = Text(text)
            .font(font)
            .foregroundColor(isSelected ? selectedFontColor : fontColor)
        if let shadow = textShadowColor {
            base.shadow(
                color: shadow,
                radius: textShadowRadius,
                x: textShadowOffset.width,
                y: textShadowOffset.height
            )
        } else {
            base
        }
    }
    
    private var font: Font {
        let resolved: Font
        if let fontName = fontName {
            resolved = .custom(fontName, size: fontSize)
        } else {
            resolved = .system(size: fontSize)
        }
        if let weight = fontWeight {
            return resolved.weight(weight)
        }
        return resolved
    }
}

// MARK: - Stateful version with toggle support
public struct IconLabelButton: View {
    let text: String
    let iconOn: String?
    let iconOff: String?
    let iconPosition: IconLabelView.IconPosition
    let iconSize: CGFloat?
    let iconWidth: CGFloat?
    let iconHeight: CGFloat?
    let iconMargin: CGFloat
    let fontSize: CGFloat
    // 'font: bold' carries the weight; textShadow the {color,blur,offset}
    // object — both were dropped on the SwiftUI path (33 cross-effect).
    var fontWeight: Font.Weight? = nil
    var textShadowColor: Color? = nil
    var textShadowRadius: CGFloat = 1
    var textShadowOffset: CGSize = CGSize(width: 0, height: 1)
    let fontColor: Color
    let selectedFontColor: Color
    let fontName: String?
    /// `selected` from the layout. When supplied the ViewModel owns the state,
    /// so the tap does not toggle it — a self-toggling button would fight the
    /// binding it was told to follow. Left nil, the button keeps its own state,
    /// which is what a layout with no `selected` asks for.
    let isSelectedOverride: Bool?
    let action: (() -> Void)?

    @State private var internalSelected = false

    private var isSelected: Bool { isSelectedOverride ?? internalSelected }

    public init(
        text: String,
        iconOn: String? = nil,
        iconOff: String? = nil,
        iconPosition: IconLabelView.IconPosition = .left,
        iconSize: CGFloat? = nil,
        iconWidth: CGFloat? = nil,
        iconHeight: CGFloat? = nil,
        iconMargin: CGFloat = 5,
        fontSize: CGFloat = 16,
        fontColor: Color = .primary,
        selectedFontColor: Color = .accentColor,
        fontName: String? = nil,
        isSelected: Bool? = nil,
        action: (() -> Void)? = nil
    ) {
        self.text = text
        self.iconOn = iconOn
        self.iconOff = iconOff
        self.iconPosition = iconPosition
        self.iconSize = iconSize
        self.iconWidth = iconWidth
        self.iconHeight = iconHeight
        self.iconMargin = iconMargin
        self.fontSize = fontSize
        self.fontColor = fontColor
        self.selectedFontColor = selectedFontColor
        self.fontName = fontName
        self.isSelectedOverride = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: {
            if isSelectedOverride == nil {
                internalSelected.toggle()
            }
            action?()
        }) {
            IconLabelView(
                text: text,
                iconOn: iconOn,
                iconOff: iconOff,
                iconPosition: iconPosition,
                iconSize: iconSize,
                iconWidth: iconWidth,
                iconHeight: iconHeight,
                iconMargin: iconMargin,
                fontSize: fontSize,
                fontColor: fontColor,
                selectedFontColor: selectedFontColor,
                fontName: fontName,
                isSelected: isSelected
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
struct IconLabelView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            IconLabelView(
                text: "Home",
                iconOn: "system:house.fill",
                iconOff: "system:house",
                iconPosition: .left
            )
            
            IconLabelView(
                text: "Settings",
                iconOn: "system:gearshape.fill",
                iconOff: "system:gearshape",
                iconPosition: .top,
                isSelected: true
            )
            
            IconLabelButton(
                text: "Favorite",
                iconOn: "system:star.fill",
                iconOff: "system:star",
                iconPosition: .right,
                selectedFontColor: .yellow
            )
        }
        .padding()
    }
}