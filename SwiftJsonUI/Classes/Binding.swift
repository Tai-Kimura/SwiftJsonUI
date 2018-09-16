//
//  Binding.swift
//  Pods
//
//  Created by 木村太一朗 on 2018/09/16.
//

import UIKit

@objcMembers
open class Binding: NSObject {
    private weak var _viewHolder: ViewHolder?
    
    required public init(viewHolder: ViewHolder) {
        super.init()
        self._viewHolder = viewHolder
    }
    
    public func bindView() {
        let mirror = Mirror(reflecting: self)
        let properties = mirror.children.filter{$0.label != nil}.map{$0.label}
        if let views = _viewHolder?._views {
            for v in views.values {
                if let propertyName = v.propertyName, let index = properties.index(of: propertyName), let property = properties[index] {
                    self.setValue(v, forKeyPath: property)
                }
            }
        }
    }
    
    override open func setValue(_ value: Any?, forUndefinedKey key: String) {
        print("key not found \(key)")
    }
}
