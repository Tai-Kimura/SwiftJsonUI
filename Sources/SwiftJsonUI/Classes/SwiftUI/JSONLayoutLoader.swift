//
//  JSONLayoutLoader.swift
//  SwiftJsonUI
//
//  JSON layout loader for SwiftUI
//

import Foundation

// MARK: - JSON Loader
public class JSONLayoutLoader {

    private static var layoutsDirectoryName: String = "Layouts"
    private static var hasLoadedConfiguration = false

    #if DEBUG
    // MARK: - Component Cache (DEBUG only)
    /// Cache for parsed DynamicComponent to avoid repeated JSON parsing
    private static var componentCache: [String: DynamicComponent] = [:]
    private static let cacheLock = NSLock()

    // MARK: - JSON Dictionary Cache (for responsive resolution)
    /// Cache for processed JSON dictionaries (styles applied, includes expanded,
    /// but responsive NOT yet resolved). This allows DynamicView to resolve
    /// responsive overrides at runtime based on the current size class.
    private static var jsonDictCache: [String: [String: Any]] = [:]

    /// Load and cache a DynamicComponent by name
    /// Returns cached component if available, otherwise loads and parses JSON
    public static func loadComponent(named name: String) -> DynamicComponent? {
        cacheLock.lock()
        if let cached = componentCache[name] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        // Load and parse
        guard let data = loadJSON(named: name) else { return nil }

        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                // Apply styles first
                var processedJSON = StyleProcessor.processStyles(jsonObject)

                // Expand includes inline with ID prefix support
                let baseDir = getLayoutFileDirPath()
                processedJSON = IncludeExpander.shared.processIncludes(processedJSON, baseDir: baseDir)

                let processedData = try JSONSerialization.data(withJSONObject: processedJSON, options: [])
                let decoder = JSONDecoder()
                let component = try decoder.decode(DynamicComponent.self, from: processedData)

                // Cache the result
                cacheLock.lock()
                componentCache[name] = component
                cacheLock.unlock()

                return component
            }
        } catch {
            Logger.debug("[JSONLayoutLoader] Error parsing component \(name): \(error)")
        }
        return nil
    }

    /// Load the processed JSON dictionary for a layout by name.
    /// Returns the dictionary with styles applied and includes expanded,
    /// but without responsive resolution (that happens at the view level).
    public static func loadProcessedJSON(named name: String) -> [String: Any]? {
        cacheLock.lock()
        if let cached = jsonDictCache[name] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        guard let data = loadJSON(named: name) else { return nil }

        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                var processedJSON = StyleProcessor.processStyles(jsonObject)
                let baseDir = getLayoutFileDirPath()
                processedJSON = IncludeExpander.shared.processIncludes(processedJSON, baseDir: baseDir)

                cacheLock.lock()
                jsonDictCache[name] = processedJSON
                cacheLock.unlock()

                return processedJSON
            }
        } catch {
            Logger.debug("[JSONLayoutLoader] Error loading JSON dict \(name): \(error)")
        }
        return nil
    }

    /// Decode a processed JSON dictionary into a DynamicComponent.
    public static func decodeComponent(from json: [String: Any]) -> DynamicComponent? {
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            return try JSONDecoder().decode(DynamicComponent.self, from: data)
        } catch {
            Logger.debug("[JSONLayoutLoader] Error decoding component: \(error)")
            return nil
        }
    }

    /// Clear the component cache (call when JSON files are updated)
    public static func clearComponentCache() {
        cacheLock.lock()
        componentCache.removeAll()
        jsonDictCache.removeAll()
        cacheLock.unlock()
    }

    /// Clear specific component from cache
    public static func clearComponentCache(for name: String) {
        cacheLock.lock()
        componentCache.removeValue(forKey: name)
        jsonDictCache.removeValue(forKey: name)
        cacheLock.unlock()
    }
    #endif

    private static func loadConfigurationIfNeeded() {
        guard !hasLoadedConfiguration else { return }

        if let configURL = Bundle.main.url(forResource: "sjui.config", withExtension: "json"),
           let data = try? Data(contentsOf: configURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let layoutsDir = json["layouts_directory"] as? String {
                layoutsDirectoryName = layoutsDir
                Logger.debug("[JSONLayoutLoader] Loaded layouts_directory from config: \(layoutsDir)")
            }
        }
        hasLoadedConfiguration = true
    }

    public static func getLayoutFileDirPath() -> String {
        loadConfigurationIfNeeded()
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let cachesDirPath = paths[0]
        return "\(cachesDirPath)/\(layoutsDirectoryName)"
    }

    #if DEBUG
    public static func copyResourcesToCache() {
        loadConfigurationIfNeeded()
        let fm = FileManager.default
        let layoutFileDirPath = getLayoutFileDirPath()

        do {
            // Create cache directory if needed
            if !fm.fileExists(atPath: layoutFileDirPath) {
                try fm.createDirectory(atPath: layoutFileDirPath, withIntermediateDirectories: true, attributes: nil)
                Logger.debug("[JSONLayoutLoader] Created cache directory: \(layoutFileDirPath)")
            }

            // Copy all JSON files from bundle to cache
            var layoutURLs: [URL] = []

            // Try to get layout files from the layouts directory
            if let layoutsDirURL = Bundle.main.url(forResource: layoutsDirectoryName, withExtension: nil) {
                if let enumerator = fm.enumerator(at: layoutsDirURL, includingPropertiesForKeys: nil) {
                    for case let fileURL as URL in enumerator {
                        if fileURL.pathExtension == "json" {
                            layoutURLs.append(fileURL)
                        }
                    }
                }
            }

            // Fallback to urls(forResourcesWithExtension:subdirectory:)
            if layoutURLs.isEmpty, let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: layoutsDirectoryName) {
                layoutURLs = urls
            }

            if !layoutURLs.isEmpty {
                Logger.debug("[JSONLayoutLoader] Found \(layoutURLs.count) layout files to copy")

                // Get the base layouts directory URL for calculating relative paths
                let layoutsDirURL = Bundle.main.url(forResource: layoutsDirectoryName, withExtension: nil)

                for url in layoutURLs {
                    // Calculate relative path from Layouts directory
                    var relativePath = url.lastPathComponent
                    if let basePath = layoutsDirURL?.path {
                        let fullPath = url.path
                        if fullPath.hasPrefix(basePath) {
                            // Get path relative to Layouts directory (e.g., "home/activity_item.json")
                            relativePath = String(fullPath.dropFirst(basePath.count + 1)) // +1 for "/"
                        }
                    }

                    let toPath = "\(layoutFileDirPath)/\(relativePath)"

                    // Create subdirectory if needed
                    let toDir = (toPath as NSString).deletingLastPathComponent
                    if !fm.fileExists(atPath: toDir) {
                        try fm.createDirectory(atPath: toDir, withIntermediateDirectories: true, attributes: nil)
                    }

                    if fm.fileExists(atPath: toPath) {
                        try fm.removeItem(atPath: toPath)
                    }
                    try fm.copyItem(at: url, to: URL(fileURLWithPath: toPath))
                    Logger.debug("[JSONLayoutLoader] Copied \(relativePath) to cache")
                }
            }
        } catch {
            Logger.debug("[JSONLayoutLoader] Error copying files to cache: \(error)")
        }

        // Also copy style files to cache
        StyleProcessor.copyStylesToCache()
    }
    #endif

    // Clear all cached JSON files
    public static func clearCache() {
        let fm = FileManager.default
        let layoutFileDirPath = getLayoutFileDirPath()

        do {
            if fm.fileExists(atPath: layoutFileDirPath) {
                let contents = try fm.contentsOfDirectory(atPath: layoutFileDirPath)
                for file in contents {
                    if file.hasSuffix(".json") {
                        let filePath = "\(layoutFileDirPath)/\(file)"
                        try fm.removeItem(atPath: filePath)
                        Logger.debug("[JSONLayoutLoader] Removed cached file: \(file)")
                    }
                }
                Logger.debug("[JSONLayoutLoader] Cache cleared successfully")
            } else {
                Logger.debug("[JSONLayoutLoader] Cache directory does not exist")
            }
        } catch {
            Logger.debug("[JSONLayoutLoader] Error clearing cache: \(error)")
        }
    }

    // Clear specific cached JSON file
    public static func clearCache(for name: String) {
        let fm = FileManager.default
        let cacheFilePath = "\(getLayoutFileDirPath())/\(name).json"

        do {
            if fm.fileExists(atPath: cacheFilePath) {
                try fm.removeItem(atPath: cacheFilePath)
                Logger.debug("[JSONLayoutLoader] Removed cached file: \(name).json")
            } else {
                Logger.debug("[JSONLayoutLoader] Cached file not found: \(name).json")
            }
        } catch {
            Logger.debug("[JSONLayoutLoader] Error removing cached file: \(error)")
        }
    }

    #if DEBUG
    // DEBUGビルドではキャッシュまたはHotLoaderから取得
    public static func loadJSON(named name: String) -> Data? {
        let layoutFileDirPath = getLayoutFileDirPath()
        let fm = FileManager.default

        // Log all files in cache directory for debugging
        print("[JSONLayoutLoader] === Looking for: \(name).json ===")
        print("[JSONLayoutLoader] Cache directory: \(layoutFileDirPath)")
        if let enumerator = fm.enumerator(atPath: layoutFileDirPath) {
            print("[JSONLayoutLoader] Files in cache:")
            for case let file as String in enumerator {
                print("[JSONLayoutLoader]   - \(file)")
            }
        } else {
            print("[JSONLayoutLoader] Could not enumerate cache directory")
        }

        // First, try direct path (for files without subdirectory or with explicit path)
        let cacheFilePath = "\(layoutFileDirPath)/\(name).json"
        print("[JSONLayoutLoader] Trying direct path: \(cacheFilePath)")
        if let cacheData = try? Data(contentsOf: URL(fileURLWithPath: cacheFilePath)) {
            print("[JSONLayoutLoader] ✅ Loaded from cache: \(name)")
            return cacheData
        }
        print("[JSONLayoutLoader] ❌ Direct path not found")

        // Search in subdirectories
        print("[JSONLayoutLoader] Searching in subdirectories...")
        if let enumerator = fm.enumerator(atPath: layoutFileDirPath) {
            for case let file as String in enumerator {
                if file.hasSuffix("/\(name).json") || file == "\(name).json" {
                    let fullPath = "\(layoutFileDirPath)/\(file)"
                    print("[JSONLayoutLoader] Found match: \(file)")
                    if let cacheData = try? Data(contentsOf: URL(fileURLWithPath: fullPath)) {
                        print("[JSONLayoutLoader] ✅ Loaded from cache subdirectory: \(file)")
                        return cacheData
                    }
                }
            }
        }
        print("[JSONLayoutLoader] ❌ Not found in subdirectories")

        // Fallback to bundle
        print("[JSONLayoutLoader] Falling back to bundle: \(name)")
        return loadFromBundle(named: name)
    }
    #else
    // リリースビルドではバンドルから読み込み
    public static func loadJSON(named name: String) -> Data? {
        return loadFromBundle(named: name)
    }
    #endif

    private static func loadFromBundle(named name: String) -> Data? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            Logger.debug("[JSONLayoutLoader] File not found: \(name).json")
            return nil
        }

        do {
            return try Data(contentsOf: url)
        } catch {
            Logger.debug("[JSONLayoutLoader] Error loading file: \(error)")
            return nil
        }
    }
}
