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
    let iconSize: CGFloat
    let iconMargin: CGFloat
    let fontSize: CGFloat
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
        iconSize: CGFloat = 24,
        iconMargin: CGFloat = 5,
        fontSize: CGFloat = 16,
        fontColor: Color = .primary,
        selectedFontColor: Color = .accentColor,
        fontName: String? = nil,
        isSelected: Bool = false
    ) {
        self.text = text
        self.iconOn = iconOn
        self.iconOff = iconOff
        self.iconPosition = iconPosition
        self.iconSize = iconSize
        self.iconMargin = iconMargin
        self.fontSize = fontSize
        self.fontColor = fontColor
        self.selectedFontColor = selectedFontColor
        self.fontName = fontName
        self.isSelected = isSelected
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
    }
    
    @ViewBuilder
    private var iconView: some View {
        if let iconName = isSelected ? iconOn : (iconOff ?? iconOn) {
            if iconName.hasPrefix("system:") {
                // System icon
                Image(systemName: String(iconName.dropFirst(7)))
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(isSelected ? selectedFontColor : fontColor)
            } else {
                // Custom image
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(isSelected ? selectedFontColor : fontColor)
            }
        }
    }
    
    @ViewBuilder
    private var textView: some View {
        Text(text)
            .font(font)
            .foregroundColor(isSelected ? selectedFontColor : fontColor)
    }
    
    private var font: Font {
        if let fontName = fontName {
            return .custom(fontName, size: fontSize)
        } else {
            return .system(size: fontSize)
        }
    }
}

// MARK: - Stateful version with toggle support
public struct IconLabelButton: View {
    let text: String
    let iconOn: String?
    let iconOff: String?
    let iconPosition: IconLabelView.IconPosition
    let iconSize: CGFloat
    let iconMargin: CGFloat
    let fontSize: CGFloat
    let fontColor: Color
    let selectedFontColor: Color
    let fontName: String?
    let action: (() -> Void)?
    
    @State private var isSelected = false
    
    public init(
        text: String,
        iconOn: String? = nil,
        iconOff: String? = nil,
        iconPosition: IconLabelView.IconPosition = .left,
        iconSize: CGFloat = 24,
        iconMargin: CGFloat = 5,
        fontSize: CGFloat = 16,
        fontColor: Color = .primary,
        selectedFontColor: Color = .accentColor,
        fontName: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.text = text
        self.iconOn = iconOn
        self.iconOff = iconOff
        self.iconPosition = iconPosition
        self.iconSize = iconSize
        self.iconMargin = iconMargin
        self.fontSize = fontSize
        self.fontColor = fontColor
        self.selectedFontColor = selectedFontColor
        self.fontName = fontName
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            isSelected.toggle()
            action?()
        }) {
            IconLabelView(
                text: text,
                iconOn: iconOn,
                iconOff: iconOff,
                iconPosition: iconPosition,
                iconSize: iconSize,
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