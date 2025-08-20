# SwiftJsonUI Configuration Guide

SwiftJsonUI provides a global configuration singleton that allows you to customize default settings for all components in your SwiftUI app.

## Basic Usage

```swift
import SwiftJsonUI

// Configure at app startup
SwiftJsonUIConfiguration.shared.configure { config in
    // Font defaults
    config.defaultFontSize = 18.0
    config.defaultFontWeight = .medium
    config.defaultFontName = "Avenir Next"
    
    // Color defaults
    config.defaultFontColor = .primary
    config.defaultLinkColor = .blue
    
    // Button defaults
    config.defaultButtonBackground = .blue
    config.defaultButtonCornerRadius = 12.0
}
```

## Available Settings

### Font Settings
- `defaultFontSize`: Base font size (default: 17.0)
- `defaultFontWeight`: Base font weight (default: .regular)
- `defaultFontDesign`: Font design system (default: .default)
- `defaultFontName`: Custom font name (default: nil for system font)

### Color Settings
- `defaultFontColor`: Default text color
- `defaultHintColor`: Placeholder text color
- `defaultLinkColor`: Link text color
- `defaultDisabledFontColor`: Disabled state text color
- `defaultDisabledBackground`: Disabled state background

### Button Settings
- `defaultButtonBackground`: Button background color
- `defaultButtonFontColor`: Button text color
- `defaultButtonCornerRadius`: Button corner radius
- `defaultButtonPadding`: Button content padding

### TextField Settings
- `defaultTextFieldBorderColor`: TextField border color
- `defaultTextFieldBackground`: TextField background
- `defaultTextFieldCornerRadius`: TextField corner radius

### Other Settings
- `defaultLineHeightMultiple`: Line spacing multiplier
- `defaultStackSpacing`: Default spacing for stacks
- `defaultAnimationDuration`: Animation duration
- `defaultAnimation`: Default animation type

## Custom Providers

You can provide custom functions to handle colors, fonts, images, and actions:

```swift
SwiftJsonUIConfiguration.shared.configure { config in
    // Custom color provider
    config.colorProvider = { identifier in
        switch identifier as? String {
        case "brand":
            return Color(red: 0.2, green: 0.6, blue: 1.0)
        case "accent":
            return Color.orange
        default:
            return nil
        }
    }
    
    // Custom font provider
    config.fontProvider = { fontName in
        switch fontName {
        case "title":
            return Font.custom("Georgia", size: 24).bold()
        case "body":
            return Font.custom("Helvetica", size: 16)
        default:
            return nil
        }
    }
    
    // Custom image provider
    config.imageProvider = { imageName in
        // Load images from custom bundle or source
        if let uiImage = UIImage(named: "custom_\(imageName)") {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    // Global action handler
    config.globalActionHandler = { action, context in
        print("Action triggered: \(action)")
        // Return true to indicate the action was handled
        // Return false to let default handling continue
        return false
    }
}
```

## Theme Presets

SwiftJsonUIConfiguration includes convenient theme presets:

```swift
// Apply dark theme
SwiftJsonUIConfiguration.shared.applyDarkTheme()

// Apply light theme
SwiftJsonUIConfiguration.shared.applyLightTheme()

// Apply high contrast theme
SwiftJsonUIConfiguration.shared.applyHighContrast()
```

## Reset to Defaults

You can reset all settings to their default values:

```swift
SwiftJsonUIConfiguration.shared.reset()
```

## Example: Complete App Configuration

```swift
import SwiftUI
import SwiftJsonUI

@main
struct MyApp: App {
    init() {
        configureSwiftJsonUI()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func configureSwiftJsonUI() {
        SwiftJsonUIConfiguration.shared.configure { config in
            // Brand colors
            config.defaultButtonBackground = Color(hex: "#007AFF") ?? .blue
            config.defaultLinkColor = Color(hex: "#007AFF") ?? .blue
            
            // Typography
            config.defaultFontSize = 16.0
            config.defaultFontWeight = .regular
            config.defaultFontName = "SF Pro Text"
            
            // Component styling
            config.defaultButtonCornerRadius = 10.0
            config.defaultTextFieldCornerRadius = 8.0
            
            // Custom providers
            config.colorProvider = { identifier in
                // Custom color mapping
                AppColors.color(for: identifier)
            }
            
            config.globalActionHandler = { action, context in
                // Custom action handling
                return AppActions.handle(action, context: context)
            }
        }
    }
}
```

## Integration with Dynamic Mode

The configuration automatically applies to both Static and Dynamic mode components:

- Labels and Text components use the default font settings
- Buttons inherit default styling
- Custom providers are called when resolving colors and fonts
- All components respect the global configuration

## Migration from UIKit Configuration

If you're migrating from the UIKit version of SwiftJsonUI, the SwiftUI configuration offers similar functionality:

UIKit version:
```swift
SJUIManager.shared.config.defaultTextFont = UIFont.systemFont(ofSize: 17)
```

SwiftUI version:
```swift
SwiftJsonUIConfiguration.shared.defaultFontSize = 17.0
```

The SwiftUI configuration is designed to be more SwiftUI-native while maintaining compatibility with the JSON-based component system.