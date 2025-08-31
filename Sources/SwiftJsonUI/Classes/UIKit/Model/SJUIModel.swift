//
//  SJUIModel.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2018/09/12.


import UIKit

@objcMembers
open class SJUIModel: NSObject {
    
    open var _json: JSON
    
    public var selected: Bool = false
    
    public init(json: JSON) {
        _json = json
    }
    
    open override func value(forUndefinedKey key: String) -> Any? {
        Logger.debug("key（\(key)）is undefined.")
        return nil
    }
}
