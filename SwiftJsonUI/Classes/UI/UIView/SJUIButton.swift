//
//  CustomUIButton.swift
//
//  Created by 木村太一朗 on 2016/02/02.
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

public class SJUIButton: UIButton {
    public var defaultFontColor: UIColor?
    public var disabledBackgroundColor: UIColor?
    public var disabledFontColor: UIColor?
    
    override public var isEnabled: Bool {
        didSet {
            if self.isEnabled {
                self.setTitleColor(defaultFontColor, for: UIControlState())
                self.backgroundColor = defaultBackgroundColor
            } else {
                self.setTitleColor(disabledFontColor == nil ? defaultFontColor : disabledFontColor, for: UIControlState())
                self.backgroundColor = disabledBackgroundColor == nil ? defaultBackgroundColor : disabledBackgroundColor
            }
        }
    }
    
    override public func setTitleColor(_ color: UIColor?, for state: UIControlState) {
        defaultFontColor = color
        super.setTitleColor(color, for: state)
    }
    
    public class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUIButton {
        let b = SJUIButton()
        b.isUserInteractionEnabled = true
        b.setTitle(NSLocalizedString(attr["text"].stringValue, comment: ""), for: UIControlState())
        if let fontColor = UIColor.findColorByJSON(attr: attr["fontColor"]) {
            b.setTitleColor(fontColor, for: UIControlState())
        }
        if let fontColor = UIColor.findColorByJSON(attr: attr["hilightColor"]) {
            b.setTitleColor(fontColor, for: UIControlState.highlighted)
        }
        if let image = attr["image"].string {
            b.setBackgroundImage(UIImage(named: image), for: UIControlState())
        }
        let size = attr["fontSize"].cgFloat != nil ? attr["fontSize"].cgFloatValue : 17.0
        let name = attr["font"].string != nil ? attr["font"].stringValue : SJUIViewCreator.defaultFont
        let font = UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
        b.titleLabel?.font = font
        if let onclick = attr["onclick"].string {
            b.addTarget(target, action: Selector(onclick), for: UIControlEvents.touchUpInside)
        } else if let onclicks = attr["onclick"].array {
            for onclick in onclicks {
                if let events = onclick["events"].arrayObject as? [String], let selector = onclick["selector"].string {
                    var clickEvents = [UIControlEvents]()
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
                    
                    b.addTarget(target, action: Selector(selector), for: UIControlEvents(clickEvents))
                }
            }
        }
        b.disabledBackgroundColor = UIColor.findColorByJSON(attr: attr["disabledBackground"])
        b.disabledFontColor = UIColor.findColorByJSON(attr: attr["disabledFontColor"])
        b.isEnabled = attr["enabled"].bool ?? true
        return b
    }
}
