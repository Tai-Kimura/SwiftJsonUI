//
//  SJUISegmentedControl.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2018/09/13.


import UIKit

open class SJUISegmentedControl: UISegmentedControl {
    
    open class var viewClass: SJUISegmentedControl.Type {
        get {
            return SJUISegmentedControl.self
        }
    }
    
    public static var defaultTintColor = UIColor.gray
    public static var defaultSelectedColor = UIColor.white
    
    required public override init(items: [Any]?) {
        super.init(items: items)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
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
        let s = viewClass.init(items: items)
        s.selectedSegmentIndex = 0
        s.tintColor = UIColor.findColorByJSON(attr: attr["tintColor"]) ?? SJUISegmentedControl.defaultTintColor
        let size = attr["fontSize"].cgFloat != nil ? attr["fontSize"].cgFloatValue : 16.0
        let name = attr["font"].string ?? SJUIViewCreator.defaultFont
        let font = UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
        let normalColor = UIColor.findColorByJSON(attr: attr["normalColor"]) ?? SJUIViewCreator.defaultFontColor
        let selectedColor = UIColor.findColorByJSON(attr: attr["selectedColor"]) ?? SJUISegmentedControl.defaultSelectedColor
        let normalAttributes: [NSAttributedString.Key: NSObject] = [NSAttributedString.Key.foregroundColor: normalColor, NSAttributedString.Key.font: font]
        let selectedAttributes: [NSAttributedString.Key: NSObject] = [NSAttributedString.Key.foregroundColor: selectedColor, NSAttributedString.Key.font: font]
        s.setTitleTextAttributes(normalAttributes, for: UIControl.State.normal)
        s.setTitleTextAttributes(selectedAttributes, for: UIControl.State.selected)
        if let valueChange = attr["valueChange"].string {
            s.addTarget(target, action: Selector(valueChange), for: UIControl.Event.valueChanged)
        }
        s.isEnabled = attr["enabled"].bool ?? true
        return s
    }
    
}
