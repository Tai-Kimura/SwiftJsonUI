//
//  UIButtonExtension.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2016/01/08.


import UIKit

extension UIButton {
    
    override open var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                if self.tapBackgroundColor != nil {
                    self.backgroundColor = tapBackgroundColor
                }
            } else {
                if self.defaultBackgroundColor != nil {
                    self.backgroundColor = defaultBackgroundColor
                }
            }
        }
    }
    
}
