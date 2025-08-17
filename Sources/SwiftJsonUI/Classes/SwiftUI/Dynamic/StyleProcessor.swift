import Foundation

/// Process and apply styles to Dynamic components
public class StyleProcessor {
    
    // Cache for loaded style files
    private static var styleCache: [String: [String: Any]] = [:]
    
    /// Process a JSON dictionary and apply styles recursively
    public static func processStyles(_ json: [String: Any]) -> [String: Any] {
        var result = json
        
        // Check if this component has a style attribute
        if let styleName = json["style"] as? String {
            if let styleData = loadStyle(named: styleName) {
                // Deep merge style data with component data
                // Component properties override style properties
                result = deepMerge(base: styleData, override: json)
                // Remove the style attribute after processing
                result.removeValue(forKey: "style")
            }
        }
        
        // Process child components recursively
        if let child = json["child"] {
            if let childArray = child as? [[String: Any]] {
                result["child"] = childArray.map { processStyles($0) }
            } else if let childDict = child as? [String: Any] {
                result["child"] = processStyles(childDict)
            }
        }
        
        // Process children array (for components like TabView)
        if let children = json["children"] as? [[String: Any]] {
            result["children"] = children.map { processStyles($0) }
        }
        
        return result
    }
    
    /// Load a style file from the Styles directory
    private static func loadStyle(named name: String) -> [String: Any]? {
        // Check cache first
        if let cached = styleCache[name] {
            return cached
        }
        
        // Try to load from bundle
        if let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Styles") {
            do {
                let data = try Data(contentsOf: url)
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // Cache the loaded style
                    styleCache[name] = json
                    Logger.debug("[StyleProcessor] Loaded style: \(name)")
                    return json
                }
            } catch {
                Logger.debug("[StyleProcessor] Error loading style \(name): \(error)")
            }
        }
        
        // Try without subdirectory (for flat bundle structure)
        if let url = Bundle.main.url(forResource: "Styles/\(name)", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // Cache the loaded style
                    styleCache[name] = json
                    Logger.debug("[StyleProcessor] Loaded style from flat structure: \(name)")
                    return json
                }
            } catch {
                Logger.debug("[StyleProcessor] Error loading style \(name): \(error)")
            }
        }
        
        Logger.debug("[StyleProcessor] Style not found: \(name)")
        return nil
    }
    
    /// Deep merge two dictionaries
    /// - Parameters:
    ///   - base: The base dictionary (style data)
    ///   - override: The override dictionary (component data)
    /// - Returns: Merged dictionary
    private static func deepMerge(base: [String: Any], override: [String: Any]) -> [String: Any] {
        var result = base
        
        for (key, value) in override {
            if let baseDict = result[key] as? [String: Any],
               let overrideDict = value as? [String: Any] {
                // Both are dictionaries, merge recursively
                result[key] = deepMerge(base: baseDict, override: overrideDict)
            } else {
                // Override the value
                result[key] = value
            }
        }
        
        return result
    }
    
    /// Clear the style cache
    public static func clearCache() {
        styleCache.removeAll()
        Logger.debug("[StyleProcessor] Style cache cleared")
    }
}