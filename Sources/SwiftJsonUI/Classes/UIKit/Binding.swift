//
//  Binding.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2018/09/16.
//

import UIKit

@MainActor
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
                for property in properties {
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
    
    open func bindView() {
        if let views = _viewHolder?._views {
            for v in views.values {
                if let propertyName = v.propertyName, let index = properties.firstIndex(of: propertyName) {
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
                    label.linkable ? label.applyLinkableAttributedText(text) : label.applyAttributedText(text)
                } else if let textField = v as? UITextField {
                    textField.text = text
                } else if let textView = v as? UITextView {
                    textView.text = text
                } else if let selectBox = v as? SJUISelectBox, let index = selectBox.items.firstIndex(of: text) {
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
        } else if let model = data as? DataBindingModel, let value = model[binding] {
            return value
        } else if let array = data as? [Any], let index = Int(binding) {
            return array[index]
        } else if let array = data as? [String], let index = array.firstIndex(of: binding) {
            return array[index]
        } else if let object = data as? NSObject {
            return object.value(forKey: binding)
        }
        return nil
    }
    
    private lazy var properties: [String] = {[weak self, weak _viewHolder] in
        var properties = [String]()
        let viewHolder = _viewHolder
        if let weakSelf = self {
            weakSelf._viewHolder = nil
            var mirror = Mirror(reflecting: weakSelf)
            while mirror.subjectType is Binding.Type {
                for child in mirror.children {
                    if let label = child.label {
                        properties.append( label)
                    }
                }
                guard let sMirror = mirror.superclassMirror, let t = sMirror.subjectType as? Binding.Type else {
                    break
                }
                mirror = sMirror
            }
            weakSelf._viewHolder = viewHolder
        }
        return properties
        }()
    
    override open func setValue(_ value: Any?, forUndefinedKey key: String) {
        Logger.debug("key not found \(key)")
    }
    
    open override func value(forUndefinedKey key: String) -> Any? {
        Logger.debug("key not found \(key)")
        return nil
    }
    
    private class DummyViewHolder: ViewHolder {
        var _views =  [String : UIView]()
    }
}
