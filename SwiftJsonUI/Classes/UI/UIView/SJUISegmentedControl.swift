//
//  SJUISegmentedControl.swift
//  SwiftJsonUI
//
//  Created by 木村太一朗 on 2018/09/13.
//  Copyright © 2018年 TANOSYS, LLC. All rights reserved.
//

import UIKit

open class SJUISegmentedControl: UISegmentedControl {
    
    open class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUISegmentedControl {
        
        let itemNames:[String]
        if let names = attr["items"].arrayObject as? [String] {
            itemNames = names
        } else if let string = attr["items"].string {
            itemNames =  string.components(separatedBy: ",")
        } else {
            itemNames = []
        }
        var items = Array<String>()
        for itemName in itemNames {
            items.append(NSLocalizedString(itemName, comment: ""))
        }
        let s = SJUISegmentedControl(items: items)
        s.selectedSegmentIndex = 0
        s.tintColor = UIColor.findColorByJSON(attr: attr["tintColor"]) ?? UIColor.gray
        let size = attr["fontSize"].cgFloat != nil ? attr["fontSize"].cgFloatValue : 16.0
        let name = attr["font"].string ?? SJUIViewCreator.defaultFont
        let font = UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
        let normalColor = UIColor.findColorByJSON(attr: attr["normalColor"]) ?? SJUIViewCreator.defaultFontColor
        let selectedColor = UIColor.findColorByJSON(attr: attr["selectedColor"]) ?? UIColor.white
        let normalAttributes: [NSAttributedStringKey: NSObject] = [NSAttributedStringKey.foregroundColor: normalColor, NSAttributedStringKey.font: font]
        let selectedAttributes: [NSAttributedStringKey: NSObject] = [NSAttributedStringKey.foregroundColor: selectedColor, NSAttributedStringKey.font: font]
        s.setTitleTextAttributes(normalAttributes, for: UIControlState.normal)
        s.setTitleTextAttributes(selectedAttributes, for: UIControlState.selected)
        if let valueChange = attr["valueChange"].string {
            s.addTarget(target, action: Selector(valueChange), for: UIControlEvents.valueChanged)
        }
        s.isEnabled = attr["enabled"].bool ?? true
        return s
    }
    
}
