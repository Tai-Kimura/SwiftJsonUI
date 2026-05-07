//
//  SJUICollectionViewDelegateProxy.swift
//  SwiftJsonUI
//
//  Created by Claude on 2026/01/15.
//

import UIKit

/// カスタムレイアウト用のアダプター基底クラス
@MainActor
open class SJUILayoutDelegateAdapter: NSObject {

    /// メタタイプからのインスタンス化に必要
    public required override init() {
        super.init()
    }

    /// レイアウトにデリゲートをアタッチする
    open func attachToLayout(_ layout: UICollectionViewLayout) {
        // サブクラスでオーバーライド
    }
}

/// UICollectionViewDelegate/DataSource/FlowLayoutDelegate のクロージャを保持するプロキシクラス
@MainActor
public class SJUICollectionViewDelegateProxy: NSObject {

    // MARK: - Layout Adapter Registry

    private static var layoutAdapterRegistry: [ObjectIdentifier: SJUILayoutDelegateAdapter.Type] = [:]

    /// カスタムレイアウト用のアダプターを登録
    public static func registerLayoutAdapter<L: UICollectionViewLayout, A: SJUILayoutDelegateAdapter>(
        forLayoutType layoutType: L.Type,
        adapterType: A.Type
    ) {
        layoutAdapterRegistry[ObjectIdentifier(layoutType)] = adapterType
    }

    /// 登録されたアダプタータイプを取得
    static func adapterType(for layout: UICollectionViewLayout) -> SJUILayoutDelegateAdapter.Type? {
        layoutAdapterRegistry[ObjectIdentifier(type(of: layout))]
    }

    // MARK: - Instance Properties

    /// カスタムレイアウト用のアダプター
    public private(set) var layoutAdapter: SJUILayoutDelegateAdapter?

    /// レイアウトアダプターを設定
    func setupLayoutAdapter(for layout: UICollectionViewLayout) {
        if let adapterType = Self.adapterType(for: layout) {
            layoutAdapter = adapterType.init()
            layoutAdapter?.attachToLayout(layout)
        }
    }

    // MARK: - UICollectionViewDataSource Closures

    public var numberOfSections: ((UICollectionView) -> Int)?
    public var numberOfItemsInSection: ((UICollectionView, Int) -> Int)?
    public var cellForItem: ((UICollectionView, IndexPath) -> UICollectionViewCell)?
    public var supplementaryView: ((UICollectionView, String, IndexPath) -> UICollectionReusableView)?
    public var canMoveItem: ((UICollectionView, IndexPath) -> Bool)?
    public var moveItem: ((UICollectionView, IndexPath, IndexPath) -> Void)?

    // MARK: - UICollectionViewDelegate Closures

    public var shouldSelectItem: ((UICollectionView, IndexPath) -> Bool)?
    public var didSelectItem: ((UICollectionView, IndexPath) -> Void)?
    public var shouldDeselectItem: ((UICollectionView, IndexPath) -> Bool)?
    public var didDeselectItem: ((UICollectionView, IndexPath) -> Void)?

    public var shouldHighlightItem: ((UICollectionView, IndexPath) -> Bool)?
    public var didHighlightItem: ((UICollectionView, IndexPath) -> Void)?
    public var didUnhighlightItem: ((UICollectionView, IndexPath) -> Void)?

    public var willDisplayCell: ((UICollectionView, UICollectionViewCell, IndexPath) -> Void)?
    public var didEndDisplayingCell: ((UICollectionView, UICollectionViewCell, IndexPath) -> Void)?
    public var willDisplaySupplementaryView: ((UICollectionView, UICollectionReusableView, String, IndexPath) -> Void)?
    public var didEndDisplayingSupplementaryView: ((UICollectionView, UICollectionReusableView, String, IndexPath) -> Void)?

    // MARK: - UICollectionViewDelegateFlowLayout Closures

    public var sizeForItem: ((UICollectionView, UICollectionViewLayout, IndexPath) -> CGSize)?
    public var insetForSection: ((UICollectionView, UICollectionViewLayout, Int) -> UIEdgeInsets)?
    public var minimumLineSpacing: ((UICollectionView, UICollectionViewLayout, Int) -> CGFloat)?
    public var minimumInteritemSpacing: ((UICollectionView, UICollectionViewLayout, Int) -> CGFloat)?
    public var referenceSizeForHeader: ((UICollectionView, UICollectionViewLayout, Int) -> CGSize)?
    public var referenceSizeForFooter: ((UICollectionView, UICollectionViewLayout, Int) -> CGSize)?

    // MARK: - UIScrollViewDelegate Closures

    public var didScroll: ((UIScrollView) -> Void)?
    public var willBeginDragging: ((UIScrollView) -> Void)?
    public var didEndDragging: ((UIScrollView, Bool) -> Void)?
    public var willBeginDecelerating: ((UIScrollView) -> Void)?
    public var didEndDecelerating: ((UIScrollView) -> Void)?
    public var didEndScrollingAnimation: ((UIScrollView) -> Void)?
    public var willEndDragging: ((UIScrollView, CGPoint, UnsafeMutablePointer<CGPoint>) -> Void)?
}

// MARK: - UICollectionViewDataSource

extension SJUICollectionViewDelegateProxy: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        numberOfSections?(collectionView) ?? 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        numberOfItemsInSection?(collectionView, section) ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        cellForItem?(collectionView, indexPath) ?? UICollectionViewCell()
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        supplementaryView?(collectionView, kind, indexPath) ?? UICollectionReusableView()
    }

    public func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        canMoveItem?(collectionView, indexPath) ?? false
    }

    public func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        moveItem?(collectionView, sourceIndexPath, destinationIndexPath)
    }
}

// MARK: - UICollectionViewDelegate

extension SJUICollectionViewDelegateProxy: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        shouldSelectItem?(collectionView, indexPath) ?? true
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectItem?(collectionView, indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        shouldDeselectItem?(collectionView, indexPath) ?? true
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        didDeselectItem?(collectionView, indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        shouldHighlightItem?(collectionView, indexPath) ?? true
    }

    public func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        didHighlightItem?(collectionView, indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        didUnhighlightItem?(collectionView, indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        willDisplayCell?(collectionView, cell, indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        didEndDisplayingCell?(collectionView, cell, indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        willDisplaySupplementaryView?(collectionView, view, elementKind, indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        didEndDisplayingSupplementaryView?(collectionView, view, elementKind, indexPath)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SJUICollectionViewDelegateProxy: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let size = sizeForItem?(collectionView, collectionViewLayout, indexPath) {
            return size
        }
        // FlowLayoutのデフォルトサイズを使用
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            return flowLayout.itemSize
        }
        return CGSize(width: 50, height: 50)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if let insets = insetForSection?(collectionView, collectionViewLayout, section) {
            return insets
        }
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            return flowLayout.sectionInset
        }
        return .zero
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if let spacing = minimumLineSpacing?(collectionView, collectionViewLayout, section) {
            return spacing
        }
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            return flowLayout.minimumLineSpacing
        }
        return 10
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if let spacing = minimumInteritemSpacing?(collectionView, collectionViewLayout, section) {
            return spacing
        }
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            return flowLayout.minimumInteritemSpacing
        }
        return 10
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if let size = referenceSizeForHeader?(collectionView, collectionViewLayout, section) {
            return size
        }
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            return flowLayout.headerReferenceSize
        }
        return .zero
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if let size = referenceSizeForFooter?(collectionView, collectionViewLayout, section) {
            return size
        }
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            return flowLayout.footerReferenceSize
        }
        return .zero
    }
}

// MARK: - UIScrollViewDelegate

extension SJUICollectionViewDelegateProxy: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScroll?(scrollView)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        willBeginDragging?(scrollView)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        didEndDragging?(scrollView, decelerate)
    }

    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        willBeginDecelerating?(scrollView)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didEndDecelerating?(scrollView)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        didEndScrollingAnimation?(scrollView)
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        willEndDragging?(scrollView, velocity, targetContentOffset)
    }
}
