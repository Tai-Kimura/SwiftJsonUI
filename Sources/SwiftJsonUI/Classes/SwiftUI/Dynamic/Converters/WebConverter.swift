//
//  WebConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI WebView.
//  Rewritten to match web_converter.rb modifier order.
//
//  Modifier order (matching Ruby converter):
//  1. WebView(url:)
//  2. applyStandardModifiers()
//

import SwiftUI
#if DEBUG

public struct WebConverter {

    public static func convert(
        component: DynamicComponent,
        data: [String: Any],
        viewId: String? = nil
    ) -> AnyView {
        // Resolve URL - supports both static string and @{binding} expression
        let urlString: String? = {
            if let src = component.src {
                return resolveUrlString(src, data: data)
            }
            // Fallback: check rawData for "url" key (Ruby converter uses 'url' attribute)
            if let urlRaw = component.rawData["url"] as? String {
                return resolveUrlString(urlRaw, data: data)
            }
            return nil
        }()

        guard let resolvedUrl = urlString, let url = URL(string: resolvedUrl) else {
            return AnyView(
                Text("Invalid URL")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        }

        // Resolve background color
        let bgColor: UIColor? = {
            if let bg = component.rawData["background"] as? String,
               let color = SwiftJsonUIConfiguration.shared.getColor(for: bg) {
                return UIColor(color)
            }
            return nil
        }()

        // 1. WebView(url:, backgroundColor:)
        var result = AnyView(WebView(url: url, backgroundColor: bgColor))

        // 2. applyStandardModifiers()
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }

    // MARK: - Private Helpers

    /// Resolve a URL string that may contain @{binding} expression
    private static func resolveUrlString(_ value: String, data: [String: Any]) -> String {
        if value.hasPrefix("@{") && value.hasSuffix("}") {
            let propertyName = String(value.dropFirst(2).dropLast(1))
            if let resolved = data[propertyName] as? String {
                return resolved
            }
            if let resolvedUrl = data[propertyName] as? URL {
                return resolvedUrl.absoluteString
            }
            return value
        }
        return value
    }
}

#endif // DEBUG
