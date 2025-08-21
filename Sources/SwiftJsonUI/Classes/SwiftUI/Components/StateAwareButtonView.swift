import SwiftUI

// Custom button style for state-aware buttons
struct StateAwareButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
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
        let button = Button(action: action) {
            PartialAttributedText(
                text,
                partialAttributes: partialAttributes ?? [],
                fontSize: fontSize,
                fontWeight: fontWeight,
                fontColor: textColor
            )
            .padding(padding ?? EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            .frame(maxWidth: width == nil ? nil : .infinity)
        }
        .buttonStyle(StateAwareButtonStyle(
            backgroundColor: backgroundColorComputed,
            cornerRadius: cornerRadius ?? 8
        ))
        .disabled(!isEnabled)
        
        // Apply frame if width or height is specified
        let framedButton = Group {
            if let w = width, let h = height {
                button.frame(width: w, height: h)
            } else if let w = width {
                button.frame(width: w)
            } else if let h = height {
                button.frame(height: h)
            } else {
                button
            }
        }
        
        framedButton
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