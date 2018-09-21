//
//  UIViewExtension.swift
//
//  Created by 木村太一朗 on 2016/01/18.
//  Copyright © 2016年 木村太一朗 All rights reserved.
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

var DefaultBackgroundColorKey: UInt8 = 0

var TapBackgroundColorKey: UInt8 = 1

var PropertyNameKey: UInt8 = 2

var BindingKey: UInt8 = 3

var BindingSetKey: UInt8 = 4

var ConstraintInfoKey: UInt8 = 5

var ActivatedConstraintInfoKey: UInt8 = 6

@objc public protocol UIViewTapDelegate {
    func touchBegin(_ view: UIView)
    func touchEnd(_ view: UIView)
}

public extension UIView {
    
    public var defaultBackgroundColor: UIColor! {
        get {
            guard let object = objc_getAssociatedObject(self, &DefaultBackgroundColorKey) as? UIColor else {
                return nil
            }
            return object
        }
        set {
            objc_setAssociatedObject(self, &DefaultBackgroundColorKey, newValue, .OBJC_ASSOCIATION_RETAIN)
            var red: CGFloat = 1.0
            var green: CGFloat = 1.0
            var blue: CGFloat = 1.0
            var alpha: CGFloat = 1.0
            self.defaultBackgroundColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            if alpha == 1.0 {
                let isWhite = red == 1.0 && green == 1.0 && blue == 1.0
                red = red * (isWhite ? 0.95 : 0.8)
                green = green * (isWhite ? 0.95 : 0.8)
                blue = blue * (isWhite ? 0.95 : 0.8)
                self.tapBackgroundColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
            } else {
                alpha = 0.1
                self.tapBackgroundColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
            }
        }
    }
    
    public var tapBackgroundColor: UIColor! {
        get {
            guard let object = objc_getAssociatedObject(self, &TapBackgroundColorKey) as? UIColor else {
                return nil
            }
            return object
        }
        set {
            objc_setAssociatedObject(self, &TapBackgroundColorKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public var propertyName: String? {
        get {
            guard let object = objc_getAssociatedObject(self, &PropertyNameKey) as? String else {
                return nil
            }
            return object
        }
        set {
            objc_setAssociatedObject(self, &PropertyNameKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public var binding: String? {
        get {
            guard let object = objc_getAssociatedObject(self, &BindingKey) as? String else {
                return nil
            }
            return object
        }
        set {
            objc_setAssociatedObject(self, &BindingKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public var bindingSet: [String:String]? {
        get {
            guard let object = objc_getAssociatedObject(self, &BindingSetKey) as? [String:String] else {
                return nil
            }
            return object
        }
        set {
            objc_setAssociatedObject(self, &BindingSetKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public var constraintInfo: UILayoutConstraintInfo? {
        get {
            guard let object = objc_getAssociatedObject(self, &ConstraintInfoKey) as? UILayoutConstraintInfo else {
                return nil
            }
            return object
        }
        set {
            objc_setAssociatedObject(self, &ConstraintInfoKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public var isActiveForConstraint: Bool {
        get {
            guard let object = objc_getAssociatedObject(self, &ActivatedConstraintInfoKey) as? Bool else {
                return false
            }
            return object
        }
        set {
            objc_setAssociatedObject(self, &ActivatedConstraintInfoKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    @objc
    public func onBeginTap() {
        if tapBackgroundColor != nil {
            self.backgroundColor = tapBackgroundColor
        }
    }
    @objc
    public func onEndTap() {
        if defaultBackgroundColor != nil {
            self.backgroundColor = defaultBackgroundColor
        }
    }
    
    public func shouldWrapContent() -> Bool {
        guard let info = self.constraintInfo else {
            return false
        }
        if info.width == UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue || info.height == UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue {
            return true
        }
        if let orientation = (self as? SJUIView)?.orientation {
            switch orientation {
            case .vertical:
                return info.height == nil && info.maxHeight == nil && info.heightWeight == nil && info.maxHeightWeight == nil
            case .horizontal:
                return info.width == nil && info.maxWidth == nil && info.widthWeight == nil && info.maxWidthWeight == nil
            }
        }
        return false
    }
    
    public func hasEffectiveRelatedConstraintWith(view: UIView) -> Bool {
        if let superview = view.superview as? SJUIView, superview.orientation != nil  {
            if let myIndex = superview.subviews.index(of: self), let viewIndex = superview.subviews.index(of: view) {
                if viewIndex == myIndex + 1 {
                    return true
                }
            }
        }
        if let constraintInfo = view.constraintInfo {
            return constraintInfo.alignTopOfView == self || constraintInfo.alignBottomOfView == self || constraintInfo.alignLeftOfView == self || constraintInfo.alignRightOfView == self
        }
        return false
    }
    
    
    public func updateConstraintInfo() {
        if var constraintInfo = self.constraintInfo {
            NSLayoutConstraint.deactivate(constraintInfo.constraints)
            UIViewDisposure.applyConstraint(onView: self, toConstraintInfo: &constraintInfo)
        }
        for subview in self.subviews {
            if var info = subview.constraintInfo {
                NSLayoutConstraint.deactivate(info.constraints)
                UIViewDisposure.applyConstraint(onView: subview, toConstraintInfo: &info)
            }
        }
        if let superview = superview {
            for subview in superview.subviews {
                if var info = subview.constraintInfo, subview != self {
                    if self.hasEffectiveRelatedConstraintWith(view: subview) {
                        NSLayoutConstraint.deactivate(info.constraints)
                        UIViewDisposure.applyConstraint(onView: subview, toConstraintInfo: &info)
                    }
                }
            }
        }
        (self.superview ?? self).setNeedsLayout()
    }
    
    public func resetConstraintInfo() {
        updateConstraintInfo()
        (self.superview ?? self).layoutIfNeeded()
    }
    
    public func animateWithConstraintInfo(duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        updateConstraintInfo()
        UIView.animate(withDuration: duration, animations: {
            (self.superview ?? self).layoutIfNeeded()
        }, completion: completion)
    }
}

