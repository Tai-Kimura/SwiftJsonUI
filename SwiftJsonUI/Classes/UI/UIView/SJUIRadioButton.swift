//
//  SJUIRadioButton.swift
//
//  Created by 木村太一朗 on 2016/01/23.
//  Copyright © 2016年 木村太一朗 All rights reserved.
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

@objc public protocol RadioGroupDelegate {
    func radioGroupCheckChanged(_ radiogroup: NSRadioGroup)
}

open class SJUIRadioButton: UIView {
    
    public static var defaultOffColor = UIColor.gray
    
    public static var defaultOnColor = UIColor.red
    
    public var label: UILabel!
    
    public var iconView: UIView!
    
    public var iconImageView: UIImageView!
    
    public var iconImage: UIImage?
    
    public var selectedIconImage: UIImage?
    
    public var fontColor: UIColor!
    
    public weak var ragioGroup: NSRadioGroup?
    
    
    public init(text: String, font: UIFont, fontColor: UIColor, iconImage icon:UIImage?, selectedIconImage selectedIcon: UIImage?, inRadioGroup group: NSRadioGroup? = nil) {
        iconImage = icon
        selectedIconImage = selectedIcon
        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = iconImage
        let iconOut = SJUICircleView(frame: CGRect(x: 0,y: 0,width: 20.0,height: 20.0))
        iconOut.layer.borderColor = SJUIRadioButton.defaultOffColor.cgColor
        iconOut.layer.borderWidth = 1.0
        iconOut.translatesAutoresizingMaskIntoConstraints = false
        iconView = SJUICircleView(frame: CGRect(x: 2,y: 2,width: 14.0,height: 14.0))
        iconView.backgroundColor = SJUIRadioButton.defaultOnColor
        iconOut.addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        super.init(frame: CGRect.zero)
        self.addSubview(iconImageView)
        self.addSubview(iconOut)
        if iconImage == nil || selectedIconImage == nil {
            iconImageView.isHidden = true
        } else {
            iconOut.isHidden = true
        }
        iconView.isHidden = true
        self.addSubview(label)
        var constraints = Array<NSLayoutConstraint>()
        
        constraints.append(NSLayoutConstraint(item: iconView, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: iconOut, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0))
        
        constraints.append(NSLayoutConstraint(item: iconView, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: iconOut, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0))
        
        constraints.append(NSLayoutConstraint(item: iconView, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 14.0))
        
        constraints.append(NSLayoutConstraint(item: iconView, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 14.0))
        
        iconOut.addConstraints(constraints)
        
        constraints = Array<NSLayoutConstraint>()
        
        constraints.append(NSLayoutConstraint(item: iconOut, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0))
        
        constraints.append(NSLayoutConstraint(item: iconOut, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0))
        
        constraints.append(NSLayoutConstraint(item: iconOut, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 20.0))
        
        constraints.append(NSLayoutConstraint(item: iconOut, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 20.0))
        
        constraints.append(NSLayoutConstraint(item: iconImageView, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0))
        
        constraints.append(NSLayoutConstraint(item: iconImageView, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0))
        
        constraints.append(NSLayoutConstraint(item: iconImageView, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 20.0))
        
        constraints.append(NSLayoutConstraint(item: iconImageView, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 20.0))
        
        constraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0))
        
        constraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: iconOut, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 10.0))
        
        constraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0))
        
        self.addConstraints(constraints)
        
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SJUIRadioButton.onCheck)))
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.1
        label.attributedText = NSMutableAttributedString(string: text, attributes: [NSAttributedStringKey.paragraphStyle: paragraphStyle, NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: fontColor])
        
        group?.radioBtns.append(self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc open func onCheck() {
        self.ragioGroup?.check(self)
    }
    
    open class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUIRadioButton {
        
        let text = NSLocalizedString(attr["text"].stringValue, comment: "")
        let size = attr["fontSize"].cgFloat != nil ? attr["fontSize"].cgFloatValue : 14.0
        let name = attr["font"].string ?? SJUIViewCreator.defaultFont
        let fontColor = UIColor.findColorByJSON(attr: attr["fontColor"]) ?? SJUIViewCreator.defaultFontColor
        let font = UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
        let r = SJUIRadioButton(text: text, font: font, fontColor: fontColor, iconImage: UIImage(named: attr["icon"].stringValue), selectedIconImage: UIImage(named: attr["selected_icon"].stringValue))
        return r
    }
    
}

public class NSRadioGroup: NSObject {
    fileprivate var radioBtns: [SJUIRadioButton] = Array<SJUIRadioButton>()
    
    public weak var selectedBtn: SJUIRadioButton?
    
    public weak var delegate: RadioGroupDelegate?
    
    public var selectedIndex: Int? {
        get {
            if let selectedBtn = self.selectedBtn {
                return self.radioBtns.index(of: selectedBtn)
            }
            return nil
        }
    }
    
    public func add(_ radioBtn: SJUIRadioButton) {
        self.radioBtns.append(radioBtn)
        radioBtn.ragioGroup = self
    }
    
    public func removeAll() {
        self.radioBtns.removeAll()
    }
    
    public func remove(index: Int) {
        self.radioBtns.remove(at: index)
    }
    
    public func remove(radioBtn btn: SJUIRadioButton) -> Bool {
        if let index = radioBtns.index(of: btn) {
            self.radioBtns.remove(at: index)
            return true
        }
        return false
    }
    
    public func check(_ btn: SJUIRadioButton) {
        if let selectedBtn = selectedBtn {
            selectedBtn.iconView.isHidden = true
            selectedBtn.iconImageView.image = selectedBtn.iconImage
        }
        btn.iconView.isHidden = false
        btn.iconImageView.image = btn.selectedIconImage
        self.selectedBtn = btn
        delegate?.radioGroupCheckChanged(self)
    }
    
    public func uncheck() {
        selectedBtn?.iconView.isHidden = true
        selectedBtn?.iconImageView.image = selectedBtn?.iconImage
        selectedBtn = nil
    }
    
    public func checkAtIndex(_ index: Int) {
        if radioBtns.count > index {
            let btn = radioBtns[index]
            btn.onCheck()
        }
    }
}
