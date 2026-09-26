//
//  NSAttibutedStringExtension.swift
//  Created by Taichiro Kimura on 2016/02/09.
//

import UIKit

public extension NSAttributedString {
    func heightForAttributedString(_ inWidth: CGFloat, lineHeightMultiple: CGFloat, fontSize: CGFloat = SJUIViewCreator.defaultFontSize) -> CGFloat {
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
    
    func widthForAttributedString() -> CGFloat {
        
        // Create the framesetter with the attributed string.
        let framesetter = CTFramesetterCreateWithAttributedString(self)
        
        let box = CGRect(x: 0,y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        let startIndex = 0
        
        let path = CGMutablePath()
        path.addRect(box)
        
        let frame = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(startIndex, 0), nil, box.size, nil)
        return frame.width;
    }
    
    func lineCountForAttributedString(_ inWidth: CGFloat, lineHeightMultiple: CGFloat, fontSize: CGFloat) -> CGFloat {
        
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
    
    func applyAttributesFromJSON(attrs: [JSON], toLabel label: SJUILabel? = nil) -> NSMutableAttributedString {
        let attString = NSMutableAttributedString(attributedString: self)
        let text = self.string as NSString
        for (attrIndex, attr) in attrs.enumerated() {
            let paragraphStyle = NSMutableParagraphStyle()
            if let lineSpacing = attr["lineSpacing"].cgFloat {
                paragraphStyle.lineSpacing = lineSpacing
            }
            paragraphStyle.lineHeightMultiple = attr["lineHeightMultiple"].cgFloat != nil ? attr["lineHeightMultiple"].cgFloatValue :1.4
            let size = attr["fontSize"].cgFloat ?? SJUIViewCreator.defaultFontSize
            let name = attr["font"].string != nil ? attr["font"].stringValue : SJUIViewCreator.defaultFont
            let font = UIFont(name: name, size: size) ?? (name == "bold" ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size))
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
                            // Add to linkedRanges for tap handling (PartialRangeHandler).
                            // Include partialAttributeIndex for mapping with setPartialAttributeOnClick
                            label?.appendLinkedRange(start: range[0], end: range[1], handler: PartialRangeHandler(attr), index: attrIndex)
                        }
                    } else if let range = range as? String {
                        let textRange = text.range(of: range.localized())
                        attString.addAttributes(attributes, range: textRange)
                        // Add to linkedRanges for tap handling (PartialRangeHandler).
                        // Include partialAttributeIndex for mapping with setPartialAttributeOnClick
                        label?.appendLinkedRange(start: textRange.lowerBound, end: textRange.upperBound, handler: PartialRangeHandler(attr), index: attrIndex)
                    }
                }
            }
        }
        return attString
    }

}

/// A partialAttributes range's handler, as the UIKit label takes it: `onClick`
/// first, then `onclick`, its alias, each a binding or a method name — as
/// jsonui-cli shared/core/tap_accessibility.rb `range_handler` reads them. From
/// jsonui-cli 1.9.0 the normalizer folds `onclick` into `onClick` in the
/// layouts `jui build` distributes, so a name arrives in onClick; this read
/// `onclick` as the selector and onClick as a binding only, and a folded name
/// was a range that called nothing. A name is the selector the label performs;
/// a binding is the closure the generated binding code sets
/// (`setPartialAttributeOnClick`). A value that names no method (`""`, `"@{ }"`)
/// or is neither a binding nor a name (`"@{a} b"`) passes to the next spelling;
/// with none, the range is no link.
enum PartialRangeHandler: Equatable {
    case selector(String)
    case binding

    init?(_ attr: JSON) {
        for key in ["onClick", "onclick"] {
            guard let value = attr[key].string, PartialRangeHandler.namesAMethod(value) else { continue }
            if value.hasPrefix("@{") && value.hasSuffix("}") { self = .binding; return }
            if !value.hasPrefix("@{") { self = .selector(value); return }
        }
        return nil
    }

    /// Not blank, inside a binding's braces or as a bare name (Unicode white
    /// space is blank) — the Dynamic runtime's TapAccessibility.namesAMethod,
    /// which is built for DEBUG only.
    private static func namesAMethod(_ value: String) -> Bool {
        var inner = Substring(value)
        if inner.hasPrefix("@{") && inner.hasSuffix("}") && inner.count >= 3 {
            inner = inner.dropFirst(2).dropLast()
        }
        return !inner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension SJUILabel {
    /// A linked range for a partialAttributes range with a handler: a selector
    /// range carries its name under "onclick"; a binding range carries none,
    /// and setPartialAttributeOnClick gives it its closure.
    func appendLinkedRange(start: Int, end: Int, handler: PartialRangeHandler?, index: Int) {
        switch handler {
        case .selector(let name)?:
            linkedRanges.append(["start": start, "end": end, "onclick": name, "partialAttributeIndex": index])
        case .binding?:
            linkedRanges.append(["start": start, "end": end, "partialAttributeIndex": index])
        case nil:
            break
        }
    }
}
