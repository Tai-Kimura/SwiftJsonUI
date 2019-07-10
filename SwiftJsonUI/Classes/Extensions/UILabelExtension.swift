//
//  UILabelExtension.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2016/01/25.

import UIKit

public extension UILabel {
    func lineNumber() -> Int {
        let oneLineRect  =  "a".boundingRect(with: self.bounds.size, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: self.font], context: nil)
        let boundingRect = self.text!.boundingRect(with: self.bounds.size, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: self.font], context: nil)
        
        return Int(boundingRect.height / oneLineRect.height)
    }
}
