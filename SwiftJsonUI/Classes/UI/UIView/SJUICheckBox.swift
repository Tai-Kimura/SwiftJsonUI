//
//  UICheckBox.swift
//
//  Created by 木村太一朗 on 2015/12/25.
//  Copyright © 2015年 木村太一朗 All rights reserved.
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

@objc public protocol SJUICheckBoxDelegate {
    func checkBoxOnCheck(_ checkBox: SJUICheckBox)
}


public class SJUICheckBox: UIButton {
    
    static let checkBoxSize = CGSize(width: 20.0, height: 20.0)
    
    public weak var targetModel: SJUIModel?
    
    public weak var checkBoxDelegate: SJUICheckBoxDelegate?
    
    public init(withLabel label:UIView!, imagePath: String!, onImagePath: String!) {
        super.init(frame: CGRect(x: 0, y: 0, width: SJUICheckBox.checkBoxSize.width, height: SJUICheckBox.checkBoxSize.height))
        if let ipath = imagePath {
            let offImage = UIImage(named: ipath)!
            self.setImage(offImage, for: UIControlState())
        }
        if let ipath = onImagePath {
            let onImage  = UIImage(named: ipath)!
            self.setImage(onImage, for: UIControlState.selected)
        }
        self.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        self.addTarget(self, action: #selector(SJUICheckBox.onCheck), for: UIControlEvents.touchUpInside)
        self.addLabel(label)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func addLabel(_ label: UIView!) {
        let gr = UITapGestureRecognizer(target: self, action: #selector(SJUICheckBox.onCheck))
        label?.addGestureRecognizer(gr)
        label?.isUserInteractionEnabled = true
    }
    
    @objc public func onCheck() {
        self.isSelected = !self.isSelected
        self.targetModel?.selected = self.isSelected
        self.checkBoxDelegate?.checkBoxOnCheck(self)
    }
    
    public func setCheck(_ check: Bool) {
        self.isSelected = check
        self.targetModel?.selected = self.isSelected
    }
    
    public class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUICheckBox {
        
        let c = SJUICheckBox(withLabel: views[attr["label"].stringValue], imagePath: attr["src"].string, onImagePath: attr["onSrc"].string)
        c.checkBoxDelegate = target as? SJUICheckBoxDelegate
        return c
    }
}
