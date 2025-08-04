//
//  UICircleView.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2015/02/18.


import UIKit

open class SJUICircleView: UIView {
    
    open class var viewClass: SJUICircleView.Type {
        get {
            return SJUICircleView.self
        }
    }
    
    override required public init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.masksToBounds = false
        self.layer.cornerRadius = self.frame.size.width/2.0
    }
    
    
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.masksToBounds = false
        self.layer.cornerRadius = self.frame.size.width/2.0
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        onBeginTap()
        super.touchesBegan(touches, with: event)
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        onEndTap()
        super.touchesCancelled(touches, with: event)
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        onEndTap()
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        onEndTap()
        super.touchesEnded(touches, with: event)
    }
    
    open class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUICircleView {
        let rect: CGRect
        
        if let width = attr["width"].cgFloat, let height = attr["height"].cgFloat {
            rect = CGRect(x: 0, y: 0, width: width, height: height)
        } else {
            rect = CGRect.zero
        }
        
        let c = viewClass.init(frame: rect)
        if let onclick = attr["onclick"].string {
            let gr = UITapGestureRecognizer(target: target, action: Selector(onclick))
            c.addGestureRecognizer(gr)
            c.isUserInteractionEnabled = true
        }
        return c
    }
    
}
