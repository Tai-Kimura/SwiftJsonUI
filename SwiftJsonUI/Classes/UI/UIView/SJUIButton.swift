//
//  SJUIButton.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2016/02/02.

import UIKit

open class SJUIButton: UIButton {
    open class var viewClass: SJUIButton.Type {
        get {
            return SJUIButton.self
        }
    }
    
    public var defaultFontColor: UIColor?
    public var disabledBackgroundColor: UIColor?
    public var disabledFontColor: UIColor?
    
    override open var isEnabled: Bool {
        didSet {
            if self.isEnabled {
                self.setTitleColor(defaultFontColor, for: UIControl.State())
                self.backgroundColor = defaultBackgroundColor
            } else {
                self.setTitleColor(disabledFontColor == nil ? defaultFontColor : disabledFontColor, for: UIControl.State())
                self.backgroundColor = disabledBackgroundColor == nil ? defaultBackgroundColor : disabledBackgroundColor
            }
        }
    }
    
    override open func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        defaultFontColor = color
        super.setTitleColor(color, for: state)
    }
    
    open class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUIButton {
        let b = viewClass.init()
        b.isUserInteractionEnabled = true
        b.setTitle(NSLocalizedString(attr["text"].stringValue, comment: ""), for: UIControl.State())
        if let fontColor = UIColor.findColorByJSON(attr: attr["fontColor"]) {
            b.setTitleColor(fontColor, for: UIControl.State())
        }
        if let fontColor = UIColor.findColorByJSON(attr: attr["hilightColor"]) {
            b.setTitleColor(fontColor, for: UIControl.State.highlighted)
        }
        if let image = attr["image"].string {
            b.setBackgroundImage(UIImage(named: image), for: UIControl.State())
        }
        let size = attr["fontSize"].cgFloat != nil ? attr["fontSize"].cgFloatValue : 17.0
        let name = attr["font"].string != nil ? attr["font"].stringValue : SJUIViewCreator.defaultFont
        let font = UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
        b.titleLabel?.font = font
        if let onclick = attr["onclick"].string {
            b.addTarget(target, action: Selector(onclick), for: UIControl.Event.touchUpInside)
        } else if let onclicks = attr["onclick"].array {
            for onclick in onclicks {
                if let events = onclick["events"].arrayObject as? [String], let selector = onclick["selector"].string {
                    var clickEvents = [UIControl.Event]()
                    for e in events {
                        switch e {
                        case "Down":
                            clickEvents.append(.touchDown)
                        case "DownRepeat":
                            clickEvents.append(.touchDownRepeat)
                        case "DragInside":
                            clickEvents.append(.touchDragInside)
                        case "DragOutside":
                            clickEvents.append(.touchDragOutside)
                        case "DragEnter":
                            clickEvents.append(.touchDragEnter)
                        case "DragExit":
                            clickEvents.append(.touchDragExit)
                        case "UpInside":
                            clickEvents.append(.touchUpInside)
                        case "UpOutside":
                            clickEvents.append(.touchUpOutside)
                        case "Cancel":
                            clickEvents.append(.touchCancel)
                        case "All":
                            clickEvents.append(.allTouchEvents)
                        default:
                            break
                        }
                    }
                    
                    b.addTarget(target, action: Selector(selector), for: UIControl.Event(clickEvents))
                }
            }
        }
        b.disabledBackgroundColor = UIColor.findColorByJSON(attr: attr["disabledBackground"])
        b.disabledFontColor = UIColor.findColorByJSON(attr: attr["disabledFontColor"])
        b.isEnabled = attr["enabled"].bool ?? true
        return b
    }
}
