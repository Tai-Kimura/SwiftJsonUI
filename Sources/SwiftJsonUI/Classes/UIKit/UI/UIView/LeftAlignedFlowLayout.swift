//
//  LeftAlignedFlowLayout.swift
//  SwiftJsonUI
//
//  UICollectionViewFlowLayout subclass that left-aligns items.
//  Default FlowLayout distributes items evenly across the row.
//  This layout packs items to the left with consistent spacing.
//

import UIKit

open class LeftAlignedFlowLayout: UICollectionViewFlowLayout {

    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect)?
                .map({ $0.copy() as! UICollectionViewLayoutAttributes }) else {
            return nil
        }

        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0

        for attr in attributes where attr.representedElementCategory == .cell {
            // New row detected
            if attr.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }
            attr.frame.origin.x = leftMargin
            leftMargin += attr.frame.width + minimumInteritemSpacing
            maxY = max(attr.frame.maxY, maxY)
        }

        return attributes
    }
}
