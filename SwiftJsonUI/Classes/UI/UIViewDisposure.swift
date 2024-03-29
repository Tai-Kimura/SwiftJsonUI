//
//  UIViewDisposure.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2015/12/25.

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
    
    public class func removeConstraint(constraintInfo info: UILayoutConstraintInfo) {
        if !info.constraints.isEmpty {
            NSLayoutConstraint.deactivate(info.constraints)
        }
    }
    
    public class func applyConstraint(onView view: UIView, toConstraintInfo info: inout UILayoutConstraintInfo) {
        view.invalidateIntrinsicContentSize()
        var constraints = [NSLayoutConstraint]()
        //親ビューに対して
        if let superview = view.superview {
            let subviews = superview.subviews.filter{$0.visibility != .gone}
            if let linearView = superview as? SJUIView, let orientation = linearView.orientation {
                applyConstraint(to: linearView, with: orientation, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
            } else {
                //縦の制約
                applyVerticalConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
                //横の制約
                applyHorizontalConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
                //パディングの制約
                //上揃え
                applyTopPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
                //下揃え
                applyBottomPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
                //左揃え
                applyLeftPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
                //右揃え
                applyRightPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
            }
            //高さの制約
            applyHeightWeightConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            //幅の制約
            applyWidthWeightConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            //アスペクト
            applyAspectConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
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
        applyWrapContentConstraint(on: view, toConstraintInfo: info, for: &constraints)
        applyScrollViewConstraint(onView: view, toConstraintInfo: info, for: &constraints)
        if let label = view as? UILabel {
            if let heightInfo = label.constraintInfo?.height, heightInfo == UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue {
                label.setContentCompressionResistancePriority(.required, for: .vertical)
                label.setContentHuggingPriority(.required, for: .vertical)
            } else {
                label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
                label.setContentHuggingPriority(.defaultLow, for: .vertical)
            }
            if let widthInfo = label.constraintInfo?.width, widthInfo == UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue {
                label.setContentCompressionResistancePriority(.required, for: .horizontal)
                label.setContentHuggingPriority(.required, for: .horizontal)
            } else {
                label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                label.setContentHuggingPriority(.defaultLow, for: .horizontal)
            }
        }
        NSLayoutConstraint.activate(constraints)
        info._constraints = WeakConstraint.constraints(with: constraints)
    }
    
    //MARK: Linear Layout
    public class func applyConstraint(to superview: SJUIView, with orientation: SJUIView.Orientation, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint], subviews: [UIView] ) {
        switch orientation {
        case .vertical:
            applyHorizontalConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            applyLeftPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
            applyRightPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
            applyWidthWeightConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            applyLinearVerticalConstraint(to: superview, with: orientation, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
        case .horizontal:
            applyVerticalConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            applyTopPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
            applyBottomPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
            applyHeightWeightConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints)
            applyLinearHorizontalConstraint(to: superview, with: orientation, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
        }
        applyLinearWeightConstraint(to: superview, with: orientation, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
    }
    
    public class func applyLinearVerticalConstraint(to superview: SJUIView, with orientation: SJUIView.Orientation, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] , subviews: [UIView] )  {
        switch superview.direction {
        case .topToBottom:
            if subviews.first == view {
                info.alignTop = true
                applyTopPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
            } else {
                if let index = subviews.firstIndex(of: view), index > 0 {
                    let bottomOfView = subviews[index - 1]
                    applyBottomConstraint(of: bottomOfView, onView: view, toConstraintInfo: info, for: &constraints)
                }
            }
            if let height = info.height, height == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
                info.alignBottom = true
                applyBottomPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
            } else if shouldBeLastView(view, in: superview, subviews: subviews) {
                info.alignBottom = true
                applyBottomPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
            }
        case .bottomToTop:
            if subviews.first == view {
                info.alignBottom = true
                applyBottomPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
            } else {
                if let index = subviews.firstIndex(of: view), index > 0 {
                    let topOfView = subviews[index - 1]
                    applyTopConstraint(of: topOfView, onView: view, toConstraintInfo: info, for: &constraints)
                }
            }
            if let height = info.height, height == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
                info.alignTop = true
                applyTopPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
            } else if shouldBeLastView(view, in: superview, subviews: subviews) {
                info.alignTop = true
                applyTopPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
            }
        default:
            break
        }
        
    }
    
    public class func applyLinearHorizontalConstraint(to superview: SJUIView, with orientation: SJUIView.Orientation, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] , subviews: [UIView] )  {
        switch superview.direction {
        case .leftToRight:
            if subviews.first == view {
                info.alignLeft = true
                applyLeftPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
            } else {
                if let index = subviews.firstIndex(of: view), index > 0 {
                    let rightOfView = subviews[index - 1]
                    applyRightConstraint(of: rightOfView, onView: view, toConstraintInfo: info, for: &constraints)
                }
            }
            if let width = info.width, width == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
                info.alignRight = true
                applyRightPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
            } else if shouldBeLastView(view, in: superview, subviews: subviews) {
                info.alignRight = true
                applyRightPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
            }
        case .rightToLeft:
            if subviews.first == view {
                info.alignRight = true
                applyRightPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
            } else {
                if let index = subviews.firstIndex(of: view), index > 0 {
                    let leftOfView = subviews[index - 1]
                    applyLeftConstraint(of: leftOfView, onView: view, toConstraintInfo: info, for: &constraints)
                }
            }
            if let width = info.width, width == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
                info.alignLeft = true
                applyLeftPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
            } else if shouldBeLastView(view, in: superview, subviews: subviews) {
                info.alignLeft = true
                applyLeftPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
            }
        default:
            break
        }
    }
    
    public class func applyLinearWeightConstraint(to superview: SJUIView, with orientation: SJUIView.Orientation, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] , subviews: [UIView] )  {
        guard var weightReferencedView = subviews.first, let weight = info.weight else {
            return
        }
        var baseWeight = weight
        for subview in subviews {
            if let constraintInfo = subview.constraintInfo, let bWeight = constraintInfo.weight {
                weightReferencedView = subview
                baseWeight = bWeight
                break
            }
        }
        let weightInView = weight/baseWeight
        switch orientation {
        case .vertical:
            if subviews.count > 1 {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: weightReferencedView, attribute: NSLayoutConstraint.Attribute.height, multiplier: weightInView, constant: 0))
            } else {
                info.height = UILayoutConstraintInfo.LayoutParams.matchParent.rawValue
                applyTopPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
                applyBottomPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
                info.height = nil
            }
        case .horizontal:
            if subviews.count > 1 {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: weightReferencedView, attribute: NSLayoutConstraint.Attribute.width, multiplier: weightInView, constant: 0))
            } else {
                info.width = UILayoutConstraintInfo.LayoutParams.matchParent.rawValue
                applyLeftPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
                applyRightPaddingConstraint(to: superview, onView: view, toConstraintInfo: info, for: &constraints, subviews: subviews)
                info.width = nil
            }
        }
    }
    
    public class func shouldBeLastView(_ view: UIView, in superview: SJUIView, subviews: [UIView]) -> Bool  {
        return view == subviews.last && !superview.shouldWrapContent() && shouldApplyWeight(in: superview, subviews: subviews)
    }
    
    public class func shouldApplyWeight(in superview: SJUIView, subviews: [UIView]) -> Bool  {
        if superview.orientation != nil {
            for subview in subviews {
                if subview.constraintInfo?.weight != nil {
                    return true
                }
            }
        }
        return false
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
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superview, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1.0, constant: 0 + margin))
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
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superview, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1.0, constant: 0 + margin))
        }
    }
    
    public class func applyHeightWeightConstraint(to superview: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if (info.height ?? 0) == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
            return
        }
        //高さの制約
        if let heightWeight = info.heightWeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superview, attribute: NSLayoutConstraint.Attribute.height, multiplier: heightWeight, constant: 0))
            if let _ = superview as? UIScrollView {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superview, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0))
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superview, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0))
            } else if info.centerVertical == nil && info.alignBottom == nil && ((info.topMargin == nil && info.bottomMargin == nil && info.minTopMargin == nil && info.minBottomMargin == nil && info.maxTopMargin == nil && info.maxBottomMargin == nil) || info.alignTopOfView == nil && info.alignBottomOfView == nil) {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superview, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0))
            }
        }
        //高さの制約
        if let heightWeight = info.maxHeightWeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: superview, attribute: NSLayoutConstraint.Attribute.height, multiplier: heightWeight, constant: 0))
        }
        if let heightWeight = info.minHeightWeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: superview, attribute: NSLayoutConstraint.Attribute.height, multiplier: heightWeight, constant: 0))
        }
    }
    
    public class func applyWidthWeightConstraint(to superview: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if (info.width ?? 0) == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
            return
        }
        //幅の制約
        if let widthWeight = info.widthWeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superview, attribute: NSLayoutConstraint.Attribute.width, multiplier: widthWeight, constant: 0))
            if let _ = superview as? UIScrollView {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superview, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: 0))
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superview, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: 0))
            } else if info.centerHorizontal == nil && info.alignLeft == nil && info.alignRight == nil && ((info.leftMargin == nil && info.rightMargin == nil && info.minLeftMargin == nil && info.minRightMargin == nil && info.maxLeftMargin == nil && info.maxRightMargin == nil)) && info.alignRightOfView == nil && info.alignLeftOfView == nil {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superview, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: 0))
            }
        }
        //幅の制約
        if let widthWeight = info.maxWidthWeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: superview, attribute: NSLayoutConstraint.Attribute.width, multiplier: widthWeight, constant: 0))
        }
        if let widthWeight = info.minWidthWeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: superview, attribute: NSLayoutConstraint.Attribute.width, multiplier: widthWeight, constant: 0))
        }
    }
    
    public class func applyAspectConstraint(to superview: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        //高さのアスペクト
        if let aspectHeight = info.aspectHeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.width, multiplier: aspectHeight, constant: 0))
        }
        
        //幅のアスペクト
        if let aspectWidth = info.aspectWidth {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.height, multiplier: aspectWidth, constant: 0))
        }
    }
    
    public class func applyTopPaddingConstraint(to superview: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint], subviews: [UIView] ) {
        if topPaddingNeedsToBeApplied(for: view, info: info, subviews: subviews) {
            var constant: CGFloat = 0
            if let constraintInfo = superview.constraintInfo, let paddingTop = constraintInfo.paddingTop {
                constant+=paddingTop
            }
            if let topPadding = info.topMargin {
                let relation = ((info.alignBottom ?? false) || (info.centerVertical ?? false)) && (info.height ?? 0) != UILayoutConstraintInfo.LayoutParams.matchParent.rawValue ? NSLayoutConstraint.Relation.greaterThanOrEqual : NSLayoutConstraint.Relation.equal
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: relation, toItem: superview, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: constant + topPadding))
            } else if info.minTopMargin != nil || info.maxTopMargin != nil {
                if let topPadding = info.minTopMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: superview, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: constant + topPadding))
                }
                if let topPadding = info.maxTopMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: superview, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: constant + topPadding))
                }
            } else {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superview, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: constant))
            }
        }
    }
    
    private class func topPaddingNeedsToBeApplied(for view: UIView, info: UILayoutConstraintInfo, subviews: [UIView]) -> Bool {
        if info.alignTop ?? false || ((!(info.centerVertical ?? false) || info.height == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue) && ((info.alignCenterVerticalView == nil) || info.height == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue) && info.alignBottomOfView == nil && info.alignTopView == nil && ((info.topMargin != nil || info.minTopMargin != nil || info.maxTopMargin != nil || (info.height ?? 0) == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue) || hasNoConstraintForBottom(info: info))) {
            if let superview = view.superview, (superview as? SJUIView)?.orientation ?? .horizontal == .horizontal {
                for subview in subviews {
                    if let sInfo = subview.constraintInfo {
                        if sInfo.alignTopOfView == view {
                            return false
                        }
                    }
                }
            }
            return true
        }
        return false
    }
    
    private class func hasNoConstraintForBottom(info: UILayoutConstraintInfo) -> Bool {
        return !(info.alignBottom ?? false) && info.alignTopOfView == nil && info.alignBottomView == nil && info.bottomMargin == nil && info.minBottomMargin == nil && info.maxBottomMargin == nil
    }
    
    public class func applyBottomPaddingConstraint(to superview: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint], subviews: [UIView] ) {
        if bottomPaddingNeedsToBeApplied(for: view, info: info, subviews: subviews) {
            var constant: CGFloat = 0
            if let constraintInfo = superview.constraintInfo, let paddingBottom = constraintInfo.paddingBottom {
                constant+=paddingBottom
            }
            if let bottomPadding = info.bottomMargin {
                let relation = ((info.alignBottom ?? false) && !(info.centerVertical ?? false)) || (info.height ?? 0) == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue ? NSLayoutConstraint.Relation.equal : NSLayoutConstraint.Relation.lessThanOrEqual
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: relation, toItem: superview, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: -(constant + bottomPadding)))
            } else if info.minBottomMargin != nil || info.maxBottomMargin != nil {
                if let bottomPadding = info.minBottomMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: superview, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: -(constant + bottomPadding)))
                }
                
                if let bottomPadding = info.maxBottomMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: superview, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: -(constant + bottomPadding)))
                }
            } else {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superview, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: -constant))
            }
        }
    }
    
    private class func bottomPaddingNeedsToBeApplied(for view: UIView, info: UILayoutConstraintInfo, subviews: [UIView]) -> Bool {
        if info.alignBottom ?? false || ((!(info.centerVertical ?? false) || info.height == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue) && (info.alignCenterVerticalView == nil || info.height == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue) && info.alignTopOfView == nil && info.alignBottomView == nil && (info.bottomMargin != nil || info.minBottomMargin != nil || info.maxBottomMargin != nil || (info.height ?? 0) == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue)) {
            if let superview = view.superview, (superview as? SJUIView)?.orientation ?? .horizontal == .horizontal {
                for subview in subviews {
                    if let sInfo = subview.constraintInfo {
                        if sInfo.alignBottomOfView == view {
                            return false
                        }
                    }
                }
            }
            return true
        }
        return false
    }
    
    public class func applyLeftPaddingConstraint(to superview: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint], subviews: [UIView] ) {
        if leftPaddingNeedsToBeApplied(for: view, info: info, subviews: subviews) {
            var constant: CGFloat = 0
            if let constraintInfo = superview.constraintInfo, let paddingLeft = constraintInfo.paddingLeft {
                constant+=paddingLeft
            }
            if let leftPadding = info.leftMargin {
                let relation = ((info.alignRight ?? false) || (info.centerHorizontal ?? false)) && (info.width ?? 0) != UILayoutConstraintInfo.LayoutParams.matchParent.rawValue ? NSLayoutConstraint.Relation.greaterThanOrEqual : NSLayoutConstraint.Relation.equal
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.left, relatedBy: relation, toItem: superview, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: constant + leftPadding))
            } else if info.minLeftMargin != nil && info.maxLeftMargin != nil {
                if let leftPadding = info.minLeftMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: superview, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: constant + leftPadding))
                }
                if let leftPadding = info.maxLeftMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: superview, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: constant + leftPadding))
                }
            } else {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superview, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: constant))
            }
        }
    }
    
    private class func leftPaddingNeedsToBeApplied(for view: UIView, info: UILayoutConstraintInfo, subviews: [UIView]) -> Bool {
        if info.alignLeft ?? false || ((!(info.centerHorizontal ?? false) || info.width == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue) && (info.alignCenterHorizontalView == nil || info.width == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue) && info.alignRightOfView == nil && info.alignLeftView == nil && ((info.leftMargin != nil || info.minLeftMargin != nil || info.maxLeftMargin != nil || (info.width ?? 0) == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue) || hasNoConstraintForRight(info: info))) {
            if let superview = view.superview, (superview as? SJUIView)?.orientation ?? .vertical == .vertical {
                for subview in subviews {
                    if let sInfo = subview.constraintInfo {
                        if sInfo.alignLeftOfView == view {
                            return false
                        }
                    }
                }
            }
            return true
        }
        return false
    }
    
    private class func hasNoConstraintForRight(info: UILayoutConstraintInfo) -> Bool {
        return !(info.alignRight ?? false) && info.alignLeftOfView == nil && info.alignRightView == nil && info.rightMargin == nil && info.minRightMargin == nil && info.maxRightMargin == nil
    }
    
    public class func applyRightPaddingConstraint(to superview: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint], subviews: [UIView] ) {
        if rightPaddingNeedsToBeApplied(for: view, info: info, subviews: subviews) {
            var constant: CGFloat = 0
            if let constraintInfo = superview.constraintInfo, let paddingRight = constraintInfo.paddingRight {
                constant+=paddingRight
            }
            if let rightPadding = info.rightMargin {
                let relation = ((info.alignRight ?? false) && !(info.centerHorizontal ?? false)) || (info.width ?? 0) == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue ? NSLayoutConstraint.Relation.equal : NSLayoutConstraint.Relation.lessThanOrEqual
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.right, relatedBy: relation, toItem: superview, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: -(constant + rightPadding)))
            } else if info.minRightMargin != nil || info.maxRightMargin != nil {
                if let rightPadding = info.minRightMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: superview, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: -rightPadding))
                }
                if let rightPadding = info.maxRightMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: superview, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: -(constant + rightPadding)))
                }
            } else {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superview, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: -constant))
            }
        }
    }
    
    private class func rightPaddingNeedsToBeApplied(for view: UIView, info: UILayoutConstraintInfo, subviews: [UIView]) -> Bool {
        if info.alignRight ?? false || ((!(info.centerHorizontal ?? false) || info.width == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue) && (info.alignCenterHorizontalView == nil || info.width == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue) && info.alignLeftOfView == nil && info.alignRightView == nil && (info.rightMargin != nil || info.minRightMargin != nil || info.maxRightMargin != nil || (info.width ?? 0) == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue)) {
            if let superview = view.superview, (superview as? SJUIView)?.orientation ?? .vertical == .vertical {
                for subview in subviews {
                    if let sInfo = subview.constraintInfo {
                        if sInfo.alignRightOfView == view {
                            return false
                        }
                    }
                }
            }
            return true
        }
        return false
    }
    
    public class func applyScrollViewConstraint(onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if let view = view as? SJUIScrollView, let lastView = view.subviews.last, let lastViewInfo = lastView.constraintInfo {
            if lastViewInfo.height == UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue {
                constraints.append(NSLayoutConstraint(item: lastView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0))
            } else if lastViewInfo.height == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
                var constant: CGFloat = 0
                if let paddingTop =  info.paddingTop {
                    constant+=paddingTop
                }
                if let paddingBottom =  info.paddingBottom {
                    constant+=paddingBottom
                }
                if let topMargin =  lastViewInfo.topMargin {
                    constant+=topMargin
                }
                if let bottomMargin =  info.bottomMargin {
                    constant+=bottomMargin
                }
                constraints.append(NSLayoutConstraint(item: lastView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1.0, constant: -constant))
            } else if lastViewInfo.heightWeight == nil {
                constraints.append(NSLayoutConstraint(item: lastView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0))
                constraints.append(NSLayoutConstraint(item: lastView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0))
            }
            
            if lastViewInfo.width == UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue {
                constraints.append(NSLayoutConstraint(item: lastView, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: 0))
            } else if lastViewInfo.width == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
                var constant: CGFloat = 0
                if let paddingLeft =  info.paddingLeft {
                    constant+=paddingLeft
                }
                if let paddingRight =  info.paddingRight {
                    constant+=paddingRight
                }
                if let leftMargin =  lastViewInfo.leftMargin {
                    constant+=leftMargin
                }
                if let rightMargin =  info.rightMargin {
                    constant+=rightMargin
                }
                constraints.append(NSLayoutConstraint(item: lastView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1.0, constant: -constant))
            } else if info.widthWeight == nil {
                constraints.append(NSLayoutConstraint(item: lastView, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: 0))
                constraints.append(NSLayoutConstraint(item: lastView, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: 0))
            }
        }
    }
    
    //MARK: Constraints for Related Views
    public class func applyTopConstraint(of topOfView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if topOfView.visibility == .gone {
            return
        }
        var constant: CGFloat = 0
        if let topMargin = topOfView.constraintInfo?.topMargin {
            constant+=topMargin
        }
        if let bottomMargin = info.bottomMargin {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: topOfView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: -(constant + bottomMargin)))
        } else if info.maxBottomMargin == nil && info.minBottomMargin == nil {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: topOfView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: constant))
        } else {
            if let bottomMargin = info.minBottomMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: topOfView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: -(constant + bottomMargin)))
            }
            if let bottomMargin = info.maxBottomMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: topOfView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: -(constant + bottomMargin)))
            }
        }
    }
    
    public class func applyBottomConstraint(of bottomOfView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if bottomOfView.visibility == .gone {
            return
        }
        var constant: CGFloat = 0
        if let bottomMargin = bottomOfView.constraintInfo?.bottomMargin {
            constant+=bottomMargin
        }
        if let topMargin = info.topMargin {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bottomOfView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: constant + topMargin))
        } else if info.minTopMargin == nil && info.minBottomMargin == nil {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bottomOfView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: constant))
        } else {
            if let topMargin = info.minTopMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: bottomOfView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: constant + topMargin))
            }
            if let topMargin = info.maxTopMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: bottomOfView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: constant + topMargin))
            }
        }
    }
    
    public class func applyLeftConstraint(of leftOfView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if leftOfView.visibility == .gone {
            return
        }
        var constant: CGFloat = 0
        if let leftMargin = leftOfView.constraintInfo?.leftMargin {
            constant+=leftMargin
        }
        if let rightMargin = info.rightMargin {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: leftOfView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: -(constant + rightMargin)))
        } else if info.minRightMargin == nil && info.maxRightMargin == nil {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: leftOfView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: 0))
        } else {
            if let rightMargin = info.minRightMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: leftOfView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: -(constant + rightMargin)))
            }
            if let rightMargin = info.maxRightMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: leftOfView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: -(constant + rightMargin)))
            }
        }
    }
    
    public class func applyRightConstraint(of rightOfView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if rightOfView.visibility == .gone {
            return
        }
        var constant: CGFloat = 0
        if let rightMargin = rightOfView.constraintInfo?.rightMargin {
            constant+=rightMargin
        }
        if let leftMargin = info.leftMargin {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: rightOfView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: constant + leftMargin))
        } else if info.minLeftMargin == nil && info.maxLeftMargin == nil {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: rightOfView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: constant))
        } else {
            if let leftMargin = info.minLeftMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: rightOfView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: 0 + leftMargin))
            }
            if let leftMargin = info.maxLeftMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: rightOfView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: constant + leftMargin))
            }
        }
    }
    
    //MARK: Constraints for align
    public class func applyVerticalConstraint(align centerVerticalView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if centerVerticalView.visibility == .gone {
            return
        }
        let constant: CGFloat
        if let topMargin = info.topMargin {
            constant = topMargin
        } else if let bottomMargin = info.bottomMargin {
            constant = -bottomMargin
        } else {
            constant = 0
        }
        constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: centerVerticalView, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1.0, constant: constant))
    }
    
    public class func applyHorizontalConstraint(align centerHorizontalView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if centerHorizontalView.visibility == .gone {
            return
        }
        let constant: CGFloat
        if let leftMargin = info.leftMargin {
            constant = leftMargin
        } else if let rightMargin = info.rightMargin {
            constant = -rightMargin
        } else {
            constant = 0
        }
        constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: centerHorizontalView, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1.0, constant: constant))
    }
    
    
    public class func applyTopConstraint(align topView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if topView.visibility == .gone {
            return
        }
        if let topMargin = info.topMargin {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: topView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0 + topMargin))
        } else if info.minTopMargin == nil && info.minBottomMargin == nil {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: topView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0))
        } else {
            if let topMargin = info.minTopMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: topView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0 + topMargin))
            }
            if let topMargin = info.maxTopMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: topView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0 + topMargin))
            }
        }
    }
    
    public class func applyBottomConstraint(align bottomView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if bottomView.visibility == .gone {
            return
        }
        if let bottomMargin = info.bottomMargin {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bottomView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0 - bottomMargin))
        } else if info.maxBottomMargin == nil && info.minBottomMargin == nil {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bottomView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0))
        } else {
            if let bottomMargin = info.minBottomMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: bottomView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0 - bottomMargin))
            }
            if let bottomMargin = info.maxBottomMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: bottomView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0 - bottomMargin))
            }
        }
    }
    
    public class func applyLeftConstraint(align leftView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if leftView.visibility == .gone {
            return
        }
        if let leftMargin = info.leftMargin {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: leftView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: 0 + leftMargin))
        } else if info.minLeftMargin == nil && info.maxLeftMargin == nil {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: leftView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: 0))
        } else {
            if let leftMargin = info.minLeftMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: leftView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: 0 + leftMargin))
            }
            if let leftMargin = info.maxLeftMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: leftView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: 0 + leftMargin))
            }
        }
    }
    
    public class func applyRightConstraint(align rightView: UIView, onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if rightView.visibility == .gone {
            return
        }
        if let rightMargin = info.rightMargin {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: rightView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: 0 - rightMargin))
        } else if info.minRightMargin == nil && info.maxRightMargin == nil {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: rightView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: 0))
        } else {
            if let rightMargin = info.minRightMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: rightView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: 0 - rightMargin))
            }
            if let rightMargin = info.maxRightMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: rightView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: 0 - rightMargin))
            }
        }
    }
    
    //MARK: Constraints for Size
    public class func applyHeightConstraint(on view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if let height = info.height, height == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
            if let superview = view.superview {
                let constraint = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superview, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1.0, constant: 0)
                constraint.priority = .fittingSizeLevel
                constraints.append(constraint)
            }
            return
        }
        if let minHeight = info.minHeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: nil, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1.0, constant: minHeight))
        }
        if let maxHeight = info.maxHeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: nil, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1.0, constant: maxHeight))
        }
        if let height = info.height, height == UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue {
            if let superview = view.superview, superview.constraintInfo?.height ?? UILayoutConstraintInfo.LayoutParams.matchParent.rawValue != UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue {
                let topConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: superview, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: (info.topMargin ?? 0) + (superview.constraintInfo?.paddingTop ?? 0))
                constraints.append(topConstraint)
                let bottomConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: superview, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: -((info.bottomMargin ?? 0) + (superview.constraintInfo?.paddingBottom ?? 0)))
                constraints.append(bottomConstraint)
            }
            return
        }
        if let height = info.height {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1.0, constant: height))
        }
        if let orientation = (view as? SJUIView)?.orientation, orientation == .vertical, info.height == nil, info.maxHeight == nil, info.heightWeight == nil, info.maxHeightWeight == nil {
            info.height = UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue
        }
    }
    
    public class func applyWidthConstraint(on view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        if let width = info.width, width == UILayoutConstraintInfo.LayoutParams.matchParent.rawValue {
            if let superview = view.superview {
                let constraint = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superview, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1.0, constant: 0)
                constraint.priority = .fittingSizeLevel
                constraints.append(constraint)
            }
            return
        }
        if let minWidth = info.minWidth {
            let constraint = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: nil, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1.0, constant: minWidth)
            constraints.append(constraint)
        }
        if let maxWidth = info.maxWidth {
            let constraint = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: nil, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1.0, constant: maxWidth)
            constraints.append(constraint)
        }
        if let width = info.width, width == UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue {
            if let superview = view.superview, superview.constraintInfo?.width ?? UILayoutConstraintInfo.LayoutParams.matchParent.rawValue != UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue {
                let leftConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: superview, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: (info.leftMargin ?? 0) + (superview.constraintInfo?.paddingLeft ?? 0))
                constraints.append(leftConstraint)
                let rightConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: superview, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: -((info.rightMargin ?? 0) + (superview.constraintInfo?.paddingRight ?? 0)))
                constraints.append(rightConstraint)
            }
            return
        }
        if let width = info.width {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1.0, constant: width))
        }
        if let orientation = (view as? SJUIView)?.orientation, orientation == .horizontal, info.width == nil, info.maxWidth == nil, info.widthWeight == nil, info.maxWidthWeight == nil {
            info.width = UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue
        }
    }
    
    public class func applyWrapContentConstraint(on view: UIView, toConstraintInfo info: UILayoutConstraintInfo, for constraints: inout [NSLayoutConstraint] ) {
        let subviews = view.subviews.filter{$0.visibility != .gone}
        if info.height ?? 0 == UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue {
            if let lastView = subviews.last, let view = (view as? SJUIView), let orientation = view.orientation, orientation == .vertical, view.direction == .topToBottom {
                let constraint = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: lastView, attribute: .bottom, multiplier: 1.0, constant: (info.paddingBottom ?? 0) + (lastView.constraintInfo?.bottomMargin ?? 0))
                constraints.append(constraint)
            } else if let lastView = subviews.last, let view = (view as? SJUIView), let orientation = view.orientation, orientation == .vertical, view.direction == .bottomToTop {
                let constraint = NSLayoutConstraint(item: view, attribute: .top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: lastView, attribute: .top, multiplier: 1.0, constant: -((info.paddingTop ?? 0) + (lastView.constraintInfo?.topMargin ?? 0)))
                constraints.append(constraint)
            } else if (view as? SJUIView)?.orientation ?? .horizontal != .vertical  {
                for v in subviews {
                    if v.constraintInfo?.alignTopOfView == nil || v.constraintInfo?.alignTopOfView?.visibility ?? .visible == .gone {
                        let bottomConstraint = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: v, attribute: .bottom, multiplier: 1.0, constant: (info.paddingBottom ?? 0) + (v.constraintInfo?.bottomMargin ?? 0))
                        bottomConstraint.priority = subviews.count == 1 ? .required : .defaultLow
                        constraints.append(bottomConstraint)
                        if subviews.count > 1 {
                            let bottomRequiredConstraint = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .greaterThanOrEqual, toItem: v, attribute: .bottom, multiplier: 1.0, constant: (info.paddingBottom ?? 0) + (v.constraintInfo?.bottomMargin ?? 0))
                            constraints.append(bottomRequiredConstraint)
                        }
                    }
                    if  v.constraintInfo?.alignBottomOfView == nil || v.constraintInfo?.alignBottomOfView?.visibility ?? .visible == .gone {
                        let topConstraint = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: v, attribute: .top, multiplier: 1.0, constant:  -((info.paddingTop ?? 0) + (v.constraintInfo?.topMargin ?? 0)))
                        topConstraint.priority = subviews.count == 1 ? .required : .defaultLow
                        constraints.append(topConstraint)
                        if subviews.count > 1 {
                            let topRequiredConstraint = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .lessThanOrEqual, toItem: v, attribute: .top, multiplier: 1.0, constant:  -((info.paddingTop ?? 0) + (v.constraintInfo?.topMargin ?? 0)))
                            constraints.append(topRequiredConstraint)
                        }
                    }
                }
            }
        }
        
        if info.width ?? 0 == UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue {
            if let lastView = subviews.last, let view = (view as? SJUIView), let orientation = view.orientation, orientation == .horizontal, view.direction == .rightToLeft {
                let constraint = NSLayoutConstraint(item: view, attribute: .left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: lastView, attribute: .left, multiplier: 1.0, constant: -((info.paddingLeft ?? 0) + (lastView.constraintInfo?.leftMargin ?? 0)))
                constraints.append(constraint)
            } else if let lastView = subviews.last, let view = (view as? SJUIView), let orientation = view.orientation, orientation == .horizontal, view.direction == .leftToRight {
                let constraint = NSLayoutConstraint(item: view, attribute: .right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: lastView, attribute: .right, multiplier: 1.0, constant: ((info.paddingRight ?? 0) + (lastView.constraintInfo?.rightMargin ?? 0)))
                constraints.append(constraint)
            } else if (view as? SJUIView)?.orientation ?? .vertical != .horizontal  {
                for v in subviews {
                    if v.constraintInfo?.alignRightOfView == nil || v.constraintInfo?.alignRightOfView?.visibility ?? .visible == .gone {
                        let leftConstraint = NSLayoutConstraint(item: view, attribute: .left, relatedBy: .equal, toItem: v, attribute: .left, multiplier: 1.0, constant: -((info.paddingLeft ?? 0) + (v.constraintInfo?.leftMargin ?? 0)))
                        leftConstraint.priority = subviews.count == 1 ? .required : .defaultLow
                        constraints.append(leftConstraint)
                        if subviews.count > 1 {
                            let leftRequiredConstraint = NSLayoutConstraint(item: view, attribute: .left, relatedBy: .lessThanOrEqual, toItem: v, attribute: .left, multiplier: 1.0, constant: -((info.paddingLeft ?? 0) + (v.constraintInfo?.leftMargin ?? 0)))
                            constraints.append(leftRequiredConstraint)
                        }
                    }
                    if v.constraintInfo?.alignLeftOfView == nil || v.constraintInfo?.alignLeftOfView?.visibility ?? .visible == .gone {
                        let rightConstraint = NSLayoutConstraint(item: view, attribute: .right, relatedBy: .equal, toItem: v, attribute: .right, multiplier: 1.0, constant: ((info.paddingRight ?? 0) + (v.constraintInfo?.rightMargin ?? 0)))
                        rightConstraint.priority = subviews.count == 1 ? .required : .defaultLow
                        constraints.append(rightConstraint)
                        if subviews.count > 1 {
                            let rightRequiredConstraint = NSLayoutConstraint(item: view, attribute: .right, relatedBy: .greaterThanOrEqual, toItem: v, attribute: .right, multiplier: 1.0, constant: ((info.paddingRight ?? 0) + (v.constraintInfo?.rightMargin ?? 0)))
                            constraints.append(rightRequiredConstraint)
                        }
                    }
                }
            }
        }
    }
}

public class UILayoutConstraintInfo {
    var attr: JSON?
    fileprivate var _constraints = [WeakConstraint]()
    public var constraints: [NSLayoutConstraint] {
        get {
            var constraints = [NSLayoutConstraint]()
            for weakConstraint in _constraints {
                if let constraint = weakConstraint.constraint {
                    constraints.append(constraint)
                }
            }
            return constraints
        }
    }
    public weak var toView: UIView?
    public var safeAreaInsetLeft:CGFloat = 0
    public var safeAreaInsetRight:CGFloat = 0
    public var safeAreaInsetTop: CGFloat = 0
    public var safeAreaInsetBottom: CGFloat = 0
    public var originalPaddingLeft:CGFloat!
    public var originalPaddingRight:CGFloat!
    public var originalPaddingTop: CGFloat!
    public var originalPaddingBottom: CGFloat!
    public var paddingLeft:CGFloat! {
        get {
            if safeAreaInsetLeft != 0 {
                return (originalPaddingLeft ?? 0) + safeAreaInsetLeft
            } else {
                return originalPaddingLeft
            }
        }
        
        set {
            originalPaddingLeft = newValue
        }
    }
    public var paddingRight:CGFloat! {
        get {
            if safeAreaInsetRight != 0 {
                return (originalPaddingRight ?? 0) + safeAreaInsetRight
            } else {
                return originalPaddingRight
            }
        }
        
        set {
            originalPaddingRight = newValue
        }
    }
    public var paddingTop: CGFloat! {
        get {
            if safeAreaInsetTop != 0 {
                return (originalPaddingTop ?? 0) + safeAreaInsetTop
            } else {
                return originalPaddingTop
            }
        }
        
        set {
            originalPaddingTop = newValue
        }
    }
    public var paddingBottom: CGFloat! {
        get {
            if safeAreaInsetBottom != 0 {
                return (originalPaddingBottom ?? 0) + safeAreaInsetBottom
            } else {
                return originalPaddingBottom
            }
        }
        
        set {
            originalPaddingBottom = newValue
        }
    }
    public var leftMargin:CGFloat!
    public var rightMargin:CGFloat!
    public var topMargin: CGFloat!
    public var bottomMargin: CGFloat!
    public var minLeftMargin:CGFloat!
    public var minRightMargin:CGFloat!
    public var minTopMargin: CGFloat!
    public var minBottomMargin: CGFloat!
    public var maxLeftMargin:CGFloat!
    public var maxRightMargin:CGFloat!
    public var maxTopMargin: CGFloat!
    public var maxBottomMargin: CGFloat!
    public var centerVertical: Bool!
    public var centerHorizontal: Bool!
    public var alignTop: Bool!
    public var alignBottom: Bool!
    public var alignLeft: Bool!
    public var alignRight: Bool!
    public weak var _alignTopOfView:UIView?
    public var alignTopOfView: UIView?
    {
        get {
            return _alignTopOfView?.visibility ?? .gone == .gone ? nil : _alignTopOfView
        }
        set {
            _alignTopOfView = newValue
        }
    }
    public weak var _alignBottomOfView:UIView?
    public var alignBottomOfView: UIView?
    {
        get {
            return _alignBottomOfView?.visibility ?? .gone == .gone ? nil : _alignBottomOfView
        }
        set {
            _alignBottomOfView = newValue
        }
    }
    public weak var _alignLeftOfView:UIView?
    public var alignLeftOfView: UIView?
    {
        get {
            return _alignLeftOfView?.visibility ?? .gone == .gone ? nil : _alignLeftOfView
        }
        set {
            _alignLeftOfView = newValue
        }
    }
    public weak var _alignRightOfView:UIView?
    public var alignRightOfView: UIView?
    {
        get {
            return _alignRightOfView?.visibility ?? .gone == .gone ? nil : _alignRightOfView
        }
        set {
            _alignRightOfView = newValue
        }
    }
    public weak var _alignTopView: UIView?
    public var alignTopView: UIView?
    {
        get {
            return _alignTopView?.visibility ?? .gone == .gone ? nil : _alignTopView
        }
        set {
            _alignTopView = newValue
        }
    }
    public weak var _alignBottomView: UIView?
    public var alignBottomView: UIView?
    {
        get {
            return _alignBottomView?.visibility ?? .gone == .gone ? nil : _alignBottomView
        }
        set {
            _alignBottomView = newValue
        }
    }
    public weak var _alignLeftView: UIView?
    public var alignLeftView: UIView?
    {
        get {
            return _alignLeftView?.visibility ?? .gone == .gone ? nil : _alignLeftView
        }
        set {
            _alignLeftView = newValue
        }
    }
    public weak var _alignRightView: UIView?
    public var alignRightView: UIView?
    {
        get {
            return _alignRightView?.visibility ?? .gone == .gone ? nil : _alignRightView
        }
        set {
            _alignRightView = newValue
        }
    }
    public weak var _alignCenterVerticalView: UIView?
    public var alignCenterVerticalView: UIView?
    {
        get {
            return _alignCenterVerticalView?.visibility ?? .gone == .gone ? nil : _alignCenterVerticalView
        }
        set {
            _alignCenterVerticalView = newValue
        }
    }
    public weak var _alignCenterHorizontalView: UIView?
    public var alignCenterHorizontalView: UIView?
    {
        get {
            return _alignCenterHorizontalView?.visibility ?? .gone == .gone ? nil : _alignCenterHorizontalView
        }
        set {
            _alignCenterHorizontalView = newValue
        }
    }
    public var width: CGFloat!
    public var height: CGFloat!
    public var minWidth: CGFloat!
    public var minHeight: CGFloat!
    public var maxWidth: CGFloat!
    public var maxHeight: CGFloat!
    public var widthWeight: CGFloat!
    public var heightWeight: CGFloat!
    public var aspectWidth: CGFloat!
    public var aspectHeight: CGFloat!
    public var maxWidthWeight: CGFloat!
    public var maxHeightWeight: CGFloat!
    public var minWidthWeight: CGFloat!
    public var minHeightWeight: CGFloat!
    public var weight: CGFloat!
    weak var superviewToAdd: UIView?
    weak var nextToView: UIView?
    var gravities = [SJUIView.Gravity: Bool]()
    
    public init(toView: UIView? = nil, paddingLeft:CGFloat! = nil, paddingRight:CGFloat! = nil, paddingTop: CGFloat! = nil, paddingBottom: CGFloat! = nil, leftPadding:CGFloat! = nil, rightPadding:CGFloat! = nil, topPadding: CGFloat! = nil, bottomPadding: CGFloat! = nil, minLeftPadding:CGFloat! = nil, minRightPadding:CGFloat! = nil, minTopPadding: CGFloat! = nil, minBottomPadding: CGFloat! = nil, maxLeftPadding:CGFloat! = nil, maxRightPadding:CGFloat! = nil, maxTopPadding: CGFloat! = nil, maxBottomPadding: CGFloat! = nil, leftMargin:CGFloat! = nil, rightMargin:CGFloat! = nil, topMargin: CGFloat! = nil, bottomMargin: CGFloat! = nil, minLeftMargin:CGFloat! = nil, minRightMargin:CGFloat! = nil, minTopMargin: CGFloat! = nil, minBottomMargin: CGFloat! = nil, maxLeftMargin:CGFloat! = nil, maxRightMargin:CGFloat! = nil, maxTopMargin: CGFloat! = nil, maxBottomMargin: CGFloat! = nil, centerVertical: Bool! = nil, centerHorizontal: Bool! = nil, centerInParent: Bool! = nil, alignTop: Bool! = nil, alignBottom: Bool! = nil, alignLeft: Bool! = nil, alignRight: Bool! = nil, alignTopToView: Bool! = nil, alignBottomToView: Bool! = nil, alignLeftToView: Bool! = nil, alignRightToView: Bool! = nil ,alignCenterVerticalToView: Bool! = nil ,alignCenterHorizontalToView: Bool! = nil, alignTopOfView: UIView! = nil, alignBottomOfView: UIView! = nil, alignLeftOfView: UIView! = nil, alignRightOfView: UIView! = nil, alignTopView: UIView! = nil, alignBottomView: UIView! = nil, alignLeftView: UIView! = nil, alignRightView: UIView! = nil ,alignCenterVerticalView: UIView! = nil ,alignCenterHorizontalView: UIView! = nil, width:CGFloat! = nil, height:CGFloat! = nil, minWidth:CGFloat! = nil, minHeight:CGFloat! = nil, maxWidth:CGFloat! = nil, maxHeight:CGFloat! = nil, widthWeight:CGFloat! = nil, heightWeight:CGFloat! = nil, aspectWidth: CGFloat! = nil, aspectHeight: CGFloat! = nil, maxWidthWeight: CGFloat! = nil, maxHeightWeight: CGFloat! = nil, minWidthWeight: CGFloat! = nil, minHeightWeight: CGFloat! = nil,weight: CGFloat! = nil, gravities: [String]? = nil, superview: UIView? = nil) {
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
        if let centerInParent = centerInParent {
            self.centerVertical = centerInParent
            self.centerHorizontal = centerInParent
        }
        if let centerHorizontal = centerHorizontal {
            self.centerHorizontal = centerHorizontal
        }
        if let centerVertical = centerVertical {
            self.centerVertical = centerVertical
        }
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
        self.weight = weight
        fixMaxAndMinSize()
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
        fixLegacyAttributes(toView: toView, alignCenterVerticalToView: alignCenterVerticalToView, alignTopToView: alignTopToView, alignBottomToView: alignBottomToView, alignCenterHorizontalToView: alignCenterHorizontalToView, alignLeftToView: alignLeftToView, alignRightToView: alignRightToView, topMargin: topMargin, leftMargin: leftMargin, bottomMargin: bottomMargin, rightMargin: rightMargin, maxTopMargin: maxTopMargin, maxLeftMargin: maxLeftMargin, maxBottomMargin: maxBottomMargin, maxRightMargin: maxRightMargin, minTopMargin: minTopMargin, minLeftMargin: minLeftMargin, minBottomMargin: minBottomMargin, minRightMargin: minRightMargin)
        if let gravities = gravities {
            for gravity in gravities {
                if let g = SJUIView.Gravity(rawValue: gravity) {
                    self.gravities[g] = true
                }
            }
        }
        inheritGravityFrom(superview: superview)
    }
    
    private func fixMaxAndMinSize() {
        if self.maxWidth != nil && self.minWidth != nil && self.maxWidth < self.minWidth {
            self.maxWidth = self.minWidth
        }
        if self.maxHeight != nil && self.minHeight != nil && self.maxHeight < self.minHeight {
            self.maxHeight = self.minHeight
        }
        if self.width != nil && self.minWidth != nil && self.width != UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue &&  self.width != UILayoutConstraintInfo.LayoutParams.matchParent.rawValue && self.width < self.minWidth {
            self.width = self.minWidth
        } else if self.width != nil && self.maxWidth != nil && self.width != UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue &&  self.width != UILayoutConstraintInfo.LayoutParams.matchParent.rawValue && self.width > self.maxWidth {
            self.width = self.maxWidth
        }
        if self.height != nil && self.minHeight != nil && self.height != UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue &&  self.height != UILayoutConstraintInfo.LayoutParams.matchParent.rawValue && self.height < self.minHeight {
            self.height = self.minHeight
        } else if self.height != nil && self.maxHeight != nil && self.height != UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue &&  self.height != UILayoutConstraintInfo.LayoutParams.matchParent.rawValue && self.height > self.maxHeight {
            self.height = self.maxHeight
        }
        
        if self.maxWidthWeight != nil && self.minWidthWeight != nil && self.maxWidthWeight < self.minWidthWeight {
            self.maxWidthWeight = self.minWidthWeight
        }
        if self.maxHeightWeight != nil && self.minHeightWeight != nil && self.maxHeightWeight < self.minHeightWeight {
            self.maxHeightWeight = self.minHeightWeight
        }
    }
    
    private func fixLegacyAttributes(toView: UIView?, alignCenterVerticalToView: Bool?, alignTopToView: Bool?, alignBottomToView: Bool?, alignCenterHorizontalToView: Bool?, alignLeftToView: Bool?, alignRightToView: Bool?, topMargin: CGFloat?, leftMargin: CGFloat?, bottomMargin: CGFloat?, rightMargin: CGFloat?, maxTopMargin: CGFloat?, maxLeftMargin: CGFloat?, maxBottomMargin: CGFloat?, maxRightMargin: CGFloat?, minTopMargin: CGFloat?, minLeftMargin: CGFloat?, minBottomMargin: CGFloat?, minRightMargin: CGFloat?) {
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
    
    private  func inheritGravityFrom(superview: UIView?) {
        if let layoutGravities = superview?.constraintInfo?.gravities, let orientation = (superview as? SJUIView)?.orientation {
            if self.alignTop == nil && self.alignBottom == nil {
                self.alignTop = layoutGravities[.top]
                self.alignBottom = layoutGravities[.bottom]
            }
            if self.alignLeft == nil && self.alignRight == nil {
                self.alignLeft = layoutGravities[.left]
                self.alignRight = layoutGravities[.right]
            }
            switch orientation {
            case .vertical:
                if self.centerHorizontal == nil && self.alignLeft == nil && self.alignRight == nil {
                    self.centerHorizontal = layoutGravities[.centerHorizontal]
                }
            case .horizontal:
                if self.centerVertical == nil && self.alignTop == nil && self.alignBottom == nil {
                    self.centerVertical = layoutGravities[.centerVertical]
                }
            }
        }
    }
    
    public class func sizeFrom(attr: JSON) -> CGFloat? {
        let size: CGFloat?
        if let s = attr.cgFloat {
            size = s
        } else if let s = attr.string {
            if s == "matchParent" {
                size = UILayoutConstraintInfo.LayoutParams.matchParent.rawValue
            } else if s == "wrapContent" {
                size = UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue
            } else {
                size = nil
            }
        } else {
            size = nil
        }
        return size
    }
    
    public class func paddingsFrom(attr: JSON) -> [CGFloat?] {
        let viewPaddings: [CGFloat?]
        if let paddings = attr["paddings"].arrayObject as? [CGFloat] {
            switch (paddings.count) {
            case 0:
                viewPaddings = [attr["paddingTop"].cgFloat,attr["paddingLeft"].cgFloat,attr["paddingBottom"].cgFloat,attr["paddingRight"].cgFloat]
            case 1:
                viewPaddings = [attr["paddingTop"].cgFloat ?? paddings[0], attr["paddingLeft"].cgFloat ?? paddings[0], attr["paddingBottom"].cgFloat ?? paddings[0], attr["paddingRight"].cgFloat ?? paddings[0]]
            case 2:
                viewPaddings = [attr["paddingTop"].cgFloat ?? paddings[0], attr["paddingLeft"].cgFloat ?? paddings[1], attr["paddingBottom"].cgFloat ?? paddings[0], attr["paddingRight"].cgFloat ?? paddings[1]]
            case 3:
                viewPaddings = [attr["paddingTop"].cgFloat ?? paddings[0], attr["paddingLeft"].cgFloat ?? paddings[1], attr["paddingBottom"].cgFloat ?? paddings[2], attr["paddingRight"].cgFloat ?? paddings[1]]
            default:
                viewPaddings = [attr["paddingTop"].cgFloat ?? paddings[0], attr["paddingLeft"].cgFloat ?? paddings[1], attr["paddingBottom"].cgFloat ?? paddings[2], attr["paddingRight"].cgFloat ?? paddings[3]]
            }
        } else {
            viewPaddings = [attr["paddingTop"].cgFloat,attr["paddingLeft"].cgFloat,attr["paddingBottom"].cgFloat,attr["paddingRight"].cgFloat]
        }
        return viewPaddings
    }
    
    public class func marginsFrom(attr: JSON) -> [CGFloat?] {
        let viewMargins: [CGFloat?]
        if let margins = attr["margins"].arrayObject as? [CGFloat] {
            switch (margins.count) {
            case 0:
                viewMargins = [attr["topMargin"].cgFloat,attr["leftMargin"].cgFloat,attr["bottomMargin"].cgFloat,attr["rightMargin"].cgFloat]
            case 1:
                viewMargins = [attr["topMargin"].cgFloat ?? margins[0], attr["leftMargin"].cgFloat ?? margins[0], attr["bottomMargin"].cgFloat ?? margins[0], attr["rightMargin"].cgFloat ?? margins[0]]
            case 2:
                viewMargins = [attr["topMargin"].cgFloat ?? margins[0], attr["leftMargin"].cgFloat ?? margins[1], attr["bottomMargin"].cgFloat ?? margins[0], attr["rightMargin"].cgFloat ?? margins[1]]
            case 3:
                viewMargins = [attr["topMargin"].cgFloat ?? margins[0], attr["leftMargin"].cgFloat ?? margins[1], attr["bottomMargin"].cgFloat ?? margins[2], attr["rightMargin"].cgFloat ?? margins[1]]
            default:
                viewMargins = [attr["topMargin"].cgFloat ?? margins[0], attr["leftMargin"].cgFloat ?? margins[1], attr["bottomMargin"].cgFloat ?? margins[2], attr["rightMargin"].cgFloat ?? margins[3]]
            }
        } else {
            viewMargins = [attr["topMargin"].cgFloat,attr["leftMargin"].cgFloat,attr["bottomMargin"].cgFloat,attr["rightMargin"].cgFloat]
        }
        return viewMargins
    }
    
    public func findRelatedViews(views: [String: UIView]) {
        guard let attr = attr else {
            return
        }
        if let str = attr["toView"].string {
            self.toView = views[str]
        }
        if let str = attr["alignTopOfView"].string {
            self.alignTopOfView = views[str]
        }
        if let str = attr["alignBottomOfView"].string {
            self.alignBottomOfView = views[str]
        }
        if let str = attr["alignLeftOfView"].string {
            self.alignLeftOfView = views[str]
        }
        if let str = attr["alignRightOfView"].string {
            self.alignRightOfView = views[str]
        }
        if let str = attr["alignTopView"].string {
            self.alignTopView = views[str]
        }
        if let str = attr["alignBottomView"].string {
            self.alignBottomView = views[str]
        }
        if let str = attr["alignLeftView"].string {
            self.alignLeftView = views[str]
        }
        if let str = attr["alignRightView"].string {
            self.alignRightView = views[str]
        }
        if let str = attr["alignCenterVerticalView"].string {
            self.alignCenterVerticalView = views[str]
        }
        if let str = attr["alignCenterHorizontalView"].string {
            self.alignCenterVerticalView = views[str]
        }
        
    }
    
    public enum LayoutParams: CGFloat {
        case matchParent = -1
        case wrapContent = -2
    }
}

class WeakConstraint {
    private weak var _constraint: NSLayoutConstraint?
    var constraint: NSLayoutConstraint? {
        set {
            self._constraint = newValue
        }
        get {
            return self._constraint
        }
    }
    
    required init(constraint: NSLayoutConstraint) {
        _constraint = constraint
    }
    
    class func constraints(with constraints: [NSLayoutConstraint]) -> [WeakConstraint] {
        var weakConstraints = [WeakConstraint]()
        for constraint in constraints {
            let weakConstraint = WeakConstraint.init(constraint: constraint)
            weakConstraints.append(weakConstraint)
        }
        return weakConstraints
    }
}



