import Foundation
#if DEBUG


/// Process and apply styles to Dynamic components
public class StyleProcessor {
    
    // Cache for loaded style files
    private static var styleCache: [String: [String: Any]] = [:]
    
    #if DEBUG
    // Track file modification times for cache invalidation in DEBUG mode
    private static var styleFileTimestamps: [String: Date] = [:]
    private static let cacheDirPath = NSTemporaryDirectory().appending("Styles/")
    #endif
    
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
                Logger.debug("[StyleProcessor] Applied style '\(styleName)' to component")
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
        #if DEBUG
        // In DEBUG mode, check if cached file needs to be reloaded
        if let cached = styleCache[name] {
            if !needsReload(styleName: name) {
                return cached
            } else {
                Logger.debug("[StyleProcessor] Style file '\(name)' has been modified, reloading...")
            }
        }
        #else
        // In RELEASE mode, use cache without checking for modifications
        if let cached = styleCache[name] {
            return cached
        }
        #endif
        
        // Try to load from cache directory first (for HotLoader support)
        #if DEBUG
        let cacheFilePath = cacheDirPath + "\(name).json"
        if FileManager.default.fileExists(atPath: cacheFilePath) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: cacheFilePath))
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // Update cache and timestamp
                    styleCache[name] = json
                    if let attributes = try? FileManager.default.attributesOfItem(atPath: cacheFilePath),
                       let modificationDate = attributes[.modificationDate] as? Date {
                        styleFileTimestamps[name] = modificationDate
                    }
                    Logger.debug("[StyleProcessor] Loaded style from cache: \(name)")
                    return json
                }
            } catch {
                Logger.debug("[StyleProcessor] Error loading cached style \(name): \(error)")
            }
        }
        #endif
        
        // Try to load from bundle - multiple search strategies
        
        // Strategy 1: Look in Styles subdirectory
        if let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Styles") {
            do {
                let data = try Data(contentsOf: url)
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // Cache the loaded style
                    styleCache[name] = json
                    #if DEBUG
                    // Store the modification date
                    if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                       let modificationDate = attributes[.modificationDate] as? Date {
                        styleFileTimestamps[name] = modificationDate
                    }
                    #endif
                    Logger.debug("[StyleProcessor] Loaded style from bundle subdirectory: \(name)")
                    return json
                }
            } catch {
                Logger.debug("[StyleProcessor] Error loading style from subdirectory \(name): \(error)")
            }
        }
        
        // Strategy 2: Try with path prefix
        if let url = Bundle.main.url(forResource: "Styles/\(name)", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // Cache the loaded style
                    styleCache[name] = json
                    #if DEBUG
                    // Store the modification date
                    if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                       let modificationDate = attributes[.modificationDate] as? Date {
                        styleFileTimestamps[name] = modificationDate
                    }
                    #endif
                    Logger.debug("[StyleProcessor] Loaded style with path prefix: \(name)")
                    return json
                }
            } catch {
                Logger.debug("[StyleProcessor] Error loading style with path prefix \(name): \(error)")
            }
        }
        
        // Strategy 3: Look for style files that were copied as regular resources
        if let url = Bundle.main.url(forResource: "\(name)_style", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // Cache the loaded style
                    styleCache[name] = json
                    #if DEBUG
                    // Store the modification date
                    if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                       let modificationDate = attributes[.modificationDate] as? Date {
                        styleFileTimestamps[name] = modificationDate
                    }
                    #endif
                    Logger.debug("[StyleProcessor] Loaded style with _style suffix: \(name)")
                    return json
                }
            } catch {
                Logger.debug("[StyleProcessor] Error loading style with suffix \(name): \(error)")
            }
        }
        
        // Strategy 4: Look directly in bundle root (for when Styles folder contents are copied flat)
        if let url = Bundle.main.url(forResource: name, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                // Check if this is actually a style file (has a "type" field typical of styles)
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   json["type"] != nil {
                    // Cache the loaded style
                    styleCache[name] = json
                    #if DEBUG
                    // Store the modification date
                    if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                       let modificationDate = attributes[.modificationDate] as? Date {
                        styleFileTimestamps[name] = modificationDate
                    }
                    #endif
                    Logger.debug("[StyleProcessor] Loaded style from bundle root: \(name)")
                    return json
                }
            } catch {
                Logger.debug("[StyleProcessor] Error loading style from root \(name): \(error)")
            }
        }
        
        // Log all available resources for debugging
        #if DEBUG
        Logger.debug("[StyleProcessor] Style not found: \(name). Searching for available style resources...")
        if let resourcePath = Bundle.main.resourcePath {
            do {
                let resourceContents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                let jsonFiles = resourceContents.filter { $0.hasSuffix(".json") && $0.contains("style") }
                if !jsonFiles.isEmpty {
                    Logger.debug("[StyleProcessor] Found style-related JSON files: \(jsonFiles)")
                }
                
                // Check if Styles directory exists
                let stylesPath = (resourcePath as NSString).appendingPathComponent("Styles")
                if FileManager.default.fileExists(atPath: stylesPath) {
                    let stylesContents = try FileManager.default.contentsOfDirectory(atPath: stylesPath)
                    Logger.debug("[StyleProcessor] Styles directory contents: \(stylesContents)")
                } else {
                    Logger.debug("[StyleProcessor] Styles directory not found in bundle")
                }
            } catch {
                Logger.debug("[StyleProcessor] Error listing bundle resources: \(error)")
            }
        }
        #endif
        
        Logger.debug("[StyleProcessor] Style not found after all strategies: \(name)")
        return nil
    }
    
    #if DEBUG
    /// Check if a cached style file needs to be reloaded
    private static func needsReload(styleName: String) -> Bool {
        // Check cache directory first
        let cacheFilePath = cacheDirPath + "\(styleName).json"
        if FileManager.default.fileExists(atPath: cacheFilePath) {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: cacheFilePath),
               let modificationDate = attributes[.modificationDate] as? Date,
               let cachedDate = styleFileTimestamps[styleName] {
                return modificationDate > cachedDate
            }
            return true // Reload if we can't determine the modification date
        }
        
        // Check bundle
        if let url = Bundle.main.url(forResource: styleName, withExtension: "json", subdirectory: "Styles") {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let modificationDate = attributes[.modificationDate] as? Date,
               let cachedDate = styleFileTimestamps[styleName] {
                return modificationDate > cachedDate
            }
        }
        
        return false
    }
    
    /// Copy style files from bundle to cache directory (for HotLoader support)
    public static func copyStylesToCache() {
        let fm = FileManager.default
        
        // Create cache directory if needed
        if !fm.fileExists(atPath: cacheDirPath) {
            do {
                try fm.createDirectory(atPath: cacheDirPath, withIntermediateDirectories: true, attributes: nil)
                Logger.debug("[StyleProcessor] Created styles cache directory")
            } catch {
                Logger.debug("[StyleProcessor] Error creating cache directory: \(error)")
                return
            }
        }
        
        // Copy style files from bundle to cache
        if let stylesURL = Bundle.main.url(forResource: "Styles", withExtension: nil) {
            do {
                let styleFiles = try fm.contentsOfDirectory(at: stylesURL, includingPropertiesForKeys: nil)
                for fileURL in styleFiles where fileURL.pathExtension == "json" {
                    let filename = fileURL.lastPathComponent
                    let toPath = cacheDirPath + filename
                    
                    // Remove existing file if present
                    if fm.fileExists(atPath: toPath) {
                        try fm.removeItem(atPath: toPath)
                    }
                    
                    // Copy new file
                    try fm.copyItem(at: fileURL, to: URL(fileURLWithPath: toPath))
                    Logger.debug("[StyleProcessor] Copied style to cache: \(filename)")
                }
            } catch {
                Logger.debug("[StyleProcessor] Error copying styles to cache: \(error)")
            }
        }
    }
    #endif
    
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
        #if DEBUG
        styleFileTimestamps.removeAll()
        #endif
        Logger.debug("[StyleProcessor] Style cache cleared")
    }
    
    /// Clear cache for a specific style
    public static func clearCache(for styleName: String) {
        styleCache.removeValue(forKey: styleName)
        #if DEBUG
        styleFileTimestamps.removeValue(forKey: styleName)
        #endif
        Logger.debug("[StyleProcessor] Cleared cache for style: \(styleName)")
    }
}
#endif // DEBUG
