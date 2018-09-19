//
//  Downloader.swift
//
//  Created by 木村太一朗 on 2015/03/08.
//  Copyright (c) 2015年 木村太一朗. All rights reserved.
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

public class Downloader: NSObject,  URLSessionDownloadDelegate {
    
    public static var operationQueue: OperationQueue!
    
    public static let cachePath = "download_cache"
    
    static let maxCacheSize: Double = 500.0
    
    static let minDiscSize: Double = 1000.0
    
    fileprivate var _url: URL
    
    public var url: URL {
        get {
            return _url
        }
    }
    
    fileprivate var task: URLSessionDownloadTask?
    
    fileprivate var statusCode: Int!
    
    fileprivate static var cacheDir = ""
    
    public var isDownloading: Bool {
        get {
            return task == nil
        }
    }
    
    public var completionHandler:  ((_ data: Data?, _ exist: Bool) -> Void)?
    
    public var progressHandler:  ((_ bytesWritten: Int64, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> Void)?
    
    public init(url: URL) {
        self._url = url
        super.init()
    }
    
    deinit {
        task?.cancel()
    }
    
    public func start(_ forceDownload: Bool = false) {
        task?.cancel()
        if Downloader.operationQueue == nil {
            Downloader.operationQueue = OperationQueue()
            Downloader.operationQueue.qualityOfService = QualityOfService.userInitiated
            Downloader.operationQueue.name = "jp.sjui.download"
            Downloader.operationQueue.maxConcurrentOperationCount = 6
        }
        
        if !forceDownload {
            let fm = FileManager.default
            if fm.fileExists(atPath: Downloader.getCachePath() + self.url.absoluteString.replacingOccurrences(of: "/", with: "_")) {
                Downloader.operationQueue.addOperation({
                    let data = try? Data(contentsOf: URL(fileURLWithPath: Downloader.getCachePath() + self.url.absoluteString.replacingOccurrences(of: "/", with: "_")))
                    self.completionHandler?(data, true)
                })
                return
            }
        }
        let config = URLSessionConfiguration.default
        let session = Foundation.URLSession(configuration: config,
                                            delegate: self, delegateQueue: Downloader.operationQueue);
        task = session.downloadTask(with: url)
        task?.resume()
    }
    
    public func cancel() {
        self.task?.cancel(byProducingResumeData: {dat in
            //            Log("task cancel \(Downloader.operationQueue.maxConcurrentOperationCount)")
        })
        self.completionHandler = nil
        self.task = nil
    }
    
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        //        Log("Loacation \(location)")
        //        Downloader.clearnUpCachePathIfNeeded()
        let fm = FileManager.default
        let path = Downloader.getCachePath() + url.absoluteString.replacingOccurrences(of: "/", with: "_")
        fm.createFile(atPath: path, contents: try? Data(contentsOf: location), attributes: nil)
        //        Log("File Exist ? \(fm.fileExistsAtPath(Downloader.getCachePath() + url.absoluteString.stringByReplacingOccurrencesOfString("/", withString: "_"))) At Path \(Downloader.getCachePath() + url.absoluteString.stringByReplacingOccurrencesOfString("/", withString: "_"))")
        completionHandler?(try? Data(contentsOf: location), false)
        session.finishTasksAndInvalidate()
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        //        Log("Progress")
        progressHandler?(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        //        Log("Download Done \(error)")
        if error != nil {
            self.completionHandler?(nil, false)
        }
        session.invalidateAndCancel()
    }
    
    public static func getCachePath() -> String {
        if !cacheDir.isEmpty {
            return cacheDir
        }
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        if let path = paths.first {
            cacheDir = path + "/" + Downloader.cachePath + "/";
            let fm = FileManager.default
            var directory: ObjCBool = false
            if !fm.fileExists(atPath: cacheDir, isDirectory: &directory) || !directory.boolValue {
                do {
                    try fm.createDirectory(atPath: cacheDir, withIntermediateDirectories: true, attributes: nil)
                    print("Directory Created")
                } catch {
                    
                }
            }
            return cacheDir
        }
        return ""
    }
    
    public static func clearnUpCachePathIfNeeded() {
        DispatchQueue.global().async(execute: {
            var totalSpace: Double = 0//ディスク総容量
            var cacheSize: Double = 0
            var freeSpace: Double = 0//ディスク空き容量
            
            let fm = FileManager.default
            let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            var dictionary: [FileAttributeKey: Any]? = nil
            do {
                if let path = paths.first {
                    let documentsPath = URL(fileURLWithPath: path)
                    let c = documentsPath.appendingPathComponent(Downloader.cachePath)
                    let cacheDir = c.path
                    if !fm.fileExists(atPath: cacheDir) {
                        try fm.createDirectory(atPath: cacheDir, withIntermediateDirectories: true, attributes: nil)
                        return
                    }
                    dictionary = try fm.attributesOfFileSystem(forPath: cacheDir)
                    freeSpace = (((dictionary?[FileAttributeKey.systemFreeSize]) as? NSNumber)?.doubleValue)?.megaByte ?? 0
                    totalSpace = (((dictionary?[FileAttributeKey.systemSize]) as? NSNumber)?.doubleValue)?.megaByte ?? 0
                    let filesArray = try fm.subpathsOfDirectory(atPath: cacheDir)
                    for  file in filesArray {
                        let fileDictionary: NSDictionary = try fm.attributesOfItem(atPath: cacheDir + "/" + file) as NSDictionary
                        let fileSize = fileDictionary.fileSize()
                        //                    Log("File Path: \(fileSize)")
                        cacheSize+=Double(fileSize)
                    }
                    cacheSize = cacheSize.megaByte
                    print("File size: \(totalSpace)")
                    print("space: \(freeSpace)")
                    print("Cache space: \(cacheSize)")
                }
            } catch {
                print("Exception Occurred \(error)")
                return
            }
            
            
            if(freeSpace < Downloader.minDiscSize || cacheSize > Downloader.maxCacheSize){
                //空き容量が不十分な際またはキャッシュが最大サイズを超えた際に行う処理
                print("Cache Dir Clean");
                if let path = paths.first {
                    let cacheDir = path + "/" + Downloader.cachePath
                    if (fm.fileExists(atPath: cacheDir)) {
                        do {
                            try fm.removeItem(atPath: cacheDir)
                        } catch {
                            
                        }
                    }
                }
            }
        })
        
    }
    
    
    public static func clearnUpCachePath() {
        let fm = FileManager.default
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        print("Cache Dir Clean");
        if let path = paths.first {
            let cacheDir = path + "/" + Downloader.cachePath
            if (fm.fileExists(atPath: cacheDir)) {
                do {
                    try fm.removeItem(atPath: cacheDir)
                } catch {
                    
                }
            }
        }
    }
    
}
