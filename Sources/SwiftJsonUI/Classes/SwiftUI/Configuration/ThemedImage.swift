import SwiftUI
import UIKit

/// A colour mode's own picture.
///
/// jui build writes `<name>.<mode>.svg` (beside `<name>.svg`) as the asset
/// `<name>__<mode>`, the mode spelled `[a-z0-9_]`. An image named `<name>` is
/// drawn from the asset of the current theme mode
/// (`SwiftJsonUIConfiguration.shared.currentThemeMode`, which the generated
/// ColorManager sets) when the app carries one, and from `<name>` otherwise —
/// as it always was. The appearance of an asset catalog is not used: it knows
/// light and dark only, and it follows the OS while a mode chosen in the app
/// does not.
public enum ThemedImage {
    /// The mode as jui build spells it in an asset's name.
    public static func modeSuffix(_ mode: String) -> String {
        String(mode.lowercased().map { ($0.isASCII && ($0.isLetter || $0.isNumber)) || $0 == "_" ? $0 : "_" })
    }

    /// The asset an image named *name* is drawn from in *mode*.
    public static func assetName(_ name: String, mode: String) -> String {
        let themed = "\(name)__\(modeSuffix(mode))"
        return UIImage(named: themed) != nil ? themed : name
    }

    /// The asset in the current theme mode.
    public static func assetName(_ name: String) -> String {
        assetName(name, mode: SwiftJsonUIConfiguration.shared.currentThemeMode)
    }
}

public extension Image {
    /// An image from the app's assets, in the current colour mode (ThemedImage).
    init(jsonUIAsset name: String) {
        self.init(ThemedImage.assetName(name))
    }
}
