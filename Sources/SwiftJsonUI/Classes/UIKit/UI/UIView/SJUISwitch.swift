//
//  SJUISwitch.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2018/09/13.

import UIKit

open class SJUISwitch: UISwitch {
    
    open class var viewClass: SJUISwitch.Type {
        get {
            return SJUISwitch.self
        }
    }
    
    open class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUISwitch {
        let s = viewClass.init()
        if let onclick = attr["onValueChange"].string {
            s.addTarget(target, action: Selector(onclick), for: UIControl.Event.valueChanged)
        }
        
        if let tintColor = UIColor.findColorByJSON(attr: attr["tint"]) {
            s.onTintColor = tintColor
        }
        return s
    }
}
