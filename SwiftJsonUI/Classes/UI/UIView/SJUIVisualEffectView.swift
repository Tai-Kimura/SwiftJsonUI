//
//  SJUIVisualEffectView.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2018/09/13.

import UIKit

open class SJUIVisualEffectView: UIVisualEffectView {
    
    open class var viewClass: SJUIVisualEffectView.Type {
        get {
            return SJUIVisualEffectView.self
        }
    }
    
    required public override init(effect: UIVisualEffect?) {
        super.init(effect: effect)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUIVisualEffectView {
        var effectStyle: UIBlurEffect.Style = UIBlurEffect.Style.light
        if let style = attr["effectStyle"].string {
            switch (style) {
            case "Light":
                effectStyle = .light
            case "Dark":
                effectStyle = .dark
            case "ExtraLight":
                effectStyle = .extraLight
            default:
                break
            }
        }
        let effect = UIBlurEffect(style: effectStyle)
        let v = viewClass.init(effect: effect)
        v.layer.masksToBounds = true
        
        if let onclick = attr["onclick"].string {
            let gr = UITapGestureRecognizer(target: target, action: Selector(onclick))
            v.addGestureRecognizer(gr)
            v.isUserInteractionEnabled = true
        }
        return v
    }
}
