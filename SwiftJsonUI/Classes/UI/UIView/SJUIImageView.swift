//
//  SJUIImageView.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2016/05/11.
//

import UIKit

open class SJUIImageView: UIImageView {
    
    open class var viewClass: SJUIImageView.Type {
        get {
            return SJUIImageView.self
        }
    }
    
    public var canTap = false
    
    internal var filter: SJUIView?
    
    open func setMask() {
        let filter = SJUIView()
        
        filter.defaultBackgroundColor = UIColor.clear
        filter.canTap = true
        filter.translatesAutoresizingMaskIntoConstraints = false
        filter.autoresizingMask = UIView.AutoresizingMask()
        self.addSubview(filter)
        let constraints = [
            NSLayoutConstraint(item: filter, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: filter, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: filter, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: filter, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: 0)
        ]
        NSLayoutConstraint.activate(constraints)
        self.filter = filter
    }
    
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: self) {
            if location.x >= 0 && location.x <= self.frame.size.width && location.y >= 0 && location.y <= self.frame.size.height {
                onBeginTap()
            }
        }
        super.touchesBegan(touches, with: event)
        
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        onEndTap()
        super.touchesCancelled(touches, with: event)
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        onEndTap()
        super.touchesEnded(touches, with: event)
    }
    
    @objc override open func onBeginTap() {
        if canTap {
            self.filter?.onBeginTap()
        }
    }
    
    @objc override open func onEndTap() {
        if canTap {
            self.filter?.onEndTap()
        }
    }
    
    open class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUIImageView {
        
        let i = viewClass.init()
        i.setMask()
        i.clipsToBounds = true
        if let imgSrc = attr["src"].string {
            i.image = UIImage(named: imgSrc)
        }
        if let imgSrc = attr["highlightSrc"].string {
            i.highlightedImage = UIImage(named: imgSrc)
        }
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
            i.contentMode = UIView.ContentMode.center
        }
        if let onclick = attr["onclick"].string {
            let gr = UITapGestureRecognizer(target: target, action: Selector(onclick))
            i.addGestureRecognizer(gr)
            i.isUserInteractionEnabled = true
        }
        i.canTap = attr["canTap"].bool ?? true
        if let width = attr["width"].string, width == "wrapContent", attr["compressHorizontal"].string == nil {
            i.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        }
        
        if let height = attr["height"].string, height == "wrapContent", attr["compressVertical"].string == nil {
            i.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        }
        
        if let width = attr["width"].string, width == "wrapContent", attr["hugHorizontal"].string == nil {
            i.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        }
        
        if let height = attr["height"].string, height == "wrapContent", attr["hugVertical"].string == nil {
            i.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        }
        return i
    }
    
}
