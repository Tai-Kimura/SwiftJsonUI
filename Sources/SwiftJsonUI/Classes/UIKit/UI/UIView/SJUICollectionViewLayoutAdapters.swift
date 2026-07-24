//
//  SJUICollectionViewLayoutAdapters.swift
//  SwiftJsonUI
//
//  Created by Claude on 2026/01/15.
//
//  カスタムレイアウト用のアダプター実装例とプロトコル定義
//

import UIKit

// MARK: - Waterfall Layout Protocol

/// WaterfallLayoutのデリゲートプロトコル（アプリ側で実装するレイアウトが準拠するもの）
@MainActor
public protocol SJUIWaterfallLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath) -> CGFloat
    func numberOfColumns(in collectionView: UICollectionView, section: Int) -> Int
}

// MARK: - Waterfall Layout Adapter

/// WaterfallLayout用のアダプター
/// アプリ側でWaterfallLayoutを実装し、このアダプターを登録することでクロージャベースで使用可能になる
@MainActor
public class SJUIWaterfallLayoutAdapter: SJUILayoutDelegateAdapter, SJUIWaterfallLayoutDelegate {

    // MARK: - Closure Properties

    public var heightForItem: ((UICollectionView, IndexPath) -> CGFloat)?
    public var numberOfColumns: ((UICollectionView, Int) -> Int)?

    // MARK: - Default Values

    public var defaultHeight: CGFloat = 100
    public var defaultColumns: Int = 2

    // MARK: - SJUILayoutDelegateAdapter

    public override func attachToLayout(_ layout: UICollectionViewLayout) {
        // アプリ側でレイアウトのdelegateプロパティにselfを設定する
        // 例: (layout as? WaterfallLayout)?.delegate = self
    }

    // MARK: - SJUIWaterfallLayoutDelegate

    public func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath) -> CGFloat {
        heightForItem?(collectionView, indexPath) ?? defaultHeight
    }

    public func numberOfColumns(in collectionView: UICollectionView, section: Int) -> Int {
        numberOfColumns?(collectionView, section) ?? defaultColumns
    }
}

// MARK: - SJUICollectionView Extension for Waterfall

public extension SJUICollectionView {

    /// WaterfallLayoutアダプターを取得
    var waterfallAdapter: SJUIWaterfallLayoutAdapter? {
        delegateProxy.layoutAdapter as? SJUIWaterfallLayoutAdapter
    }

    /// アイテムの高さを設定（Waterfall用）
    @discardableResult
    func onWaterfallHeightForItem(_ handler: @escaping (UICollectionView, IndexPath) -> CGFloat) -> Self {
        waterfallAdapter?.heightForItem = handler
        return self
    }

    /// カラム数を設定（Waterfall用）
    @discardableResult
    func onWaterfallNumberOfColumns(_ handler: @escaping (UICollectionView, Int) -> Int) -> Self {
        waterfallAdapter?.numberOfColumns = handler
        return self
    }
}

// MARK: - Carousel Layout Protocol

/// CarouselLayoutのデリゲートプロトコル
@MainActor
public protocol SJUICarouselLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, scaleForItemAt indexPath: IndexPath, distanceFromCenter: CGFloat) -> CGFloat
    func collectionView(_ collectionView: UICollectionView, alphaForItemAt indexPath: IndexPath, distanceFromCenter: CGFloat) -> CGFloat
}

// MARK: - Carousel Layout Adapter

/// CarouselLayout用のアダプター
@MainActor
public class SJUICarouselLayoutAdapter: SJUILayoutDelegateAdapter, SJUICarouselLayoutDelegate {

    // MARK: - Closure Properties

    public var scaleForItem: ((UICollectionView, IndexPath, CGFloat) -> CGFloat)?
    public var alphaForItem: ((UICollectionView, IndexPath, CGFloat) -> CGFloat)?

    // MARK: - Default Values

    public var defaultMinScale: CGFloat = 0.8
    public var defaultMinAlpha: CGFloat = 0.5

    // MARK: - SJUICarouselLayoutDelegate

    public func collectionView(_ collectionView: UICollectionView, scaleForItemAt indexPath: IndexPath, distanceFromCenter: CGFloat) -> CGFloat {
        scaleForItem?(collectionView, indexPath, distanceFromCenter) ?? max(defaultMinScale, 1.0 - abs(distanceFromCenter) * 0.2)
    }

    public func collectionView(_ collectionView: UICollectionView, alphaForItemAt indexPath: IndexPath, distanceFromCenter: CGFloat) -> CGFloat {
        alphaForItem?(collectionView, indexPath, distanceFromCenter) ?? max(defaultMinAlpha, 1.0 - abs(distanceFromCenter) * 0.5)
    }
}

// MARK: - SJUICollectionView Extension for Carousel

public extension SJUICollectionView {

    /// CarouselLayoutアダプターを取得
    var carouselAdapter: SJUICarouselLayoutAdapter? {
        delegateProxy.layoutAdapter as? SJUICarouselLayoutAdapter
    }

    /// アイテムのスケールを設定（Carousel用）
    @discardableResult
    func onCarouselScaleForItem(_ handler: @escaping (UICollectionView, IndexPath, CGFloat) -> CGFloat) -> Self {
        carouselAdapter?.scaleForItem = handler
        return self
    }

    /// アイテムの透明度を設定（Carousel用）
    @discardableResult
    func onCarouselAlphaForItem(_ handler: @escaping (UICollectionView, IndexPath, CGFloat) -> CGFloat) -> Self {
        carouselAdapter?.alphaForItem = handler
        return self
    }
}
