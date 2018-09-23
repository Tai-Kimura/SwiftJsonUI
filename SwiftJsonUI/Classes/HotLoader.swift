//
//  HotLoader.swift
//  Pods
//
//  Created by 木村太一朗 on 2018/09/21.
//

import UIKit

#if DEBUG
import SocketIO
let socketManager = SocketManager(socketURL: URL(string: "http://\((Bundle.main.object(forInfoDictionaryKey: "CurrentIp") as? String) ?? ""):8080")!)
public class HotLoader {
    
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
    
    private weak var _socket: SocketIOClient?
    
    private func connectToSocket() {
        socketManager.handleQueue.async(execute: {
            let socket = socketManager.defaultSocket
            socket.on(clientEvent: .connect) {data, ack in
                Logger.debug("socket connected")
            }
            socket.on("layoutChanged") {data, ack in
                Logger.debug("\(data[0])")
                Logger.debug("\(data[1])")
                Logger.debug("\(data[2])")
                if let strs = data as? [String], strs.count >= 3 {
                    self.downloadLayout(layoutPath: strs[0], dirName: strs[1], fileName: strs[2])
                }
            }
            
            socket.once(clientEvent: .disconnect, callback: {data, ack in
                let notification = NSNotification.Name("socketDidDisConnected")
                NotificationCenter.default.post(name: notification, object: nil)
            })
            socket.connect()
            self._socket = socket
        })
    }
    
    private func disconnectFromSocket() {
        socketManager.handleQueue.async(execute: {
            self._socket?.disconnect()
        })
    }
    
    private func downloadLayout(layoutPath: String, dirName: String, fileName: String) {
        if let url = URL(string: "http://\((Bundle.main.object(forInfoDictionaryKey: "CurrentIp") as? String) ?? ""):3000/\(layoutPath)?file_path=\(fileName)&dir_name=\(dirName)&\(additionalRequestParameter)") {
            Logger.debug("\(url.absoluteString)")
            let downloader = Downloader(url: url)
            downloader.completionHandler = { data, exist in
                let fm = FileManager.default
                let dir: String
                switch dirName {
                case "styles":
                    dir = SJUIViewCreator.getStyleFileDirPath()
                case "scripts":
                    dir = SJUIViewCreator.getScriptFileDirPath()
                default:
                    dir = SJUIViewCreator.getLayoutFileDirPath()
                }
                let toPath = "\(dir)/\(fileName).json";
                do {
                    if (fm.fileExists(atPath: toPath)) {
                        try fm.removeItem(atPath: toPath)
                    }
                    fm.createFile(atPath: toPath, contents:data, attributes:nil)
                    Logger.debug("Layout Updated")
                    DispatchQueue.main.async(execute: {
                        let notification = NSNotification.Name("layoutFileDidChanged")
                        NotificationCenter.default.post(name: notification, object: nil)
                    })
                } catch let error {
                    Logger.debug("Error: \(error)")
                }
            }
            downloader.start(true)
        }
    }
}
#endif
