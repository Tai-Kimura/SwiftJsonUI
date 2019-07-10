//
//  UIColorExtension.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2015/02/11.


import UIKit

public extension UIColor {
    
    class func colorWithHexString(_ hex: String, alpha: CGFloat) -> UIColor {
        var cString = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased() as NSString
        if (cString.hasPrefix("#")) {
            cString = cString.substring(from: 1) as NSString
        }
        
        let rString = cString.substring(to: 2)
        let gString = cString.substring(with: NSMakeRange(2, 2))
        let bString = cString.substring(with: NSMakeRange(4, 2))
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        Scanner(string: rString).scanHexInt32(&r)
        Scanner(string: gString).scanHexInt32(&g)
        Scanner(string: bString).scanHexInt32(&b)
        return UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: alpha)
    }
    
    class func colorWithHexString(_ hex: String) -> UIColor! {
        var cString = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased() as NSString
        if (cString.hasPrefix("#")) {
            cString = cString.substring(from: 1) as NSString
        }
        if cString.length == 6 {
            let rString = cString.substring(to: 2)
            let gString = cString.substring(with: NSMakeRange(2, 2))
            let bString = cString.substring(with: NSMakeRange(4, 2))
            var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
            Scanner(string: rString).scanHexInt32(&r)
            Scanner(string: gString).scanHexInt32(&g)
            Scanner(string: bString).scanHexInt32(&b)
            return UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: 1.0)
        } else if cString.length == 8 {
            let aString = cString.substring(to: 2)
            let rString = cString.substring(with: NSMakeRange(2, 2))
            let gString = cString.substring(with: NSMakeRange(4, 2))
            let bString = cString.substring(with: NSMakeRange(6, 2))
            var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0, a:CUnsignedInt = 0;
            Scanner(string: aString).scanHexInt32(&a)
            Scanner(string: rString).scanHexInt32(&r)
            Scanner(string: gString).scanHexInt32(&g)
            Scanner(string: bString).scanHexInt32(&b)
            return UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: CGFloat(a)/255.0)
        } else {
            Logger.debug("Invalid Color Code")
            return nil
        }
        
    }
    
    class func findColorByJSON(attr:JSON) -> UIColor? {
        if let background = attr.string {
            return UIColor.colorWithHexString(background)
        } else if let closure = SJUIViewCreator.findColorFunc, let background = attr.int {
            return closure(background)
        } else {
            return nil
        }
    }
}
