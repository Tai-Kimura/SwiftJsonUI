//
//  SJUICollectionView.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2018/09/13.

//

import UIKit

open class SJUICollectionView: UICollectionView {

    /// Scroll anchor for initial display (e.g., .bottom to start at bottom)
    public enum ScrollAnchor {
        case top, bottom
    }
    public var defaultScrollAnchor: ScrollAnchor?

    open class var viewClass: SJUICollectionView.Type {
        get {
            return SJUICollectionView.self
        }
    }
    
    required public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUICollectionView {
        let collectionViewLayout = getCollectionViewLayout(attr: attr)
        let isWrapContent = attr["height"].string == "wrapContent" || attr["height"].string == "wrap_content"
        let c: SJUICollectionView
        if isWrapContent {
            c = WrapContentCollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
            c.isScrollEnabled = false
        } else {
            c = viewClass.init(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        }
        if #available(iOS 11.0, *) {
            if let contentInsetAdjustmentBehavior = attr["contentInsetAdjustmentBehavior"].string {
                switch contentInsetAdjustmentBehavior {
                case "automatic":
                    c.contentInsetAdjustmentBehavior = .automatic
                case "always":
                    c.contentInsetAdjustmentBehavior = .always
                case "never":
                    c.contentInsetAdjustmentBehavior = .never
                case "scrollableAxes":
                    c.contentInsetAdjustmentBehavior = .scrollableAxes
                default:
                    c.contentInsetAdjustmentBehavior = .never
                }
            }
        }
        var contentInsets = Array<CGFloat>()
        if let insetStr = attr["contentInsets"].string {
            let paddingStars = insetStr.components(separatedBy: "|")
            for p in paddingStars {
                if let n = NumberFormatter().number(from: p) {
                    contentInsets.append(CGFloat(truncating:n))
                }
            }
        } else if let insetArray = attr["contentInsets"].array {
            for inset in insetArray {
                if let value = inset.cgFloat {
                    contentInsets.append(value)
                }
            }
        }
        var insets:[CGFloat] = [0,0,0,0]
        switch (contentInsets.count) {
        case 0:
            break
        case 1:
            insets = [contentInsets[0], contentInsets[0], contentInsets[0], contentInsets[0]]
        case 2:
            insets = [contentInsets[0], contentInsets[1], contentInsets[0], contentInsets[1]]
        case 3:
            insets = [contentInsets[0], contentInsets[1], contentInsets[2], contentInsets[1]]
        default:
            insets = [contentInsets[0], contentInsets[1], contentInsets[2], contentInsets[3]]
        }
        c.contentInset = UIEdgeInsets.init(top: insets[0], left: insets[1], bottom: insets[2], right: insets[3])
        c.showsHorizontalScrollIndicator = attr["showsHorizontalScrollIndicator"].boolValue
        c.showsVerticalScrollIndicator = attr["showsVerticalScrollIndicator"].boolValue
        if let paging = attr["paging"].bool {
            c.isPagingEnabled = paging
        }
        if var moduleName = Bundle.main.infoDictionary!["CFBundleName"] as? String {
            moduleName = moduleName.replacingOccurrences(of: "[^0-9a-zA-Z_]", with: "_", options: .regularExpression, range: nil)
            if let cellClasses = attr["cellClasses"].array {
                for cellClass in cellClasses {
                    if let className = cellClass["className"].string, let classFromString = NSClassFromString("\(moduleName).\(className)") {
                        let cellIdentifier = cellClass["identifier"].string ?? className
                        c.register(classFromString, forCellWithReuseIdentifier: cellIdentifier)
                    }
                }
            }
            if let headerClasses = attr["headerClasses"].array {
                for headerClass in headerClasses {
                    if let className = headerClass["className"].string, let classFromString = NSClassFromString("\(moduleName).\(className)") {
                        let headerIdentifier = headerClass["identifier"].string ?? className
                        c.register(classFromString, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerIdentifier)
                    }
                }
            }
            if let footerClasses = attr["footerClasses"].array {
                for footerClass in footerClasses {
                    if let className = footerClass["className"].string, let classFromString = NSClassFromString("\(moduleName).\(className)") {
                        let footerIdentifier = footerClass["identifier"].string ?? className
                        c.register(classFromString, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: footerIdentifier)
                    }
                }
            }
        }
        // scrollEnabled
        if let scrollEnabled = attr["scrollEnabled"].bool {
            c.isScrollEnabled = scrollEnabled
        }

        // containerInset (alias for contentInsets)
        if attr["containerInset"].array != nil || attr["containerInset"].string != nil {
            var containerInsets: [CGFloat] = []
            if let insetArray = attr["containerInset"].array {
                for inset in insetArray {
                    if let value = inset.cgFloat {
                        containerInsets.append(value)
                    }
                }
            } else if let insetStr = attr["containerInset"].string {
                for p in insetStr.components(separatedBy: "|") {
                    if let n = NumberFormatter().number(from: p) {
                        containerInsets.append(CGFloat(truncating: n))
                    }
                }
            }
            if !containerInsets.isEmpty {
                var ci: [CGFloat] = [0, 0, 0, 0]
                switch containerInsets.count {
                case 1: ci = [containerInsets[0], containerInsets[0], containerInsets[0], containerInsets[0]]
                case 2: ci = [containerInsets[0], containerInsets[1], containerInsets[0], containerInsets[1]]
                case 4: ci = [containerInsets[0], containerInsets[1], containerInsets[2], containerInsets[3]]
                default: break
                }
                c.contentInset = UIEdgeInsets(top: ci[0], left: ci[1], bottom: ci[2], right: ci[3])
            }
        }

        // defaultScrollAnchor - scroll to bottom after initial layout
        if attr["defaultScrollAnchor"].string == "bottom" {
            c.defaultScrollAnchor = .bottom
        }

        if attr["setTargetAsDelegate"].boolValue {
            c.delegate = target as? UICollectionViewDelegate
        }
        if attr["setTargetAsDataSource"].boolValue {
            c.dataSource = target as? UICollectionViewDataSource
        }
        
        // Enable keyboard avoidance if specified in JSON
        if let keyboardAvoidance = attr["keyboardAvoidance"].bool {
            c.isKeyboardAvoidanceEnabled = keyboardAvoidance
        } else {
            // Use global configuration default
            c.isKeyboardAvoidanceEnabled = KeyboardAvoidanceConfig.shared.isEnabledByDefault
        }
        
        return c
    }
    
    open class func getCollectionViewLayout(attr: JSON) -> UICollectionViewLayout {
        let collectionViewLayout = getCollectionViewFlowLayout(attr: attr)
        let weight = attr["itemWeight"].cgFloat != nil ? attr["itemWeight"].cgFloat! : 1.0
        collectionViewLayout.itemSize = CGSize(width: UIScreen.main.bounds.size.width*weight, height: 300)
        var edgeInsets = Array<CGFloat>()
        if let insetStr = attr["insets"].string {
            let paddingStars = insetStr.components(separatedBy: "|")
            for p in paddingStars {
                if let n = NumberFormatter().number(from: p) {
                    edgeInsets.append(CGFloat(truncating:n))
                }
            }
        } else if let insetArray = attr["insets"].array {
            for inset in insetArray {
                if let value = inset.cgFloat {
                    edgeInsets.append(value)
                }
            }
        }
        
        if edgeInsets.isEmpty {
            let insetHorizontal = attr["insetHorizontal"].cgFloat != nil ? attr["insetHorizontal"].cgFloat! : 0
            let insetVertical = attr["insetVertical"].cgFloat != nil ? attr["insetVertical"].cgFloat! : 0
            collectionViewLayout.sectionInset = UIEdgeInsets.init(top: insetVertical, left: insetHorizontal, bottom: insetVertical, right: insetHorizontal)
        } else {
            var insets:[CGFloat] = [0,0,0,0]
            switch (edgeInsets.count) {
            case 0:
                break
            case 1:
                insets = [edgeInsets[0], edgeInsets[0], edgeInsets[0], edgeInsets[0]]
            case 2:
                insets = [edgeInsets[0], edgeInsets[1], edgeInsets[0], edgeInsets[1]]
            case 3:
                insets = [edgeInsets[0], edgeInsets[1], edgeInsets[2], edgeInsets[1]]
            default:
                insets = [edgeInsets[0], edgeInsets[1], edgeInsets[2], edgeInsets[3]]
            }
            collectionViewLayout.sectionInset = UIEdgeInsets.init(top: insets[0], left: insets[1], bottom: insets[2], right: insets[3])
        }
        
        if attr["horizontalScroll"].bool == true || attr["layout"].string == "horizontal" || attr["orientation"].string == "horizontal" {
            collectionViewLayout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        }
        return collectionViewLayout
    }
    
    open class func getCollectionViewFlowLayout(attr: JSON) -> UICollectionViewFlowLayout {
        let collectionViewLayout: UICollectionViewFlowLayout
        let layoutType = attr["layout"].string ?? "Flow"
        switch(layoutType) {
        case "LeftAligned", "leftAligned":
            let layout = LeftAlignedFlowLayout()
            layout.minimumInteritemSpacing = attr["columnSpacing"].cgFloat ?? attr["itemSpacing"].cgFloat ?? 0
            layout.minimumLineSpacing = attr["lineSpacing"].cgFloat ?? attr["itemSpacing"].cgFloat ?? 0
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            collectionViewLayout = layout
        default:
            collectionViewLayout = UICollectionViewFlowLayout()
            collectionViewLayout.minimumInteritemSpacing = attr["columnSpacing"].cgFloat ?? attr["itemSpacing"].cgFloat ?? 0
            collectionViewLayout.minimumLineSpacing = attr["lineSpacing"].cgFloat ?? attr["itemSpacing"].cgFloat ?? 0
        }
        return collectionViewLayout
    }
    
}

