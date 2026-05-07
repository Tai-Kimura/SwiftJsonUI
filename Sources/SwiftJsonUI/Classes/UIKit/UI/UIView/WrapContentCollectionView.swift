//
//  WrapContentCollectionView.swift
//  SwiftJsonUI
//
//  CollectionView subclass that sizes itself to fit all its content.
//  Used when height="wrapContent" is specified in JSON.
//

import UIKit

open class WrapContentCollectionView: SJUICollectionView {

    open override var intrinsicContentSize: CGSize {
        return collectionViewLayout.collectionViewContentSize
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != intrinsicContentSize {
            invalidateIntrinsicContentSize()
        }
    }

    open override func reloadData() {
        super.reloadData()
        // After reload, recalculate content size
        layoutIfNeeded()
        invalidateIntrinsicContentSize()
    }
}
