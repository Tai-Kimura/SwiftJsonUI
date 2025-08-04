//
//  SJUIScrollView.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2018/09/13.

import UIKit

open class SJUIScrollView: UIScrollView {
    
    open class var viewClass: SJUIScrollView.Type {
        get {
            return SJUIScrollView.self
        }
    }

    open class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUIScrollView {
        let s = viewClass.init()
        s.showsHorizontalScrollIndicator = attr["showsHorizontalScrollIndicator"].boolValue
        s.showsVerticalScrollIndicator = attr["showsVerticalScrollIndicator"].boolValue
        s.delegate = target as? UIScrollViewDelegate
        if #available(iOS 11.0, *) {
            if let contentInsetAdjustmentBehavior = attr["contentInsetAdjustmentBehavior"].string {
                switch contentInsetAdjustmentBehavior {
                case "automatic":
                    s.contentInsetAdjustmentBehavior = .automatic
                case "always":
                    s.contentInsetAdjustmentBehavior = .always
                case "never":
                    s.contentInsetAdjustmentBehavior = .never
                case "scrollableAxes":
                    s.contentInsetAdjustmentBehavior = .scrollableAxes
                default:
                    s.contentInsetAdjustmentBehavior = .never
                }
            }
        }
        if let maximumZoomScale = attr["maxZoom"].cgFloat {
            s.maximumZoomScale = maximumZoomScale
        }
        if let minimumZoomScale = attr["minZoom"].cgFloat {
            s.minimumZoomScale = minimumZoomScale
        }
        if let onclick = attr["onclick"].string {
            let gr = UITapGestureRecognizer(target: target, action: Selector(onclick))
            s.addGestureRecognizer(gr)
        }
        if let cornerRadius = attr["cornerRadius"].cgFloat {
            s.layer.cornerRadius = cornerRadius
        }
        
        if let paging = attr["paging"].bool {
            s.isPagingEnabled = paging
        }
        
        if let bounces = attr["bounces"].bool {
            s.bounces = bounces
        }
        
        if let scroll = attr["scrollEnabled"].bool {
            s.isScrollEnabled = scroll
        }
        return s
    }

}
