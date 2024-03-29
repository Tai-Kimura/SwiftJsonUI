//
//  HotLoader.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2018/09/21.
//

import UIKit

#if DEBUG
public class HotLoader: NSObject, URLSessionWebSocketDelegate {
    
    private static var Instance = HotLoader()
    
    public var additionalRequestParameter = ""
    
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
        let url = URL(string: "ws://\((Bundle.main.object(forInfoDictionaryKey: "CurrentIp") as? String) ?? ""):\((Bundle.main.object(forInfoDictionaryKey: "HotLoader Port") as? String) ?? "8080")")!
        _webSocketTask = urlSession.webSocketTask(with: url)
        _webSocketTask?.resume()
        receiveMessage()
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
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Logger.debug("SwiftJSONUIHotloader socket connected")
    }
    
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let notification = NSNotification.Name("SwiftJSONUIHotloader socketDidDisConnected")
        NotificationCenter.default.post(name: notification, object: nil)
    }
    
    private func downloadLayout(layoutPath: String, dirName: String, fileName: String) {
        if let url = URL(string: "http://\((Bundle.main.object(forInfoDictionaryKey: "CurrentIp") as? String) ?? ""):3000/\(layoutPath)?file_path=\(fileName)&dir_name=\(dirName)&\(additionalRequestParameter)") {
            Logger.debug("SwiftJSONUIHotloader \(url.absoluteString)")
            let downloader = Downloader(url: url)
            downloader.completionHandler = { data, exist in
                let fm = FileManager.default
                let dir: String
                let toPath: String
                switch dirName {
                case "styles":
                    dir = SJUIViewCreator.getStyleFileDirPath()
                    toPath = "\(dir)/\(fileName).json";
                case "scripts":
                    dir = SJUIViewCreator.getScriptFileDirPath()
                    toPath = "\(dir)/\(fileName).js";
                default:
                    dir = SJUIViewCreator.getLayoutFileDirPath()
                    toPath = "\(dir)/\(fileName).json";
                }
                do {
                    if (fm.fileExists(atPath: toPath)) {
                        try fm.removeItem(atPath: toPath)
                    }
                    fm.createFile(atPath: toPath, contents:data, attributes:nil)
                    Logger.debug("SwiftJSONUIHotloader Layout Updated")
                    DispatchQueue.main.async(execute: {
                        let notification = NSNotification.Name("layoutFileDidChanged")
                        NotificationCenter.default.post(name: notification, object: nil)
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

