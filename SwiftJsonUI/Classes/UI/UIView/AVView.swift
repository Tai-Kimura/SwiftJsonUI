//
//  AVView.swift
//
//  Created by 木村太一朗 on 2015/04/21.
//

import UIKit

import AVFoundation

open class AVView: SJUIView {
    
    override open class var viewClass: SJUIView.Type {
        get {
            return AVView.self
        }
    }
    
    public var player: AVPlayer? {
        get {
            let layer: AVPlayerLayer = self.layer as! AVPlayerLayer
            return layer.player
        }
        set(newValue) {
            let layer: AVPlayerLayer = self.layer as! AVPlayerLayer
            layer.player = newValue
        }
    }

    override open class var layerClass : AnyClass {
        return AVPlayerLayer.self
    }

}
