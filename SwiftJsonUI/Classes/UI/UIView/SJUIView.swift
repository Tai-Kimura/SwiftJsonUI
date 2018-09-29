//
//  SJUIView.swift
//
//  Created by 木村太一朗 on 2016/01/25.
//  Copyright © 2016年 木村太一朗 All rights reserved.
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

open class SJUIView: UIView, UIGestureRecognizerDelegate, ViewHolder {
    public var _views: [String:UIView] = [String:UIView]()
    
    open class var viewClass: SJUIView.Type {
        get {
            return SJUIView.self
        }
    }
    
    public var bottomContentView:UIView!
    
    public var highlightBackgroundColor: UIColor?
    
    public var highlighted: Bool = false
    
    public  var canTap = false
    
    public  var touchDisabledState: TouchDisabledState = .none
    
    public  lazy var touchEnabledViewIds =  [String]()
    
    public var orientation: Orientation?
    
    public var direction: Direction = .none
    
    public var gravity: [SJUIView.Gravity:Bool]? {
        get {
            return self.constraintInfo?.gravities
        }
        set {
            if let gravity = newValue, let orientaiton = orientation {
                self.constraintInfo?.gravities = gravity
                for subview in self.subviews {
                    if let info = subview.constraintInfo {
                        if info.alignTop == nil && info.alignBottom == nil {
                            info.alignTop = gravity[.top]
                            info.alignBottom = gravity[.bottom]
                        }
                        if info.alignLeft == nil && info.alignRight == nil {
                            info.alignLeft = gravity[.left]
                            info.alignRight = gravity[.right]
                        }
                        switch orientaiton {
                        case .vertical:
                            if info.centerHorizontal == nil && info.alignLeft == nil && info.alignRight == nil {
                                info.centerHorizontal = gravity[.centerHorizontal]
                            }
                        case .horizontal:
                            if info.centerVertical == nil && info.alignTop == nil && info.alignBottom == nil {
                                info.centerVertical = gravity[.centerVertical]
                            }
                        }
                    }
                }
            }
        }
    }
    open override func didAddSubview(_ subview: UIView) {
        if self.isActiveForConstraint {
            Logger.debug("Update Constraint")
            self.resetConstraintInfo()
        }
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view = super.hitTest(point, with: event) else {
            return nil
        }
        switch self.touchDisabledState {
        case .none:
            return view
        case .onlyMe:
            return view == self ? nil : view
        case .viewsWithoutTouchEnabled:
            return view != self && view.isUserInteractionEnabled ? view : nil
        case .viewsWithoutInList:
            if let viewId = view.viewId, view != self, touchEnabledViewIds.firstIndex(of: viewId) != nil {
                return view
            }
            return nil
        }
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: self) {
            if location.x >= 0 && location.x <= self.frame.size.width && location.y >= 0 && location.y <= self.frame.size.height {
                onBeginTap()
            }
        }
        super.touchesBegan(touches, with: event)
        
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        onEndTap()
        super.touchesCancelled(touches, with: event)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        onEndTap()
        super.touchesEnded(touches, with: event)
    }
    
    @objc override public func onBeginTap() {
        if canTap {
            if tapBackgroundColor != nil {
                self.backgroundColor = tapBackgroundColor
            }
        }
    }
    
    @objc override public func onEndTap() {
        if canTap {
            if highlighted {
                let color = highlightBackgroundColor ?? defaultBackgroundColor
                if color != nil {
                    self.backgroundColor = color
                }
            } else {
                if defaultBackgroundColor != nil {
                    self.backgroundColor = defaultBackgroundColor
                }
            }
        }
    }
    
    public func addSubViewWith(json: JSON, target: Any, withCreatorClass creator: SJUIViewCreator.Type = SJUIViewCreator.self) {
        creator.createView(json, parentView: self, target: target, views: &_views, isRootView: true)
    }
    
    public class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUIView {
        let v: SJUIView
        switch attr["type"].stringValue {
        case "GradientView":
            v = GradientView()
        default:
            v = viewClass.init()
        }
        if let orientation = attr["orientation"].string {
            v.orientation = Orientation(rawValue: orientation)
            if let orientation = v.orientation {
                switch orientation {
                case .vertical:
                    let d = Direction(rawValue: attr["direction"].stringValue) ?? .topToBottom
                    switch d {
                    case .bottomToTop:
                        v.direction = d
                    default:
                        v.direction = .topToBottom
                    }
                case .horizontal:
                    let d = Direction(rawValue: attr["direction"].stringValue) ?? .leftToRight
                    switch d {
                    case .rightToLeft:
                        v.direction = d
                    default:
                        v.direction = .leftToRight
                    }
                }
            }
        }
        if let background = UIColor.findColorByJSON(attr: attr["highlightBackground"]) {
            v.highlightBackgroundColor = background
        }
        v.highlighted = attr["highlighted"].boolValue
        if v.highlighted && v.highlightBackgroundColor != nil {
            v.backgroundColor = v.highlightBackgroundColor
        }
        if let onclick = attr["onclick"].string {
            let gr = UITapGestureRecognizer(target: target, action: Selector(onclick))
            v.addGestureRecognizer(gr)
            gr.delegate = v
            v.isUserInteractionEnabled = true
            v.canTap = true
        }
        if let canTap = attr["canTap"].bool {
            v.canTap = canTap
        }
        if let state = TouchDisabledState(rawValue: attr["touchDisabledState"].stringValue) {
            v.touchDisabledState = state
            if let viewIds = attr["touchEnabledViewIds"].arrayObject as? [String], state == .viewsWithoutInList {
                v.touchEnabledViewIds = viewIds
            }
        }
        if let v = v as? GradientView, let gradient = attr["gradient"].arrayObject, let layer = v.layer as? CAGradientLayer {
            switch attr["gradientDirection"].stringValue {
            case "Vertical":
                layer.startPoint = CGPoint(x: 0, y: 0)
                layer.endPoint = CGPoint(x: 0, y: 1.0)
            case "Horizontal":
                layer.startPoint = CGPoint(x: 1, y: 0)
                layer.endPoint = CGPoint(x: 0, y: 0)
            case "Oblique":
                layer.startPoint = CGPoint(x: 1, y: 0)
                layer.endPoint = CGPoint(x: 0, y: 1)
            default:
                break
            }
            var colors = [CGColor]()
            for g in gradient {
                if let g = g as? String, let color = UIColor.colorWithHexString(g)?.cgColor {
                    colors.append(color)
                } else if let g = g as? Int, let closure = SJUIViewCreator.findColorFunc, let color = closure(g)?.cgColor {
                    colors.append(color)
                }
            }
            if let locations = attr["locations"].arrayObject as? [Float] {
                var locationNumbers = [NSNumber]()
                for l in locations {
                    locationNumbers.append(NSNumber(value: l))
                }
                layer.locations = locationNumbers
            }
            if !colors.isEmpty {
                layer.colors = colors
            }
        }
        if let events = attr["events"].array {
            for event in events {
                if let eventType = ScriptModel.EventType(rawValue: event["eventType"].stringValue), let selectorForEvent = event["selector"].string {
                    switch eventType {
                    case .onclick:
                        let gr = UITapGestureRecognizer(target: target, action: Selector(selectorForEvent))
                        v.addGestureRecognizer(gr)
                        gr.delegate = v
                        v.isUserInteractionEnabled = true
                        v.canTap = true
                    case .onlongtap:
                        let gr = UILongPressGestureRecognizer(target: target, action: Selector(selectorForEvent))
                        v.addGestureRecognizer(gr)
                        gr.delegate = v
                        v.isUserInteractionEnabled = true
                        v.canTap = true
                    case .pan:
                        let gr = UIPanGestureRecognizer(target: target, action: Selector(selectorForEvent))
                        v.addGestureRecognizer(gr)
                        gr.delegate = v
                        v.isUserInteractionEnabled = true
                    case .swipe:
                        if let directions = event["directions"].arrayObject as? [String] {
                            for direction in directions {
                                let d: UISwipeGestureRecognizerDirection
                                switch direction {
                                case "left":
                                    d = .left
                                case "right":
                                    d = .right
                                case "down":
                                    d = .down
                                case "up":
                                    d = .up
                                default:
                                    continue
                                }
                                let gr = UISwipeGestureRecognizer(target: target, action: Selector(selectorForEvent))
                                v.addGestureRecognizer(gr)
                                gr.delegate = v
                                gr.direction = d
                                v.isUserInteractionEnabled = true
                            }
                        }
                    case .rotate:
                        let gr = UIRotationGestureRecognizer(target: target, action: Selector(selectorForEvent))
                        v.addGestureRecognizer(gr)
                        gr.delegate = v
                        v.isUserInteractionEnabled = true
                    default:
                        break
                    }
                }
            }
        }
        return v
    }
    
    public enum Orientation: String {
        case vertical = "vertical"
        case horizontal = "horizontal"
    }
    
    public enum Direction: String {
        case none = "none"
        case topToBottom = "topToBottom"
        case leftToRight = "leftToRight"
        case bottomToTop = "bottomToTop"
        case rightToLeft = "rightToLeft"
    }
    
    public enum Gravity: String {
        case top = "top"
        case left = "left"
        case bottom = "bottom"
        case right = "right"
        case centerVertical = "centerVertical"
        case centerHorizontal = "centerHorizontal"
    }
    public enum Visibility: String {
        case visible = "visible"
        case invisible = "invisible"
        case gone = "gone"
    }
    
    public enum TouchDisabledState: String {
        case none = "none"
        case onlyMe = "onlyMe"
        case viewsWithoutTouchEnabled = "viewsWithoutTouchEnabled"
        case viewsWithoutInList = "viewsWithoutInList"
    }
}


