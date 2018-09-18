//
//  SJUITextView.swift
//
//  Created by 木村太一朗 on 2016/01/18.
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

@objc public protocol SJUITextViewDelegate {
    func textViewDidChangeFrame(textView: SJUITextView)
}

open class SJUITextView: UITextView {
    
    open class var viewClass: SJUITextView.Type {
        get {
            return SJUITextView.self
        }
    }
    
    
    public var maxHeight: CGFloat = 0
    
    public var minHeight: CGFloat = 21.0
    
    public var flexible: Bool = false
    
    public var placeHolder: UILabel!
    
    public var hasContainer = false
    
    public var fontSize: CGFloat = 12.0
    
    public var hideOnFocused = true
    
    public var hintColor: UIColor = SJUIViewCreator.defaultHintColor
    
    public var hintFont: String = SJUIViewCreator.defaultFont
    
    public weak var sjuiDelegate: SJUITextViewDelegate?
    
    override open var text:String! {
        get { return super.text; }
        set (val) {
            super.text = val;
            self.setPlaceHolderIfNeeded()
        }
    }
    
    override open var attributedText:NSAttributedString! {
        get { return super.attributedText; }
        set (val) {
            super.attributedText = val;
            self.setPlaceHolderIfNeeded()
        }
    }
    
    
    open var hint: String! {
        willSet {
            if self.placeHolder == nil {
                self.placeHolder = UILabel()
                self.placeHolder.numberOfLines = 0
                self.placeHolder.lineBreakMode = NSLineBreakMode.byWordWrapping
                self.placeHolder.translatesAutoresizingMaskIntoConstraints = false
                self.placeHolder.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
                self.placeHolder.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
                self.placeHolder.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
                self.placeHolder.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
                self.addSubview(placeHolder)
                let inset = self.textContainerInset
                NSLayoutConstraint.activate([NSLayoutConstraint(item: self.placeHolder, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: inset.left)])
                NSLayoutConstraint.activate([NSLayoutConstraint(item: self.placeHolder, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: inset.right)])
                NSLayoutConstraint.activate([NSLayoutConstraint(item: self.placeHolder, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: inset.top-5.0)])
            }
            self.placeHolder.preferredMaxLayoutWidth = self.frame.size.width
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.4
            let size:CGFloat = fontSize
            let font = UIFont(name: hintFont, size: size) ?? UIFont.systemFont(ofSize: size)
            let attrText = NSMutableAttributedString(string: newValue, attributes: [NSAttributedStringKey.paragraphStyle: paragraphStyle, NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: hintColor])
            placeHolder.attributedText = attrText
            placeHolder.sizeToFit()
        }
    }
    
    override public init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.new, context: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(SJUITextView.textChanged), name:NSNotification.Name.UITextViewTextDidChange, object:nil)
        NotificationCenter.default.addObserver(self, selector:#selector(SJUITextView.textBeginEditing), name:NSNotification.Name.UITextViewTextDidBeginEditing, object:nil)
        NotificationCenter.default.addObserver(self, selector:#selector(SJUITextView.textEndEditing), name:NSNotification.Name.UITextViewTextDidEndEditing, object:nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        self.removeObserver(self, forKeyPath: "contentSize")
        NotificationCenter.default.removeObserver(self)
    }
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        
    }
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath != nil && keyPath == "contentSize" {
            if !flexible {
                return
            }
            let height: CGFloat
            if contentSize.height < self.minHeight {
                height = self.minHeight
            } else if self.maxHeight > 0 && contentSize.height > maxHeight {
                height = self.maxHeight
            } else {
                height = contentSize.height
            }
            let constraints = self.constraints
            var found = false
            for constraint in constraints {
                if constraint.firstItem as? NSObject == self && constraint.firstAttribute == NSLayoutAttribute.height && constraint.relation == .equal {
                    constraint.constant = height
                    found = true
                    break
                }
            }
            
            if !found {
                NSLayoutConstraint.activate([NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: height)])
            }
            
            let currentVersion = (UIDevice.current.systemVersion as NSString).floatValue
            if (currentVersion < 8.0) {
                super.layoutSubviews()
            }
            
        } else {
            let height: CGFloat
            if contentSize.height < self.minHeight {
                height = self.minHeight
            } else if self.maxHeight > 0 && contentSize.height > maxHeight {
                height = self.maxHeight
            } else {
                height = contentSize.height
            }
            
            self.frame.size.height = height
        }
        self.sjuiDelegate?.textViewDidChangeFrame(textView: self)
    }
    
    @objc open func textChanged() {
        if self.isFirstResponder {
            setPlaceHolderIfNeeded()
        }
    }
    
    open func setPlaceHolderIfNeeded() {
        if self.text.count == 0 {
            self.placeHolder?.isHidden = hideOnFocused
        } else {
            self.placeHolder?.isHidden = true
        }
    }
    
    @objc open func textBeginEditing() {
        if self.isFirstResponder {
            self.placeHolder?.isHidden = true
        }
    }
    
    @objc open func textEndEditing() {
        if self.text.count == 0 {
            self.placeHolder?.isHidden = false
        } else {
            self.placeHolder?.isHidden = true
        }
    }
    
    open class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUITextView {
        let t = viewClass.init()
        t.hintColor = UIColor.findColorByJSON(attr: attr["hintColor"]) ?? SJUIViewCreator.defaultHintColor
        t.delegate = target as? UITextViewDelegate
        t.sjuiDelegate = target as? SJUITextViewDelegate
        let size = attr["fontSize"].cgFloat ?? SJUIViewCreator.defaultFontSize
        let name = attr["font"].string ?? SJUIViewCreator.defaultFont
        t.hintFont = attr["hintFont"].string ?? name
        let font = UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
        t.fontSize = size
        t.font = font
        t.textContainer.lineFragmentPadding = 0
        t.textContainerInset = UIEdgeInsets.zero
        var edgeInsets = Array<CGFloat>()
        if let paddingStr = attr["containerInset"].string {
            let paddingStars = paddingStr.components(separatedBy: "|")
            
            for p in paddingStars {
                if let n = NumberFormatter().number(from: p) {
                    edgeInsets.append(CGFloat(truncating: n))
                }
            }
        } else if let insets = attr["containerInset"].arrayObject as? [CGFloat] {
            edgeInsets = insets
        }
        if (!edgeInsets.isEmpty) {
            var paddings:[CGFloat] = [0,0,0,0]
            switch (edgeInsets.count) {
            case 0:
                break
            case 1:
                paddings = [edgeInsets[0], edgeInsets[0], edgeInsets[0], edgeInsets[0]]
            case 2:
                paddings = [edgeInsets[0], edgeInsets[1], edgeInsets[0], edgeInsets[1]]
            case 3:
                paddings = [edgeInsets[0], edgeInsets[1], edgeInsets[2], edgeInsets[1]]
            default:
                paddings = [edgeInsets[0], edgeInsets[1], edgeInsets[2], edgeInsets[3]]
            }
            t.textContainerInset = UIEdgeInsetsMake(paddings[0], paddings[1], paddings[2], paddings[3])
        }
        
        if let minHeight = attr["minHeight"].cgFloat {
            t.minHeight = minHeight
        }
        
        if let maxHeight = attr["maxHeight"].cgFloat {
            t.maxHeight = maxHeight
        }
        
        if let isFlexible = attr["flexible"].bool {
            t.flexible = isFlexible
        }
        
        if let hint = attr["hint"].string {
            t.hint = NSLocalizedString(hint, comment: "")
        }
        
        if let hasContainer = attr["hasContainer"].bool {
            t.hasContainer = hasContainer
        }
        
        if let returnKeyType = attr["returnKeyType"].string {
            switch (returnKeyType) {
            case "Done":
                t.returnKeyType = .done
            case "Next":
                t.returnKeyType = .next
            case "Search":
                t.returnKeyType = .search
            case "Send":
                t.returnKeyType = .send
            case "Go":
                t.returnKeyType = .go
            case "Route":
                t.returnKeyType = .route
            case "Yahoo":
                t.returnKeyType = .yahoo
            case "Google":
                t.returnKeyType = .google
            default:
                break
            }
        }
        return t
    }
    
}
