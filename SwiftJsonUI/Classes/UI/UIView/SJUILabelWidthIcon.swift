//
//  UILabelWithIcon.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2016/01/17.

import UIKit

open class SJUILabelWithIcon: SJUIView {
    
    override open class var viewClass: SJUIView.Type {
        get {
            return SJUILabelWithIcon.self
        }
    }
    
    public var label: SJUILabel!
    
    public var iconView: SJUIImageView!
    
    public var iconOn: UIImage!
    
    public var iconOff: UIImage!
    
    public var fontColor: UIColor!
    
    public var selectedFontColor: UIColor!
    
    public var effectView: UIView!
    
    public var isSelected: Bool = false {
        willSet {
            self.label.selected = newValue
            self.iconView.image = newValue ? self.iconOn : self.iconOff
        }
    }
    
    required public init(labelText text: String!, onIcon: String?, offIcon: String?, fontColor: UIColor!, selectedFontColor: UIColor!, fontName:String!, fontSize:CGFloat!, iconPosition: IconPosition, shadow: JSON, iconMargin: CGFloat) {
        label = SJUILabel()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.0
        let size:CGFloat = fontSize ?? SJUIViewCreator.defaultFontSize
        let name = fontName == nil ? SJUIViewCreator.defaultFont : fontName!
        let font = UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
        label.font = font
        label.textColor = fontColor
        label.padding = UIEdgeInsets.zero
        var attributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: font]
        attributes[NSAttributedString.Key.foregroundColor] = fontColor
        
        if !shadow.isEmpty, let shadowColor = UIColor.findColorByJSON(attr: shadow["color"]), let shadowBlur = shadow["blur"].cgFloat, let shadowOffset = shadow["offset"].arrayObject as? [CGFloat] {
            let s = NSShadow()
            s.shadowColor = shadowColor;
            s.shadowBlurRadius = shadowBlur
            s.shadowOffset = CGSize(width: shadowOffset[0], height: shadowOffset[1]);
            attributes[NSAttributedString.Key.shadow] = s
        }
        
        label.attributes = attributes
        label.highlightAttributes = attributes
        label.highlightAttributes[NSAttributedString.Key.foregroundColor] = selectedFontColor
        
        label.applyAttributedText(text)
        
        self.fontColor = fontColor
        self.selectedFontColor = selectedFontColor
        label.numberOfLines = 1
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        
        if let iconOn = onIcon, let iconOff = offIcon {
            self.iconOn = UIImage(named: iconOn)
            self.iconOff = UIImage(named: iconOff)
            iconView = SJUIImageView(image: self.iconOff)
            iconView.translatesAutoresizingMaskIntoConstraints = false
            super.init(frame: CGRect.zero)
            self.translatesAutoresizingMaskIntoConstraints = false
            
            let iconConstraintInfo = UILayoutConstraintInfo(width: UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue, height: UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue, superview: self)
            
            iconView.constraintInfo = iconConstraintInfo
            
            let labelConstraintInfo = UILayoutConstraintInfo(width: UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue, height: UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue, superview: self)
            
            label.constraintInfo = labelConstraintInfo
            
            switch iconPosition {
            case .top:
                self.orientation = .vertical
                self.direction = .topToBottom
                label.constraintInfo?.topMargin = iconMargin
                label?.constraintInfo?.centerHorizontal = true
                iconView?.constraintInfo?.centerHorizontal = true
                self.addSubview(iconView)
                self.addSubview(label)
            case .left:
                self.orientation = .horizontal
                self.direction = .leftToRight
                label.constraintInfo?.leftMargin = iconMargin
                label?.constraintInfo?.centerVertical = true
                iconView?.constraintInfo?.centerVertical = true
                self.addSubview(iconView)
                self.addSubview(label)
            case .right:
                self.orientation = .horizontal
                self.direction = .leftToRight
                iconView.constraintInfo?.leftMargin = iconMargin
                label?.constraintInfo?.centerVertical = true
                iconView?.constraintInfo?.centerVertical = true
                self.addSubview(label)
                self.addSubview(iconView)
            case .bottom:
                self.orientation = .vertical
                self.direction = .topToBottom
                iconView.constraintInfo?.topMargin = iconMargin
                label.constraintInfo?.topMargin = iconMargin
                label?.constraintInfo?.centerHorizontal = true
                iconView?.constraintInfo?.centerHorizontal = true
                self.addSubview(label)
                self.addSubview(iconView)
            }
        } else {
            super.init(frame: CGRect(x: 0, y: 0, width: label.frame.size.width, height: label.frame.size.height))
            self.addSubview(label)
            var constraints = Array<NSLayoutConstraint>()
            
            constraints.append(NSLayoutConstraint(item: label as Any, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1.0, constant: 0))
            constraints.append(NSLayoutConstraint(item: label as Any, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1.0, constant: 0))
            NSLayoutConstraint.activate(constraints)
        }
        self.clipsToBounds = true
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUILabelWithIcon {
        let fontColor = UIColor.findColorByJSON(attr: attr["fontColor"]) ?? SJUIViewCreator.defaultFontColor
        let selectedFontColor =  UIColor.findColorByJSON(attr: attr["selectedFontColor"]) ?? fontColor
        
        let iconPositionStr = attr["iconPosition"].string ?? "Left"
        let iconPosition: IconPosition
        switch iconPositionStr {
        case "Top":
            iconPosition = .top
        case "Left":
            iconPosition = .left
        case "Right":
            iconPosition = .right
        case "Bottom":
            iconPosition = .bottom
        default:
            iconPosition = .left
        }
        
        
        let l = (viewClass as! SJUILabelWithIcon.Type).init(labelText:  NSLocalizedString(attr["text"].stringValue, comment: "") , onIcon: attr["icon_on"].string , offIcon: attr["icon_off"].string , fontColor: fontColor, selectedFontColor: selectedFontColor, fontName: attr["font"].string, fontSize: attr["fontSize"].cgFloat, iconPosition: iconPosition, shadow: attr["textShadow"], iconMargin: attr["iconMargin"].cgFloat ?? 5.0)
        
        if let onclick = attr["onclick"].string {
            let gr = UITapGestureRecognizer(target: target, action: Selector(onclick))
            l.addGestureRecognizer(gr)
            l.isUserInteractionEnabled = true
            l.canTap = true
        }
        
        return l
    }
    
    public enum IconPosition {
        case top
        case left
        case right
        case bottom
    }
}


