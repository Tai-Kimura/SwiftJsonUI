//
//  JSONLayoutLoader.swift
//  SwiftJsonUI
//
//  JSON layout loader for SwiftUI
//

import Foundation

// MARK: - JSON Loader
public class JSONLayoutLoader {
    
    #if DEBUG
    // DEBUGビルドではHotLoaderから取得
    public static func loadJSON(named name: String) -> Data? {
        if HotLoader.instance.isHotLoadEnabled {
            // Debug: Check available keys
            Logger.debug("[JSONLayoutLoader] Looking for: \(name)")
            Logger.debug("[JSONLayoutLoader] Available keys: \(HotLoader.instance.jsonData.keys)")
            
            if let data = HotLoader.instance.jsonData[name] {
                Logger.debug("[JSONLayoutLoader] Found in HotLoader cache")
                return data
            }
            
            // HotLoaderキャッシュにない場合、バンドルから読み込んでキャッシュに追加
            if let bundleData = loadFromBundle(named: name) {
                Logger.debug("[JSONLayoutLoader] Loading from bundle and caching for HotLoader")
                HotLoader.instance.jsonData[name] = bundleData
                return bundleData
            }
        }
        // フォールバック: ローカルファイルから読み込み
        Logger.debug("[JSONLayoutLoader] Falling back to bundle")
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