//
//  SJUICollectionView+DataSource.swift
//  SwiftJsonUI
//
//  Created by Claude on 2026/01/15.
//

import UIKit

public extension SJUICollectionView {

    /// UIKitCollectionDataSourceを使ってCollectionViewをセットアップ
    @discardableResult
    func setupWithDataSource(_ dataSource: UIKitCollectionDataSource?) -> Self {
        guard let dataSource = dataSource else { return self }

        // デフォルトサイズを取得
        let defaultItemSize: CGSize
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            defaultItemSize = flowLayout.itemSize
        } else {
            defaultItemSize = CGSize(width: 50, height: 50)
        }

        let defaultHeaderSize: CGSize
        let defaultFooterSize: CGSize
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            defaultHeaderSize = flowLayout.headerReferenceSize
            defaultFooterSize = flowLayout.footerReferenceSize
        } else {
            defaultHeaderSize = .zero
            defaultFooterSize = .zero
        }

        // セル、ヘッダー、フッターを登録
        for section in dataSource.sections {
            // セルを登録（デフォルト + 追加クラス）
            if let cells = section.cells {
                register(cells.cellClass, forCellWithReuseIdentifier: cells.viewName)
                for additional in section.additionalCellClasses {
                    register(additional.cellClass, forCellWithReuseIdentifier: additional.viewName)
                }
            }
            // ヘッダーを登録
            if let header = section.header {
                register(
                    header.viewClass,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: header.viewName
                )
            }
            // フッターを登録
            if let footer = section.footer {
                register(
                    footer.viewClass,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                    withReuseIdentifier: footer.viewName
                )
            }
        }

        return self
            // DataSource
            .onNumberOfSections { _ in
                dataSource.numberOfSections
            }
            .onNumberOfItemsInSection { _, section in
                dataSource.numberOfItems(in: section)
            }
            .onCellForItem { collectionView, indexPath in
                guard let cellInfo = dataSource.cellData(at: indexPath) else {
                    return UICollectionViewCell()
                }
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: cellInfo.viewName,
                    for: indexPath
                )
                // セルにデータを適用（型消去されたconfigure呼び出し）
                if let configurableCell = cell as? AnyUIKitCollectionCellConfigurable {
                    configurableCell.configureWithAny(cellInfo.data)
                }
                return cell
            }
            .onSupplementaryView { collectionView, kind, indexPath in
                if kind == UICollectionView.elementKindSectionHeader {
                    if let headerInfo = dataSource.headerData(for: indexPath.section) {
                        let view = collectionView.dequeueReusableSupplementaryView(
                            ofKind: kind,
                            withReuseIdentifier: headerInfo.viewName,
                            for: indexPath
                        )
                        if let configurableView = view as? AnyUIKitCollectionCellConfigurable {
                            configurableView.configureWithAny(headerInfo.data)
                        }
                        return view
                    }
                } else if kind == UICollectionView.elementKindSectionFooter {
                    if let footerInfo = dataSource.footerData(for: indexPath.section) {
                        let view = collectionView.dequeueReusableSupplementaryView(
                            ofKind: kind,
                            withReuseIdentifier: footerInfo.viewName,
                            for: indexPath
                        )
                        if let configurableView = view as? AnyUIKitCollectionCellConfigurable {
                            configurableView.configureWithAny(footerInfo.data)
                        }
                        return view
                    }
                }
                return UICollectionReusableView()
            }
            // Delegate
            .onDidSelectItem { _, indexPath in
                dataSource.handleSelection(at: indexPath)
            }
            .onWillDisplayCell { _, cell, indexPath in
                if let cellData = dataSource.cellData(at: indexPath) {
                    dataSource.onWillDisplayCell?(cell, indexPath, cellData.data)
                }
            }
            .onDidEndDisplayingCell { _, cell, indexPath in
                dataSource.onDidEndDisplayingCell?(cell, indexPath)
            }
            // FlowLayout Delegate
            .onSizeForItem { [weak self] _, _, indexPath in
                // カラム数指定がある場合はそれに基づいてサイズ計算
                if indexPath.section < dataSource.sections.count {
                    let section = dataSource.sections[indexPath.section]
                    if section.numberOfColumns > 1 {
                        let collectionWidth = self?.bounds.width ?? UIScreen.main.bounds.width
                        let totalSpacing = section.interItemSpacing * CGFloat(section.numberOfColumns - 1)
                        let cellWidth = (collectionWidth - totalSpacing) / CGFloat(section.numberOfColumns)
                        let cellHeight = section.cellHeight ?? cellWidth
                        return CGSize(width: cellWidth, height: cellHeight)
                    }
                }
                return dataSource.cellSize(at: indexPath, defaultSize: defaultItemSize)
            }
            .onHeaderReferenceSize { _, _, section in
                dataSource.headerSize(for: section, defaultSize: defaultHeaderSize)
            }
            .onFooterReferenceSize { _, _, section in
                dataSource.footerSize(for: section, defaultSize: defaultFooterSize)
            }
            // ScrollView Delegate
            .onDidScroll { scrollView in
                dataSource.onDidScroll?(scrollView)
            }
    }

    /// データソースを更新してリロード
    func reloadWithDataSource(_ dataSource: UIKitCollectionDataSource?) {
        setupWithDataSource(dataSource)
        reloadData()
        applyDefaultScrollAnchor()
    }

    /// Apply defaultScrollAnchor after reload
    private func applyDefaultScrollAnchor() {
        guard let anchor = defaultScrollAnchor, anchor == .bottom else { return }
        layoutIfNeeded()
        let lastSection = numberOfSections - 1
        guard lastSection >= 0 else { return }
        let lastItem = numberOfItems(inSection: lastSection) - 1
        guard lastItem >= 0 else { return }
        scrollToItem(at: IndexPath(item: lastItem, section: lastSection), at: .bottom, animated: false)
    }

    /// データのみ更新してリロード（DataSourceは再設定しない）
    func reloadData<T>(with data: [T], in section: Int = 0) {
        // 現在のDataSourceのデータを更新してリロード
        // Note: この呼び出しの前にDataSourceのupdateCellsを呼ぶ必要がある
        reloadData()
    }
}
