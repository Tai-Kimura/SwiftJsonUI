//
//  UIKitCollectionDataSource.swift
//  SwiftJsonUI
//
//  Created by Claude on 2026/01/15.
//

import UIKit

/// セクションごとのデータ
@MainActor
public class UIKitCollectionSection {

    /// ヘッダービュー名、クラス、データ
    public var header: (viewName: String, viewClass: UICollectionReusableView.Type, data: Any)?

    /// セルビュー名、クラス、データ配列
    public var cells: (viewName: String, cellClass: UICollectionViewCell.Type, data: [Any])?

    /// 追加のセルクラス登録（複数セルタイプ用）
    public var additionalCellClasses: [(viewName: String, cellClass: UICollectionViewCell.Type)] = []

    /// セルごとにviewNameを切り替えるリゾルバ（nilを返すとデフォルトのcells.viewNameを使用）
    public var cellClassResolver: ((Int, Any) -> String)?

    /// フッタービュー名、クラス、データ
    public var footer: (viewName: String, viewClass: UICollectionReusableView.Type, data: Any)?

    /// セル選択時のハンドラ
    public var onSelectCell: ((Int, Any) -> Void)?

    /// セルサイズ計算のハンドラ
    public var sizeForCell: ((Int, Any) -> CGSize)?

    /// ヘッダーサイズ計算のハンドラ
    public var sizeForHeader: ((Any) -> CGSize)?

    /// フッターサイズ計算のハンドラ
    public var sizeForFooter: ((Any) -> CGSize)?

    /// カラム数（グリッド表示用）
    public var numberOfColumns: Int = 1

    /// セル間のスペーシング
    public var interItemSpacing: CGFloat = 0

    /// セルの高さ（カラム指定時に使用）
    public var cellHeight: CGFloat?

    public init() {}

    /// モジュール名を取得
    private static var moduleName: String {
        var name = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
        name = name.replacingOccurrences(of: "[^0-9a-zA-Z_]", with: "_", options: .regularExpression, range: nil)
        return name
    }

    /// viewNameからクラスを解決
    private static func resolveClass<T>(_ viewName: String) -> T? {
        let fullClassName = "\(moduleName).\(viewName)"
        return NSClassFromString(fullClassName) as? T
    }

    /// セルを設定（viewNameとオプショナルなcellClass）
    @discardableResult
    public func setCells<T>(viewName: String, cellClass: UICollectionViewCell.Type? = nil, data: [T]) -> Self {
        guard let resolvedClass = cellClass ?? Self.resolveClass(viewName) else {
            fatalError("Could not resolve cell class for viewName: \(viewName)")
        }
        cells = (viewName: viewName, cellClass: resolvedClass, data: data)
        return self
    }

    /// セルを設定（複数viewName対応 — 最初のviewNameがデフォルト）
    @discardableResult
    public func setCells<T>(viewNames: [String], data: [T]) -> Self {
        guard let primaryName = viewNames.first else {
            fatalError("viewNames must not be empty")
        }
        guard let primaryClass: UICollectionViewCell.Type = Self.resolveClass(primaryName) else {
            fatalError("Could not resolve cell class for viewName: \(primaryName)")
        }
        cells = (viewName: primaryName, cellClass: primaryClass, data: data)

        // 追加のviewNameを登録
        for name in viewNames.dropFirst() {
            guard let cls: UICollectionViewCell.Type = Self.resolveClass(name) else {
                fatalError("Could not resolve cell class for viewName: \(name)")
            }
            additionalCellClasses.append((viewName: name, cellClass: cls))
        }
        return self
    }

    /// セルクラスリゾルバを設定（viewNameを返す）
    @discardableResult
    public func resolveCellClass(_ resolver: @escaping (Int, Any) -> String) -> Self {
        cellClassResolver = resolver
        return self
    }

    /// ヘッダーを設定（viewNameとオプショナルなviewClass）
    @discardableResult
    public func setHeader<T>(viewName: String, viewClass: UICollectionReusableView.Type? = nil, data: T) -> Self {
        guard let resolvedClass: UICollectionReusableView.Type = viewClass ?? Self.resolveClass(viewName) else {
            fatalError("Could not resolve header view class for viewName: \(viewName)")
        }
        header = (viewName: viewName, viewClass: resolvedClass, data: data)
        return self
    }

    /// ヘッダーを設定（データなし）
    @discardableResult
    public func setHeader(viewName: String, viewClass: UICollectionReusableView.Type? = nil) -> Self {
        guard let resolvedClass: UICollectionReusableView.Type = viewClass ?? Self.resolveClass(viewName) else {
            fatalError("Could not resolve header view class for viewName: \(viewName)")
        }
        header = (viewName: viewName, viewClass: resolvedClass, data: () as Any)
        return self
    }

    /// フッターを設定（viewNameとオプショナルなviewClass）
    @discardableResult
    public func setFooter<T>(viewName: String, viewClass: UICollectionReusableView.Type? = nil, data: T) -> Self {
        guard let resolvedClass: UICollectionReusableView.Type = viewClass ?? Self.resolveClass(viewName) else {
            fatalError("Could not resolve footer view class for viewName: \(viewName)")
        }
        footer = (viewName: viewName, viewClass: resolvedClass, data: data)
        return self
    }

    /// フッターを設定（データなし）
    @discardableResult
    public func setFooter(viewName: String, viewClass: UICollectionReusableView.Type? = nil) -> Self {
        guard let resolvedClass: UICollectionReusableView.Type = viewClass ?? Self.resolveClass(viewName) else {
            fatalError("Could not resolve footer view class for viewName: \(viewName)")
        }
        footer = (viewName: viewName, viewClass: resolvedClass, data: () as Any)
        return self
    }

    /// セル選択時のハンドラを設定（ジェネリック版）
    @discardableResult
    public func onSelect<T>(_ handler: @escaping (Int, T) -> Void) -> Self {
        onSelectCell = { index, data in
            if let typedData = data as? T {
                handler(index, typedData)
            }
        }
        return self
    }

    /// セルサイズを設定（ジェネリック版）
    @discardableResult
    public func cellSize<T>(_ handler: @escaping (Int, T) -> CGSize) -> Self {
        sizeForCell = { index, data in
            if let typedData = data as? T {
                return handler(index, typedData)
            }
            return .zero
        }
        return self
    }

    /// セルサイズを固定値で設定
    @discardableResult
    public func cellSize(_ size: CGSize) -> Self {
        sizeForCell = { _, _ in size }
        return self
    }

    /// カラム数を設定（グリッド表示）
    @discardableResult
    public func columns(_ count: Int, spacing: CGFloat = 0, height: CGFloat? = nil) -> Self {
        numberOfColumns = count
        interItemSpacing = spacing
        cellHeight = height
        return self
    }

    /// ヘッダーサイズを設定（ジェネリック版）
    @discardableResult
    public func headerSize<T>(_ handler: @escaping (T) -> CGSize) -> Self {
        sizeForHeader = { data in
            if let typedData = data as? T {
                return handler(typedData)
            }
            return .zero
        }
        return self
    }

    /// ヘッダーサイズを固定値で設定
    @discardableResult
    public func headerSize(_ size: CGSize) -> Self {
        sizeForHeader = { _ in size }
        return self
    }

    /// フッターサイズを設定（ジェネリック版）
    @discardableResult
    public func footerSize<T>(_ handler: @escaping (T) -> CGSize) -> Self {
        sizeForFooter = { data in
            if let typedData = data as? T {
                return handler(typedData)
            }
            return .zero
        }
        return self
    }

    /// フッターサイズを固定値で設定
    @discardableResult
    public func footerSize(_ size: CGSize) -> Self {
        sizeForFooter = { _ in size }
        return self
    }

    /// セルデータを追加
    public func addCellData<T>(_ data: T) {
        if let cellsData = cells {
            var newData = cellsData.data
            newData.append(data)
            cells = (viewName: cellsData.viewName, cellClass: cellsData.cellClass, data: newData)
        }
    }

    /// セルデータをクリア
    public func clearCellData() {
        if let cellsData = cells {
            cells = (viewName: cellsData.viewName, cellClass: cellsData.cellClass, data: [])
        }
    }

    /// セルデータを更新（viewName, cellClassは維持）
    @discardableResult
    public func updateCells<T>(_ data: [T]) -> Self {
        if let cellsData = cells {
            cells = (viewName: cellsData.viewName, cellClass: cellsData.cellClass, data: data)
        }
        return self
    }

    /// ヘッダーデータを更新（viewName, viewClassは維持）
    @discardableResult
    public func updateHeader<T>(_ data: T) -> Self {
        if let headerData = header {
            header = (viewName: headerData.viewName, viewClass: headerData.viewClass, data: data)
        }
        return self
    }

    /// フッターデータを更新（viewName, viewClassは維持）
    @discardableResult
    public func updateFooter<T>(_ data: T) -> Self {
        if let footerData = footer {
            footer = (viewName: footerData.viewName, viewClass: footerData.viewClass, data: data)
        }
        return self
    }
}

/// UIKit用CollectionViewデータソース
@MainActor
public class UIKitCollectionDataSource {

    /// セクション配列
    public var sections: [UIKitCollectionSection] = []

    /// グローバルなセル選択ハンドラ
    public var onDidSelectItem: ((IndexPath, Any) -> Void)?

    /// グローバルなセルサイズハンドラ
    public var sizeForItem: ((IndexPath, Any) -> CGSize)?

    /// スクロールイベント
    public var onDidScroll: ((UIScrollView) -> Void)?

    /// セル表示時のハンドラ
    public var onWillDisplayCell: ((UICollectionViewCell, IndexPath, Any) -> Void)?

    /// セル非表示時のハンドラ
    public var onDidEndDisplayingCell: ((UICollectionViewCell, IndexPath) -> Void)?

    public init() {}

    /// セクションを追加してビルダーパターンで設定
    @discardableResult
    public func addSection() -> UIKitCollectionSection {
        let section = UIKitCollectionSection()
        sections.append(section)
        return section
    }

    /// セクションを追加
    public func addSection(_ section: UIKitCollectionSection) {
        sections.append(section)
    }

    /// 全セクションをクリア
    public func clearSections() {
        sections.removeAll()
    }

    // MARK: - Data Access

    /// セクション数
    public var numberOfSections: Int {
        sections.count
    }

    /// セクション内のアイテム数
    public func numberOfItems(in section: Int) -> Int {
        guard section < sections.count else { return 0 }
        return sections[section].cells?.data.count ?? 0
    }

    /// セルデータの取得（cellClassResolverがあればviewNameを切り替え）
    public func cellData(at indexPath: IndexPath) -> (viewName: String, data: Any)? {
        guard indexPath.section < sections.count,
              let cells = sections[indexPath.section].cells,
              indexPath.item < cells.data.count else {
            return nil
        }
        let data = cells.data[indexPath.item]
        let section = sections[indexPath.section]
        let viewName = section.cellClassResolver?(indexPath.item, data) ?? cells.viewName
        return (viewName, data)
    }

    /// ヘッダーデータの取得
    public func headerData(for section: Int) -> (viewName: String, viewClass: UICollectionReusableView.Type, data: Any)? {
        guard section < sections.count else { return nil }
        return sections[section].header
    }

    /// フッターデータの取得
    public func footerData(for section: Int) -> (viewName: String, viewClass: UICollectionReusableView.Type, data: Any)? {
        guard section < sections.count else { return nil }
        return sections[section].footer
    }

    /// セルサイズの取得
    public func cellSize(at indexPath: IndexPath, defaultSize: CGSize) -> CGSize {
        guard indexPath.section < sections.count,
              let cells = sections[indexPath.section].cells,
              indexPath.item < cells.data.count else {
            return defaultSize
        }

        let data = cells.data[indexPath.item]

        // セクション固有のサイズハンドラを優先
        if let sectionHandler = sections[indexPath.section].sizeForCell {
            return sectionHandler(indexPath.item, data)
        }

        // グローバルハンドラ
        if let globalHandler = sizeForItem {
            return globalHandler(indexPath, data)
        }

        return defaultSize
    }

    /// ヘッダーサイズの取得
    public func headerSize(for section: Int, defaultSize: CGSize) -> CGSize {
        guard section < sections.count,
              let header = sections[section].header else {
            return .zero
        }

        if let sizeHandler = sections[section].sizeForHeader {
            return sizeHandler(header.data)
        }

        return defaultSize
    }

    /// フッターサイズの取得
    public func footerSize(for section: Int, defaultSize: CGSize) -> CGSize {
        guard section < sections.count,
              let footer = sections[section].footer else {
            return .zero
        }

        if let sizeHandler = sections[section].sizeForFooter {
            return sizeHandler(footer.data)
        }

        return defaultSize
    }

    /// セル選択の処理
    public func handleSelection(at indexPath: IndexPath) {
        guard let cellData = cellData(at: indexPath) else { return }

        // セクション固有のハンドラを優先
        if let sectionHandler = sections[indexPath.section].onSelectCell {
            sectionHandler(indexPath.item, cellData.data)
        } else {
            onDidSelectItem?(indexPath, cellData.data)
        }
    }

    // MARK: - Data Update

    /// 指定セクションのセルデータを更新
    public func updateCells<T>(in sectionIndex: Int, data: [T]) {
        guard sectionIndex < sections.count else { return }
        sections[sectionIndex].updateCells(data)
    }

    /// 最初のセクションのセルデータを更新
    public func updateCells<T>(_ data: [T]) {
        updateCells(in: 0, data: data)
    }

    /// 指定セクションを取得
    public func section(at index: Int) -> UIKitCollectionSection? {
        guard index < sections.count else { return nil }
        return sections[index]
    }

    /// 最初のセクションを取得
    public var firstSection: UIKitCollectionSection? {
        sections.first
    }
}
