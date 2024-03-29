//
//  UIViewExtension.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2016/01/18.


import UIKit

var DefaultBackgroundColorKey: UInt8 = 0
var TapBackgroundColorKey: UInt8 = 1
var PropertyNameKey: UInt8 = 2
var BindingKey: UInt8 = 3
var BindingSetKey: UInt8 = 4
var ConstraintInfoKey: UInt8 = 5
var ActivatedConstraintInfoKey: UInt8 = 6
var VisibilityKey: UInt8 = 7
var ViewIdKey: UInt8 = 8
var ScriptsKey: UInt8 = 9
var UIControlStateKey: UInt8 = 10

@objc public protocol UIViewTapDelegate {
    func touchBegin(_ view: UIView)
    func touchEnd(_ view: UIView)
}

public extension UIView {
    var viewId: String? {
        get {
            guard let object = objc_getAssociatedObject(self, &ViewIdKey) as? String else {
                return nil
            }
            return object
        }
        set {
            objc_setAssociatedObject(self, &ViewIdKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var scripts: [ScriptModel.EventType:ScriptModel] {
        get {
            guard let object = objc_getAssociatedObject(self, &ScriptsKey) as? [ScriptModel.EventType:ScriptModel] else {
                let s = [ScriptModel.EventType:ScriptModel]()
                self.scripts = s
                return s
            }
            return object
        }
        set {
            objc_setAssociatedObject(self, &ScriptsKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var defaultBackgroundColor: UIColor! {
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
            var alpha: CGFloat = 0
            self.defaultBackgroundColor?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
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
    
    var tapBackgroundColor: UIColor! {
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
    
    var controlState: UIControl.State {
        get {
            guard let object = objc_getAssociatedObject(self, &UIControlStateKey) as? UIControl.State else {
                return .normal
            }
            return object
        }
        set {
            objc_setAssociatedObject(self, &UIControlStateKey, newValue, .OBJC_ASSOCIATION_RETAIN)
            if newValue == .highlighted {
                if tapBackgroundColor != nil {
                    self.backgroundColor = tapBackgroundColor
                }
            } else {
                if defaultBackgroundColor != nil {
                    self.backgroundColor = defaultBackgroundColor
                }
            }
        }
    }
    
    var propertyName: String? {
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
    
    var binding: String? {
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
    
    var bindingSet: [String:String]? {
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
    
    var constraintInfo: UILayoutConstraintInfo? {
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
    
    var isActiveForConstraint: Bool {
        get {
            guard let object = objc_getAssociatedObject(self, &ActivatedConstraintInfoKey) as? Bool else {
                return false
            }
            return object
        }
        set {
            if isActiveForConstraint != newValue {
                objc_setAssociatedObject(self, &ActivatedConstraintInfoKey, newValue, .OBJC_ASSOCIATION_RETAIN)
                setVisibility(oldValue: .visible, newValue: self.visibility)
            }
        }
    }
    
    var visibility: SJUIView.Visibility {
        get {
            guard let object = objc_getAssociatedObject(self, &VisibilityKey) as? SJUIView.Visibility else {
                return .visible
            }
            return object
        }
        set {
            if visibility != newValue {
                let oldValue = self.visibility
                objc_setAssociatedObject(self, &VisibilityKey, newValue, .OBJC_ASSOCIATION_RETAIN)
                if self.isActiveForConstraint {
                    setVisibility(oldValue: oldValue, newValue: newValue)
                }
            }
        }
    }
    
    private func setVisibility(oldValue: SJUIView.Visibility, newValue: SJUIView.Visibility) {
        switch newValue {
        case .visible:
            self.isHidden = false
            if oldValue == .gone {
                if let info = self.constraintInfo, let superview = info.superviewToAdd {
                    if let nextToView = self.findNextVisibleView() {
                        superview.insertSubview(self, aboveSubview: nextToView)
                    } else {
                        superview.insertSubview(self, at: 0)
                    }
                    info.superviewToAdd = nil
                    resetConstraintInfo(resetAllSubviews: true)
                }
            }
        case .invisible:
            self.isHidden = true
            if oldValue == .gone {
                if let info = self.constraintInfo, let superview = info.superviewToAdd {
                    if let nextToView = self.findNextVisibleView() {
                        superview.insertSubview(self, aboveSubview: nextToView)
                    } else {
                        superview.insertSubview(self, at: 0)
                    }
                    info.superviewToAdd = nil
                    resetConstraintInfo(resetAllSubviews: true)
                }
            }
        case .gone:
            if let info = self.constraintInfo {
                info.superviewToAdd = self.superview
                self.removeFromSuperview()
                info.superviewToAdd?.resetConstraintInfo()
            }
        }
    }
    
    private func findNextVisibleView() -> UIView? {
        guard let nextToView = self.constraintInfo?.nextToView else {
            return nil
        }
        if nextToView.visibility != .gone {
            return nextToView
        }
        return nextToView.findNextVisibleView()
    }
    
    func setBackgroundColor(color: UIColor?, forState state: UIControl.State = .normal) {
        if state == .highlighted {
            self.tapBackgroundColor = color
        } else  {
            self.defaultBackgroundColor = color
        }
        self.backgroundColor = color
    }
    
    @objc
    func onBeginTap() {
        controlState = .highlighted
    }
    @objc
    func onEndTap() {
        controlState = .normal
    }
    
    func shouldWrapContent() -> Bool {
        guard let info = self.constraintInfo else {
            return false
        }
        if let orientation = (self as? SJUIView)?.orientation {
            switch orientation {
            case .vertical:
                return info.height == UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue || (info.height == nil && info.maxHeight == nil && info.heightWeight == nil && info.maxHeightWeight == nil)
            case .horizontal:
                return info.width == UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue || (info.width == nil && info.maxWidth == nil && info.widthWeight == nil && info.maxWidthWeight == nil)
            }
        }
        return false
    }
    
    func isExistsOnDisplay() -> Bool {
        return self.visibility != .gone
    }
    
    func hasEffectiveRelatedConstraintWith(view: UIView) -> Bool {
        if let superview = view.superview as? SJUIView, superview.orientation != nil  {
            if let myIndex = superview.subviews.firstIndex(of: self), let viewIndex = superview.subviews.firstIndex(of: view) {
                if viewIndex == myIndex + 1 {
                    return true
                } else if superview.subviews.count <= 2 {
                    return true
                }
            }
        }
        if let constraintInfo = view.constraintInfo {
            return constraintInfo.alignTopOfView == self || constraintInfo.alignBottomOfView == self || constraintInfo.alignLeftOfView == self || constraintInfo.alignRightOfView == self
        }
        return false
    }
    
    
    func updateConstraintInfo(resetAllSubviews: Bool = false) {
        if var constraintInfo = self.constraintInfo {
            UIViewDisposure.removeConstraint(constraintInfo: constraintInfo)
            if self.visibility != .gone {
                UIViewDisposure.applyConstraint(onView: self, toConstraintInfo: &constraintInfo)
            }
        }
        resetSubviews(resetAllSubviews: resetAllSubviews)
        if let superview = superview {
            for subview in superview.subviews {
                if var info = subview.constraintInfo, subview != self {
                    if self.hasEffectiveRelatedConstraintWith(view: subview) {
                        UIViewDisposure.removeConstraint(constraintInfo: info)
                        UIViewDisposure.applyConstraint(onView: subview, toConstraintInfo: &info)
                    }
                }
            }
            if var constraintInfo = superview.constraintInfo {
                UIViewDisposure.removeConstraint(constraintInfo: constraintInfo)
                UIViewDisposure.applyConstraint(onView: superview, toConstraintInfo: &constraintInfo)
            }
        }
        (self.superview ?? self).setNeedsLayout()
    }
    
    private func resetSubviews(resetAllSubviews: Bool) {
        for subview in self.subviews {
            if var info = subview.constraintInfo {
                UIViewDisposure.removeConstraint(constraintInfo: info)
                UIViewDisposure.applyConstraint(onView: subview, toConstraintInfo: &info)
                if resetAllSubviews && !subview.subviews.isEmpty {
                    subview.resetSubviews(resetAllSubviews: resetAllSubviews)
                }
            }
        }
    }
    
    func resetConstraintInfo(resetAllSubviews: Bool = false) {
        guard self.isActiveForConstraint else {
            return
        }
        updateConstraintInfo(resetAllSubviews: resetAllSubviews)
        (self.superview ?? self).layoutIfNeeded()
    }
    
    func animateWithConstraintInfo(duration: TimeInterval, resetAllSubviews: Bool = false, otherAnimations:( () -> Void)? = nil, completion: ((Bool) -> Void)? = nil) {
        updateConstraintInfo(resetAllSubviews: resetAllSubviews)
        UIView.animate(withDuration: duration, animations: {
            (self.superview ?? self).layoutIfNeeded()
            otherAnimations?()
        }, completion: completion)
    }
}

public extension UIView {
    
    func click(_ closure: @escaping (_ gesture: UITapGestureRecognizer)->()) {
        let sleeve = GestureClosureSleeve<UITapGestureRecognizer>(closure)
        let recognizer = UITapGestureRecognizer(target: sleeve, action: #selector(GestureClosureSleeve.invoke(_:)))
        self.addGestureRecognizer(recognizer)
        objc_setAssociatedObject(self, String(format: "[%d]", arc4random()), sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
    
    func longPress(duration: CFTimeInterval, _ closure: @escaping (_ gesture: UILongPressGestureRecognizer)->()) {
        let sleeve = GestureClosureSleeve<UILongPressGestureRecognizer>(closure)
        let recognizer = UILongPressGestureRecognizer(target: sleeve, action: #selector(GestureClosureSleeve.invoke(_:)))
        recognizer.minimumPressDuration = duration
        self.addGestureRecognizer(recognizer)
        objc_setAssociatedObject(self, String(format: "[%d]", arc4random()), sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
    
    func pan(_ closure: @escaping (_ gesture: UIPanGestureRecognizer)->()) {
        let sleeve = GestureClosureSleeve<UIPanGestureRecognizer>(closure)
        let recognizer = UIPanGestureRecognizer(target: sleeve, action: #selector(GestureClosureSleeve.invoke(_:)))
        self.addGestureRecognizer(recognizer)
        objc_setAssociatedObject(self, String(format: "[%d]", arc4random()), sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }

    func pinch(_ closure: @escaping (_ gesture: UIPinchGestureRecognizer)->()) {
        let sleeve = GestureClosureSleeve<UIPinchGestureRecognizer>(closure)
        let recognizer = UIPinchGestureRecognizer(target: sleeve, action: #selector(GestureClosureSleeve.invoke(_:)))
        self.addGestureRecognizer(recognizer)
        objc_setAssociatedObject(self, String(format: "[%d]", arc4random()), sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}


class GestureClosureSleeve<T: UIGestureRecognizer> {
    let closure: (_ gesture: T)->()

    init(_ closure: @escaping (_ gesture: T)->()) {
        self.closure = closure
    }

    @objc func invoke(_ gesture: Any) {
        guard let gesture = gesture as? T else { return }
        closure(gesture)
    }
}


