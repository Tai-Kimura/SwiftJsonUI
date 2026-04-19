import SwiftUI

/// CheckBoxView - A customizable checkbox component for SwiftUI Static mode
/// Supports custom icons, labels, and two-way binding
public struct CheckBoxView: View {
    private var isOn: SwiftUI.Binding<Bool>
    let label: String?
    let icon: String?
    let selectedIcon: String?
    let iconSize: CGFloat
    let spacing: CGFloat
    let fontSize: CGFloat?
    let fontWeight: Font.Weight?
    let fontColor: Color?
    let checkedColor: Color
    let uncheckedColor: Color
    let isEnabled: Bool
    let onValueChanged: ((Bool) -> Void)?

    public init(
        isOn: SwiftUI.Binding<Bool>,
        label: String? = nil,
        icon: String? = nil,
        selectedIcon: String? = nil,
        iconSize: CGFloat = 24,
        spacing: CGFloat = 8,
        fontSize: CGFloat? = nil,
        fontWeight: Font.Weight? = nil,
        fontColor: Color? = nil,
        checkedColor: Color = .blue,
        uncheckedColor: Color = .gray,
        isEnabled: Bool = true,
        onValueChanged: ((Bool) -> Void)? = nil
    ) {
        self.isOn = isOn
        self.label = label
        self.icon = icon
        self.selectedIcon = selectedIcon
        self.iconSize = iconSize
        self.spacing = spacing
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.fontColor = fontColor
        self.checkedColor = checkedColor
        self.uncheckedColor = uncheckedColor
        self.isEnabled = isEnabled
        self.onValueChanged = onValueChanged
    }

    /// Convenience initializer with string fontWeight
    public init(
        isOn: SwiftUI.Binding<Bool>,
        label: String? = nil,
        icon: String? = nil,
        selectedIcon: String? = nil,
        iconSize: CGFloat = 24,
        spacing: CGFloat = 8,
        fontSize: CGFloat? = nil,
        fontWeight: String,
        fontColor: Color? = nil,
        checkedColor: Color = .blue,
        uncheckedColor: Color = .gray,
        isEnabled: Bool = true,
        onValueChanged: ((Bool) -> Void)? = nil
    ) {
        self.init(
            isOn: isOn,
            label: label,
            icon: icon,
            selectedIcon: selectedIcon,
            iconSize: iconSize,
            spacing: spacing,
            fontSize: fontSize,
            fontWeight: Font.Weight.from(string: fontWeight),
            fontColor: fontColor,
            checkedColor: checkedColor,
            uncheckedColor: uncheckedColor,
            isEnabled: isEnabled,
            onValueChanged: onValueChanged
        )
    }

    public var body: some View {
        HStack(spacing: spacing) {
            // Checkbox icon
            checkboxIcon
                .onTapGesture {
                    guard isEnabled else { return }
                    isOn.wrappedValue.toggle()
                    onValueChanged?(isOn.wrappedValue)
                }

            // Label text if provided
            if let label = label, !label.isEmpty {
                labelView(text: label)
            }
        }
        .opacity(isEnabled ? 1.0 : 0.5)
    }

    @ViewBuilder
    private var checkboxIcon: some View {
        if let customIcon = isOn.wrappedValue ? selectedIcon : icon,
           !customIcon.isEmpty {
            // Custom icon provided
            Image(customIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
        } else {
            // System checkbox icons
            Image(systemName: isOn.wrappedValue ? "checkmark.square.fill" : "square")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(isOn.wrappedValue ? checkedColor : uncheckedColor)
        }
    }

    @ViewBuilder
    private func labelView(text: String) -> some View {
        let baseText = Text(text)

        if let fontSize = fontSize {
            if let fontWeight = fontWeight {
                baseText
                    .font(.system(size: fontSize, weight: fontWeight))
                    .foregroundColor(fontColor ?? .primary)
            } else {
                baseText
                    .font(.system(size: fontSize))
                    .foregroundColor(fontColor ?? .primary)
            }
        } else if let fontWeight = fontWeight {
            baseText
                .fontWeight(fontWeight)
                .foregroundColor(fontColor ?? .primary)
        } else {
            baseText
                .foregroundColor(fontColor ?? .primary)
        }
    }
}

// MARK: - Preview
#if DEBUG
struct CheckBoxView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Default checkbox
            CheckBoxView(
                isOn: .constant(false),
                label: "Unchecked"
            )

            // Checked checkbox
            CheckBoxView(
                isOn: .constant(true),
                label: "Checked"
            )

            // Disabled checkbox
            CheckBoxView(
                isOn: .constant(true),
                label: "Disabled",
                isEnabled: false
            )

            // Styled checkbox
            CheckBoxView(
                isOn: .constant(true),
                label: "Styled",
                fontSize: 18,
                fontWeight: .bold,
                fontColor: .blue,
                checkedColor: .green
            )
        }
        .padding()
    }
}
#endif
