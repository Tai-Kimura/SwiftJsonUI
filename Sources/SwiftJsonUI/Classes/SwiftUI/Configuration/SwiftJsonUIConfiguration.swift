//
//  SwiftJsonUIConfiguration.swift
//  SwiftJsonUI
//
//  Global configuration for SwiftJsonUI SwiftUI components
//

import SwiftUI

/// Global configuration for SwiftJsonUI
public class SwiftJsonUIConfiguration {
    
    // MARK: - Singleton
    public static let shared = SwiftJsonUIConfiguration()
    
    // MARK: - Default Font Settings
    
    /// Default font size for text components
    public var defaultFontSize: CGFloat = 17.0
    
    /// Default font weight for text components
    public var defaultFontWeight: Font.Weight = .regular
    
    /// Default font design (default, serif, monospaced, rounded)
    public var defaultFontDesign: Font.Design = .default
    
    /// Default font name (nil uses system font)
    public var defaultFontName: String? = nil
    
    // MARK: - Default Colors
    
    /// Default text color
    public var defaultFontColor: Color = .primary
    
    /// Default hint/placeholder color
    public var defaultHintColor: Color = .secondary
    
    /// Default link color
    public var defaultLinkColor: Color = .blue
    
    /// Default disabled text color
    public var defaultDisabledFontColor: Color = Color(UIColor.secondaryLabel)
    
    /// Default disabled background color
    public var defaultDisabledBackground: Color = Color(UIColor.systemGray5)
    
    // MARK: - Button Defaults
    
    /// Default button background color
    public var defaultButtonBackground: Color = .blue
    
    /// Default button text color
    public var defaultButtonFontColor: Color = .white
    
    /// Default button corner radius
    public var defaultButtonCornerRadius: CGFloat = 8.0
    
    /// Default button padding
    public var defaultButtonPadding: EdgeInsets = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
    
    // MARK: - TextField Defaults
    
    /// Default TextField border color
    public var defaultTextFieldBorderColor: Color = Color(UIColor.systemGray4)
    
    /// Default TextField background color
    public var defaultTextFieldBackground: Color = Color(UIColor.systemGray6)
    
    /// Default TextField corner radius
    public var defaultTextFieldCornerRadius: CGFloat = 8.0
    
    // MARK: - Spacing Defaults
    
    /// Default line spacing multiplier
    public var defaultLineHeightMultiple: CGFloat = 1.0
    
    /// Default stack spacing
    public var defaultStackSpacing: CGFloat = 8.0
    
    // MARK: - Animation Defaults
    
    /// Default animation duration
    public var defaultAnimationDuration: Double = 0.3
    
    /// Default animation type
    public var defaultAnimation: Animation = .easeInOut
    
    // MARK: - Custom Configuration Functions
    
    /// Custom color provider function
    /// Can be used to provide colors based on color IDs or names
    public var colorProvider: ((Any) -> Color?)? = nil
    
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
        // Configure default values based on system settings
        setupSystemDefaults()
    }
    
    // MARK: - Public Methods
    
    /// Reset all settings to default values
    public func reset() {
        defaultFontSize = 17.0
        defaultFontWeight = .regular
        defaultFontDesign = .default
        defaultFontName = nil
        
        defaultFontColor = .primary
        defaultHintColor = .secondary
        defaultLinkColor = .blue
        defaultDisabledFontColor = Color(UIColor.secondaryLabel)
        defaultDisabledBackground = Color(UIColor.systemGray5)
        
        defaultButtonBackground = .blue
        defaultButtonFontColor = .white
        defaultButtonCornerRadius = 8.0
        defaultButtonPadding = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        
        defaultTextFieldBorderColor = Color(UIColor.systemGray4)
        defaultTextFieldBackground = Color(UIColor.systemGray6)
        defaultTextFieldCornerRadius = 8.0
        
        defaultLineHeightMultiple = 1.0
        defaultStackSpacing = 8.0
        
        defaultAnimationDuration = 0.3
        defaultAnimation = .easeInOut
        
        colorProvider = nil
        fontProvider = nil
        imageProvider = nil
        globalActionHandler = nil
    }
    
    /// Configure with a closure for easy setup
    public func configure(_ configuration: (SwiftJsonUIConfiguration) -> Void) {
        configuration(self)
    }
    
    /// Get font with current configuration
    public func getFont(size: CGFloat? = nil, weight: Font.Weight? = nil, design: Font.Design? = nil, name: String? = nil) -> Font {
        let fontSize = size ?? defaultFontSize
        let fontWeight = weight ?? defaultFontWeight
        let fontDesign = design ?? defaultFontDesign
        let fontName = name ?? defaultFontName
        
        // Check custom font provider first
        if let name = fontName, let customFont = fontProvider?(name) {
            return customFont
        }
        
        // Use custom font if specified
        if let fontName = fontName {
            return Font.custom(fontName, size: fontSize)
        }
        
        // Use system font with specified parameters
        return Font.system(size: fontSize, weight: fontWeight, design: fontDesign)
    }
    
    /// Get color with fallback to color provider
    public func getColor(for identifier: Any) -> Color? {
        // Try hex string first
        if let hexString = identifier as? String {
            return Color(hex: hexString)
        }
        
        // Try color provider
        return colorProvider?(identifier)
    }
    
    // MARK: - Private Methods
    
    private func setupSystemDefaults() {
        // Adjust defaults based on system settings
        if UITraitCollection.current.preferredContentSizeCategory.isAccessibilityCategory {
            // Increase default font size for accessibility
            defaultFontSize = 20.0
        }
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
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

// MARK: - Convenience Configuration Functions

public extension SwiftJsonUIConfiguration {
    
    /// Configure for a dark theme
    func applyDarkTheme() {
        defaultFontColor = .white
        defaultButtonBackground = Color(UIColor.systemBlue)
        defaultTextFieldBackground = Color(UIColor.systemGray5)
        defaultTextFieldBorderColor = Color(UIColor.systemGray3)
    }
    
    /// Configure for a light theme
    func applyLightTheme() {
        defaultFontColor = .black
        defaultButtonBackground = Color(UIColor.systemBlue)
        defaultTextFieldBackground = Color(UIColor.systemGray6)
        defaultTextFieldBorderColor = Color(UIColor.systemGray4)
    }
    
    /// Configure for high contrast
    func applyHighContrast() {
        defaultFontWeight = .semibold
        defaultButtonBackground = .black
        defaultButtonFontColor = .white
        defaultTextFieldBorderColor = .black
    }
}