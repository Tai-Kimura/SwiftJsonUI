//
//  SJUIScrollView.swift
//  SwiftJsonUI
//
//  Created by 木村太一朗 on 2018/09/13.
//  Copyright © 2018年 TANOSYS, LLC. All rights reserved.
//

import UIKit

public class SJUIScrollView: UIScrollView {

    public class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUIScrollView {
        let s = SJUIScrollView()
        s.showsHorizontalScrollIndicator = attr["showsHorizontalScrollIndicator"].boolValue
        s.showsVerticalScrollIndicator = attr["showsVerticalScrollIndicator"].boolValue
        s.delegate = target as? UIScrollViewDelegate
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
