//
//  HotLoaderConfigReader.swift
//  SwiftJsonUI
//
//  Reads HotLoader configuration for SwiftUI apps
//

import Foundation

public class HotLoaderConfigReader {
    public static func getHotLoaderConfig() -> (ip: String, port: Int) {
        // For SwiftUI apps, try to read from Bundle first
        if let url = Bundle.main.url(forResource: "sjui.config", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let hotloader = json["hotloader"] as? [String: Any] {
            let ip = hotloader["ip"] as? String ?? "127.0.0.1"
            let port = hotloader["port"] as? Int ?? 8081
            Logger.debug("[HotLoader] Config loaded from Bundle - IP: \(ip), Port: \(port)")
            return (ip, port)
        }
        
        // Try to read from Documents directory (for UIKit apps)
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let configPath = (documentsPath as NSString).appendingPathComponent("sjui.config")
        
        if let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let hotloader = json["hotloader"] as? [String: Any] {
            let ip = hotloader["ip"] as? String ?? "127.0.0.1"
            let port = hotloader["port"] as? Int ?? 8081
            Logger.debug("[HotLoader] Config loaded from Documents - IP: \(ip), Port: \(port)")
            return (ip, port)
        }
        
        // Fallback to Info.plist
        let ip = Bundle.main.object(forInfoDictionaryKey: "CurrentIp") as? String ?? "127.0.0.1"
        let port = Bundle.main.object(forInfoDictionaryKey: "HotLoader Port") as? Int ?? 8081
        Logger.debug("[HotLoader] Using fallback config - IP: \(ip), Port: \(port)")
        return (ip, port)
    }
}