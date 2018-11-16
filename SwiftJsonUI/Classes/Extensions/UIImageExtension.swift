//
//  UIImageExtension.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2016/01/25.

import UIKit

public extension UIImage {
    
    public func resize(_ size: CGSize) -> UIImage {
        if self.size.width > size.width || self.size.height > size.height {
            let widthRatio = size.width / self.size.width
            let heightRatio = size.height / self.size.height
            let ratio = (widthRatio < heightRatio) ? widthRatio : heightRatio
            let resizedSize = CGSize(width: (self.size.width * ratio), height: (self.size.height * ratio))
            UIGraphicsBeginImageContext(resizedSize)
            draw(in: CGRect(x: 0, y: 0, width: resizedSize.width, height: resizedSize.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return UIImage(cgImage: resizedImage!.cgImage!)
        } else {
            return UIImage(cgImage: self.cgImage!)
        }
    }
    
    
    public func fixOrientation () -> UIImage {
        if self.imageOrientation == .up {
            return self
        }
        var transform = CGAffineTransform.identity
        let width = self.size.width
        let height = self.size.height
        
        switch (self.imageOrientation) {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: width, y: height)
            transform = transform.rotated(by: CGFloat(Double.pi))
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi/2))
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: height)
            transform = transform.rotated(by: CGFloat(-Double.pi/2))
        default: // o.Up, o.UpMirrored:
            break
        }
        
        switch (self.imageOrientation) {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default: // o.Up, o.Down, o.Left, o.Right
            break
        }
        let cgimage = self.cgImage
        
        let ctx = CGContext(data: nil, width: Int(width), height: Int(height),
            bitsPerComponent: (cgimage?.bitsPerComponent)!, bytesPerRow: 0,
            space: (cgimage?.colorSpace!)!,
            bitmapInfo: (cgimage?.bitmapInfo.rawValue)!)
        
        ctx?.concatenate(transform)
        
        switch (self.imageOrientation) {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx?.draw(cgimage!, in: CGRect(x: 0, y: 0, width: height, height: width))
        default:
            ctx?.draw(cgimage!, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        let cgimg = ctx?.makeImage()
        let img = UIImage(cgImage: cgimg!)
        return img
    }
    
    func circularScaleAndCropImage() -> UIImage! {
        //Get the width and heights
        let imageWidth = self.size.width
        let imageHeight = self.size.height
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
        self.draw(in: CGRect(x: 0, y: 0, width: rectWidth, height: rectHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        return newImage;
    }
    
    public func base64image() -> String {
        let data = NSData(data: self.pngData()!) as Data
        return data.base64EncodedString(options: .lineLength64Characters)
    }
}
