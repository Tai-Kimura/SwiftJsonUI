//
//  NetworkImageView.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2015/11/26.

import UIKit

open class NetworkImageView: SJUIImageView {
    
    static let animationKey = "network_image_view_animation_key"
    
    public var defaultImage: UIImage? = nil
    
    public var loadingImage: UIImage? = nil
    
    public var errorImage: UIImage? = nil
    
    public var downloader: Downloader?
    
    public var previousPath: String?
    
    public var renderingMode: UIImage.RenderingMode?
    
    deinit {
        Logger.debug("NetworkImage Deinit")
        self.image = nil
    }
    
    open func setImageResource(_ image: UIImage?) {
        self.previousPath = nil
        self.layer.removeAllAnimations()
        self.layer.opacity = 1
        downloader?.completionHandler = nil
        downloader?.cancel()
        self.image = image
    }
    
    open func setImageURL(string: String!) {
        if let string = string, let url = URL(string: string) {
            self.setImageURL(url: url)
        } else {
            self.setImageResource(nil)
        }
    }
    
    open func setImageURL(url: URL) {
        downloader?.completionHandler = nil
        downloader?.cancel()
        downloader = nil
        self.layer.removeAllAnimations()
        self.layer.opacity = 1
        if url.absoluteString.count == 0 {
            self.image = self.errorImage != nil ? self.errorImage : self.defaultImage
            return
        }
        
        let path = Downloader.getCachePath() + "/" + url.absoluteString.replacingOccurrences(of: "/", with: "_")
        
        if self.previousPath != nil && self.image != nil && self.image != self.errorImage && self.image != self.defaultImage {
            NetworkImageCache.sharedInstance().cacheImage(self.image!, forKey: previousPath! + (renderingMode != nil ? "\(renderingMode!.rawValue)" : ""))
        }
        
        if let image = NetworkImageCache.sharedInstance().getImage(path + (renderingMode != nil ? "\(renderingMode!.rawValue)" : "")) {
            self.layer.opacity = 1
            self.image = image
            self.setNeedsLayout()
            self.previousPath = path
            return
        } else if previousPath == nil || path != previousPath  {
            self.image = self.loadingImage == nil ? defaultImage : self.loadingImage
        }
        
        let d = Downloader(url: url)
        let urlStr = d.url.absoluteString
        d.completionHandler = { [weak self] (data, exist) in
            if let data = data {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async(execute: {
                        self?.layer.removeAllAnimations()
                        if urlStr == self?.downloader?.url.absoluteString {
                            self?.layer.opacity = exist ? 1.0 : 0
                            self?.image = self?.renderingMode != nil ? image.withRenderingMode(self!.renderingMode!) : image
                            self?.setNeedsLayout()
                            self?.previousPath = path
                            if !exist {
                                let anim = CABasicAnimation(keyPath: "opacity")
                                anim.toValue = 1
                                anim.fromValue = 0
                                anim.duration = 0.3
                                anim.repeatCount = 0
                                anim.autoreverses = false
                                anim.isRemovedOnCompletion = false
                                anim.fillMode = CAMediaTimingFillMode.forwards
                                anim.delegate = self
                                self?.layer.add(anim, forKey: NetworkImageView.animationKey)
                            }
                            self?.downloader = nil
                        } else {
                            Logger.debug("Not Same")
                        }
                    })
                    NetworkImageCache.sharedInstance().cacheImage(image, forKey: path)
                }
                return
            }
            
            DispatchQueue.main.async(execute: {
                self?.layer.removeAllAnimations()
                if urlStr == self?.downloader?.url.absoluteString {
                    self?.image = self?.errorImage != nil ? self?.errorImage : self?.defaultImage
                }
            })
            self?.downloader = nil
        }
        downloader = d
        downloader?.start()
    }
    
    override open func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.layer.removeAllAnimations()
        self.layer.opacity = 1
    }
    
    @discardableResult open class func deleteCaheForPath(url: URL!) -> Bool {
        if url == nil {
            return false
        }
        do {
            let fm = FileManager.default
            let path = Downloader.getCachePath() + "/" + url.absoluteString.replacingOccurrences(of: "/", with: "_")
            if fm.fileExists(atPath: path) {
                try fm.removeItem(atPath: path);
            }
            return true
        } catch {
            return false
        }
    }
    
    override open class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> NetworkImageView {
        let i = NetworkImageView()
        i.setMask()
        if let contentMode = attr["contentMode"].string {
            switch (contentMode) {
            case "AspectFill":
                i.contentMode = UIView.ContentMode.scaleAspectFill
            case "AspectFit":
                i.contentMode = UIView.ContentMode.scaleAspectFit
            default:
                i.contentMode = UIView.ContentMode.center
            }
        } else {
            i.contentMode = UIView.ContentMode.scaleAspectFill
        }
        i.clipsToBounds = true
        if let onclick = attr["onclick"].string {
            let gr = UITapGestureRecognizer(target: target, action: Selector(onclick))
            i.addGestureRecognizer(gr)
            i.canTap = true
            i.isUserInteractionEnabled = true
        }
        if let defaultImage = attr["defaultImage"].string {
            i.defaultImage = UIImage(named: defaultImage)
            i.image = i.defaultImage
        }
        if let errorImage = attr["errorImage"].string {
            i.errorImage = UIImage(named: errorImage)
        }
        if let loadingImage = attr["loadingImage"].string {
            i.loadingImage = UIImage(named: loadingImage)
        }
        return i
    }
    
}
