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
    
    public var iconView: UIImageView!
    
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
    
    required public init(labelText text: String!, onIcon: String?, offIcon: String?, fontColor: UIColor!, selectedFontColor: UIColor!, fontName:String!, fontSize:CGFloat!, position: NSTextAlignment, shadow: JSON, iconMargin: CGFloat) {
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
            iconView = UIImageView(image: self.iconOff)
            iconView.translatesAutoresizingMaskIntoConstraints = false
            let width = iconView.frame.size.width + iconMargin + label.frame.size.width
            let height = iconView.frame.size.height > label.frame.size.height ? iconView.frame.size.height : label.frame.size.height
            super.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
            self.addSubview(iconView)
            self.addSubview(label)
            self.translatesAutoresizingMaskIntoConstraints = false
            var constraints = Array<NSLayoutConstraint>()
            
            constraints.append(NSLayoutConstraint(item: iconView, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1.0, constant: 0))
            
            constraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1.0, constant: 0))
            
            switch position {
            case .left, .natural, .justified:
                constraints.append(NSLayoutConstraint(item: iconView, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: iconMargin))
                
                constraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: iconView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: iconView.frame.size.width + iconMargin))
                
                constraints.append(NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: label, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: 0))
            case .center:
                let totalWidth = label.frame.size.width + iconView.frame.size.width + iconMargin
                if label.frame.size.width > iconView.frame.size.width {
                    constraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1.0, constant: -(label.frame.size.width - totalWidth/2.0)))
                    constraints.append(NSLayoutConstraint(item: iconView, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1.0, constant: -(label.frame.size.width - totalWidth/2.0) - iconMargin))
                } else {
                    
                }
            case .right:
                constraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: -iconMargin))
                
                constraints.append(NSLayoutConstraint(item: iconView, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: label, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant:  -iconMargin))
            }
            
            NSLayoutConstraint.activate(constraints)
        } else {
            super.init(frame: CGRect(x: 0, y: 0, width: label.frame.size.width, height: label.frame.size.height))
            self.addSubview(label)
            var constraints = Array<NSLayoutConstraint>()
            
            constraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1.0, constant: 0))
            constraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1.0, constant: 0))
            NSLayoutConstraint.activate(constraints)
        }
        self.clipsToBounds = true
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func onBeginTap() {
        if canTap {
            if effectView == nil {
                let frame = self.frame
                let size = frame.size.width > frame.size.height ? frame.size.width : frame.size.height
                let x = frame.size.width > frame.size.height ? 0 : (frame.size.width - frame.size.height)/2.0
                let y = frame.size.width < frame.size.height ? 0 : (frame.size.height - frame.size.width)/2.0
                effectView = UIView(frame: CGRect(x: x,y: y,width: size,height: size))
                effectView.layer.cornerRadius = size/2.0
            }
            self.effectView.layer.removeAllAnimations()
            if effectView.superview == nil {
                self.insertSubview(effectView, at: 0)
            }
            effectView.backgroundColor = self.defaultBackgroundColor
            self.backgroundColor = self.tapBackgroundColor
            UIView.animate(withDuration: 0.1, delay: 0, options: UIView.AnimationOptions.allowUserInteraction, animations: {
                self.effectView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            }, completion: {finished in
                self.effectView.removeFromSuperview()
            })
            UIView.transition(with: label, duration: 0.17, options: UIView.AnimationOptions.transitionCrossDissolve, animations: {
                self.label.textColor = self.selectedFontColor
            }, completion: nil)
        }
    }
    
    override open func onEndTap() {
        if canTap {
            if effectView.superview == nil {
                self.insertSubview(effectView, at: 0)
            }
            effectView.backgroundColor = self.defaultBackgroundColor
            UIView.animate(withDuration: 0.1, delay: 0, options: UIView.AnimationOptions.allowUserInteraction, animations: {
                self.effectView.transform = CGAffineTransform.identity
            }, completion: {finished in
                self.effectView.removeFromSuperview()
                self.backgroundColor = self.defaultBackgroundColor
            })
            UIView.transition(with: label, duration: 0.17, options: UIView.AnimationOptions.transitionCrossDissolve, animations: {
                self.label.textColor = self.fontColor
            }, completion: nil)
        }
    }
    
    override open class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUILabelWithIcon {
        let fontColor = UIColor.findColorByJSON(attr: attr["fontColor"]) ?? SJUIViewCreator.defaultFontColor
        let selectedFontColor =  UIColor.findColorByJSON(attr: attr["selectedFontColor"]) ?? fontColor
        let positionStr = attr["position"].string ?? "Left"
        let position: NSTextAlignment
        switch positionStr {
        case "Left":
            position = .left
        case "Center":
            position = .center
        case "Right":
            position = .right
        default:
            position = .left
        }
        let l = (viewClass as! SJUILabelWithIcon.Type).init(labelText:  NSLocalizedString(attr["text"].stringValue, comment: "") , onIcon: attr["icon_on"].string , offIcon: attr["icon_off"].string , fontColor: fontColor, selectedFontColor: selectedFontColor, fontName: attr["font"].string, fontSize: attr["fontSize"].cgFloat, position: position, shadow: attr["textShadow"], iconMargin: attr["iconMargin"].cgFloat ?? 5.0)
        
        if let onclick = attr["onclick"].string {
            let gr = UITapGestureRecognizer(target: target, action: Selector(onclick))
            l.addGestureRecognizer(gr)
            l.isUserInteractionEnabled = true
            l.canTap = true
        }
        
        return l
    }
}
