//
//  ScriptModel.swift
//  Pods
//
//  Created by 木村太一朗 on 2018/09/28.
//

import UIKit
public struct ScriptModel {
    public let type: ScriptType
    public let value: String
    init(type: ScriptType, value: String) {
        self.type = type
        self.value = value
    }
    public enum ScriptType: String {
        case string = "string"
        case file = "file"
    }
    
    public enum EventType: String {
        case onclick = "onclick"
        case onlongtap = "onlongtap"
        case pan = "pan"
        case swipe = "swipe"
        case rotate = "rotate"
        case scroll = "scroll"
    }
}

