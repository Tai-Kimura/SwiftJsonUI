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
    
    public var data: Any? = nil {
        didSet {
            if let data = data {
                for property in getProperties() {
                    if let v = value(forKey: property) as? UIView {
                        if let binding = v.binding {
                            bindData(data: data, view: v, binding: binding)
                        } else if let bindingSet = v.bindingSet, let binding = bindingSet[String(describing: type(of: data)).toSnake()] {
                            bindData(data: data, view: v, binding: binding)
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
    
    private func bindData(data: Any, view v: UIView, binding: String) {
        let bindings = binding.components(separatedBy: ".")
        if let b = bindings.first {
            let fetchedValue = fetchValue(data: data, binding: b)
            if let text = fetchedValue as? String {
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
            } else if let date = fetchedValue as? Date, let selectBox = v as? SJUISelectBox {
                selectBox.selectedDate = date
            } else if let index = fetchedValue as? Int, let selectBox = v as? SJUISelectBox {
                selectBox.selectedIndex = selectBox.hasPrompt && !selectBox.includePromptWhenDataBinding ? index + 1 : index
            } else if let image = fetchedValue as? UIImage, let imageView = v as? UIImageView {
                if let circleImageView = imageView as? CircleImageView {
                    circleImageView.setImageResource(image.circularScaleAndCropImage())
                } else if let networkImageView = imageView as? NetworkImageView {
                    networkImageView.setImageResource(image)
                } else {
                    imageView.image = image
                }
            } else if let boolValue = fetchedValue as? Bool, let checkbox = v as? SJUICheckBox {
                checkbox.isSelected = boolValue
            } else if let object = fetchedValue, bindings.count > 1 {
                let nextBinding = binding.replacingOccurrences(of: "^\(b)\\.", with: "", options: .regularExpression, range: nil)
                bindData(data: object, view: v, binding: nextBinding)
            }
        }
    }
    
    private func fetchValue(data: Any, binding: String) -> Any? {
        if let dictionary = data as? [String:Any] {
            return dictionary[binding]
        } else if let array = data as? [Any], let index = Int(binding) {
            return array[index]
        } else if let array = data as? [String], let index = array.index(of: binding) {
            return array[index]
        } else if let object = data as? NSObject {
            return object.value(forKey: binding)
        }
        return nil
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
    
    open override func value(forUndefinedKey key: String) -> Any? {
        print("key not found \(key)")
        return nil
    }
}
