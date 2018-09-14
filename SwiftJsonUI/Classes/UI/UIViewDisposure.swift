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
    
    open class func applyConstraint(onView view: UIView, toConstraintInfo info: UILayoutConstraintInfo) {
        var constraints = Array<NSLayoutConstraint>()
        
        //親ビューに対して
        if let superview = view.superview {
            
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
            
            //下揃え
            if let _ = info.alignBottom {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0))
            }
            
            //左揃え
            if let _ = info.alignLeft {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0))
            }
            
            //右揃え
            if let _ = info.alignRight {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0))
            }
            
            //高さの制約
            if let heightWeight = info.heightWeight {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.height, multiplier: heightWeight, constant: 0))
                
                if let _ = superview as? UIScrollView {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0))
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0))
                } else if info.centerVertical == nil && info.topPadding == nil && info.bottomPadding == nil && info.alignBottom == nil && ((info.topMargin == nil && info.bottomMargin == nil && info.minTopMargin == nil && info.minBottomMargin == nil && info.maxTopMargin == nil && info.maxBottomMargin == nil && info.alignTopToView == nil && info.alignBottomToView == nil) || info.toView == nil) {
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
            
            //幅の制約
            if let widthWeight = info.widthWeight {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.width, multiplier: widthWeight, constant: 0))
                
                if let _ = superview as? UIScrollView {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0))
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0))
                } else if info.centerHorizontal == nil && info.leftPadding == nil && info.rightPadding == nil && info.alignLeft == nil && info.alignRight == nil && ((info.leftMargin == nil && info.rightMargin == nil && info.minLeftMargin == nil && info.minRightMargin == nil && info.maxLeftMargin == nil && info.maxRightMargin == nil && info.alignLeftToView == nil && info.alignRightToView == nil) || info.toView == nil) && info.alignRightOfView == nil && info.alignLeftOfView == nil {
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
            
            //高さのアスペクト
            if let aspectHeight = info.aspectHeight {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.width, multiplier: aspectHeight, constant: 0))
            }
            
            //幅のアスペクト
            if let aspectWidth = info.aspectWidth {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.height, multiplier: aspectWidth, constant: 0))
            }
            
            //パディングの制約
            if let topPadding = info.topPadding {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: topPadding))
            } else {
                if let topPadding = info.minTopPadding {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: topPadding))
                }
                if let topPadding = info.maxTopPadding {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: topPadding))
                }
            }
            
            if let bottomPadding = info.bottomPadding {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: -bottomPadding))
            } else {
                if let bottomPadding = info.minBottomPadding {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: -bottomPadding))
                }
                
                if let bottomPadding = info.maxBottomPadding {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: -bottomPadding))
                }
            }
            
            if let leftPadding = info.leftPadding {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: leftPadding))
            } else {
                if let leftPadding = info.minLeftPadding {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: leftPadding))
                }
                if let leftPadding = info.maxLeftPadding {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: leftPadding))
                }
            }
            
            if let rightPadding = info.rightPadding {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: -rightPadding))
            } else {
                if let rightPadding = info.minRightPadding {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: -rightPadding))
                }
                if let rightPadding = info.maxRightPadding {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: superview, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: -rightPadding))
                }
            }
            
            if let _ = superview as? UIScrollView {
                if info.heightWeight == nil {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0))
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0))
                }
            }
            
            if let _ = superview as? UIScrollView {
                if info.widthWeight == nil {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0))
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: superview, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0))
                }
            }
        }
        
        //任意のビューに対して
        if let toView = info.toView {
            
            //中央揃え
            if let _ = info.alignCenterVerticalToView {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: toView, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0))
            } else {
                //上揃え
                if let _ = info.alignTopToView {
                    let topMargin = info.topMargin ?? 0
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: toView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0 + topMargin))
                } else if let topMargin = info.topMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: toView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: topMargin))
                } else {
                    if let topMargin = info.minTopMargin {
                        constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: toView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: topMargin))
                    }
                    
                    if let topMargin = info.maxTopMargin {
                        constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: toView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: topMargin))
                    }
                }
                
                //下揃え
                if let _ = info.alignBottomToView {
                    let bottomMargin = info.bottomMargin ?? 0
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: toView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0 - bottomMargin))
                } else if let bottomMargin = info.bottomMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: toView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: -bottomMargin))
                } else {
                    if let bottomMargin = info.minBottomMargin {
                        constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: toView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: -bottomMargin))
                    }
                    if let bottomMargin = info.maxBottomMargin {
                        constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: toView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: -bottomMargin))
                    }
                }
                
            }
            
            //中央揃え
            if let _ = info.alignCenterHorizontalToView {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: toView, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0))
            } else {
                //左揃え
                if let _ = info.alignLeftToView {
                    let leftMargin = info.leftMargin ?? 0
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: toView, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0 + leftMargin))
                } else if let leftMargin = info.leftMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: toView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: leftMargin))
                } else {
                    if let leftMargin = info.minLeftMargin {
                        constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: toView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: leftMargin))
                    }
                    
                    if let leftMargin = info.maxLeftMargin {
                        constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: toView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: leftMargin))
                    }
                }
                
                //右揃え
                if let _ = info.alignRightToView {
                    let rightMargin = info.rightMargin ?? 0
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: toView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0 - rightMargin))
                } else if let rightMargin = info.rightMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: toView, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: -rightMargin))
                } else {
                    if let rightMargin = info.minRightMargin {
                        constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: toView, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: -rightMargin))
                    }
                    if let rightMargin = info.maxRightMargin {
                        constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: toView, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: -rightMargin))
                    }
                }
            }
        }
        
        
        
        if let topOfView = info.alignTopOfView {
            if let bottomMargin = info.bottomMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: topOfView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0 - bottomMargin))
            } else if info.maxBottomMargin == nil && info.minBottomMargin == nil {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: topOfView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0))
            } else {
                if let bottomMargin = info.minBottomMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: topOfView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0 - bottomMargin))
                }
                if let bottomMargin = info.maxBottomMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: topOfView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0 - bottomMargin))
                }
            }
        }
        
        if let bottomOfView = info.alignBottomOfView {
            if let topMargin = info.topMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: bottomOfView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0 + topMargin))
            } else if info.minTopMargin == nil && info.minBottomMargin == nil {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: bottomOfView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0))
            } else {
                if let topMargin = info.minTopMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: bottomOfView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0 + topMargin))
                }
                if let topMargin = info.maxTopMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: bottomOfView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0 + topMargin))
                }
            }
        }
        
        if let leftOfView = info.alignLeftOfView {
            if let rightMargin = info.rightMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: leftOfView, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0 - rightMargin))
            } else if info.minRightMargin == nil && info.maxRightMargin == nil {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: leftOfView, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0))
            } else {
                if let rightMargin = info.minRightMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: leftOfView, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0 - rightMargin))
                }
                if let rightMargin = info.maxRightMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: leftOfView, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0 - rightMargin))
                }
            }
        }
        
        if let rightOfView = info.alignRightOfView {
            if let leftMargin = info.leftMargin {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: rightOfView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0 + leftMargin))
            } else if info.minLeftMargin == nil && info.maxLeftMargin == nil {
                constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: rightOfView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0))
            } else {
                if let leftMargin = info.minLeftMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: rightOfView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0 + leftMargin))
                }
                if let leftMargin = info.maxLeftMargin {
                    constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: rightOfView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0 + leftMargin))
                }
            }
        }
        
        //中央揃え
        if let centerVerticalView = info.alignCenterVerticalView {
            let constant: CGFloat
            if let topMargin = info.topMargin {
                constant = topMargin
            } else if let bottomMargin = info.bottomMargin {
                constant = -bottomMargin
            } else {
                constant = 0
            }
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: centerVerticalView, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: constant))
        } else {
            
            if let topView = info.alignTopView {
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
            
            if let bottomView = info.alignBottomView {
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
        }
        
        //中央揃え
        if let centerHorizontalView = info.alignCenterHorizontalView {
            let constant: CGFloat
            if let leftMargin = info.leftMargin {
                constant = leftMargin
            } else if let rightMargin = info.rightMargin {
                constant = -rightMargin
            } else {
                constant = 0
            }
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: centerHorizontalView, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: constant))
        } else {
            
            if let leftView = info.alignLeftView {
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
            
            if let rightView = info.alignRightView {
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
        }
        
        if let minWidth = info.minWidth {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: minWidth))
        }
        
        if let minHeight = info.minHeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: minHeight))
        }
        
        if let maxWidth = info.maxWidth {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: maxWidth))
        }
        
        if let maxHeight = info.maxHeight {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: maxHeight))
        }
        
        
        if let width = info.width {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: width))
        }
        
        if let height = info.height {
            constraints.append(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: height))
        }
        
        NSLayoutConstraint.activate(constraints)
        
    }
}

public class UILayoutConstraintInfo {
    weak var toView: UIView?
    var leftPadding:CGFloat!
    var rightPadding:CGFloat!
    var topPadding: CGFloat!
    var bottomPadding: CGFloat!
    var minLeftPadding:CGFloat!
    var minRightPadding:CGFloat!
    var minTopPadding: CGFloat!
    var minBottomPadding: CGFloat!
    var maxLeftPadding:CGFloat!
    var maxRightPadding:CGFloat!
    var maxTopPadding: CGFloat!
    var maxBottomPadding: CGFloat!
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
    var alignBottom: Bool!
    var alignLeft: Bool!
    var alignRight: Bool!
    var alignTopToView: Bool!
    var alignBottomToView: Bool!
    var alignLeftToView: Bool!
    var alignRightToView: Bool!
    var alignCenterVerticalToView:Bool!
    var alignCenterHorizontalToView:Bool!
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
    
    public init(toView: UIView?, leftPadding:CGFloat! = nil, rightPadding:CGFloat! = nil, topPadding: CGFloat! = nil, bottomPadding: CGFloat! = nil, minLeftPadding:CGFloat! = nil, minRightPadding:CGFloat! = nil, minTopPadding: CGFloat! = nil, minBottomPadding: CGFloat! = nil, maxLeftPadding:CGFloat! = nil, maxRightPadding:CGFloat! = nil, maxTopPadding: CGFloat! = nil, maxBottomPadding: CGFloat! = nil, leftMargin:CGFloat! = nil, rightMargin:CGFloat! = nil, topMargin: CGFloat! = nil, bottomMargin: CGFloat! = nil, minLeftMargin:CGFloat! = nil, minRightMargin:CGFloat! = nil, minTopMargin: CGFloat! = nil, minBottomMargin: CGFloat! = nil, maxLeftMargin:CGFloat! = nil, maxRightMargin:CGFloat! = nil, maxTopMargin: CGFloat! = nil, maxBottomMargin: CGFloat! = nil, centerVertical: Bool! = nil, centerHorizontal: Bool! = nil, alignBottom: Bool! = nil, alignLeft: Bool! = nil, alignRight: Bool! = nil, alignTopToView: Bool! = nil, alignBottomToView: Bool! = nil, alignLeftToView: Bool! = nil, alignRightToView: Bool! = nil ,alignCenterVerticalToView: Bool! = nil ,alignCenterHorizontalToView: Bool! = nil, alignTopOfView: UIView! = nil, alignBottomOfView: UIView! = nil, alignLeftOfView: UIView! = nil, alignRightOfView: UIView! = nil, alignTopView: UIView! = nil, alignBottomView: UIView! = nil, alignLeftView: UIView! = nil, alignRightView: UIView! = nil ,alignCenterVerticalView: UIView! = nil ,alignCenterHorizontalView: UIView! = nil, width:CGFloat! = nil, height:CGFloat! = nil, minWidth:CGFloat! = nil, minHeight:CGFloat! = nil, maxWidth:CGFloat! = nil, maxHeight:CGFloat! = nil, widthWeight:CGFloat! = nil, heightWeight:CGFloat! = nil, aspectWidth: CGFloat! = nil, aspectHeight: CGFloat! = nil, maxWidthWeight: CGFloat! = nil, maxHeightWeight: CGFloat! = nil, minWidthWeight: CGFloat! = nil, minHeightWeight: CGFloat! = nil) {
        self.toView = toView
        self.leftPadding = leftPadding
        self.rightPadding = rightPadding
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.minLeftPadding = minLeftPadding
        self.minRightPadding = minRightPadding
        self.minTopPadding = minTopPadding
        self.minBottomPadding = minBottomPadding
        self.maxLeftPadding = maxLeftPadding
        self.maxRightPadding = maxRightPadding
        self.maxTopPadding = maxTopPadding
        self.maxBottomPadding = maxBottomPadding
        self.leftMargin = leftMargin
        self.rightMargin = rightMargin
        self.topMargin = topMargin
        self.bottomMargin = bottomMargin
        self.minLeftMargin = minLeftMargin
        self.minRightMargin = minRightMargin
        self.minTopMargin = minTopMargin
        self.minBottomMargin = minBottomMargin
        self.maxLeftMargin = maxLeftMargin
        self.maxRightMargin = maxRightMargin
        self.maxTopMargin = maxTopMargin
        self.maxBottomMargin = maxBottomMargin
        self.centerHorizontal = centerHorizontal
        self.centerVertical = centerVertical
        self.alignBottom = alignBottom
        self.alignLeft = alignLeft
        self.alignRight = alignRight
        self.alignTopToView = alignTopToView
        self.alignBottomToView = alignBottomToView
        self.alignLeftToView = alignLeftToView
        self.alignRightToView = alignRightToView
        self.alignCenterVerticalToView = alignCenterVerticalToView
        self.alignCenterHorizontalToView = alignCenterHorizontalToView
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
        
    }
}
