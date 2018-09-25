//
//  NSAttibutedStringExtension.swift
//
//  Created by 木村太一朗 on 2016/02/09.
//

import UIKit

public extension NSAttributedString {
    public func heightForAttributedString(_ inWidth: CGFloat, lineHeightMultiple: CGFloat, fontSize: CGFloat = SJUIViewCreator.defaultFontSize) -> CGFloat {
        var H: CGFloat = 0
        
        // Create the framesetter with the attributed string.
        let framesetter = CTFramesetterCreateWithAttributedString(self)
        
        let box = CGRect(x: 0,y: 0, width: inWidth, height: CGFloat.greatestFiniteMagnitude)
        
        let startIndex = 0
        
        let path = CGMutablePath()
        path.addRect(box)
        
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(startIndex, 0), path, nil)
        let lineArray = CTFrameGetLines(frame)
        let lineCount = CFArrayGetCount(lineArray)
        //        Log("Text \(self.string)")
        //        Log("Lines \(lineCount)")
        var h:CGFloat = 0, ascent:CGFloat = 0, descent:CGFloat = 0, leading:CGFloat = 0
        for _ in 0 ..< lineCount {
            let currentLine = CTLineCreateWithAttributedString(self)
            CTLineGetTypographicBounds(currentLine, &ascent, &descent, &leading)
            //            Log("ascend \(ascent) descent: \(descent) leading: \(leading)")
            h = ascent + descent
            H+=h;
        }
        H = (H*lineHeightMultiple)
        H+=4.0
        let iH = CGFloat(Int(H))
        if H - iH > 0.5 {
            H = iH + 1.0
        } else {
            H = iH + 0.5
        }
//        Log("Height:\(H)")
        return H;
    }
    
    public func widthForAttributedString() -> CGFloat {
        
        // Create the framesetter with the attributed string.
        let framesetter = CTFramesetterCreateWithAttributedString(self)
        
        let box = CGRect(x: 0,y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        let startIndex = 0
        
        let path = CGMutablePath()
        path.addRect(box)
        
        let frame = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(startIndex, 0), nil, box.size, nil)
        return frame.width;
    }
    
    public func lineCountForAttributedString(_ inWidth: CGFloat, lineHeightMultiple: CGFloat, fontSize: CGFloat) -> CGFloat {
        
        // Create the framesetter with the attributed string.
        let framesetter = CTFramesetterCreateWithAttributedString(self)
        
        let box = CGRect(x: 0,y: 0, width: inWidth, height: CGFloat.greatestFiniteMagnitude)
        
        let startIndex = 0
        
        let path = CGMutablePath()
        path.addRect(box)
        
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(startIndex, 0), path, nil)
        let lineArray = CTFrameGetLines(frame)
        let lineCount = CFArrayGetCount(lineArray)
        
        return CGFloat(lineCount);
    }
    
    public func applyAttributesFromJSON(attrs: [JSON], toLabel label: SJUILabel? = nil) -> NSMutableAttributedString {
        let attString = NSMutableAttributedString(attributedString: self)
        let text = self.string as NSString
        for attr in attrs {
            let paragraphStyle = NSMutableParagraphStyle()
            if let lineSpacing = attr["lineSpacing"].cgFloat {
                paragraphStyle.lineSpacing = lineSpacing
            }
            paragraphStyle.lineHeightMultiple = attr["lineHeightMultiple"].cgFloat != nil ? attr["lineHeightMultiple"].cgFloatValue :1.4
            let size = attr["fontSize"].cgFloat ?? SJUIViewCreator.defaultFontSize
            let name = attr["font"].string != nil ? attr["font"].stringValue : SJUIViewCreator.defaultFont
            let font = UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
            var attributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: font]
            if let lineBreakMode = attr["lineBreakMode"].string {
                switch (lineBreakMode) {
                case "Char":
                    paragraphStyle.lineBreakMode = NSLineBreakMode.byCharWrapping
                case "Clip":
                    paragraphStyle.lineBreakMode = NSLineBreakMode.byClipping
                case "Word":
                    paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
                case "Head":
                    paragraphStyle.lineBreakMode = NSLineBreakMode.byTruncatingHead
                case "Middle":
                    paragraphStyle.lineBreakMode = NSLineBreakMode.byTruncatingMiddle
                case "Tail":
                    paragraphStyle.lineBreakMode = NSLineBreakMode.byTruncatingTail
                default:
                    break
                }
            }
            if let alignment = attr["textAlign"].string {
                switch (alignment) {
                case "Left":
                    paragraphStyle.alignment = NSTextAlignment.left
                case "Right":
                    paragraphStyle.alignment = NSTextAlignment.right
                case "Center":
                    paragraphStyle.alignment = NSTextAlignment.center
                default:
                    break
                }
            }
            if !attr["underline"].isEmpty {
                let underline = attr["underline"]
                switch underline["lineStyle"].stringValue {
                case "Single":
                    attributes[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.styleSingle.rawValue as NSObject?
                case "Double":
                    attributes[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.styleDouble.rawValue as NSObject?
                case "Thick":
                    attributes[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.styleThick.rawValue as NSObject?
                case "None":
                    attributes[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.styleNone.rawValue as NSObject?
                default:
                    attributes[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.styleSingle.rawValue as NSObject?
                }
                attributes[NSAttributedString.Key.underlineColor] = UIColor.findColorByJSON(attr: underline["color"])
                attributes[NSAttributedString.Key.baselineOffset] = underline["lineOffset"].cgFloatValue as NSObject?
            }
            let color = UIColor.findColorByJSON(attr: attr["fontColor"]) ?? SJUIViewCreator.defaultFontColor
            attributes[NSAttributedString.Key.foregroundColor] = color
            
            let shadow = attr["textShadow"]
            if !shadow.isEmpty, let shadowColor = UIColor.findColorByJSON(attr: shadow["color"]), let shadowBlur = shadow["blur"].cgFloat, let shadowOffset = shadow["offset"].arrayObject as? [CGFloat] {
                let s = NSShadow()
                s.shadowColor = shadowColor;
                s.shadowBlurRadius = shadowBlur
                s.shadowOffset = CGSize(width: shadowOffset[0], height: shadowOffset[1]);
                attributes[NSAttributedString.Key.shadow] = s
            }
            
            if let ranges = attr["range"].arrayObject {
                for range in ranges {
                    if let range = range as? [Int] {
                        if range.count > 1 {
                            let r = NSRange(location: range[0], length: range[1])
                            attString.addAttributes(attributes, range: r)
                            if let onclick = attr["onclick"].string {
                                label?.linkedRanges.append(["start": range[0], "end": range[1], "onclick": onclick])
                            }
                        }
                    } else if let range = range as? String {
                        let textRange = text.range(of: NSLocalizedString(range, comment: ""))
                        attString.addAttributes(attributes, range: textRange)
                        if let onclick = attr["onclick"].string {
                            label?.linkedRanges.append(["start": textRange.lowerBound, "end": textRange.upperBound, "onclick": onclick])
                        }
                    }
                }
            }
        }
        return attString
    }

}
