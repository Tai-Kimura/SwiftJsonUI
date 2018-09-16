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
        let properties = getProperties()
        if let views = _viewHolder?._views {
            for v in views.values {
                if let propertyName = v.propertyName, let index = properties.index(of: propertyName) {
                    let property = properties[index]
                    self.setValue(v, forKeyPath: property)
                }
            }
        }
    }
    
    private func getProperties() -> [String] {
        var mirror = Mirror(reflecting: self)
        var properties = mirror.children.filter{$0.label != nil}.map{$0.label}
        while let sMirror = mirror.superclassMirror, sMirror.subjectType is Binding.Type {
            properties.append(contentsOf: sMirror.children.filter{$0.label != nil}.map{$0.label})
            mirror = sMirror
        }
        return properties as! [String]
    }
    
    override open func setValue(_ value: Any?, forUndefinedKey key: String) {
        print("key not found \(key)")
    }
}
