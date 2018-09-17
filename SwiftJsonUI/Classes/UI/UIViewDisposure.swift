//
//  UIViewDisposure.swift
//
//  Created by 木村太一朗 on 2015/12/25.
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
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


open class UIViewDisposure {
    
    static let screenSize = UIScreen.main.bounds.size
    
    public class func applyConstraint(onView view: UIView, toConstraintInfo info: inout UILayoutConstraintInfo) {
        var constraints = [NSLayoutConstraint]()
        //親ビューに対して
        if let superview = view.superview {
            if let linearView = superview as? SJUIView, let orientation = linearView.orientation {
                applyConstraint(to: linearView, with: orientation, onView: view, toConstraintInfo: info, for: &constraints)
            } else {
                //縦の制約
                applyVerticalConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
                //横の制約
                applyHorizontalConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
                //パディングの制約
                //上揃え
                applyTopPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
                //下揃え
                applyBottomPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
                //左揃え
                applyLeftPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
                //右揃え
                applyRightPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            }
            //高さの制約
            applyHeightWeightConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            //幅の制約
            applyWidthWeightConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            //アスペクト
            applyAspectConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            
            if let superview = superview as? UIScrollView {
                applyScrollViewConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            }
        }
        //任意のビューに対して
        if (view.superview as? SJUIView)?.orientation ?? .horizontal == .horizontal {
            if let topOfView = info.alignTopOfView {
                applyTopConstraint(of: topOfView, onView: view, toConstraintInfo: info, for: &constraints)
            }
            if let bottomOfView = info.alignBottomOfView {
                applyBottomConstraint(of: bottomOfView, onView: view, toConstraintInfo: info, for: &constraints)
            }
            if let centerVerticalView = info.alignCenterVerticalView {
                applyVerticalConstraint(align: centerVerticalView, onView: view, toConstraintInfo: info, for: &constraints)
            } else {
                if let topView = info.alignTopView {
                    applyTopConstraint(align: topView, onView: view, toConstraintInfo: info, for: &constraints)
                }
                if let bottomView = info.alignBottomView {
                    applyBottomConstraint(align: bottomView, onView: view, toConstraintInfo: info, for: &constraints)
                }
            }
        }
        if (view.superview as? SJUIView)?.orientation ?? .vertical == .vertical {
            if let leftOfView = info.alignLeftOfView {
                applyLeftConstraint(of: leftOfView, onView: view, toConstraintInfo: info, for: &constraints)
            }
            if let rightOfView = info.alignRightOfView {
                applyRightConstraint(of: rightOfView, onView: view, toConstraintInfo: info, for: &constraints)
            }
            //中央揃え
            if let centerHorizontalView = info.alignCenterHorizontalView {
                applyHorizontalConstraint(align: centerHorizontalView, onView: view, toConstraintInfo: info, for: &constraints)
            } else {
                if let leftView = info.alignLeftView {
                    applyLeftConstraint(align: leftView, onView: view, toConstraintInfo: info, for: &constraints)
                }
                if let rightView = info.alignRightView {
                    applyRightConstraint(align: rightView, onView: view, toConstraintInfo: info, for: &constraints)
                }
            }
        }
        applyWidthConstraint(on: view, toConstraintInfo: info, for: &constraints)
        applyHeightConstraint(on: view, toConstraintInfo: info, for: &constraints)
        NSLayoutConstraint.activate(constraints)
    }
    
    //MARK: Linear Layout
    public class func applyConstraint(to superview: SJUIView, with orientation: SJUIView.Orientation, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        switch orientation {
        case .vertical:
            applyHorizontalConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            applyLeftPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            applyRightPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            applyWidthWeightConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            applyLinearVerticalConstraint(to: superview, with: orientation, onView: view, toConstraintInfo: info, for: &constraints)
        case .horizontal:
            applyVerticalConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            applyTopPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            applyBottomPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            applyHeightWeightConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            applyLinearHorizontalConstraint(to: superview, with: orientation, onView: view, toConstraintInfo: info, for: &constraints)
        }
    }
    
    public class func applyLinearVerticalConstraint(to superview: SJUIView, with orientation: SJUIView.Orientation, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] )  {
        switch superview.direction {
        case .topToBottom:
            if superview.subviews.count <= 1 {
                info.alignTop = true
                applyTopPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            } else {
                let bottomOfView = superview.subviews[superview.subviews.count - 2]
                applyBottomConstraint(of: bottomOfView, onView: view, toConstraintInfo: info, for: &constraints)
            }
            if let height = info.height, height == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
                info.alignBottom = true
                applyBottomPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            }
        case .bottomToTop:
            if superview.subviews.count <= 1 {
                info.alignBottom = true
                applyBottomPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            } else {
                let topOfView = superview.subviews[superview.subviews.count - 2]
                applyTopConstraint(of: topOfView, onView: view, toConstraintInfo: info, for: &constraints)
            }
            if let height = info.height, height == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
                info.alignTop = true
                applyTopPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            }
        default:
            break
        }

    }
    
    public class func applyLinearHorizontalConstraint(to superview: SJUIView, with orientation: SJUIView.Orientation, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] )  {
        switch superview.direction {
        case .leftToRight:
            if superview.subviews.count <= 1 {
                info.alignLeft = true
                applyLeftPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            } else {
                let rightOfView = superview.subviews[superview.subviews.count - 2]
                applyRightConstraint(of: rightOfView, onView: view, toConstraintInfo: info, for: &constraints)
            }
            if let width = info.width, width == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
                info.alignRight = true
                applyRightPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            }
        case .rightToLeft:
            if superview.subviews.count <= 1 {
                info.alignRight = true
                applyRightPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            } else {
                let leftOfView = superview.subviews[superview.subviews.count - 2]
                applyLeftConstraint(of: leftOfView, onView: view, toConstraintInfo: info, for: &constraints)
            }
            if let width = info.width, width == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
                info.alignLeft = true
                applyLeftPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            }
        default:
            break
        }
    }
    
    //MARK: Constraints for Parent
    public class func applyVerticalConstraint(to superview: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if let height = info.height, height == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
            return
        }
        //縦の制約
        if let _ = info.centerVertical {
            var margin: CGFloat = 0
            if let top = info.topMargin {
                margin = top
            } else if let bottom = info.bottomMargin {
                margin = -bottom
            }
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0 + margin))
        }
    }
    
    public class func applyHorizontalConstraint(to superview: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if let width = info.width, width == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
            return
        }
        //横の制約
        if let _ = info.centerHorizontal {
            var margin: CGFloat = 0
            if let left = info.leftMargin {
                margin = left
            } else if let right = info.rightMargin {
                margin = -right
            }
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0 + margin))
        }
    }
    
    public class func applyHeightWeightConstraint(to superview: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if (info.height ?? 0) == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
            return
        }
        //高さの制約
        if let heightWeight = info.heightWeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.height, multiplier: heightWeight, constant: 0))
            if let _ = superview as? UIScrollView {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0))
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0))
            } else if info.centerVertical == nil && info.alignBottom == nil && ((info.topMargin == nil && info.bottomMargin == nil && info.minTopMargin == nil && info.minBottomMargin == nil && info.maxTopMargin == nil && info.maxBottomMargin == nil) || info.alignTopOfView == nil && info.alignBottomOfView == nil) {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0))
            }
        }
        //高さの制約
        if let heightWeight = info.maxHeightWeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.height, multiplier: heightWeight, constant: 0))
        }
        if let heightWeight = info.minHeightWeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.height, multiplier: heightWeight, constant: 0))
        }
    }
    
    public class func applyWidthWeightConstraint(to superview: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if (info.width ?? 0) == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
            return
        }
        //幅の制約
        if let widthWeight = info.widthWeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.width, multiplier: widthWeight, constant: 0))
            if let _ = superview as? UIScrollView {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0))
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0))
            } else if info.centerHorizontal == nil && info.alignLeft == nil && info.alignRight == nil && ((info.leftMargin == nil && info.rightMargin == nil && info.minLeftMargin == nil && info.minRightMargin == nil && info.maxLeftMargin == nil && info.maxRightMargin == nil)) && info.alignRightOfView == nil && info.alignLeftOfView == nil {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0))
            }
        }
        //幅の制約
        if let widthWeight = info.maxWidthWeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.width, multiplier: widthWeight, constant: 0))
        }
        if let widthWeight = info.minWidthWeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.width, multiplier: widthWeight, constant: 0))
        }
    }
    
    public class func applyAspectConstraint(to superview: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        //高さのアスペクト
        if let aspectHeight = info.aspectHeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.width, multiplier: aspectHeight, constant: 0))
        }
        
        //幅のアスペクト
        if let aspectWidth = info.aspectWidth {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.height, multiplier: aspectWidth, constant: 0))
        }
    }
    
    public class func applyTopPaddingConstraint(to superview: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if topPaddingNeedsToBeApplied(info: info) {
            var constant: CGFloat = 0
            if let constraintInfo = superview.constraintInfo, let paddingTop = constraintInfo.paddingTop {
                constant+=paddingTop
            }
            if let topPadding = info.topMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: constant + topPadding))
            } else if info.minTopMargin != nil || info.maxTopMargin != nil {
                if let topPadding = info.minTopMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: constant + topPadding))
                }
                if let topPadding = info.maxTopMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: constant + topPadding))
                }
            } else {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: constant))
            }
        }
    }
    
    private class func topPaddingNeedsToBeApplied(info: UILayoutConstraintInfo) -> Bool {
        return info.alignTop ?? false || (!(info.centerVertical ?? false) && info.alignCenterVerticalView == nil && info.alignBottomOfView == nil && info.alignTopView == nil && ((info.topMargin != nil || info.minTopMargin != nil || info.maxTopMargin != nil || (info.height ?? 0) == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue) || hasNoConstraintForBottom(info: info)))
    }
    
    private class func hasNoConstraintForBottom(info: UILayoutConstraintInfo) -> Bool {
        return !(info.alignBottom ?? false) && info.alignTopOfView == nil && info.alignBottomView == nil && info.bottomMargin == nil && info.minBottomMargin == nil && info.maxBottomMargin == nil
    }
    
    public class func applyBottomPaddingConstraint(to superview: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if bottomPaddingNeedsToBeApplied(info: info) {
            var constant: CGFloat = 0
            if let constraintInfo = superview.constraintInfo, let paddingBottom = constraintInfo.paddingBottom {
                constant+=paddingBottom
            }
            if let bottomPadding = info.bottomMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: -(constant + bottomPadding)))
            } else if info.minBottomMargin != nil || info.maxBottomMargin != nil {
                if let bottomPadding = info.minBottomMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: -(constant + bottomPadding)))
                }
                
                if let bottomPadding = info.maxBottomMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: -(constant + bottomPadding)))
                }
            } else {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: -constant))
            }
        }
    }
    
    private class func bottomPaddingNeedsToBeApplied(info: UILayoutConstraintInfo) -> Bool {
        return info.alignBottom ?? false || (!(info.centerVertical ?? false) && info.alignCenterVerticalView == nil && info.alignTopOfView == nil && info.alignBottomView == nil && (info.bottomMargin != nil || info.minBottomMargin != nil || info.maxBottomMargin != nil || (info.height ?? 0) == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue))
    }
    
    public class func applyLeftPaddingConstraint(to superview: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if leftPaddingNeedsToBeApplied(info: info) {
            var constant: CGFloat = 0
            if let constraintInfo = superview.constraintInfo, let paddingLeft = constraintInfo.paddingLeft {
                constant+=paddingLeft
            }
            if let leftPadding = info.leftMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: constant + leftPadding))
            } else if info.minLeftMargin != nil && info.maxLeftMargin != nil {
                if let leftPadding = info.minLeftMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: constant + leftPadding))
                }
                if let leftPadding = info.maxLeftMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: constant + leftPadding))
                }
            } else {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: constant))
            }
        }
    }
    
    private class func leftPaddingNeedsToBeApplied(info: UILayoutConstraintInfo) -> Bool {
        return info.alignLeft ?? false || (!(info.centerHorizontal ?? false) && info.alignCenterHorizontalView == nil && info.alignRightOfView == nil && info.alignLeftView == nil && ((info.leftMargin != nil || info.minLeftMargin != nil || info.maxLeftMargin != nil || (info.width ?? 0) == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue) || hasNoConstraintForRight(info: info)))
    }
    
    private class func hasNoConstraintForRight(info: UILayoutConstraintInfo) -> Bool {
        return !(info.alignRight ?? false) && info.alignLeftOfView == nil && info.alignRightView == nil && info.rightMargin == nil && info.minRightMargin == nil && info.maxRightMargin == nil
    }
    
    public class func applyRightPaddingConstraint(to superview: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if rightPaddingNeedsToBeApplied(info: info) {
            var constant: CGFloat = 0
            if let constraintInfo = superview.constraintInfo, let paddingRight = constraintInfo.paddingRight {
                constant+=paddingRight
            }
            if let rightPadding = info.rightMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: -(constant + rightPadding)))
            } else if info.minRightMargin != nil || info.maxRightMargin != nil {
                if let rightPadding = info.minRightMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: -rightPadding))
                }
                if let rightPadding = info.maxRightMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: -(constant + rightPadding)))
                }
            } else {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: -constant))
            }
        }
    }
    
    private class func rightPaddingNeedsToBeApplied(info: UILayoutConstraintInfo) -> Bool {
        return info.alignRight ?? false || (!(info.centerHorizontal ?? false) && info.alignCenterHorizontalView == nil && info.alignLeftOfView == nil && info.alignRightView == nil && (info.rightMargin != nil || info.minRightMargin != nil || info.maxRightMargin != nil || (info.width ?? 0) == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue))
    }
    
    public class func applyScrollViewConstraint(to superview: UIScrollView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if info.heightWeight == nil {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0))
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0))
        }
        
        if info.widthWeight == nil {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0))
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0))
        }
    }
    
    //MARK: Constraints for Related Views
    public class func applyTopConstraint(of topOfView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        var constant: CGFloat = 0
        if let topMargin = topOfView.constraintInfo?.topMargin {
            constant+=topMargin
        }
        if let bottomMargin = info.bottomMargin {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: topOfView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: -(constant + bottomMargin)))
        } else if info.maxBottomMargin == nil && info.minBottomMargin == nil {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: topOfView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: constant))
        } else {
            if let bottomMargin = info.minBottomMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: topOfView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: -(constant + bottomMargin)))
            }
            if let bottomMargin = info.maxBottomMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: topOfView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: -(constant + bottomMargin)))
            }
        }
    }
    
    public class func applyBottomConstraint(of bottomOfView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        var constant: CGFloat = 0
        if let bottomMargin = bottomOfView.constraintInfo?.bottomMargin {
            constant+=bottomMargin
        }
        if let topMargin = info.topMargin {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: bottomOfView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: constant + topMargin))
        } else if info.minTopMargin == nil && info.minBottomMargin == nil {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: bottomOfView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: constant))
        } else {
            if let topMargin = info.minTopMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: bottomOfView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: constant + topMargin))
            }
            if let topMargin = info.maxTopMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: bottomOfView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: constant + topMargin))
            }
        }
    }
    
    public class func applyLeftConstraint(of leftOfView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        var constant: CGFloat = 0
        if let leftMargin = leftOfView.constraintInfo?.leftMargin {
            constant+=leftMargin
        }
        if let rightMargin = info.rightMargin {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: leftOfView, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: -(constant + rightMargin)))
        } else if info.minRightMargin == nil && info.maxRightMargin == nil {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: leftOfView, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0))
        } else {
            if let rightMargin = info.minRightMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: leftOfView, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: -(constant + rightMargin)))
            }
            if let rightMargin = info.maxRightMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: leftOfView, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: -(constant + rightMargin)))
            }
        }
    }
    
    public class func applyRightConstraint(of rightOfView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        var constant: CGFloat = 0
        if let rightMargin = rightOfView.constraintInfo?.rightMargin {
            constant+=rightMargin
        }
        if let leftMargin = info.leftMargin {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: rightOfView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: constant + leftMargin))
        } else if info.minLeftMargin == nil && info.maxLeftMargin == nil {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: rightOfView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: constant))
        } else {
            if let leftMargin = info.minLeftMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: rightOfView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0 + leftMargin))
            }
            if let leftMargin = info.maxLeftMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: rightOfView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: constant + leftMargin))
            }
        }
    }
    
    //MARK: Constraints for align
    public class func applyVerticalConstraint(align centerVerticalView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        let constant: CGFloat
        if let topMargin = info.topMargin {
            constant = topMargin
        } else if let bottomMargin = info.bottomMargin {
            constant = -bottomMargin
        } else {
            constant = 0
        }
        constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: centerVerticalView, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: constant))
    }
    
    public class func applyHorizontalConstraint(align centerHorizontalView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        let constant: CGFloat
        if let leftMargin = info.leftMargin {
            constant = leftMargin
        } else if let rightMargin = info.rightMargin {
            constant = -rightMargin
        } else {
            constant = 0
        }
        constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: centerHorizontalView, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: constant))
    }
    
    
    public class func applyTopConstraint(align topView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if let topMargin = info.topMargin {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: topView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0 + topMargin))
        } else if info.minTopMargin == nil && info.minBottomMargin == nil {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: topView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0))
        } else {
            if let topMargin = info.minTopMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: topView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0 + topMargin))
            }
            if let topMargin = info.maxTopMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: topView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0 + topMargin))
            }
        }
    }
    
    public class func applyBottomConstraint(align bottomView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if let bottomMargin = info.bottomMargin {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: bottomView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0 - bottomMargin))
        } else if info.maxBottomMargin == nil && info.minBottomMargin == nil {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: bottomView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0))
        } else {
            if let bottomMargin = info.minBottomMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: bottomView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0 - bottomMargin))
            }
            if let bottomMargin = info.maxBottomMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: bottomView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0 - bottomMargin))
            }
        }
    }
    
    public class func applyLeftConstraint(align leftView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if let leftMargin = info.leftMargin {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: leftView, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0 + leftMargin))
        } else if info.minLeftMargin == nil && info.maxLeftMargin == nil {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: leftView, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0))
        } else {
            if let leftMargin = info.minLeftMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: leftView, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0 + leftMargin))
            }
            if let leftMargin = info.maxLeftMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: leftView, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0 + leftMargin))
            }
        }
    }
    
    public class func applyRightConstraint(align rightView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if let rightMargin = info.rightMargin {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: rightView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0 - rightMargin))
        } else if info.minRightMargin == nil && info.maxRightMargin == nil {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: rightView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0))
        } else {
            if let rightMargin = info.minRightMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: rightView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0 - rightMargin))
            }
            if let rightMargin = info.maxRightMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: rightView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0 - rightMargin))
            }
        }
    }
    
    //MARK: Constraints for Size
    public class func applyHeightConstraint(on view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if let height = info.height, height == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
            return
        }
        if let minHeight = info.minHeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: minHeight))
        }
        if let maxHeight = info.maxHeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: maxHeight))
        }
        if let height = info.height {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: height))
        }
        
        if let orientation = (view as? SJUIView)?.orientation, orientation == .vertical, info.height == nil, info.maxHeight == nil, info.heightWeight == nil, info.maxHeightWeight == nil {
            info.height = UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue
        }
    }
    
    public class func applyWidthConstraint(on view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if let width = info.width, width == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
            return
        }
        if let minWidth = info.minWidth {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: minWidth))
        }
        if let maxWidth = info.maxWidth {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: maxWidth))
        }
        if let width = info.width {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: width))
        }
        if let orientation = (view as? SJUIView)?.orientation, orientation == .horizontal, info.width == nil, info.maxWidth == nil, info.widthWeight == nil, info.maxWidthWeight == nil {
            info.width = UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue
        }
    }
}

public class UILayoutConstraintInfo {
    weak var toView: UIView?
    var paddingLeft:CGFloat!
    var paddingRight:CGFloat!
    var paddingTop: CGFloat!
    var paddingBottom: CGFloat!
    var leftMargin:CGFloat!
    var rightMargin:CGFloat!
    var topMargin: CGFloat!
    var bottomMargin: CGFloat!
    var minLeftMargin:CGFloat!
    var minRightMargin:CGFloat!
    var minTopMargin: CGFloat!
    var minBottomMargin: CGFloat!
    var maxLeftMargin:CGFloat!
    var maxRightMargin:CGFloat!
    var maxTopMargin: CGFloat!
    var maxBottomMargin: CGFloat!
    var centerVertical: Bool!
    var centerHorizontal: Bool!
    var alignTop: Bool!
    var alignBottom: Bool!
    var alignLeft: Bool!
    var alignRight: Bool!
    weak var alignTopOfView:UIView?
    weak var alignBottomOfView:UIView?
    weak var alignLeftOfView:UIView?
    weak var alignRightOfView:UIView?
    weak var alignTopView: UIView?
    weak var alignBottomView: UIView?
    weak var alignLeftView: UIView?
    weak var alignRightView: UIView?
    weak var alignCenterVerticalView: UIView?
    weak var alignCenterHorizontalView: UIView?
    var width: CGFloat!
    var height: CGFloat!
    var minWidth: CGFloat!
    var minHeight: CGFloat!
    var maxWidth: CGFloat!
    var maxHeight: CGFloat!
    var widthWeight: CGFloat!
    var heightWeight: CGFloat!
    var aspectWidth: CGFloat!
    var aspectHeight: CGFloat!
    var maxWidthWeight: CGFloat!
    var maxHeightWeight: CGFloat!
    var minWidthWeight: CGFloat!
    var minHeightWeight: CGFloat!
    
    public init(toView: UIView?, paddingLeft:CGFloat! = nil, paddingRight:CGFloat! = nil, paddingTop: CGFloat! = nil, paddingBottom: CGFloat! = nil, leftPadding:CGFloat! = nil, rightPadding:CGFloat! = nil, topPadding: CGFloat! = nil, bottomPadding: CGFloat! = nil, minLeftPadding:CGFloat! = nil, minRightPadding:CGFloat! = nil, minTopPadding: CGFloat! = nil, minBottomPadding: CGFloat! = nil, maxLeftPadding:CGFloat! = nil, maxRightPadding:CGFloat! = nil, maxTopPadding: CGFloat! = nil, maxBottomPadding: CGFloat! = nil, leftMargin:CGFloat! = nil, rightMargin:CGFloat! = nil, topMargin: CGFloat! = nil, bottomMargin: CGFloat! = nil, minLeftMargin:CGFloat! = nil, minRightMargin:CGFloat! = nil, minTopMargin: CGFloat! = nil, minBottomMargin: CGFloat! = nil, maxLeftMargin:CGFloat! = nil, maxRightMargin:CGFloat! = nil, maxTopMargin: CGFloat! = nil, maxBottomMargin: CGFloat! = nil, centerVertical: Bool! = nil, centerHorizontal: Bool! = nil, alignTop: Bool! = nil, alignBottom: Bool! = nil, alignLeft: Bool! = nil, alignRight: Bool! = nil, alignTopToView: Bool! = nil, alignBottomToView: Bool! = nil, alignLeftToView: Bool! = nil, alignRightToView: Bool! = nil ,alignCenterVerticalToView: Bool! = nil ,alignCenterHorizontalToView: Bool! = nil, alignTopOfView: UIView! = nil, alignBottomOfView: UIView! = nil, alignLeftOfView: UIView! = nil, alignRightOfView: UIView! = nil, alignTopView: UIView! = nil, alignBottomView: UIView! = nil, alignLeftView: UIView! = nil, alignRightView: UIView! = nil ,alignCenterVerticalView: UIView! = nil ,alignCenterHorizontalView: UIView! = nil, width:CGFloat! = nil, height:CGFloat! = nil, minWidth:CGFloat! = nil, minHeight:CGFloat! = nil, maxWidth:CGFloat! = nil, maxHeight:CGFloat! = nil, widthWeight:CGFloat! = nil, heightWeight:CGFloat! = nil, aspectWidth: CGFloat! = nil, aspectHeight: CGFloat! = nil, maxWidthWeight: CGFloat! = nil, maxHeightWeight: CGFloat! = nil, minWidthWeight: CGFloat! = nil, minHeightWeight: CGFloat! = nil) {
        self.paddingLeft = paddingLeft
        self.paddingRight = paddingRight
        self.paddingTop = paddingTop
        self.paddingBottom = paddingBottom
        self.leftMargin = leftMargin ?? leftPadding
        self.rightMargin = rightMargin ?? rightPadding
        self.topMargin = topMargin ?? topPadding
        self.bottomMargin = bottomMargin ?? bottomPadding
        self.minLeftMargin = minLeftMargin ?? minLeftPadding
        self.minRightMargin = minRightMargin ?? minRightPadding
        self.minTopMargin = minTopMargin ?? minTopPadding
        self.minBottomMargin = minBottomMargin ?? minBottomPadding
        self.maxLeftMargin = maxLeftMargin ?? maxLeftPadding
        self.maxRightMargin = maxRightMargin ?? maxRightPadding
        self.maxTopMargin = maxTopMargin ?? maxTopPadding
        self.maxBottomMargin = maxBottomMargin ?? maxBottomPadding
        self.centerHorizontal = centerHorizontal
        self.centerVertical = centerVertical
        self.alignTop = alignTop
        self.alignBottom = alignBottom
        self.alignLeft = alignLeft
        self.alignRight = alignRight
        self.alignTopOfView = alignTopOfView
        self.alignBottomOfView = alignBottomOfView
        self.alignLeftOfView = alignLeftOfView
        self.alignRightOfView = alignRightOfView
        self.alignTopView = alignTopView
        self.alignBottomView = alignBottomView
        self.alignLeftView = alignLeftView
        self.alignRightView = alignRightView
        self.alignCenterVerticalView = alignCenterVerticalView
        self.alignCenterHorizontalView = alignCenterHorizontalView
        self.width = width
        self.height = height
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.widthWeight = widthWeight
        self.heightWeight = heightWeight
        self.aspectWidth = aspectWidth
        self.aspectHeight = aspectHeight
        self.maxWidthWeight = maxWidthWeight
        self.maxHeightWeight = maxHeightWeight
        self.minWidthWeight = minWidthWeight
        self.minHeightWeight = minHeightWeight
        
        if self.maxWidth != nil && self.minWidth != nil && self.maxWidth < self.minWidth {
            self.maxWidth = self.minWidth
        }
        if self.maxHeight != nil && self.minHeight != nil && self.maxHeight < self.minHeight {
            self.maxHeight = self.minHeight
        }
        if self.width != nil && self.minWidth != nil &&  self.width < self.minWidth {
            self.width = self.minWidth
        } else if self.width != nil && self.maxWidth != nil && self.width > self.maxWidth {
            self.width = self.maxWidth
        }
        if self.height != nil && self.minHeight != nil && self.height < self.minHeight {
            self.height = self.minHeight
        } else if self.height != nil && self.maxHeight != nil && self.height > self.maxHeight {
            self.height = self.maxHeight
        }
        
        if self.maxWidthWeight != nil && self.minWidthWeight != nil && self.maxWidthWeight < self.minWidthWeight {
            self.maxWidthWeight = self.minWidthWeight
        }
        if self.maxHeightWeight != nil && self.minHeightWeight != nil && self.maxHeightWeight < self.minHeightWeight {
            self.maxHeightWeight = self.minHeightWeight
        }
        
        if let centerVertical = centerVertical, centerVertical {
            if self.topMargin != nil && self.bottomMargin != nil {
                self.centerVertical = nil
            }
        }
        if self.alignCenterVerticalView != nil {
            if self.topMargin != nil && self.bottomMargin != nil {
                self.alignCenterVerticalView = nil
            }
        }
        if let centerHorizontal = centerHorizontal, centerHorizontal {
            if self.leftMargin != nil && self.rightMargin != nil {
                self.centerHorizontal = nil
            }
        }
        if self.alignCenterHorizontalView != nil {
            if self.leftMargin != nil && self.rightMargin != nil {
                self.alignCenterHorizontalView = nil
            }
        }
        
        if let toView = toView {
            if alignCenterVerticalToView ?? false {
                self.alignCenterVerticalView = toView
            } else {
                if alignTopToView ?? false {
                    self.alignTopView = toView
                } else if topMargin != nil || maxTopMargin != nil || minTopMargin != nil {
                    self.alignBottomOfView = toView
                }
                if alignBottomToView ?? false {
                    self.alignBottomView = toView
                } else if bottomMargin != nil || maxBottomMargin != nil || minBottomMargin != nil {
                    self.alignTopOfView = toView
                }
            }
            if alignCenterHorizontalToView ?? false {
                self.alignCenterHorizontalView = toView
            } else {
                if alignLeftToView ?? false {
                    self.alignLeftView = toView
                } else if leftMargin != nil || maxLeftMargin != nil || minLeftMargin != nil {
                    self.alignRightOfView = toView
                }
                if alignRightToView ?? false {
                    self.alignRightView = toView
                } else if rightMargin != nil || maxRightMargin != nil || minRightMargin != nil {
                    self.alignLeftOfView = toView
                }
            }
        }
    }
    
    public enum LayoutParams: CGFloat {
        case matchParent = -1
        case wrapContent = -2
    }
}
