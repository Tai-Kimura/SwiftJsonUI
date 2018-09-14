//
//  NetworkImageCache.swift
//  crjooy
//
//  Created by 木村太一朗 on 2016/07/13.
//

import UIKit

open class NetworkImageCache: NSObject {
    
    public static let instance = NetworkImageCache()
    
    public var cache: NSCache<AnyObject, AnyObject>
    
    public var keys = [String]()
    
    public var maxCount = 40
    
    open class func sharedInstance() -> NetworkImageCache {
        return instance
    }
    
    override public init() {
        cache = NSCache()
        super.init()
        cache.countLimit = maxCount
    }
    
    open func cacheImage(_ image: UIImage, forKey key:String) {
        self.cache.setObject(image, forKey: key as AnyObject)
    }
    
    open func cacheImage(_ image: UIImage, forURL url:String) {
        if let URL = URL(string: url) {
            let key = Downloader.getCachePath() + "/" + URL.absoluteString.replacingOccurrences(of: "/", with: "_")
            self.cacheImage(image, forKey: key)
        }
    }
    
    open func getImage(_ key: String) -> UIImage? {
        return self.cache.object(forKey: key as AnyObject) as? UIImage
    }
}
