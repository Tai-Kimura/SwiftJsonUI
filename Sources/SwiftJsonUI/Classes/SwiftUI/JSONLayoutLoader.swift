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
                for url in layoutURLs {
                    let filename = url.lastPathComponent
                    let toPath = "\(layoutFileDirPath)/\(filename)"
                    
                    if fm.fileExists(atPath: toPath) {
                        try fm.removeItem(atPath: toPath)
                    }
                    try fm.copyItem(at: url, to: URL(fileURLWithPath: toPath))
                    Logger.debug("[JSONLayoutLoader] Copied \(filename) to cache")
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
        // First, try to load from cache directory (updated by HotLoader)
        let cacheFilePath = "\(getLayoutFileDirPath())/\(name).json"
        if let cacheData = try? Data(contentsOf: URL(fileURLWithPath: cacheFilePath)) {
            Logger.debug("[JSONLayoutLoader] Loaded from cache: \(name)")
            return cacheData
        }
        
        // Fallback to bundle
        Logger.debug("[JSONLayoutLoader] Cache miss, falling back to bundle: \(name)")
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