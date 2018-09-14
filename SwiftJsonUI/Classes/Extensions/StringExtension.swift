//
//  StringExtension.swift
//
//  Created by 木村太一朗 on 2016/07/04.
//

import Foundation

public extension String {
    public func katakana() -> String {
        var str = ""
        
        // 文字列を表現するUInt32
        for c in unicodeScalars {
            if c.value >= 0x3041 && c.value <= 0x3096 {
                str.append(String(describing: UnicodeScalar(c.value+96)))
            } else {
                str.append(String(c))
            }
        }
        print("str: \(str), Self: \(self)")
        return str
    }
    
    public func hiragana() -> String {
        var str = ""
        for c in self.unicodeScalars {
            if c.value >= 0x30A1 && c.value <= 0x30F6 {
                if let hiragana = UnicodeScalar(c.value-96) {
                    str.append(String(hiragana))
                    continue
                }
            }
            str.append(String(c))
        }
        return str
    }
    
    // マッチした数を返す
    public func getMatchCount(pattern: String) -> Int {
        
        do {
            
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let targetStringRange = NSRange(location: 0, length: (self as NSString).length)
            
            return regex.numberOfMatches(in: self, options: [], range: targetStringRange)
            
        } catch {
            print("error: getMatchCount")
        }
        return 0
    }
    
    func isMatch(pattern: String) -> Bool {
        return getMatchCount(pattern: pattern) > 0
    }
    
    public func getFormattedZipcode() -> String {
        var t = ""
        let text = self
        var substrStartIndex = text.index(text.startIndex, offsetBy: 0)
        var substrEndIndex = text.index(text.startIndex, offsetBy: 0)
        if text.count > 3 {
            substrStartIndex = text.index(text.startIndex, offsetBy: 0)
            substrEndIndex = text.index(text.startIndex, offsetBy: 3)
            t+=String(text[substrStartIndex..<substrEndIndex])
            t+="-"
            substrStartIndex = text.index(text.startIndex, offsetBy: 3)
            substrEndIndex = text.endIndex
            t+=String(text[substrStartIndex..<substrEndIndex])
        } else {
            t+=text
        }
        return t
    }
    
    public func toDate(format: String = "yyyy/MM/dd HH:mm:ss") -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: self)
    }
}
