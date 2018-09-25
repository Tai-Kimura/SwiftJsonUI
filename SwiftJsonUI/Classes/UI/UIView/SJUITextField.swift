//
//  SJUITextField.swift
//
//  Created by 木村太一朗 on 2017/07/22.
//

import UIKit

@objc public protocol SJUITextFieldDelegate {
    @objc optional func textFieldDidDeleteBackward(textField: UITextField)
}

open class SJUITextField: UITextField {
    
    open class var viewClass: SJUITextField.Type {
        get {
            return SJUITextField.self
        }
    }
    
    public static var accessoryBackgroundColor = UIColor.gray
    
    public static var accessoryTextColor = UIColor.blue
    
    public static var defaultBorderColor = UIColor.lightGray
    
    private var _sjUiDelegate: SJUITextFieldDelegate?
    
    override open var delegate: UITextFieldDelegate? {
        didSet {
            self._sjUiDelegate = self.delegate as? SJUITextFieldDelegate
        }
    }
    
    override open func deleteBackward() {
        super.deleteBackward()
        self._sjUiDelegate?.textFieldDidDeleteBackward?(textField: self)
    }
    
    open class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUITextField {
        
        let t = viewClass.init()
        switch attr["textVerticalAlign"].string ?? "" {
        case "Center":
            t.contentVerticalAlignment = .center
        case "Top":
            t.contentVerticalAlignment = .top
        case "Bottom":
            t.contentVerticalAlignment = .bottom
        default:
            t.contentVerticalAlignment = .center
        }
        t.delegate = target as? UITextFieldDelegate
        if let tintColor = UIColor.findColorByJSON(attr: attr["tintColor"]) {
            t.tintColor = tintColor
        }
        let size = attr["fontSize"].cgFloat ?? SJUIViewCreator.defaultFontSize
        let name = attr["font"].string ?? SJUIViewCreator.defaultFont
        let font = UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
        t.font = font
        t.textColor = UIColor.findColorByJSON(attr: attr["fontColor"]) ?? SJUIViewCreator.defaultFontColor
        t.layer.cornerRadius = attr["cornerRadius"].cgFloat == nil ? 0 : attr["cornerRadius"].cgFloat!
        t.layer.borderColor = (UIColor.findColorByJSON(attr: attr["borderColor"]) ?? SJUITextField.defaultBorderColor).cgColor
        t.layer.borderWidth = attr["borderWidth"].cgFloat == nil ? 0.3 : attr["borderWidth"].cgFloat!
        let leftPaddingView = UIView(frame:CGRect(x: 0, y: 0, width: attr["textPaddingLeft"].cgFloat ?? 10.0, height: attr["textPaddingRight"].cgFloat ?? 5.0))
        leftPaddingView.isOpaque = false
        leftPaddingView.backgroundColor = UIColor.clear
        t.leftView = leftPaddingView
        t.leftViewMode = UITextFieldViewMode.always
        switch attr["borderStyle"].stringValue {
        case "RoundedRect":
            t.borderStyle = UITextBorderStyle.roundedRect
        case "Line":
            t.borderStyle = UITextBorderStyle.line
        case "Bazel":
            t.borderStyle = UITextBorderStyle.bezel
        default:
            t.borderStyle = UITextBorderStyle.none
        }
        let rightPaddingView = UIView(frame:CGRect(x: 0, y: 0, width: attr["fieldPadding"].cgFloat ?? 5, height: 5))
        rightPaddingView.isOpaque = false
        rightPaddingView.backgroundColor = UIColor.clear
        t.rightView = rightPaddingView
        t.rightViewMode = UITextFieldViewMode.always
        if let onTextChange = attr["onTextChange"].string {
            t.addTarget(target, action: Selector(onTextChange), for: UIControlEvents.editingChanged)
        }
        if let hint = attr["hint"].string {
            let hintColor = UIColor.findColorByJSON(attr: attr["hintColor"]) ?? SJUIViewCreator.defaultHintColor
            let paragraphStyle = NSMutableParagraphStyle()
            let placeholder = NSLocalizedString(hint, comment: "")
            var hintFont: UIFont
            if let f = attr["hintFont"].string {
                let s = attr["hintFontSize"].cgFloat ?? size
                let n = f
                hintFont = UIFont(name: n, size: s) ?? UIFont.systemFont(ofSize: size)
                paragraphStyle.lineHeightMultiple = attr["hintLineHeightMultiple"].cgFloat ?? 1.0
            } else {
                hintFont = font
            }
            t.attributedPlaceholder = NSMutableAttributedString(string:  placeholder, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: hintFont, NSAttributedString.Key.foregroundColor: hintColor])
        }
        
        if let input = attr["input"].string {
            switch (input) {
            case "alphabet":
                t.keyboardType = UIKeyboardType.alphabet
                break
            case "email":
                t.keyboardType = UIKeyboardType.emailAddress
                break
            case "password":
                t.keyboardType = UIKeyboardType.asciiCapable
                t.isSecureTextEntry = true
                break
            case "number", "decimal":
                t.keyboardType = input == "decimal" ? UIKeyboardType.decimalPad : UIKeyboardType.numberPad
                t.isSecureTextEntry = attr["secure"].boolValue
                let accessory = UIView(frame: CGRect(x: 0,y: 0,width: UIScreen.main.bounds.size.width, height: 50.0))
                accessory.backgroundColor = UIColor.findColorByJSON(attr: attr["accessoryBackground"]) ?? SJUITextField.accessoryBackgroundColor
                let l  = SJUILabel(frame: CGRect(x: UIScreen.main.bounds.size.width - 100.0,y: 0, width: 100, height: 50))
                l.textAlignment = NSTextAlignment.center
                l.font = UIFont(name: SJUIViewCreator.defaultFont, size: 15.0)
                l.textColor = UIColor.findColorByJSON(attr: attr["accessoryTextColor"]) ?? SJUITextField.accessoryTextColor
                l.text = attr["doneText"].string == nil ? NSLocalizedString("done", comment: "") : NSLocalizedString(attr["doneText"].stringValue, comment: "")
                l.isUserInteractionEnabled = true
                l.defaultBackgroundColor = UIColor.colorWithHexString("000000", alpha: 0)
                l.addGestureRecognizer(UITapGestureRecognizer(target: target, action: #selector(SJUIViewController.returnNumberPad)))
                accessory.addSubview(l)
                t.inputAccessoryView = accessory
            default:
                break
            }
            
        }
        
        if let delegate = target as? UITextFieldDelegate {
            t.delegate = delegate
        }
        
        t.returnKeyType = UIReturnKeyType.done
        
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
        if let alignment = attr["textAlign"].string {
            switch (alignment) {
            case "Left":
                t.textAlignment = NSTextAlignment.left
                t.contentHorizontalAlignment = UIControlContentHorizontalAlignment.left
            case "Right":
                t.textAlignment = NSTextAlignment.right
                t.contentHorizontalAlignment = UIControlContentHorizontalAlignment.right
            case "Center":
                t.textAlignment = NSTextAlignment.center
                t.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
            default:
                break
            }
        }
        
        return t
    }
    
}
