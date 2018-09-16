//
//  SJUIViewCreator.swift
//
//  Created by 木村太一朗 on 2015/12/26.
//  Copyright © 2015年 木村太一朗 All rights reserved.
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import WebKit

open class SJUIViewCreator:NSObject {
    private static let systemFontString = "SJUI_System_Font"
    public static var defaultFont = SJUIViewCreator.systemFontString
    public static var defaultFontColor = UIColor.black
    public static var defaultHintColor = UIColor.lightGray
    public static var defaultFontSize: CGFloat = 14.0
    public static var findColorFunc: (((Any)) -> UIColor?)?
    
    @discardableResult open class func createView(_ path: String, target: ViewHolder, onView view: UIView? = nil) -> UIView? {
        let url = getURL(path: path)
        
        do {
            let jsonString = try String(contentsOfFile: url, encoding: String.Encoding.utf8)
            let enc:String.Encoding = String.Encoding.utf8
            let json = JSON(data: jsonString.data(using: enc)!)
            
            let parentView:UIView
            if view != nil {
                parentView = view!
            } else if let v = getOnView(target: target) {
                parentView = v
            } else {
                return createView(json, parentView: nil, target: target, views: &target._views)
            }
            return createView(json, parentView: parentView, target: target, views: &target._views)
        } catch let error {
            return createErrorView("\(error)")
        }
        
    }
    
    open class func getOnView(target: ViewHolder) -> UIView? {
        return nil
    }
    
    open class func createErrorView(_ text:String = "JSONの形式が正しくありません") -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let label = UILabel(frame: CGRect(x: 0,y: 0,width: 100,height: 20.0))
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = NSTextAlignment.center
        label.text = text
        label.preferredMaxLayoutWidth = UIScreen.main.bounds.size.width - 40.0
        label.center = view.center
        view.addSubview(label)
        NSLayoutConstraint.activate([NSLayoutConstraint(item: label, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0)])
        NSLayoutConstraint.activate([NSLayoutConstraint(item: label, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0)])
        NSLayoutConstraint.activate([NSLayoutConstraint(item: label, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1.0, constant: 0)])
        label.sizeToFit()
        return view
    }
    
    open class func getURL(path: String) -> String {
        #if DEBUG
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let cachesDirPath = paths[0]
        let layoutFileDirPath = "\(cachesDirPath)/Layouts"
        return layoutFileDirPath + "/\(path).json"
        #else
        return Bundle.main.path(forResource: path, ofType: "json")!
        #endif
    }
    
    @discardableResult open class func createView(_ attr: JSON, parentView: UIView!, target: Any, views: inout [String: UIView]) -> UIView! {
        if let include = attr["include"].string {
            let url = getURL(path: include)
            do {
                var jsonString = try String(contentsOfFile: url, encoding: String.Encoding.utf8)
                if let variables = attr["variables"].array {
                    for variable in variables {
                        if let key = variable["key"].string {
                            if let value = variable["value"].string {
                                jsonString = jsonString.replacingOccurrences(of: key, with: value)
                            } else if let value = variable["value"].int {
                                jsonString = jsonString.replacingOccurrences(of: "\"\(key)\"", with: "\(value)")
                            } else if let value = variable["value"].cgFloat {
                                jsonString = jsonString.replacingOccurrences(of: "\"\(key)\"", with: "\(value)")
                            } else if let value = variable["value"].bool {
                                jsonString = jsonString.replacingOccurrences(of: "\"\(key)\"", with: "\(value)")
                            }
                        }
                    }
                }
                
                let enc:String.Encoding = String.Encoding.utf8
                let json = JSON(data: jsonString.data(using: enc)!)
                return createView(json, parentView: parentView, target: target, views: &views)
            } catch let error {
                return createErrorView("\(error)")
            }
        }
        guard let view = getViewFromJSON(attr: attr, target: target, views: &views) else {
            return createErrorView()
        }
        
        if let tag = attr["tag"].int {
            view.tag = tag
        }
        
        if let shadow = attr["shadow"].string {
            let shadowParam = shadow.components(separatedBy: "|")
            if shadowParam.count == 5 {
                view.layer.shadowColor = UIColor.colorWithHexString(shadowParam[0]).cgColor
                if let offsetX = NumberFormatter().number(from: shadowParam[1]), let offsetY = NumberFormatter().number(from: shadowParam[2]) {
                    view.layer.shadowOffset = CGSize(width: CGFloat(truncating: offsetX), height: CGFloat(truncating: offsetY))
                }
                
                if let opacity = NumberFormatter().number(from: shadowParam[3]) {
                    view.layer.shadowOpacity = Float(truncating: opacity)
                }
                
                if let radius = NumberFormatter().number(from: shadowParam[4]) {
                    view.layer.shadowRadius = CGFloat(truncating: radius)
                }
            }
        } else if !attr["shadow"].isEmpty {
            let shadow = attr["shadow"]
            if let color = UIColor.findColorByJSON(attr: shadow["color"]) {
                view.layer.shadowColor = color.cgColor
            }
            if let offsetX = shadow["offsetX"].cgFloat, let offsetY = shadow["offsetY"].cgFloat {
                view.layer.shadowOffset = CGSize(width: offsetX, height: offsetY)
            }
            
            if let opacity = shadow["opacity"].float {
                view.layer.shadowOpacity = opacity
            }
            
            if let radius = shadow["radius"].cgFloat {
                view.layer.shadowRadius = radius
            }
        }
        if let background = UIColor.findColorByJSON(attr: attr["background"]) {
            view.defaultBackgroundColor = background
            if attr["enabled"].bool ?? true || UIColor.findColorByJSON(attr: attr["disabledBackground"]) == nil {
                view.backgroundColor = background
            }
        }
        if let background = UIColor.findColorByJSON(attr: attr["tapBackground"]) {
            view.tapBackgroundColor = background
        }
        if let cornerRadius = attr["cornerRadius"].cgFloat {
            view.layer.cornerRadius = cornerRadius
        }
        
        if let borderColor = UIColor.findColorByJSON(attr: attr["borderColor"]) {
            view.layer.borderColor = borderColor.cgColor
            let borderWidth = attr["borderWidth"].cgFloat == nil ? 1.0 : attr["borderWidth"].cgFloat!
            view.layer.borderWidth = borderWidth
        }
        if let clip = attr["clipToBounds"].bool {
            view.clipsToBounds = clip
        }
        if let rect = attr["rect"].arrayObject as? [CGFloat] {
            view.translatesAutoresizingMaskIntoConstraints = true
            view.frame = CGRect(x: rect[0], y: rect[1], width: rect[2], height: rect[3])
        } else {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.autoresizingMask = UIViewAutoresizing()
        }
        view.isHidden = attr["hidden"].boolValue
        if let alpha = attr["alpha"].cgFloat {
            view.alpha = alpha
        }
        
        if parentView != nil {
            if let indexBelow = attr["indexBelow"].string, let aboveView = views[indexBelow] {
                parentView.insertSubview(view, belowSubview: aboveView)
            } else if let indexAbove = attr["indexAbove"].string, let belowView = views[indexAbove] {
                parentView.insertSubview(view, aboveSubview: belowView)
            } else {
                parentView.addSubview(view)
            }
        }
        
        let constraintInfo = UILayoutConstraintInfo(toView:views[attr["toView"].stringValue], leftPadding: attr["leftPadding"].cgFloat, rightPadding: attr["rightPadding"].cgFloat, topPadding: attr["topPadding"].cgFloat, bottomPadding: attr["bottomPadding"].cgFloat, minLeftPadding: attr["minLeftPadding"].cgFloat, minRightPadding: attr["minRightPadding"].cgFloat, minTopPadding: attr["minTopPadding"].cgFloat, minBottomPadding: attr["minBottomPadding"].cgFloat, maxLeftPadding: attr["maxLeftPadding"].cgFloat, maxRightPadding: attr["maxRightPadding"].cgFloat, maxTopPadding: attr["maxTopPadding"].cgFloat, maxBottomPadding: attr["maxBottomPadding"].cgFloat, leftMargin: attr["leftMargin"].cgFloat, rightMargin: attr["rightMargin"].cgFloat, topMargin: attr["topMargin"].cgFloat, bottomMargin: attr["bottomMargin"].cgFloat, minLeftMargin: attr["minLeftMargin"].cgFloat, minRightMargin: attr["minRightMargin"].cgFloat, minTopMargin: attr["minTopMargin"].cgFloat, minBottomMargin: attr["minBottomMargin"].cgFloat, maxLeftMargin: attr["maxLeftMargin"].cgFloat, maxRightMargin: attr["maxRightMargin"].cgFloat, maxTopMargin: attr["maxTopMargin"].cgFloat, maxBottomMargin: attr["maxBottomMargin"].cgFloat, centerVertical: attr["centerVertical"].bool, centerHorizontal: attr["centerHorizontal"].bool, alignTop: attr["alignTop"].bool, alignBottom: attr["alignBottom"].bool, alignLeft: attr["alignLeft"].bool, alignRight: attr["alignRight"].bool, alignTopToView: attr["alignTopToView"].bool,alignBottomToView: attr["alignBottomToView"].bool, alignLeftToView: attr["alignLeftToView"].bool, alignRightToView: attr["alignRightToView"].bool, alignCenterVerticalToView: attr["alignCenterVerticalToView"].bool, alignCenterHorizontalToView: attr["alignCenterHorizontalToView"].bool, alignTopOfView: views[attr["alignTopOfView"].stringValue], alignBottomOfView: views[attr["alignBottomOfView"].stringValue], alignLeftOfView: views[attr["alignLeftOfView"].stringValue], alignRightOfView: views[attr["alignRightOfView"].stringValue], alignTopView: views[attr["alignTopView"].stringValue], alignBottomView: views[attr["alignBottomView"].stringValue], alignLeftView: views[attr["alignLeftView"].stringValue], alignRightView: views[attr["alignRightView"].stringValue], alignCenterVerticalView: views[attr["alignCenterVerticalView"].stringValue], alignCenterHorizontalView: views[attr["alignCenterHorizontalView"].stringValue], width: attr["width"].cgFloat, height: attr["height"].cgFloat, minWidth: attr["minWidth"].cgFloat, minHeight: attr["minHeight"].cgFloat, maxWidth: attr["maxWidth"].cgFloat, maxHeight: attr["maxHeight"].cgFloat, widthWeight: attr["widthWeight"].cgFloat, heightWeight: attr["heightWeight"].cgFloat, aspectWidth: attr["aspectWidth"].cgFloat, aspectHeight: attr["aspectHeight"].cgFloat, maxWidthWeight: attr["maxWidthWeight"].cgFloat, maxHeightWeight: attr["maxHeightWeight"].cgFloat, minWidthWeight: attr["minWidthWeight"].cgFloat, minHeightWeight: attr["minHeightWeight"].cgFloat)
        
        UIViewDisposure.applyConstraint(onView: view, toConstraintInfo: constraintInfo)
        
        if let id = attr["id"].string {
            views[id] = view
            view.propertyName = id.toCamel()
        }
        if let propertyName = attr["propertyName"].string {
            view.propertyName = propertyName
        }
        if let binding = attr["binding"].string {
            view.binding = binding
        }
        
        if let children = attr["child"].array {
            for child in children {
                createView(child, parentView: view, target: target, views: &views)
            }
        }
        
        if let wrapContent = attr["wrapContent"].bool {
            if wrapContent {
                var paddings:[CGFloat] = [0,0,25.0,0]
                var edgeInsets = [CGFloat]()
                if let paddingStr = attr["innerPadding"].string {
                    let paddingStars = paddingStr.components(separatedBy: "|")
                    for p in paddingStars {
                        if let n = NumberFormatter().number(from: p) {
                            edgeInsets.append(CGFloat(truncating: n))
                        }
                    }
                } else if let padding = attr["innerPadding"].arrayObject as? [CGFloat] {
                    edgeInsets = padding
                }
                
                switch (edgeInsets.count) {
                case 0:
                    break
                case 1:
                    paddings = [edgeInsets[0], edgeInsets[0], edgeInsets[0], edgeInsets[0]]
                case 2:
                    paddings = [edgeInsets[0], edgeInsets[1], edgeInsets[0], edgeInsets[1]]
                case 3:
                    paddings = [edgeInsets[0], edgeInsets[1], edgeInsets[2], edgeInsets[1]]
                default:
                    paddings = [edgeInsets[0], edgeInsets[1], edgeInsets[2], edgeInsets[3]]
                }
                
                if let keyBottomView = attr["keyBottomView"].string {
                    let keyViews = keyBottomView.components(separatedBy: ",")
                    for keyView in keyViews {
                        if let v = views[keyView] {
                            NSLayoutConstraint.activate([NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: v, attribute: .bottom, multiplier: 1.0, constant: paddings[2])])
                        }
                    }
                } else if let keyViews = attr["keyBottomView"].arrayObject as? [String] {
                    for keyView in keyViews {
                        if let v = views[keyView] {
                            NSLayoutConstraint.activate([NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: v, attribute: .bottom, multiplier: 1.0, constant: paddings[2])])
                        }
                    }
                } else if let lastView = view.subviews.last, let view = (view as? SJUIView), let orientation = view.orientation, orientation == .vertical, view.direction == .topToBottom {
                    NSLayoutConstraint.activate([NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: lastView, attribute: .bottom, multiplier: 1.0, constant: paddings[2])])
                }
                
                if let keyTopView = attr["keyTopView"].string {
                    let keyViews = keyTopView.components(separatedBy: ",")
                    for keyView in keyViews {
                        if let v = views[keyView] {
                            NSLayoutConstraint.activate([NSLayoutConstraint(item: view, attribute: .top, relatedBy: NSLayoutRelation.equal, toItem: v, attribute: .top, multiplier: 1.0, constant: -paddings[0])])
                        }
                    }
                } else if let keyViews = attr["keyTopView"].arrayObject as? [String] {
                    for keyView in keyViews {
                        if let v = views[keyView] {
                            NSLayoutConstraint.activate([NSLayoutConstraint(item: view, attribute: .top, relatedBy: NSLayoutRelation.equal, toItem: v, attribute: .top, multiplier: 1.0, constant: -paddings[0])])
                        }
                    }
                } else if let lastView = view.subviews.last, let view = (view as? SJUIView), let orientation = view.orientation, orientation == .vertical, view.direction == .bottomToTop {
                    NSLayoutConstraint.activate([NSLayoutConstraint(item: view, attribute: .top, relatedBy: NSLayoutRelation.equal, toItem: lastView, attribute: .top, multiplier: 1.0, constant: -paddings[0])])
                }
                
                if let keyLeftView = attr["keyLeftView"].string {
                    let keyViews = keyLeftView.components(separatedBy: ",")
                    for keyView in keyViews {
                        if let v = views[keyView] {
                            NSLayoutConstraint.activate([NSLayoutConstraint(item: view, attribute: .left, relatedBy: NSLayoutRelation.equal, toItem: v, attribute: .left, multiplier: 1.0, constant: -paddings[1])])
                        }
                    }
                } else if let keyViews = attr["keyLeftView"].arrayObject as? [String] {
                    for keyView in keyViews {
                        if let v = views[keyView] {
                            NSLayoutConstraint.activate([NSLayoutConstraint(item: view, attribute: .left, relatedBy: NSLayoutRelation.equal, toItem: v, attribute: .left, multiplier: 1.0, constant: -paddings[1])])
                        }
                    }
                } else if let lastView = view.subviews.last, let view = (view as? SJUIView), let orientation = view.orientation, orientation == .horizontal, view.direction == .rightToLeft {
                    NSLayoutConstraint.activate([NSLayoutConstraint(item: view, attribute: .left, relatedBy: NSLayoutRelation.equal, toItem: lastView, attribute: .left, multiplier: 1.0, constant: -paddings[1])])
                }
                
                if let keyRightView = attr["keyRightView"].string {
                    let keyViews = keyRightView.components(separatedBy: ",")
                    for keyView in keyViews {
                        if let v = views[keyView] {
                            NSLayoutConstraint.activate([NSLayoutConstraint(item: view, attribute: .right, relatedBy: NSLayoutRelation.equal, toItem: v, attribute: .right, multiplier: 1.0, constant: paddings[3])])
                        }
                    }
                } else if let keyViews = attr["keyRightView"].arrayObject as? [String] {
                    for keyView in keyViews {
                        if let v = views[keyView] {
                            NSLayoutConstraint.activate([NSLayoutConstraint(item: view, attribute: .right, relatedBy: NSLayoutRelation.equal, toItem: v, attribute: .right, multiplier: 1.0, constant: paddings[3])])
                        }
                    }
                } else if let lastView = view.subviews.last, let view = (view as? SJUIView), let orientation = view.orientation, orientation == .horizontal, view.direction == .leftToRight {
                    NSLayoutConstraint.activate([NSLayoutConstraint(item: view, attribute: .right, relatedBy: NSLayoutRelation.equal, toItem: lastView, attribute: .right, multiplier: 1.0, constant: paddings[3])])
                }
            }
        }
        return view
    }
    
    open class func copyResourcesToDocuments() {
        #if DEBUG
        let fm = FileManager.default
        let bundlePath = Bundle.main.bundlePath
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let cachesDirPath = paths[0]
        let layoutFileDirPath = "\(cachesDirPath)/Layouts"
        do {
            if (!fm.fileExists(atPath: layoutFileDirPath)) {
                try fm.createDirectory(atPath: layoutFileDirPath, withIntermediateDirectories: false, attributes: nil)
            }
            
            let contents = try fm.contentsOfDirectory(atPath: bundlePath)
            for content:String in contents {
                if (content.hasSuffix("json")) {
                    let toPath = "\(layoutFileDirPath)/\(content)"
                    if (fm.fileExists(atPath: toPath)) {
                        try fm.removeItem(atPath: toPath)
                    }
                    try fm.copyItem(atPath: "\(bundlePath)/\(content)", toPath:toPath)
                }
            }
        } catch let error {
            print("\(error)")
        }
        #endif
    }
    
    open class func getViewFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> UIView? {
        let view: UIView
        switch(attr["type"].stringValue) {
        case "View":
            view = SJUIView.createFromJSON(attr: attr, target: target, views: &views)
        case "GradientView":
            view = GradientView.createFromJSON(attr: attr, target: target, views: &views)
        case "Blur":
            view = SJUIVisualEffectView.createFromJSON(attr: attr, target: target, views: &views)
        case "CircleView":
            view = SJUICircleView.createFromJSON(attr: attr, target: target, views: &views)
        case "Scroll":
            view = SJUIScrollView.createFromJSON(attr: attr, target: target, views: &views)
        case "Table":
            view = SJUITableView.createFromJSON(attr: attr, target: target, views: &views)
        case "Collection":
            view = SJUICollectionView.createFromJSON(attr: attr, target: target, views: &views)
        case "Segment":
            view = SJUISegmentedControl.createFromJSON(attr: attr, target: target, views: &views)
        case "Label":
            view = SJUILabel.createFromJSON(attr: attr, target: target, views: &views)
        case "IconLabel":
            view = SJUILabelWithIcon.createFromJSON(attr: attr, target: target, views: &views)
            break
        case "Button":
            view = SJUIButton.createFromJSON(attr: attr, target: target, views: &views)
        case "Image":
            view = SJUIImageView.createFromJSON(attr: attr, target: target, views: &views)
        case "NetworkImage":
            view = NetworkImageView.createFromJSON(attr: attr, target: target, views: &views)
        case "CircleImage":
            view = CircleImageView.createFromJSON(attr: attr, target: target, views: &views)
        case "Web":
            let w = WKWebView()
            view = w
        case "TextField":
            view = SJUITextField.createFromJSON(attr: attr, target: target, views: &views)
            break
        case "TextView":
            view = SJUITextView.createFromJSON(attr: attr, target: target, views: &views)
            break
        case "Switch":
            view = SJUISwitch.createFromJSON(attr: attr, target: target, views: &views)
            break
        case "Radio":
            view = SJUIRadioButton.createFromJSON(attr: attr, target: target, views: &views)
            break
        case "Check":
            view = SJUICheckBox.createFromJSON(attr: attr, target: target, views: &views)
            break
        case "Progress":
            let v = UIProgressView()
            if let tintColor = UIColor.findColorByJSON(attr: attr["tintColor"]) {
                v.tintColor = tintColor
            }
            view = v
        case "Slider":
            let v = UISlider()
            if let tintColor = UIColor.findColorByJSON(attr: attr["tintColor"]) {
                v.tintColor = tintColor
            }
            view = v
        case "SelectBox":
            view = SJUISelectBox.createFromJSON(attr: attr, target: target, views: &views)
        case "Indicator":
            let style: UIActivityIndicatorViewStyle
            switch attr["style"].stringValue {
            case "White":
                style = .white
            case "WhiteLarge":
                style = .whiteLarge
            case "Gray":
                style = .gray
            default:
                style = .white
            }
            let i = UIActivityIndicatorView(activityIndicatorStyle: style)
            view = i
        default:
            return nil
        }
        return view
    }
    
    open class func getLayoutFileDirPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let cachesDirPath = paths[0]
        return "\(cachesDirPath)/Layouts"
    }
    
    public class func getViewJSON(path: String) -> JSON? {
        let url = getURL(path: path)
        do {
            let jsonString = try String(contentsOfFile: url, encoding: String.Encoding.utf8)
            let enc:String.Encoding = String.Encoding.utf8
            let json = JSON(data: jsonString.data(using: enc)!)
            return json
        } catch let error {
            print("JSON encoding error \(error)")
            return nil
        }
    }
    
    public class func findViewJSON(byId viewId: String, inJSON json: JSON) -> JSON? {
        if let vId = json["id"].string {
            if viewId == vId {
                return json
            }
        }
        if let children = json["child"].array {
            for child in children {
                if let json = findViewJSON(byId: viewId, inJSON: child) {
                    return json
                }
            }
        }
        return nil
    }
    
}

public protocol ViewHolder: class {
    var _views: [String:UIView]
    {
        get
        set
    }
}


