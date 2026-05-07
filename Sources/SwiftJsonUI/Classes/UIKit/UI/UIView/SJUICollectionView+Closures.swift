//
//  SJUICollectionView+Closures.swift
//  SwiftJsonUI
//
//  Created by Claude on 2026/01/15.
//

import UIKit

// Associated Object Key
private var CollectionViewDelegateProxyKey: UInt8 = 0

public extension SJUICollectionView {

    // MARK: - Delegate Proxy

    /// プロキシを取得または作成
    var delegateProxy: SJUICollectionViewDelegateProxy {
        if let proxy = objc_getAssociatedObject(self, &CollectionViewDelegateProxyKey) as? SJUICollectionViewDelegateProxy {
            return proxy
        }
        let proxy = SJUICollectionViewDelegateProxy()
        objc_setAssociatedObject(self, &CollectionViewDelegateProxyKey, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        self.delegate = proxy
        self.dataSource = proxy
        // カスタムレイアウトアダプターをセットアップ
        proxy.setupLayoutAdapter(for: self.collectionViewLayout)
        return proxy
    }

    // MARK: - UICollectionViewDataSource

    /// セクション数を設定
    @discardableResult
    func onNumberOfSections(_ handler: @escaping (UICollectionView) -> Int) -> Self {
        delegateProxy.numberOfSections = handler
        return self
    }

    /// セクション内のアイテム数を設定
    @discardableResult
    func onNumberOfItemsInSection(_ handler: @escaping (UICollectionView, Int) -> Int) -> Self {
        delegateProxy.numberOfItemsInSection = handler
        return self
    }

    /// セルを生成
    @discardableResult
    func onCellForItem(_ handler: @escaping (UICollectionView, IndexPath) -> UICollectionViewCell) -> Self {
        delegateProxy.cellForItem = handler
        return self
    }

    /// ヘッダー/フッターなどの補助ビューを生成
    @discardableResult
    func onSupplementaryView(_ handler: @escaping (UICollectionView, String, IndexPath) -> UICollectionReusableView) -> Self {
        delegateProxy.supplementaryView = handler
        return self
    }

    /// アイテムが移動可能かどうか
    @discardableResult
    func onCanMoveItem(_ handler: @escaping (UICollectionView, IndexPath) -> Bool) -> Self {
        delegateProxy.canMoveItem = handler
        return self
    }

    /// アイテムが移動された
    @discardableResult
    func onMoveItem(_ handler: @escaping (UICollectionView, IndexPath, IndexPath) -> Void) -> Self {
        delegateProxy.moveItem = handler
        return self
    }

    // MARK: - UICollectionViewDelegate - Selection

    /// アイテムが選択可能かどうか
    @discardableResult
    func onShouldSelectItem(_ handler: @escaping (UICollectionView, IndexPath) -> Bool) -> Self {
        delegateProxy.shouldSelectItem = handler
        return self
    }

    /// アイテムが選択された
    @discardableResult
    func onDidSelectItem(_ handler: @escaping (UICollectionView, IndexPath) -> Void) -> Self {
        delegateProxy.didSelectItem = handler
        return self
    }

    /// アイテムが選択解除可能かどうか
    @discardableResult
    func onShouldDeselectItem(_ handler: @escaping (UICollectionView, IndexPath) -> Bool) -> Self {
        delegateProxy.shouldDeselectItem = handler
        return self
    }

    /// アイテムが選択解除された
    @discardableResult
    func onDidDeselectItem(_ handler: @escaping (UICollectionView, IndexPath) -> Void) -> Self {
        delegateProxy.didDeselectItem = handler
        return self
    }

    // MARK: - UICollectionViewDelegate - Highlighting

    /// アイテムがハイライト可能かどうか
    @discardableResult
    func onShouldHighlightItem(_ handler: @escaping (UICollectionView, IndexPath) -> Bool) -> Self {
        delegateProxy.shouldHighlightItem = handler
        return self
    }

    /// アイテムがハイライトされた
    @discardableResult
    func onDidHighlightItem(_ handler: @escaping (UICollectionView, IndexPath) -> Void) -> Self {
        delegateProxy.didHighlightItem = handler
        return self
    }

    /// アイテムのハイライトが解除された
    @discardableResult
    func onDidUnhighlightItem(_ handler: @escaping (UICollectionView, IndexPath) -> Void) -> Self {
        delegateProxy.didUnhighlightItem = handler
        return self
    }

    // MARK: - UICollectionViewDelegate - Display

    /// セルが表示される直前
    @discardableResult
    func onWillDisplayCell(_ handler: @escaping (UICollectionView, UICollectionViewCell, IndexPath) -> Void) -> Self {
        delegateProxy.willDisplayCell = handler
        return self
    }

    /// セルが画面外に出た
    @discardableResult
    func onDidEndDisplayingCell(_ handler: @escaping (UICollectionView, UICollectionViewCell, IndexPath) -> Void) -> Self {
        delegateProxy.didEndDisplayingCell = handler
        return self
    }

    /// 補助ビューが表示される直前
    @discardableResult
    func onWillDisplaySupplementaryView(_ handler: @escaping (UICollectionView, UICollectionReusableView, String, IndexPath) -> Void) -> Self {
        delegateProxy.willDisplaySupplementaryView = handler
        return self
    }

    /// 補助ビューが画面外に出た
    @discardableResult
    func onDidEndDisplayingSupplementaryView(_ handler: @escaping (UICollectionView, UICollectionReusableView, String, IndexPath) -> Void) -> Self {
        delegateProxy.didEndDisplayingSupplementaryView = handler
        return self
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    /// アイテムのサイズ
    @discardableResult
    func onSizeForItem(_ handler: @escaping (UICollectionView, UICollectionViewLayout, IndexPath) -> CGSize) -> Self {
        delegateProxy.sizeForItem = handler
        return self
    }

    /// セクションの余白
    @discardableResult
    func onInsetForSection(_ handler: @escaping (UICollectionView, UICollectionViewLayout, Int) -> UIEdgeInsets) -> Self {
        delegateProxy.insetForSection = handler
        return self
    }

    /// 行間の最小スペース
    @discardableResult
    func onMinimumLineSpacing(_ handler: @escaping (UICollectionView, UICollectionViewLayout, Int) -> CGFloat) -> Self {
        delegateProxy.minimumLineSpacing = handler
        return self
    }

    /// アイテム間の最小スペース
    @discardableResult
    func onMinimumInteritemSpacing(_ handler: @escaping (UICollectionView, UICollectionViewLayout, Int) -> CGFloat) -> Self {
        delegateProxy.minimumInteritemSpacing = handler
        return self
    }

    /// ヘッダーの参照サイズ
    @discardableResult
    func onHeaderReferenceSize(_ handler: @escaping (UICollectionView, UICollectionViewLayout, Int) -> CGSize) -> Self {
        delegateProxy.referenceSizeForHeader = handler
        return self
    }

    /// フッターの参照サイズ
    @discardableResult
    func onFooterReferenceSize(_ handler: @escaping (UICollectionView, UICollectionViewLayout, Int) -> CGSize) -> Self {
        delegateProxy.referenceSizeForFooter = handler
        return self
    }

    // MARK: - UIScrollViewDelegate

    /// スクロールした
    @discardableResult
    func onDidScroll(_ handler: @escaping (UIScrollView) -> Void) -> Self {
        delegateProxy.didScroll = handler
        return self
    }

    /// ドラッグ開始
    @discardableResult
    func onWillBeginDragging(_ handler: @escaping (UIScrollView) -> Void) -> Self {
        delegateProxy.willBeginDragging = handler
        return self
    }

    /// ドラッグ終了
    @discardableResult
    func onDidEndDragging(_ handler: @escaping (UIScrollView, Bool) -> Void) -> Self {
        delegateProxy.didEndDragging = handler
        return self
    }

    /// 減速開始
    @discardableResult
    func onWillBeginDecelerating(_ handler: @escaping (UIScrollView) -> Void) -> Self {
        delegateProxy.willBeginDecelerating = handler
        return self
    }

    /// 減速終了
    @discardableResult
    func onDidEndDecelerating(_ handler: @escaping (UIScrollView) -> Void) -> Self {
        delegateProxy.didEndDecelerating = handler
        return self
    }

    /// スクロールアニメーション終了
    @discardableResult
    func onDidEndScrollingAnimation(_ handler: @escaping (UIScrollView) -> Void) -> Self {
        delegateProxy.didEndScrollingAnimation = handler
        return self
    }

    /// ドラッグ終了時（ターゲットオフセット指定可能）
    @discardableResult
    func onWillEndDragging(_ handler: @escaping (UIScrollView, CGPoint, UnsafeMutablePointer<CGPoint>) -> Void) -> Self {
        delegateProxy.willEndDragging = handler
        return self
    }

    // MARK: - Custom Layout Support

    /// カスタムレイアウトアダプターを取得
    func layoutAdapter<T: SJUILayoutDelegateAdapter>(as type: T.Type) -> T? {
        delegateProxy.layoutAdapter as? T
    }
}
