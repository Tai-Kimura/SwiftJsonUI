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
    
    public var data: NSObject? = nil {
        didSet {
            if let data = data, let views = _viewHolder?._views {
                for v in views.values {
                    if let binding = v.binding {
                        if let text = data.value(forKey: binding) as? String {
                            if let label = v as? SJUILabel {
                                label.applyAttributedText(text)
                            } else if let textField = v as? UITextField {
                                textField.text = text
                            } else if let textView = v as? UITextView {
                                textView.text = text
                            } else if let selectBox = v as? SJUISelectBox, let index = selectBox.items.index(of: text) {
                                selectBox.selectedIndex = index
                            } else if let networkImageView = v as? NetworkImageView {
                                networkImageView.setImageURL(string: text)
                            }
                        } else if let date = data.value(forKey: binding) as? Date, let selectBox = v as? SJUISelectBox {
                            selectBox.selectedDate = date
                        } else if let index = data.value(forKey: binding) as? Int, let selectBox = v as? SJUISelectBox {
                            selectBox.selectedIndex = index
                        } else if let image = data.value(forKey: binding) as? UIImage, let imageView = v as? UIImageView {
                            if let circleImageView = imageView as? CircleImageView {
                                circleImageView.setImageResource(image.circularScaleAndCropImage())
                            } else if let networkImageView = imageView as? NetworkImageView {
                                networkImageView.setImageResource(image)
                            } else {
                                imageView.image = image
                            }
                        }
                    }
                }
            }
        }
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
