//
//  HotLoader.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2018/09/21.
//
//  Wire protocol v2 (SwiftJsonUI 9.2.0 / jui-tools centralized hotload):
//    client → server: { "type": "hello", "platform": "ios" }
//    server → client: { "type": "welcome", ... }
//    server → client: { "type": "hello_ack", "platform": "ios" }
//    server → client: { "type": "layout_changed",
//                       "platform": "ios", "kind": "modified",
//                       "layout": "home/home_header",
//                       "path": "/ios/layout/home/home_header" }
//    server → client: { "type": "style_changed",
//                       "platform": "ios", "kind": "...",
//                       "style": "card" }
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
        let config = HotLoaderConfigReader.getHotLoaderConfig()
        let url = URL(string: "ws://\(config.ip):\(config.port)\(config.wsPath)")!
        _webSocketTask = urlSession.webSocketTask(with: url)
        _webSocketTask?.resume()
        sendHello()
        receiveMessage()
    }

    private func sendHello() {
        let hello: [String: Any] = ["type": "hello", "platform": "ios"]
        guard let data = try? JSONSerialization.data(withJSONObject: hello, options: []),
              let text = String(data: data, encoding: .utf8) else { return }
        _webSocketTask?.send(.string(text)) { error in
            if let error = error {
                Logger.debug("SwiftJSONUIHotloader hello send error: \(error)")
            }
        }
    }

    private func receiveMessage() {
        _webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessage()
            case .failure(let error):
                Logger.debug("SwiftJSONUIHotloader Failed! error: \(error)")
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        let data: Data?
        switch message {
        case .string(let text):
            data = text.data(using: .utf8)
        case .data(let d):
            data = d
        @unknown default:
            return
        }
        guard let payload = data,
              let obj = try? JSONSerialization.jsonObject(with: payload, options: []) as? [String: Any],
              let type = obj["type"] as? String else { return }

        switch type {
        case "welcome":
            Logger.debug("SwiftJSONUIHotloader welcome: \(obj)")
        case "hello_ack":
            Logger.debug("SwiftJSONUIHotloader hello_ack: \(obj)")
        case "layout_changed":
            guard let layoutName = obj["layout"] as? String else { return }
            downloadLayout(layoutName: layoutName)
        case "style_changed":
            guard let styleName = obj["style"] as? String else { return }
            downloadStyle(styleName: styleName)
        default:
            Logger.debug("SwiftJSONUIHotloader unhandled message type: \(type)")
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

    private func downloadLayout(layoutName: String) {
        let config = HotLoaderConfigReader.getHotLoaderConfig()
        // layoutName may contain subdirectory (e.g. "home/home_header")
        let encoded = layoutName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? layoutName
        let query = additionalRequestParameter.isEmpty ? "" : "?\(additionalRequestParameter)"
        guard let url = URL(string: "http://\(config.ip):\(config.port)/ios/layout/\(encoded)\(query)") else { return }
        Logger.debug("SwiftJSONUIHotloader GET \(url.absoluteString)")
        let downloader = Downloader(url: url)
        downloader.completionHandler = { [weak self] data, _ in
            guard let self = self, let payload = data else { return }
            self.writeLayoutToDisk(layoutName: layoutName, data: payload)
        }
        downloader.start(true)
    }

    private func downloadStyle(styleName: String) {
        // In the centralized server, style files are merged into layouts
        // before the layout is served. We still receive `style_changed`
        // events so that any cached layouts downstream can be
        // invalidated. Clear the JSONLayoutLoader component cache so
        // subsequent layout fetches re-resolve against the new style.
        Logger.debug("SwiftJSONUIHotloader style_changed: \(styleName) — clearing caches")
        JSONLayoutLoader.clearComponentCache()
        DispatchQueue.main.async {
            self.lastUpdate = Date()
            let notification = NSNotification.Name("layoutFileDidChanged")
            NotificationCenter.default.post(name: notification, object: nil)
        }
    }

    private func writeLayoutToDisk(layoutName: String, data: Data) {
        let fm = FileManager.default
        let dir = SJUIViewCreator.getLayoutFileDirPath()
        let toPath = "\(dir)/\(layoutName).json"
        let toDir = (toPath as NSString).deletingLastPathComponent

        do {
            if !fm.fileExists(atPath: toDir) {
                try fm.createDirectory(atPath: toDir, withIntermediateDirectories: true, attributes: nil)
                Logger.debug("SwiftJSONUIHotloader Created directory: \(toDir)")
            }
            if fm.fileExists(atPath: toPath) {
                try fm.removeItem(atPath: toPath)
            }
            fm.createFile(atPath: toPath, contents: data, attributes: nil)
            Logger.debug("SwiftJSONUIHotloader Layout Updated: \(toPath)")

            // Key by the base file name (no subdirectory) for backward compat
            // with SwiftUI consumers that look up layouts by short name.
            let baseName = (layoutName as NSString).lastPathComponent
            self.jsonData[baseName] = data

            JSONLayoutLoader.clearComponentCache(for: baseName)
            Logger.debug("[HotLoader] Cleared component cache for: \(baseName)")

            DispatchQueue.main.async {
                self.lastUpdate = Date()
                let notification = NSNotification.Name("layoutFileDidChanged")
                NotificationCenter.default.post(name: notification, object: nil)
            }
        } catch {
            Logger.debug("SwiftJSONUIHotloader Error: \(error)")
        }
    }
}
#endif
