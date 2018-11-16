//
//  SJUICollectionView.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2018/09/13.

//

import UIKit

open class SJUICollectionView: UICollectionView {
    
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
        let c = viewClass.init(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        c.showsHorizontalScrollIndicator = attr["showsHorizontalScrollIndicator"].boolValue
        c.showsVerticalScrollIndicator = attr["showsVerticalScrollIndicator"].boolValue
        if let paging = attr["paging"].bool {
            c.isPagingEnabled = paging
        }
        if let moduleName = Bundle.main.infoDictionary!["CFBundleName"] as? String {
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
        c.delegate = target as? UICollectionViewDelegate
        c.dataSource = target as? UICollectionViewDataSource
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
        } else if let insets = attr["insets"].arrayObject as? [CGFloat] {
            edgeInsets = insets
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
        
        if let _ = attr["horizontalScroll"].bool {
            collectionViewLayout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        }
        return collectionViewLayout
    }
    
    open class func getCollectionViewFlowLayout(attr: JSON) -> UICollectionViewFlowLayout {
        let collectionViewLayout: UICollectionViewFlowLayout
        let layoutType = attr["layout"].string ?? "Flow"
        switch(layoutType) {
        default:
            collectionViewLayout = UICollectionViewFlowLayout()
            collectionViewLayout.minimumInteritemSpacing = attr["columnSpacing"].cgFloatValue
            collectionViewLayout.minimumLineSpacing = attr["lineSpacing"].cgFloatValue
        }
        return collectionViewLayout
    }
    
}

