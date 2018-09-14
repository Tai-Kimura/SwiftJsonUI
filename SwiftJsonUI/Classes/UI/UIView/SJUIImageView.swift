//
//  CustomUIImageView.swift
//
//  Created by 木村太一朗 on 2016/05/11.
//  Copyright © 2016年 TANOSYS. All rights reserved.
//

import UIKit

public class SJUIImageView: UIImageView {
    
    public var canTap = false
    
    internal var filter: SJUIView?
    
    public func setMask() {
        let filter = SJUIView()
        
        filter.defaultBackgroundColor = UIColor.clear
        filter.canTap = true
        filter.translatesAutoresizingMaskIntoConstraints = false
        filter.autoresizingMask = UIViewAutoresizing()
        self.addSubview(filter)
        let constraints = [
            NSLayoutConstraint(item: filter, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: filter, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: filter, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: filter, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0)
        ]
        NSLayoutConstraint.activate(constraints)
        self.filter = filter
    }
    
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: self) {
            if location.x >= 0 && location.x <= self.frame.size.width && location.y >= 0 && location.y <= self.frame.size.height {
                onBeginTap()
            }
        }
        super.touchesBegan(touches, with: event)
        
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        onEndTap()
        super.touchesCancelled(touches, with: event)
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        onEndTap()
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        onEndTap()
        super.touchesEnded(touches, with: event)
    }
    
    @objc override public func onBeginTap() {
        if canTap {
            self.filter?.onBeginTap()
        }
    }
    
    @objc override public func onEndTap() {
        if canTap {
            self.filter?.onEndTap()
        }
    }
    
    public class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUIImageView {
        
        let i = SJUIImageView()
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
                i.contentMode = UIViewContentMode.scaleAspectFill
            case "AspectFit":
                i.contentMode = UIViewContentMode.scaleAspectFit
            default:
                i.contentMode = UIViewContentMode.center
            }
        } else {
            i.contentMode = UIViewContentMode.center
        }
        if let onclick = attr["onclick"].string {
            let gr = UITapGestureRecognizer(target: target, action: Selector(onclick))
            i.addGestureRecognizer(gr)
            i.isUserInteractionEnabled = true
            i.canTap = attr["canTap"].bool ?? true
        }
        return i
    }
    
}
