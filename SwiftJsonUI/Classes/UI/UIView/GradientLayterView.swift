//
//  GradientFilterView.swift
//
//  Created by 木村太一朗 on 2016/11/17.
//

import UIKit

class GradientView: SJUIView {
    
    override public class var layerClass : AnyClass {
        return CAGradientLayer.self
    }
}
