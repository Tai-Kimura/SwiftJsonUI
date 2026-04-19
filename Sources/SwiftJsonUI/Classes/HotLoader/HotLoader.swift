//
//  HotLoader.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2018/09/21.
//

import UIKit
import Combine

#if DEBUG
public class HotLoader: NSObject, URLSessionWebSocketDelegate, ObservableObject {
    
    private static var Instance = HotLoader()
    
    public var additionalRequestParameter = ""
    
    // SwiftUI用のPublished properties
    @Published public var jsonData: [String: Data] = [:]
    @Published public var lastUpdate = Date()
    
    public static var instance: HotLoader {
        get {
            return Instance
        }
    }
    
    public var isHotLoadEnabled: Bool = false
    {
        willSet {
            if newValue != isHotLoadEnabled {
                newValue ? connectToSocket() : disconnectFromSocket()
            }
        }
    }
    
    private var _webSocketTask: URLSessionWebSocketTask?
    
    private var _delegateQueue = DispatchQueue(label: "swiftjsonui.hotloader")
    
    private func connectToSocket() {
        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        let (ip, port) = getHotLoaderConfig()
        let url = URL(string: "ws://\(ip):\(port)/websocket")!
        _webSocketTask = urlSession.webSocketTask(with: url)
        _webSocketTask?.resume()
        receiveMessage()
    }
    
    private func getHotLoaderConfig() -> (ip: String, port: String) {
        let config = HotLoaderConfigReader.getHotLoaderConfig()
        return (config.ip, String(config.port))
    }
    
    private func receiveMessage() {
        _webSocketTask?.receive { [weak self] result in
            switch result {
              case .success(let message):
                do {
                    switch message {
                    case .string(let text):
                        if let data = text.data(using: .utf8) {
                            
                            if let strs = try JSONSerialization.jsonObject(with: data, options: []) as? [String],  strs.count >= 3 {
                                Logger.debug("SwiftJSONUIHotloader \(strs[0])")
                                Logger.debug("SwiftJSONUIHotloader \(strs[1])")
                                Logger.debug("SwiftJSONUIHotloader \(strs[2])")
                                self?.downloadLayout(layoutPath: strs[0], dirName: strs[1], fileName: strs[2])
                            }
                            
                        }
                    case .data(let data):
                        print("SwiftJSONUIHotloader Received! binary: \(data)")
                        if let strs = try JSONSerialization.jsonObject(with: data, options: []) as? [String],  strs.count >= 3 {
                            Logger.debug("SwiftJSONUIHotloader \(strs[0])")
                            Logger.debug("SwiftJSONUIHotloader \(strs[1])")
                            Logger.debug("SwiftJSONUIHotloader \(strs[2])")
                            self?.downloadLayout(layoutPath: strs[0], dirName: strs[1], fileName: strs[2])
                        }
                    @unknown default:
                        fatalError()
                    }
                } catch {
                    Logger.debug("SwiftJSONUIHotloader Parse Json Error: \(error.localizedDescription)")
                }
                self?.receiveMessage()  // <- 継続して受信するために再帰的に呼び出す
              case .failure(let error):
                Logger.debug("SwiftJSONUIHotloader Failed! error: \(error)")
            }
        }
    }
    
    private func disconnectFromSocket() {
        Logger.debug("SwiftJSONUIHotloader socket disconnect")
        _webSocketTask?.cancel()
        _webSocketTask = nil
    }

    /// Reconnect to the WebSocket server if enabled
    /// Call this when the app returns to foreground or when switching modes
    public func reconnectIfNeeded() {
        guard isHotLoadEnabled else { return }

        // Check if connection is still active
        if let task = _webSocketTask, task.state == .running {
            Logger.debug("SwiftJSONUIHotloader already connected")
            return
        }

        Logger.debug("SwiftJSONUIHotloader reconnecting...")
        connectToSocket()
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Logger.debug("SwiftJSONUIHotloader socket connected")
    }
    
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let notification = NSNotification.Name("SwiftJSONUIHotloader socketDidDisConnected")
        NotificationCenter.default.post(name: notification, object: nil)
    }
    
    private func downloadLayout(layoutPath: String, dirName: String, fileName: String) {
        let (ip, port) = getHotLoaderConfig()
        // URL encode the fileName to handle subdirectory paths (e.g., "home/whisky_card")
        let encodedFileName = fileName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? fileName
        if let url = URL(string: "http://\(ip):\(port)/\(layoutPath)?file_path=\(encodedFileName)&dir_name=\(dirName)&\(additionalRequestParameter)") {
            Logger.debug("SwiftJSONUIHotloader \(url.absoluteString)")
            let downloader = Downloader(url: url)
            downloader.completionHandler = { data, exist in
                let fm = FileManager.default
                let dir: String
                let ext: String
                switch dirName {
                case "styles":
                    dir = SJUIViewCreator.getStyleFileDirPath()
                    ext = ".json"
                case "scripts":
                    dir = SJUIViewCreator.getScriptFileDirPath()
                    ext = ".js"
                default:
                    dir = SJUIViewCreator.getLayoutFileDirPath()
                    ext = ".json"
                }

                // fileName may contain subdirectory path (e.g., "home/whisky_card")
                // We need to create the subdirectory if it doesn't exist
                let toPath = "\(dir)/\(fileName)\(ext)"
                let toDir = (toPath as NSString).deletingLastPathComponent

                do {
                    // Create subdirectory if needed
                    if !fm.fileExists(atPath: toDir) {
                        try fm.createDirectory(atPath: toDir, withIntermediateDirectories: true, attributes: nil)
                        Logger.debug("SwiftJSONUIHotloader Created directory: \(toDir)")
                    }

                    if (fm.fileExists(atPath: toPath)) {
                        try fm.removeItem(atPath: toPath)
                    }
                    fm.createFile(atPath: toPath, contents:data, attributes:nil)
                    Logger.debug("SwiftJSONUIHotloader Layout Updated: \(toPath)")

                    // SwiftUI用にもデータを保存
                    // Use just the base filename (without subdirectory) as the key for backward compatibility
                    let baseName = (fileName as NSString).lastPathComponent
                    let jsonName = baseName.replacingOccurrences(of: ".json", with: "")
                    self.jsonData[jsonName] = data
                    Logger.debug("[HotLoader] Saved JSON with key: \(jsonName)")

                    // Clear JSONLayoutLoader component cache so it reloads from disk
                    JSONLayoutLoader.clearComponentCache(for: jsonName)
                    Logger.debug("[HotLoader] Cleared component cache for: \(jsonName)")

                    DispatchQueue.main.async(execute: {
                        // 既存のUIKit用通知
                        let notification = NSNotification.Name("layoutFileDidChanged")
                        NotificationCenter.default.post(name: notification, object: nil)

                        // SwiftUI用の更新トリガー
                        self.lastUpdate = Date()
                        Logger.debug("[HotLoader] Updated lastUpdate trigger")
                    })
                } catch let error {
                    Logger.debug("SwiftJSONUIHotloader Error: \(error)")
                }
            }
            downloader.start(true)
        }
    }
}
#endif

