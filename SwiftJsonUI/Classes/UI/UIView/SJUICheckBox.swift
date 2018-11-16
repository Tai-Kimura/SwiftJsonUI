//
//  UICheckBox.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2015/12/25.

import UIKit

@objc public protocol SJUICheckBoxDelegate {
    func checkBoxOnCheck(_ checkBox: SJUICheckBox)
}


open class SJUICheckBox: UIButton {
    
    open class var viewClass: SJUICheckBox.Type {
        get {
            return SJUICheckBox.self
        }
    }
    
    static let checkBoxSize = CGSize(width: 20.0, height: 20.0)
    
    public weak var targetModel: SJUIModel?
    
    public weak var checkBoxDelegate: SJUICheckBoxDelegate?
    
    required public init(withLabel label:UIView!, imagePath: String!, onImagePath: String!) {
        super.init(frame: CGRect(x: 0, y: 0, width: SJUICheckBox.checkBoxSize.width, height: SJUICheckBox.checkBoxSize.height))
        if let ipath = imagePath {
            let offImage = UIImage(named: ipath)!
            self.setImage(offImage, for: UIControl.State())
        }
        if let ipath = onImagePath {
            let onImage  = UIImage(named: ipath)!
            self.setImage(onImage, for: UIControl.State.selected)
        }
        self.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        self.addTarget(self, action: #selector(SJUICheckBox.onCheck), for: UIControl.Event.touchUpInside)
        self.addLabel(label)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open func addLabel(_ label: UIView!) {
        let gr = UITapGestureRecognizer(target: self, action: #selector(SJUICheckBox.onCheck))
        label?.addGestureRecognizer(gr)
        label?.isUserInteractionEnabled = true
    }
    
    @objc open func onCheck() {
        self.isSelected = !self.isSelected
        self.targetModel?.selected = self.isSelected
        self.checkBoxDelegate?.checkBoxOnCheck(self)
    }
    
    open func setCheck(_ check: Bool) {
        self.isSelected = check
        self.targetModel?.selected = self.isSelected
    }
    
    open class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUICheckBox {
        
        let c = viewClass.init(withLabel: views[attr["label"].stringValue], imagePath: attr["src"].string, onImagePath: attr["onSrc"].string)
        c.checkBoxDelegate = target as? SJUICheckBoxDelegate
        return c
    }
}
