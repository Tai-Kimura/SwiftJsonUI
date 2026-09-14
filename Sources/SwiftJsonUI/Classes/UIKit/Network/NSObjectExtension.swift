//
//  NSObjectExtension.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2016/09/30.
//

import UIKit


// `@retroactive`: NSObject and CAAnimationDelegate both belong to other modules, so
// this conformance is declared by neither owner. The attribute states that
// deliberately. It changes what the COMPILER is told, not what runs — if ObjectiveC
// ever declares the conformance itself, the clash is identical with or without it.
extension NSObject: @retroactive CAAnimationDelegate {
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        
    }
    
    public func animationDidStart(_ theAnimation: CAAnimation) {
        
    }
}
