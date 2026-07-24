//
//  HotLoaderConfigReader.swift
//  SwiftJsonUI
//
//  Reads HotLoader configuration for SwiftUI / UIKit apps.
//
//  Config schema (written by `jui build` from docs/hotload/config.json):
//    {
//      "server": { "host": "0.0.0.0", "port": 8081, "wsPath": "/ws" },
//      "client": { "ip": "192.168.x.x", "fallbackToLocalhost": true }
//    }
//
//  Lookup order:
//    1. Bundle resource `hotloader.json`
//    2. Documents directory `hotloader.json`
//    3. Info.plist keys `CurrentIp` / `HotLoader Port` (legacy fallback)
//

import Foundation

public struct HotLoaderRuntimeConfig {
    public let ip: String
    public let port: Int
    public let wsPath: String
}

public class HotLoaderConfigReader {
    public static func getHotLoaderConfig() -> HotLoaderRuntimeConfig {
        if let fromBundle = readFromBundle() {
            return fromBundle
        }
        if let fromDocuments = readFromDocuments() {
            return fromDocuments
        }
        return readFromInfoPlist()
    }

    private static func readFromBundle() -> HotLoaderRuntimeConfig? {
        guard let url = Bundle.main.url(forResource: "hotloader", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        if let cfg = parse(data: data) {
            Logger.debug("[HotLoader] Config loaded from Bundle - IP: \(cfg.ip), Port: \(cfg.port), wsPath: \(cfg.wsPath)")
            return cfg
        }
        return nil
    }

    private static func readFromDocuments() -> HotLoaderRuntimeConfig? {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let configPath = (documentsPath as NSString).appendingPathComponent("hotloader.json")
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)) else {
            return nil
        }
        if let cfg = parse(data: data) {
            Logger.debug("[HotLoader] Config loaded from Documents - IP: \(cfg.ip), Port: \(cfg.port), wsPath: \(cfg.wsPath)")
            return cfg
        }
        return nil
    }

    private static func readFromInfoPlist() -> HotLoaderRuntimeConfig {
        let ip = Bundle.main.object(forInfoDictionaryKey: "CurrentIp") as? String ?? "127.0.0.1"
        let port = Bundle.main.object(forInfoDictionaryKey: "HotLoader Port") as? Int ?? 8081
        Logger.debug("[HotLoader] Using Info.plist fallback - IP: \(ip), Port: \(port)")
        return HotLoaderRuntimeConfig(ip: ip, port: port, wsPath: "/ws")
    }

    private static func parse(data: Data) -> HotLoaderRuntimeConfig? {
        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return nil
        }

        let server = json["server"] as? [String: Any]
        let client = json["client"] as? [String: Any]

        let port = (server?["port"] as? Int) ?? 8081
        let wsPath = (server?["wsPath"] as? String) ?? "/ws"

        var ip = (client?["ip"] as? String) ?? ""
        let fallbackToLocalhost = (client?["fallbackToLocalhost"] as? Bool) ?? true
        if ip.isEmpty && fallbackToLocalhost {
            ip = "127.0.0.1"
        }
        if ip.isEmpty {
            ip = (server?["host"] as? String) ?? "127.0.0.1"
            if ip == "0.0.0.0" {
                ip = "127.0.0.1"
            }
        }

        return HotLoaderRuntimeConfig(ip: ip, port: port, wsPath: wsPath)
    }
}
