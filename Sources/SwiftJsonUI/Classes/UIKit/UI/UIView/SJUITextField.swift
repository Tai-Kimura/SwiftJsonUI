//
//  SJUITextField.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2017/07/22.

import UIKit

@MainActor
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

    // Liquid Glass properties
    public static var defaultApplyLiquidGlass: Bool = {
        if #available(iOS 26.0, *) {
            return true
        } else {
            return false
        }
    }()

    public static var defaultAccessoryCornerRadius: CGFloat = 16.0

    public static var defaultGlassEffectStyle: String = "systemMaterial"
    
    public var placeholderAttributes: [NSAttributedString.Key : Any]?
    
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
        t.leftViewMode = UITextField.ViewMode.always
        switch attr["borderStyle"].stringValue {
        case "RoundedRect":
            t.borderStyle = UITextField.BorderStyle.roundedRect
        case "Line":
            t.borderStyle = UITextField.BorderStyle.line
        case "Bezel":
            t.borderStyle = UITextField.BorderStyle.bezel
        default:
            t.borderStyle = UITextField.BorderStyle.none
        }
        let rightPaddingView = UIView(frame:CGRect(x: 0, y: 0, width: attr["fieldPadding"].cgFloat ?? 5, height: 5))
        rightPaddingView.isOpaque = false
        rightPaddingView.backgroundColor = UIColor.clear
        rightPaddingView.isUserInteractionEnabled = false
        t.rightView = rightPaddingView
        t.rightViewMode = UITextField.ViewMode.always
        if let onTextChange = attr["onTextChange"].string {
            t.addTarget(target, action: Selector(onTextChange), for: UIControl.Event.editingChanged)
        }
        
        let hintColor = UIColor.findColorByJSON(attr: attr["hintColor"]) ?? SJUIViewCreator.defaultHintColor
        let paragraphStyle = NSMutableParagraphStyle()
        let hintFont: UIFont
        if let f = attr["hintFont"].string {
            let s = attr["hintFontSize"].cgFloat ?? size
            let n = f
            hintFont = UIFont(name: n, size: s) ?? UIFont.systemFont(ofSize: size)
            paragraphStyle.lineHeightMultiple = attr["hintLineHeightMultiple"].cgFloat ?? 1.0
        } else {
            hintFont = font
        }
        t.placeholderAttributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: hintFont, NSAttributedString.Key.foregroundColor: hintColor]
        if let hint = attr["hint"].string {
            let placeholder = hint.localized()
            t.attributedPlaceholder = NSMutableAttributedString(string:  placeholder, attributes: t.placeholderAttributes)
        }
        
        if let input = attr["input"].string {
            switch (input) {
            case "alphabet":
                t.keyboardType = .alphabet
            case "email":
                t.keyboardType = .emailAddress
            case "password":
                t.keyboardType = .asciiCapable
                t.isSecureTextEntry = true
            case "twitter":
                t.keyboardType = .twitter
            case "webSearch":
                t.keyboardType = .webSearch
            case "URL":
                t.keyboardType = .URL
            case "namePhonePad":
                t.keyboardType = .namePhonePad
            case "number", "decimal":
                t.keyboardType = input == "decimal" ? .decimalPad : .numberPad

                // Determine if liquid glass should be applied
                let applyLiquidGlass = attr["applyLiquidGlass"].bool ?? SJUITextField.defaultApplyLiquidGlass
                let accessoryRadius = attr["accessoryCornerRadius"].cgFloat ?? SJUITextField.defaultAccessoryCornerRadius
                let glassEffectStyle = attr["glassEffectStyle"].string ?? SJUITextField.defaultGlassEffectStyle

                if applyLiquidGlass, #available(iOS 13.0, *) {
                    // Create visual effect view for liquid glass effect
                    let blurEffect: UIBlurEffect
                    switch glassEffectStyle {
                    case "systemUltraThinMaterial":
                        blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
                    case "systemThinMaterial":
                        blurEffect = UIBlurEffect(style: .systemThinMaterial)
                    case "systemMaterial":
                        blurEffect = UIBlurEffect(style: .systemMaterial)
                    case "systemThickMaterial":
                        blurEffect = UIBlurEffect(style: .systemThickMaterial)
                    case "systemChromeMaterial":
                        blurEffect = UIBlurEffect(style: .systemChromeMaterial)
                    case "regular":
                        blurEffect = UIBlurEffect(style: .regular)
                    case "prominent":
                        blurEffect = UIBlurEffect(style: .prominent)
                    case "light":
                        blurEffect = UIBlurEffect(style: .light)
                    case "dark":
                        blurEffect = UIBlurEffect(style: .dark)
                    case "extraLight":
                        blurEffect = UIBlurEffect(style: .extraLight)
                    default:
                        blurEffect = UIBlurEffect(style: .systemMaterial)
                    }

                    let visualEffectView = UIVisualEffectView(effect: blurEffect)
                    visualEffectView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 50.0)
                    visualEffectView.layer.cornerRadius = accessoryRadius
                    visualEffectView.clipsToBounds = true

                    // Add a vibrancy effect for the text
                    let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
                    let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
                    vibrancyView.frame = visualEffectView.bounds
                    vibrancyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

                    let l = SJUILabel(frame: CGRect(x: UIScreen.main.bounds.size.width - 100.0, y: 0, width: 100, height: 50))
                    l.textAlignment = NSTextAlignment.center
                    l.font = UIFont(name: SJUIViewCreator.defaultFont, size: 15.0)
                    l.textColor = UIColor.findColorByJSON(attr: attr["accessoryTextColor"]) ?? SJUITextField.accessoryTextColor
                    l.text = attr["doneText"].string == nil ? "done".localized() : attr["doneText"].stringValue.localized()
                    l.isUserInteractionEnabled = true
                    l.defaultBackgroundColor = UIColor.colorWithHexString("000000", alpha: 0)
                    l.addGestureRecognizer(UITapGestureRecognizer(target: target, action: #selector(SJUIViewController.returnNumberPad)))

                    vibrancyView.contentView.addSubview(l)
                    visualEffectView.contentView.addSubview(vibrancyView)

                    // Set background color if specified (will show through the blur effect)
                    if let bgColor = UIColor.findColorByJSON(attr: attr["accessoryBackground"]) {
                        let backgroundView = UIView(frame: visualEffectView.bounds)
                        backgroundView.backgroundColor = bgColor.withAlphaComponent(0.3) // Slight transparency for glass effect
                        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                        visualEffectView.contentView.insertSubview(backgroundView, at: 0)
                    }

                    t.inputAccessoryView = visualEffectView
                } else {
                    // Fallback to regular view for older iOS versions or when liquid glass is disabled
                    let accessory = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 50.0))
                    accessory.backgroundColor = UIColor.findColorByJSON(attr: attr["accessoryBackground"]) ?? SJUITextField.accessoryBackgroundColor
                    accessory.layer.cornerRadius = accessoryRadius
                    accessory.clipsToBounds = true

                    let l = SJUILabel(frame: CGRect(x: UIScreen.main.bounds.size.width - 100.0, y: 0, width: 100, height: 50))
                    l.textAlignment = NSTextAlignment.center
                    l.font = UIFont(name: SJUIViewCreator.defaultFont, size: 15.0)
                    l.textColor = UIColor.findColorByJSON(attr: attr["accessoryTextColor"]) ?? SJUITextField.accessoryTextColor
                    l.text = attr["doneText"].string == nil ? "done".localized() : attr["doneText"].stringValue.localized()
                    l.isUserInteractionEnabled = true
                    l.defaultBackgroundColor = UIColor.colorWithHexString("000000", alpha: 0)
                    l.addGestureRecognizer(UITapGestureRecognizer(target: target, action: #selector(SJUIViewController.returnNumberPad)))
                    accessory.addSubview(l)
                    t.inputAccessoryView = accessory
                }
            default:
                break
            }
            
        }
        
        if #available(iOS 10.0, *) {
            if let contentType = attr["contentType"].string {
                switch (contentType) {
                case "name":
                    t.textContentType = .name
                case "namePrefix":
                    t.textContentType = .namePrefix
                case "givenName":
                    t.textContentType = .givenName
                case "middleName":
                    t.textContentType = .middleName
                case "familyName":
                    t.textContentType = .familyName
                case "nameSuffix":
                    t.textContentType = .nameSuffix
                case "nickname":
                    t.textContentType = .nickname
                case "jobTitle":
                    t.textContentType = .jobTitle
                case "organizationName":
                    t.textContentType = .organizationName
                case "location":
                    t.textContentType = .location
                case "fullStreetAddress":
                    t.textContentType = .fullStreetAddress
                case "streetAddressLine1":
                    t.textContentType = .streetAddressLine1
                case "streetAddressLine2":
                    t.textContentType = .streetAddressLine2
                case "addressCity":
                    t.textContentType = .addressCity
                case "addressState":
                    t.textContentType = .addressState
                case "addressCityAndState":
                    t.textContentType = .addressCityAndState
                case "sublocality":
                    t.textContentType = .sublocality
                case "countryName":
                    t.textContentType = .countryName
                case "postalCode":
                    t.textContentType = .postalCode
                case "telephoneNumber":
                    t.textContentType = .telephoneNumber
                case "emailAddress":
                    t.textContentType = .emailAddress
                case "URL":
                    t.textContentType = .URL
                case "creditCardNumber":
                    t.textContentType = .creditCardNumber
                case "username":
                    if #available(iOS 11.0, *) {
                        t.textContentType = .username
                    }
                case "password":
                    if #available(iOS 11.0, *) {
                        t.textContentType = .password
                    }
                case "newPassword":
                    if #available(iOS 12.0, *) {
                        t.textContentType = .newPassword
                    }
                case "oneTimeCode":
                    if #available(iOS 12.0, *) {
                        t.textContentType = .oneTimeCode
                    }
                default:
                    break
                }
            }
        }
        
        if let secure = attr["secure"].bool {
            t.isSecureTextEntry = secure
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
                t.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.left
            case "Right":
                t.textAlignment = NSTextAlignment.right
                t.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.right
            case "Center":
                t.textAlignment = NSTextAlignment.center
                t.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.center
            default:
                break
            }
        }
        
        if let enabled = attr["enabled"].bool {
            t.isEnabled = enabled
        }
        return t
    }
    
}
