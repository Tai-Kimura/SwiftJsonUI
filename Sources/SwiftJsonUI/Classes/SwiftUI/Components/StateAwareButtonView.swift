import SwiftUI

// Custom button style for state-aware buttons
// All styling (background, cornerRadius, border) is applied inside the button
struct StateAwareButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let borderWidth: CGFloat?
    let borderColor: Color?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(backgroundColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(cornerRadius)
            .overlay(
                Group {
                    if let borderWidth = borderWidth, borderWidth > 0, let borderColor = borderColor {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: borderWidth)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// State-aware button for Static mode
// Tracks pressed and disabled states for visual feedback
public struct StateAwareButtonView: View {
    let text: String
    let partialAttributes: [PartialAttribute]?
    let action: () -> Void
    let fontSize: CGFloat?
    let fontWeight: Font.Weight?
    let fontColor: Color?
    let backgroundColor: Color?
    let tapBackground: Color?
    let highlightColor: Color?
    let disabledFontColor: Color?
    let disabledBackground: Color?
    let cornerRadius: CGFloat?
    let borderWidth: CGFloat?
    let borderColor: Color?
    let padding: EdgeInsets?
    let isEnabled: Bool
    let width: CGFloat?
    let height: CGFloat?

    @State private var isPressed = false

    public init(
        text: String,
        partialAttributes: [PartialAttribute]? = nil,
        action: @escaping () -> Void,
        fontSize: CGFloat? = nil,
        fontWeight: Font.Weight? = nil,
        fontColor: Color? = nil,
        backgroundColor: Color? = nil,
        tapBackground: Color? = nil,
        highlightColor: Color? = nil,
        disabledFontColor: Color? = nil,
        disabledBackground: Color? = nil,
        cornerRadius: CGFloat? = nil,
        borderWidth: CGFloat? = nil,
        borderColor: Color? = nil,
        padding: EdgeInsets? = nil,
        isEnabled: Bool = true,
        width: CGFloat? = nil,
        height: CGFloat? = nil
    ) {
        self.text = text
        self.partialAttributes = partialAttributes
        self.action = action
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.fontColor = fontColor
        self.backgroundColor = backgroundColor
        self.tapBackground = tapBackground
        self.highlightColor = highlightColor
        self.disabledFontColor = disabledFontColor
        self.disabledBackground = disabledBackground
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.padding = padding
        self.isEnabled = isEnabled
        self.width = width
        self.height = height
    }
    
    /// Convenience initializer for backward compatibility with string fontWeight
    public init(
        text: String,
        partialAttributes: [PartialAttribute]? = nil,
        action: @escaping () -> Void,
        fontSize: CGFloat? = nil,
        fontWeight: String,
        fontColor: Color? = nil,
        backgroundColor: Color? = nil,
        tapBackground: Color? = nil,
        highlightColor: Color? = nil,
        disabledFontColor: Color? = nil,
        disabledBackground: Color? = nil,
        cornerRadius: CGFloat? = nil,
        borderWidth: CGFloat? = nil,
        borderColor: Color? = nil,
        padding: EdgeInsets? = nil,
        isEnabled: Bool = true,
        width: CGFloat? = nil,
        height: CGFloat? = nil
    ) {
        self.init(
            text: text,
            partialAttributes: partialAttributes,
            action: action,
            fontSize: fontSize,
            fontWeight: Font.Weight.from(string: fontWeight),
            fontColor: fontColor,
            backgroundColor: backgroundColor,
            tapBackground: tapBackground,
            highlightColor: highlightColor,
            disabledFontColor: disabledFontColor,
            disabledBackground: disabledBackground,
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            borderColor: borderColor,
            padding: padding,
            isEnabled: isEnabled,
            width: width,
            height: height
        )
    }
    
    // Get text color based on state
    private var textColor: Color {
        if !isEnabled {
            // Use disabledFontColor if available
            return disabledFontColor ?? .gray
        } else if isPressed {
            // Use highlightColor if available when pressed
            return highlightColor ?? fontColor ?? .white
        } else {
            // Normal state - use fontColor
            return fontColor ?? .white
        }
    }
    
    // Get background color based on state
    private var backgroundColorComputed: Color {
        if !isEnabled {
            // Use disabledBackground if available
            return disabledBackground ?? Color.gray.opacity(0.3)
        } else if isPressed {
            // Use tapBackground if available when pressed
            if let tapBg = tapBackground {
                return tapBg
            }
            // Darken the normal background when pressed
            return (backgroundColor ?? .blue).opacity(0.8)
        } else {
            // Normal state
            return backgroundColor ?? .blue
        }
    }
    
    public var body: some View {
        Button(action: action) {
            PartialAttributedText(
                text,
                partialAttributes: partialAttributes ?? [],
                fontSize: fontSize,
                fontWeight: fontWeight,
                fontColor: textColor
            )
            .padding(padding ?? EdgeInsets())
            .frame(
                minWidth: nil,
                idealWidth: nil,
                maxWidth: width == nil ? nil : (width == -1 ? .infinity : width),
                minHeight: nil,
                idealHeight: nil,
                maxHeight: height == nil ? nil : (height == -1 ? .infinity : height)
            )
            // Apply fixed height if specified (not -1/infinity)
            .frame(height: (height != nil && height != -1) ? height : nil)
        }
        .buttonStyle(StateAwareButtonStyle(
            backgroundColor: backgroundColorComputed,
            cornerRadius: cornerRadius ?? 0,
            borderWidth: borderWidth,
            borderColor: borderColor
        ))
        .disabled(!isEnabled)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    // Handle tap
                }
        )
    }
}