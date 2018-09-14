//
//  GradientFilterView.swift
//
//  Created by 木村太一朗 on 2016/11/17.
//

import UIKit

open class GradientView: SJUIView {
    
    override open class var viewClass: SJUIView.Type {
        get {
            return GradientView.self
        }
    }
    
    override open class var layerClass : AnyClass {
        return CAGradientLayer.self
    }
}
