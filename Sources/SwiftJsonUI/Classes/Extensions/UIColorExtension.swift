//
//  UIColorExtension.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2015/02/11.


import UIKit

public extension UIColor {
    
    class func colorWithHexString(_ hex: String, alpha: CGFloat) -> UIColor {
        var cString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        
        let scanner = Scanner(string: cString)
        var hexNumber: UInt64 = 0
        if scanner.scanHexInt64(&hexNumber) {
            var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0
            switch cString.count {
            case 3:
                r = CGFloat((hexNumber & 0xF00) >> 8) / 15.0
                g = CGFloat((hexNumber & 0x0F0) >> 4) / 15.0
                b = CGFloat(hexNumber & 0x00F) / 15.0
            case 6:
                r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
                g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
                b = CGFloat(hexNumber & 0x0000FF) / 255.0
            default:
                print("Invalid Color Code")
            }
            return UIColor(red: r, green: g, blue: b, alpha: alpha)
        } else {
            print("Invalid Color Code")
            return UIColor.clear
        }
    }
    
    class func colorWithHexString(_ hex: String) -> UIColor! {
        var cString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        if cString.count == 6 {
            return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        } else if cString.count == 8 {
            let alpha = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        } else {
            print("Invalid Color Code")
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
