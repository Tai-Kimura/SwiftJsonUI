//
//  CircleImageView.swift
//
//  Created by 木村太一朗 on 2015/08/27.
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

public class CircleImageView: NetworkImageView {
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
    }
    
    override public func setImageURL(url: URL) {
        downloader?.completionHandler = nil
        downloader?.cancel()
        downloader = nil
        self.layer.removeAllAnimations()
        self.layer.opacity = 1
        if url.absoluteString.count == 0 {
            self.image = self.errorImage != nil ? self.errorImage : self.defaultImage
            return
        }
        
        
        if self.previousPath != nil && self.image != nil && self.image != self.errorImage && self.image != self.defaultImage {
            NetworkImageCache.sharedInstance().cacheImage(self.image!, forKey: previousPath!)
        }
        
        let path = Downloader.getCachePath() + "/" + "circle_" + url.absoluteString.replacingOccurrences(of: "/", with: "_")
        if let image = NetworkImageCache.sharedInstance().getImage(path) {
            self.layer.opacity = 1
            self.image = image
            self.previousPath = path
            return
        } else if previousPath == nil || path != previousPath  {
            self.image = self.loadingImage == nil ? defaultImage : self.loadingImage
        }
        let d = Downloader(url: url)
        d.completionHandler = { data, exist in
            if let data = data {
                if let image = UIImage(data: data) {
                    
                    do {
                        let fm = FileManager.default
                        let path = Downloader.getCachePath() + "/" + "circle_" + url.absoluteString.replacingOccurrences(of: "/", with: "_")
                        
                        let circleImage: UIImage?
                        if fm.fileExists(atPath: path) {
                            circleImage = UIImage(contentsOfFile: path)
                        } else {
                            circleImage = CircleImageView.circularScaleAndCropImage(image)
                            if circleImage != nil {
                                fm.createFile(atPath: path, contents: UIImagePNGRepresentation(circleImage!), attributes: nil)
                            }
                        }
                        
                        DispatchQueue.main.async(execute: {
                            if d == self.downloader {
                                self.layer.removeAllAnimations()
                                self.layer.opacity = exist ? 1.0 : 0
                                self.image = circleImage
                                self.previousPath = path
                                if !exist {
                                    let anim = CABasicAnimation(keyPath: "opacity")
                                    anim.toValue = 1
                                    anim.fromValue = 0
                                    anim.duration = 0.3
                                    anim.repeatCount = 0
                                    anim.autoreverses = false
                                    anim.isRemovedOnCompletion = false
                                    anim.delegate = self
                                    anim.fillMode = kCAFillModeForwards
                                    self.layer.add(anim, forKey: NetworkImageView.animationKey)
                                }
                            } else {
                                print("Not Same")
                            }
                        })
                        if circleImage != nil {
                            NetworkImageCache.sharedInstance().cacheImage(circleImage!, forKey: path)
                        }
                    }
                    return
                }
            }
            
            DispatchQueue.main.async(execute: {
                if d == self.downloader {
                    self.image = self.errorImage != nil ? self.errorImage : self.defaultImage
                }
            })
        }
        downloader = d
        downloader?.start()
    }
    
    
    class func circularScaleAndCropImage(_ image: UIImage!) -> UIImage! {
        
        if image == nil {
            return nil
        }
        //Get the width and heights
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        let rectWidth:CGFloat, rectHeight:CGFloat, radius: CGFloat
        
        if imageWidth > imageHeight {
            rectWidth = imageHeight
            rectHeight = imageHeight * (imageHeight/imageWidth)
            radius = rectHeight/2.0
        } else {
            rectHeight = imageWidth
            rectWidth = imageWidth * (imageWidth/imageHeight)
            radius = rectWidth/2.0
        }
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: rectWidth, height: rectHeight), false, 0)
        
        //Calculate the centre of the circle
        let imageCentreX = rectWidth/2;
        let imageCentreY = rectHeight/2;
        
        let path = UIBezierPath(arcCenter: CGPoint(x: imageCentreX, y: imageCentreY), radius:radius, startAngle: 0, endAngle: CGFloat(2*(Double.pi)), clockwise: true)
        let context = UIGraphicsGetCurrentContext()
        
        context?.saveGState()
        // Clip the drawing area to the path
        path.addClip()
        
        // Draw the image into the context
        image.draw(in: CGRect(x: 0, y: 0, width: rectWidth, height: rectHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        return newImage;
    }
    
    override public class func deleteCaheForPath(url: URL!) -> Bool {
        if url == nil {
            return false
        }
        do {
            let fm = FileManager.default
            let path = Downloader.getCachePath() + "/" + "circle_" + url.absoluteString.replacingOccurrences(of: "/", with: "_")
            if fm.fileExists(atPath: path) {
                try fm.removeItem(atPath: path);
            }
        } catch {
            return false
        }
        return super.deleteCaheForPath(url: url)
    }
    
    override public class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> CircleImageView {
        let rect: CGRect
        
        if let width = attr["width"].cgFloat, let height = attr["height"].cgFloat {
            rect = CGRect(x: 0, y: 0, width: width, height: height)
        } else {
            rect = CGRect.zero
        }
        
        let i = CircleImageView(frame: rect)
        i.clipsToBounds = true
        if let defaultImage = attr["defaultImage"].string {
            i.defaultImage = CircleImageView.circularScaleAndCropImage(UIImage(named: defaultImage))
            i.image = i.defaultImage
        }
        if let errorImage = attr["errorImage"].string {
            i.errorImage = CircleImageView.circularScaleAndCropImage(UIImage(named: errorImage))
        }
        if let loadingImage = attr["loadingImage"].string {
            i.loadingImage = CircleImageView.circularScaleAndCropImage(UIImage(named: loadingImage))
        }
        
        i.contentMode = UIViewContentMode.scaleAspectFill
        if let onclick = attr["onclick"].string {
            let gr = UITapGestureRecognizer(target: target, action: Selector(onclick))
            i.addGestureRecognizer(gr)
            i.isUserInteractionEnabled = true
        }
        return i
    }
    
}
