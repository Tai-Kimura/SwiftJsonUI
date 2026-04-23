//
//  SwiftJsonUIConfiguration.swift
//  SwiftJsonUI
//
//  Global configuration for SwiftJsonUI SwiftUI components
//

import SwiftUI
import Combine

/// Global configuration for SwiftJsonUI
///
/// Conforms to `ObservableObject` so SwiftUI views can subscribe to theme-mode
/// changes via `@ObservedObject` / `@EnvironmentObject` and recompose when
/// `setThemeMode(_:)` fires a `@Published` update on `currentThemeMode`.
public class SwiftJsonUIConfiguration: ObservableObject {

    // MARK: - Singleton
    public static let shared = SwiftJsonUIConfiguration()

    // MARK: - Nested Configuration Classes

    /// Color configuration
    public let colors = Colors()

    /// TextField configuration
    public let textField = TextFieldConfig()

    /// Button configuration
    public let button = ButtonConfig()

    /// Font configuration
    public let font = FontConfig()

    /// Spacing configuration
    public let spacing = SpacingConfig()

    /// Animation configuration
    public let animation = AnimationConfig()

    // MARK: - Colors Configuration

    public class Colors {
        /// Default background color
        public var background: UIColor = .systemBackground

        /// Default text color
        public var text: UIColor = .label

        /// Default placeholder color
        public var placeholder: UIColor = .placeholderText

        /// Default primary/accent color
        public var primary: UIColor = .systemBlue

        /// Default secondary color
        public var secondary: UIColor = .secondaryLabel

        /// Default border color
        public var border: UIColor = .separator

        /// Default link color
        public var link: UIColor = .link

        /// Default disabled color
        public var disabled: UIColor = .secondaryLabel

        /// Default disabled background color
        public var disabledBackground: UIColor = .systemGray5

        /// Get SwiftUI Color from UIColor
        public func swiftUI(_ keyPath: KeyPath<Colors, UIColor>) -> Color {
            Color(self[keyPath: keyPath])
        }
    }

    // MARK: - TextField Configuration

    public class TextFieldConfig {
        /// Default background color
        public var backgroundColor: UIColor = .systemGray6

        /// Default text color
        public var textColor: UIColor = .label

        /// Default placeholder color
        public var placeholderColor: UIColor = .placeholderText

        /// Default border color
        public var borderColor: UIColor = .separator

        /// Default corner radius
        public var cornerRadius: CGFloat = 8.0

        /// Default border width
        public var borderWidth: CGFloat = 1.0

        /// Get SwiftUI Color from UIColor
        public func swiftUI(_ keyPath: KeyPath<TextFieldConfig, UIColor>) -> Color {
            Color(self[keyPath: keyPath])
        }
    }

    // MARK: - Button Configuration

    public class ButtonConfig {
        /// Default background color
        public var backgroundColor: UIColor = .systemBlue

        /// Default text color
        public var textColor: UIColor = .white

        /// Default corner radius
        public var cornerRadius: CGFloat = 8.0

        /// Default padding
        public var padding: EdgeInsets = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)

        /// Get SwiftUI Color from UIColor
        public func swiftUI(_ keyPath: KeyPath<ButtonConfig, UIColor>) -> Color {
            Color(self[keyPath: keyPath])
        }
    }

    // MARK: - Font Configuration

    public class FontConfig {
        /// Default font size
        public var size: CGFloat = 17.0

        /// Default font weight
        public var weight: Font.Weight = .regular

        /// Default font design
        public var design: Font.Design = .default

        /// Default font name (nil uses system font)
        public var name: String? = nil

        /// Get font with current configuration
        public func getFont(size: CGFloat? = nil, weight: Font.Weight? = nil, design: Font.Design? = nil, name: String? = nil) -> Font {
            let fontSize = size ?? self.size
            let fontWeight = weight ?? self.weight
            let fontDesign = design ?? self.design
            let fontName = name ?? self.name

            if let fontName = fontName {
                return Font.custom(fontName, size: fontSize)
            }

            return Font.system(size: fontSize, weight: fontWeight, design: fontDesign)
        }
    }

    // MARK: - Spacing Configuration

    public class SpacingConfig {
        /// Default line height multiple
        public var lineHeightMultiple: CGFloat = 1.0

        /// Default stack spacing
        public var stackSpacing: CGFloat = 8.0
    }

    // MARK: - Animation Configuration

    public class AnimationConfig {
        /// Default animation duration
        public var duration: Double = 0.3

        /// Default animation type
        public var animation: Animation = .easeInOut
    }

    // MARK: - Custom Provider Functions

    /// Custom color provider function
    /// Can be used to provide colors based on color IDs or names
    public var colorProvider: ((Any) -> Color?)? = nil

    /// Theme-aware color provider. Called by `getColor(for:)` BEFORE
    /// `colorProvider` whenever the requested identifier is a String, so
    /// apps can route layout colors through a themed `ColorManager` without
    /// replacing their existing non-themed `colorProvider`.
    ///
    /// Closure args: `(currentThemeMode, key)` → optional `Color`.
    /// Return `nil` to fall through to the hex/`colorProvider` fallback.
    ///
    /// Wiring example with the tool-generated `ColorManager.swift`:
    /// ```
    /// SwiftJsonUIConfiguration.shared.themedColorProvider = { mode, key in
    ///     guard let m = ColorManager.ColorMode(rawValue: mode) else { return nil }
    ///     return ColorManager.swiftui.color(for: key, mode: m)
    /// }
    /// ```
    public var themedColorProvider: ((_ mode: String, _ key: String) -> Color?)? = nil

    /// Current theme mode (raw-string form — e.g. `"light"`, `"dark"`,
    /// `"high_contrast"`). Purely a label: the actual color set lives in
    /// `themedColorProvider`. Mutations go through `setThemeMode(_:)` so
    /// subscribers + `@Published` fire.
    @Published public private(set) var currentThemeMode: String = "light"

    /// Switch the active theme mode. Notifies SwiftUI observers (via
    /// `@Published`) AND registered callbacks, in that order. A no-op if
    /// `mode` matches `currentThemeMode`.
    public func setThemeMode(_ mode: String) {
        guard currentThemeMode != mode else { return }
        currentThemeMode = mode
        themeChangeCallbacks.values.forEach { $0(mode) }
    }

    private var themeChangeCallbacks: [UUID: (String) -> Void] = [:]

    /// Subscribe to theme-mode changes from non-SwiftUI code (UIKit, legacy
    /// observers). Returns a closure that unsubscribes.
    @discardableResult
    public func subscribeToThemeChanges(_ callback: @escaping (String) -> Void) -> () -> Void {
        let id = UUID()
        themeChangeCallbacks[id] = callback
        return { [weak self] in self?.themeChangeCallbacks.removeValue(forKey: id) }
    }

    /// Custom font provider function
    /// Can be used to provide custom fonts based on font names
    public var fontProvider: ((String) -> Font?)? = nil

    /// Custom image provider function
    /// Can be used to provide images from custom sources
    public var imageProvider: ((String) -> Image?)? = nil

    /// Custom action handler
    /// Can be used to intercept and handle actions globally
    public var globalActionHandler: ((String, Any?) -> Bool)? = nil

    // MARK: - Initialization

    private init() {
        setupSystemDefaults()
    }

    // MARK: - Public Methods

    /// Reset all settings to default values
    public func reset() {
        // Colors
        colors.background = .systemBackground
        colors.text = .label
        colors.placeholder = .placeholderText
        colors.primary = .systemBlue
        colors.secondary = .secondaryLabel
        colors.border = .separator
        colors.link = .link
        colors.disabled = .secondaryLabel
        colors.disabledBackground = .systemGray5

        // TextField
        textField.backgroundColor = .systemGray6
        textField.textColor = .label
        textField.placeholderColor = .placeholderText
        textField.borderColor = .separator
        textField.cornerRadius = 8.0
        textField.borderWidth = 1.0

        // Button
        button.backgroundColor = .systemBlue
        button.textColor = .white
        button.cornerRadius = 8.0
        button.padding = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)

        // Font
        font.size = 17.0
        font.weight = .regular
        font.design = .default
        font.name = nil

        // Spacing
        spacing.lineHeightMultiple = 1.0
        spacing.stackSpacing = 8.0

        // Animation
        animation.duration = 0.3
        animation.animation = .easeInOut

        // Providers
        colorProvider = nil
        themedColorProvider = nil
        fontProvider = nil
        imageProvider = nil
        globalActionHandler = nil

        // Theme state
        currentThemeMode = "light"
        themeChangeCallbacks.removeAll()
    }

    /// Configure with a closure for easy setup
    public func configure(_ configuration: (SwiftJsonUIConfiguration) -> Void) {
        configuration(self)
    }

    /// Get color with fallback chain:
    ///   1. Already a `Color` — pass through.
    ///   2. `themedColorProvider(currentThemeMode, key)` if identifier is a
    ///      string — this is the theme-aware path; apps hook a generated
    ///      `ColorManager` here so layout color keys follow the active mode.
    ///   3. Legacy `colorProvider(identifier)` — pre-theme custom resolution.
    ///   4. Hex string parse via `Color(hex:)`.
    public func getColor(for identifier: Any) -> Color? {
        // If already a Color, return as-is
        if let color = identifier as? Color {
            return color
        }

        // Theme-aware provider (new in 9.1.0). Runs before the legacy
        // `colorProvider` so apps that wire both get the themed result first.
        if let key = identifier as? String,
           let themed = themedColorProvider?(currentThemeMode, key) {
            return themed
        }

        // Try color provider next
        if let color = colorProvider?(identifier) {
            return color
        }

        // Fallback to hex string conversion
        if let hexString = identifier as? String {
            return Color(hex: hexString)
        }

        return nil
    }

    // MARK: - Private Methods

    private func setupSystemDefaults() {
        if UITraitCollection.current.preferredContentSizeCategory.isAccessibilityCategory {
            font.size = 20.0
        }
    }
}

// MARK: - Color Extension for Hex Support

public extension Color {
    init?(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Convenience Theme Functions

public extension SwiftJsonUIConfiguration {

    /// Configure for a dark theme
    func applyDarkTheme() {
        colors.background = .black
        colors.text = .white
        colors.placeholder = .lightGray
        textField.backgroundColor = .darkGray
        textField.borderColor = .gray
    }

    /// Configure for a light theme
    func applyLightTheme() {
        colors.background = .white
        colors.text = .black
        colors.placeholder = .darkGray
        textField.backgroundColor = .systemGray6
        textField.borderColor = .systemGray4
    }

    /// Configure for high contrast
    func applyHighContrast() {
        font.weight = .semibold
        button.backgroundColor = .black
        button.textColor = .white
        textField.borderColor = .black
    }
}
