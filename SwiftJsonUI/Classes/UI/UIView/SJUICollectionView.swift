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
            collectionViewLayout.sectionInset = UIEdgeInsetsMake(insetVertical, insetHorizontal, insetVertical, insetHorizontal)
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
            collectionViewLayout.sectionInset = UIEdgeInsetsMake(insets[0], insets[1], insets[2], insets[3])
        }
        
        if let _ = attr["horizontalScroll"].bool {
            collectionViewLayout.scrollDirection = UICollectionViewScrollDirection.horizontal
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
