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
        if HotLoader.instance.isHotLoadEnabled,
           let data = HotLoader.instance.jsonData[name] {
            return data
        }
        // フォールバック: ローカルファイルから読み込み
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