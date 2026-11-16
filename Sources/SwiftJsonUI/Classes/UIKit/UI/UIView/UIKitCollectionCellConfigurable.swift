//
//  UIKitCollectionCellConfigurable.swift
//  SwiftJsonUI
//
//  Created by Claude on 2026/01/15.
//

import UIKit

/// CollectionViewのセル/ヘッダー/フッターがデータを受け取るためのプロトコル
@MainActor
public protocol UIKitCollectionCellConfigurable {
    /// 受け取るデータの型
    associatedtype DataType

    /// データを適用してセルを設定
    func configure(with data: DataType)
}

/// 型消去されたconfigure呼び出し用プロトコル
@MainActor
public protocol AnyUIKitCollectionCellConfigurable {
    /// Any型でデータを受け取り、内部で適切な型にキャストして設定
    func configureWithAny(_ data: Any)
}

/// UIKitCollectionCellConfigurableのデフォルト実装
public extension UIKitCollectionCellConfigurable {
    func configureWithAny(_ data: Any) {
        if let typedData = data as? DataType {
            configure(with: typedData)
        }
    }
}

/// セルの静的情報を提供するプロトコル
@MainActor
public protocol UIKitCollectionCellInfo {
    /// セル識別子
    static var cellIdentifier: String { get }

    /// セルの高さ（オプション）
    static var cellHeight: CGFloat { get }
}

// デフォルト実装
public extension UIKitCollectionCellInfo {
    static var cellHeight: CGFloat { 44.0 }
}

/// ヘッダー/フッターの静的情報を提供するプロトコル
@MainActor
public protocol UIKitCollectionSupplementaryViewInfo {
    /// ビュー識別子
    static var viewIdentifier: String { get }

    /// ビューの高さ（オプション）
    static var viewHeight: CGFloat { get }
}

// デフォルト実装
public extension UIKitCollectionSupplementaryViewInfo {
    static var viewHeight: CGFloat { 44.0 }
}
