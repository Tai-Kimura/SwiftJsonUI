//
//  SJUILabel.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2016/01/28.

import UIKit

open class SJUILabel: UILabel {
    
    open class var viewClass: SJUILabel.Type {
        get {
            return SJUILabel.self
        }
    }
    
    public static var defaultLinkColor = UIColor.blue
    
    public var hint: String?
    
    public var attributes:[NSAttributedString.Key:NSObject]!
    
    public var highlightAttributes:[NSAttributedString.Key:NSObject]!
    
    public var hintAttributes:[NSAttributedString.Key:NSObject]?
    
    public var selected: Bool = false {
        didSet {
            self.applyAttributedText(self.attributedText?.string)
        }
    }
    
    public var linkable = false
    
    public var touchedURL: URL?
    
    public var linkedRanges: [[String:Any]] = [[String:Any]]()
    
    public weak var touchDelegate: UIViewTapDelegate?
    public weak var linkHandleDelegate: NSObject?
    
    // paddingの値
    public var padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
    override open func drawText(in rect: CGRect) {
        let newRect = rect.inset(by: padding)
        super.drawText(in: newRect)
    }
    
    override open var intrinsicContentSize : CGSize {
        var intrinsicContentSize = super.intrinsicContentSize
        intrinsicContentSize.height += padding.top + padding.bottom
        if intrinsicContentSize.width + (padding.left + padding.right) < 2777777.0 {
            intrinsicContentSize.width += padding.left + padding.right
        }
        return intrinsicContentSize
    }
    
    open func applyAttributedText(_ text: String!) {
        self.linkable = false
        let string = text ?? ""
        if let hint = hint, let hintAttributes = hintAttributes, string.isEmpty {
            self.attributedText = NSAttributedString(string: hint, attributes: hintAttributes)
        } else {
            let attr = selected ? highlightAttributes : attributes
            self.attributedText = NSAttributedString(string: string, attributes: attr)
        }
    }
    
    
    open func applyLinkableAttributedText(_ text: String!, withColor color: UIColor = defaultLinkColor) {
        let attrText = NSMutableAttributedString(string: text, attributes: self.attributes)
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        linkable = matches.count > 0
        isUserInteractionEnabled = true
        for match in matches {
            attrText.addAttributes([NSAttributedString.Key.foregroundColor: color], range: match.range)
        }
        self.attributedText = attrText
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count == 1 && self.linkable {
            if let location = touches.first?.location(in: self) {
                if let characterIndex = self.characterIndexAtPoint(location) {
                    if let input = self.attributedText?.string {
                        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                        let matches = detector.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
                        for match in matches {
                            if match.range.location <= characterIndex && match.range.location + match.range.length >= characterIndex {
                                touchedURL = URL(string: (input as NSString).substring(with: match.range))
                                break
                            }
                        }
                        
                    }
                }
            }
        }
        onBeginTap()
        super.touchesBegan(touches, with: event)
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        onEndTap()
        self.touchedURL = nil
        super.touchesCancelled(touches, with: event)
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchedURL = nil
        super.touchesMoved(touches, with: event)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        onEndTap()
        self.touchedURL = nil
        super.touchesEnded(touches, with: event)
    }
    
    override open func onBeginTap() {
        super.onBeginTap()
        self.touchDelegate?.touchBegin(self)
    }
    
    override open func onEndTap() {
        super.onEndTap()
        self.touchDelegate?.touchEnd(self)
    }
    
    @objc open func onLinkTap(_ sender: UITapGestureRecognizer) {
        if let linkHandleDelegate = self.linkHandleDelegate, !linkedRanges.isEmpty {
            let location = sender.location(in: self)
            if let characterIndex = self.characterIndexAtPoint(location) {
                for linkedRange in linkedRanges {
                    if let start = linkedRange["start"] as? Int, let end = linkedRange["end"] as? Int, let onclick = linkedRange["onclick"] as? String, characterIndex >= start && characterIndex <= end {
                        DispatchQueue.main.async(execute: {
                            _ = linkHandleDelegate.perform(Selector(onclick))
                        })
                        break
                    }
                }
            }
        }
    }
    
    open func characterIndexAtPoint(_ touchPoint: CGPoint) -> Int? {
        if (!self.bounds.contains(touchPoint) || self.attributedText == nil) {
            return nil;
        }
        let textRect = self.textRect(forBounds: self.bounds, limitedToNumberOfLines: 0)
        let p = CGPoint(x: touchPoint.x - textRect.origin.x, y: touchPoint.y - ((self.bounds.size.height - textRect.size.height)/2.0))
        let attributedText = self.attributedText!
        var H: CGFloat = 0
        // Create the framesetter with the attributed string.
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
        
        var box = self.frame
        
        box.size.height = CGFloat.greatestFiniteMagnitude
        
        let startIndex = 0
        
        let path = CGMutablePath()
        path.addRect(box)
        
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(startIndex, 0), path, nil)
        let lineArray = CTFrameGetLines(frame)
        let lineCount = CFArrayGetCount(lineArray)
        var size: CGFloat? = nil
        if attributedText.length > 0 {
            let attr = attributedText.attributes(at: 0, effectiveRange: nil)
            if let font = attr[NSAttributedString.Key.font] as? UIFont {
                size = font.pointSize
            }
        }
        
        var h:CGFloat = 0, ascent:CGFloat = 0, descent:CGFloat = 0, leading:CGFloat = 0
        for i in 0 ..< lineCount {
            let currentLine = CTLineCreateWithAttributedString(attributedText)
            CTLineGetTypographicBounds(currentLine, &ascent, &descent, &leading)
            if size != nil && (ascent + descent) - size! > 5.0 {
                h = size! * 1.1
            } else {
                h = (ascent + descent) * 1.1
            }
            if p.y > H && p.y <= H + h {
                let line: CTLine =  unsafeBitCast(CFArrayGetValueAtIndex(lineArray, i), to: CTLine.self)
                let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
                if p.x <= width && p.x >= -(size ?? 0)/2.0 {
                    _ = CGPoint(x: p.x, y: p.y - H)
                    let idx = CTLineGetStringIndexForPosition(line, p)
                    return idx
                }
            }
            H+=h
        }
        return nil
    }
    
    public class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUILabel {
        
        let l = viewClass.init()
        var edgeInsets = Array<CGFloat>()
        if let edgeInsetStr = attr["edgeInset"].string {
            let edgeInsetStrs = edgeInsetStr.components(separatedBy: "|")
            for e in edgeInsetStrs {
                if let n = NumberFormatter().number(from: e) {
                    edgeInsets.append(CGFloat(truncating: n))
                }
            }
        } else if let insets = attr["edgeInset"].arrayObject as? [CGFloat] {
            edgeInsets = insets
        }
        switch (edgeInsets.count) {
        case 0:
            break
        case 1:
            l.padding = UIEdgeInsets.init(top: edgeInsets[0], left: edgeInsets[0], bottom: edgeInsets[0], right: edgeInsets[0])
        case 2:
            l.padding = UIEdgeInsets.init(top: edgeInsets[0], left: edgeInsets[1], bottom: edgeInsets[0], right: edgeInsets[1])
        case 3:
            l.padding = UIEdgeInsets.init(top: edgeInsets[0], left: edgeInsets[1], bottom: edgeInsets[2], right: edgeInsets[1])
        default:
            l.padding = UIEdgeInsets.init(top: edgeInsets[0], left: edgeInsets[1], bottom: edgeInsets[2], right: edgeInsets[3])
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = attr["lineHeightMultiple"].cgFloat != nil ? attr["lineHeightMultiple"].cgFloatValue :1.0
        let size = attr["fontSize"].cgFloat ?? SJUIViewCreator.defaultFontSize
        let name = attr["font"].string != nil ? attr["font"].stringValue : SJUIViewCreator.defaultFont
        let font = UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
        var attributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: font]
        
        l.font = font
        l.numberOfLines = attr["lines"].int == nil ? 0 : attr["lines"].intValue
        l.lineBreakMode = NSLineBreakMode.byWordWrapping
        if let lineBreakMode = attr["lineBreakMode"].string {
            switch (lineBreakMode) {
            case "Char":
                paragraphStyle.lineBreakMode = NSLineBreakMode.byCharWrapping
                l.lineBreakMode = NSLineBreakMode.byCharWrapping
            case "Clip":
                paragraphStyle.lineBreakMode = NSLineBreakMode.byClipping
                l.lineBreakMode = NSLineBreakMode.byClipping
            case "Word":
                paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
                l.lineBreakMode = NSLineBreakMode.byWordWrapping
            case "Head":
                paragraphStyle.lineBreakMode = NSLineBreakMode.byTruncatingHead
                l.lineBreakMode = NSLineBreakMode.byTruncatingHead
            case "Middle":
                paragraphStyle.lineBreakMode = NSLineBreakMode.byTruncatingMiddle
                l.lineBreakMode = NSLineBreakMode.byTruncatingMiddle
            case "Tail":
                paragraphStyle.lineBreakMode = NSLineBreakMode.byTruncatingTail
                l.lineBreakMode = NSLineBreakMode.byTruncatingTail
            default:
                break
            }
        }
        if let alignment = attr["textAlign"].string {
            switch (alignment) {
            case "Left":
                paragraphStyle.alignment = NSTextAlignment.left
                l.textAlignment = NSTextAlignment.left
            case "Right":
                paragraphStyle.alignment = NSTextAlignment.right
                l.textAlignment = NSTextAlignment.right
            case "Center":
                paragraphStyle.alignment = NSTextAlignment.center
                l.textAlignment = NSTextAlignment.center
            default:
                break
            }
        }
        
        if !attr["underline"].isEmpty {
            let underline = attr["underline"]
            switch underline["lineStyle"].stringValue {
            case "Single":
                attributes[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.single.rawValue as NSObject?
            case "Double":
                attributes[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.double.rawValue as NSObject?
            case "Thick":
                attributes[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.thick.rawValue as NSObject?
            default:
                attributes[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.single.rawValue as NSObject?
            }
            attributes[NSAttributedString.Key.underlineColor] = UIColor.findColorByJSON(attr: underline["color"])
            attributes[NSAttributedString.Key.baselineOffset] = underline["lineOffset"].cgFloatValue as NSObject?
        }
        if !attr["strikethrough"].isEmpty {
            let strikethrough = attr["strikethrough"]
            switch strikethrough["lineStyle"].stringValue {
            case "Single":
                attributes[NSAttributedString.Key.strikethroughStyle] = NSUnderlineStyle.single.rawValue as NSObject?
            case "Double":
                attributes[NSAttributedString.Key.strikethroughStyle] = NSUnderlineStyle.double.rawValue as NSObject?
            case "Thick":
                attributes[NSAttributedString.Key.strikethroughStyle] = NSUnderlineStyle.thick.rawValue as NSObject?
            default:
                attributes[NSAttributedString.Key.strikethroughStyle] = NSUnderlineStyle.single.rawValue as NSObject?
            }
            attributes[NSAttributedString.Key.strikethroughColor] = UIColor.findColorByJSON(attr: strikethrough["color"])
        }
        if let autoShrink = attr["autoShrink"].bool {
            l.adjustsFontSizeToFitWidth = autoShrink
            if autoShrink {
                l.minimumScaleFactor = attr["minimumScaleFactor"].cgFloat ?? 8.0
            }
        }
        let color = UIColor.findColorByJSON(attr: attr["fontColor"]) ??  SJUIViewCreator.defaultFontColor
        attributes[NSAttributedString.Key.foregroundColor] = color
        let shadow = attr["textShadow"]
        if !shadow.isEmpty, let shadowColor = UIColor.findColorByJSON(attr: shadow["color"]), let shadowBlur = shadow["blur"].cgFloat, let shadowOffset = shadow["offset"].arrayObject as? [CGFloat] {
            let s = NSShadow()
            s.shadowColor = shadowColor;
            s.shadowBlurRadius = shadowBlur
            s.shadowOffset = CGSize(width: shadowOffset[0], height: shadowOffset[1]);
            attributes[NSAttributedString.Key.shadow] = s
        }
        if let text = attr["text"].string {
            l.textColor = color
            var attrText = NSMutableAttributedString(string:  NSLocalizedString(text, comment: ""), attributes: attributes)
            if let partialAttributes = attr["partialAttributes"].array {
                attrText = attrText.applyAttributesFromJSON(attrs: partialAttributes, toLabel: l)
                if !l.linkedRanges.isEmpty {
                    l.linkHandleDelegate = target as? NSObject
                    l.addGestureRecognizer(UITapGestureRecognizer(target: l, action: #selector(SJUILabel.onLinkTap(_:))))
                    l.isUserInteractionEnabled = true
                }
            }
            l.attributedText = attrText
            l.hint = NSLocalizedString(text, comment: "")
        } else {
            l.textColor = color
        }
        
        l.attributes = attributes
        
        if !attr["highlightAttributes"].isEmpty {
            let highlightAttr = attr["highlightAttributes"]
            let highlightSize = highlightAttr["fontSize"].cgFloat != nil ? highlightAttr["fontSize"].cgFloatValue : size
            let highlightName = highlightAttr["font"].string != nil ? highlightAttr["font"].stringValue : name
            let highlightFont = UIFont(name: highlightName, size: highlightSize) ?? UIFont.systemFont(ofSize: highlightSize)
            var highlightAttributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: highlightFont, NSAttributedString.Key.foregroundColor: color]
            if let highlightColor = UIColor.findColorByJSON(attr: highlightAttr["fontColor"]) {
                highlightAttributes[NSAttributedString.Key.foregroundColor] = highlightColor
            }
            l.highlightAttributes = highlightAttributes
        } else if let highlightColor = UIColor.findColorByJSON(attr: attr["highlightColor"]) {
            l.highlightAttributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: highlightColor]
        } else {
            l.highlightAttributes = attributes
        }
        
        if let hint = attr["hint"].string {
            l.hint = NSLocalizedString(hint, comment: "")
            l.hintAttributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: SJUIViewCreator.defaultHintColor]
        }
        
        if !attr["hintAttributes"].isEmpty {
            let hintAttr = attr["hintAttributes"]
            let hintSize = hintAttr["fontSize"].cgFloat != nil ? hintAttr["fontSize"].cgFloatValue : size
            let hintName = hintAttr["font"].string != nil ? hintAttr["font"].stringValue : name
            let hintFont = UIFont(name: hintName, size: hintSize) ?? UIFont.systemFont(ofSize: hintSize)
            var hintAttributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: hintFont, NSAttributedString.Key.foregroundColor: color]
            if let hintColor = UIColor.findColorByJSON(attr: hintAttr["fontColor"]) {
                hintAttributes[NSAttributedString.Key.foregroundColor] = hintColor
            }
            l.hintAttributes = hintAttributes
        } else if let hintColor = UIColor.findColorByJSON(attr: attr["hintColor"]) {
            l.hintAttributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: hintColor]
        }
        
        if let onclick = attr["onclick"].string {
            let gr = UITapGestureRecognizer(target: target, action: Selector(onclick))
            l.addGestureRecognizer(gr)
            l.isUserInteractionEnabled = true
        }
        
        return l
    }
}
