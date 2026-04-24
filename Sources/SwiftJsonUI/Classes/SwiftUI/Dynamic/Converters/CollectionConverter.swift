//
//  CollectionConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI collection views.
//  Rewritten to match collection_converter.rb behavior and modifier order.
//
//  Layout types (matching Ruby converter):
//  - columns == 1, vertical, with sections  -> ScrollView(.vertical) + LazyVStack
//  - columns == 1, vertical, no sections    -> List (legacy)
//  - horizontal + paging                    -> TabView(.page)
//  - horizontal                             -> ScrollView(.horizontal) + LazyHStack
//  - columns > 1                            -> ScrollView(.vertical) + LazyVGrid
//  - layout == "flow"                       -> ScrollView(.vertical) + FlowLayout
//
//  Modifier order:
//  1. Collection content (ScrollView/List/etc.)
//  2. .onReceive(scrollTo) (if scrollTo binding present)
//  3. applyStandardModifiers()
//

import SwiftUI
import Combine

#if DEBUG

// MARK: - String Extension for camelCase to snake_case conversion
extension String {
    func camelCaseToSnakeCase() -> String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let normalPattern = "([a-z0-9])([A-Z])"
        return
            self
            .replacingOccurrences(
                of: acronymPattern,
                with: "$1_$2",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: normalPattern,
                with: "$1_$2",
                options: .regularExpression
            )
            .lowercased()
    }
}

public struct CollectionConverter {

    // MARK: - Public Entry Point

    public static func convert(
        component: DynamicComponent,
        data: [String: Any],
        viewId: String? = nil
    ) -> AnyView {
        let globalColumns = component.columns ?? 1
        let sections = component.sections ?? []
        let isHorizontal = component.layout == "horizontal" || component.orientation == "horizontal"
        let isFlow = component.layout == "flow"
        let hasSections = !sections.isEmpty
        let cellIdProperty = component.rawData["cellIdProperty"] as? String
        let autoChangeTrackingId = component.rawData["autoChangeTrackingId"] as? Bool ?? false

        if autoChangeTrackingId && (cellIdProperty == nil || cellIdProperty!.isEmpty) {
            logAutoTrackingMisconfiguration(componentId: component.id)
        }

        // Resolve data source from items binding
        var dataSource: CollectionDataSource? = nil
        if let itemsBinding = component.rawData["items"] as? String,
           itemsBinding.hasPrefix("@{") && itemsBinding.hasSuffix("}") {
            let propertyName = String(itemsBinding.dropFirst(2).dropLast())
            if let resolved = data[propertyName] as? CollectionDataSource {
                dataSource = resolved.reconfigured(
                    cellIdProperty: cellIdProperty,
                    autoChangeTrackingId: autoChangeTrackingId
                )
            }
        }

        guard let dataSource = dataSource, hasSections else {
            return AnyView(
                Text("No collection data")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        }

        // Resolve onItemAppear callback
        var onItemAppearCallback: ((Int) -> Void)? = nil
        if let onItemAppearRaw = component.rawData["onItemAppear"] as? String,
           let propName = DynamicEventHelper.extractPropertyName(from: onItemAppearRaw) {
            onItemAppearCallback = data[propName] as? ((Int) -> Void)
        }

        // Resolve scroll publisher
        var scrollPublisher: AnyPublisher<Int, Never>? = nil
        if let scrollToBinding = component.scrollTo,
           scrollToBinding.hasPrefix("@{") && scrollToBinding.hasSuffix("}") {
            let propName = String(scrollToBinding.dropFirst(2).dropLast())
            if let subject = data[propName] as? PassthroughSubject<Int, Never> {
                scrollPublisher = subject.eraseToAnyPublisher()
            }
        }

        let scrollAnchorPoint: UnitPoint = {
            switch component.scrollAnchor {
            case "top": return .top
            case "center": return .center
            default: return .bottom
            }
        }()

        // lazy:false → render without any ScrollView / Lazy* container. The
        // Collection is expected to live inside an already-scrollable parent
        // (outer ScrollView, List, etc.). Paging is inherently lazy; it still
        // goes through buildPagingHorizontalLayout regardless of this flag.
        let isLazy = component.rawData["lazy"] as? Bool ?? true

        // 1. Build collection content based on layout type
        var result: AnyView

        if !isLazy && !(isHorizontal && component.paging == true) {
            result = buildNonLazyLayout(
                component: component,
                dataSource: dataSource,
                sections: sections,
                cellIdProperty: cellIdProperty,
                isHorizontal: isHorizontal,
                isFlow: isFlow,
                globalColumns: globalColumns,
                data: data,
                viewId: viewId,
                onItemAppear: onItemAppearCallback
            )
            // skipInsets mirrors the lazy branch; scrollEnabled/scrollTo/
            // defaultScrollAnchor are no-ops when there is no scroll container.
            result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data, skipInsets: true)
            return result
        }

        if isFlow {
            result = buildFlowLayout(
                component: component,
                dataSource: dataSource,
                sections: sections,
                cellIdProperty: cellIdProperty,
                scrollPublisher: scrollPublisher,
                scrollAnchorPoint: scrollAnchorPoint,
                data: data,
                viewId: viewId,
                onItemAppear: onItemAppearCallback
            )
        } else if globalColumns == 1 && !isHorizontal && hasSections {
            // Section-based vertical: ScrollView + LazyVStack
            result = buildVerticalSectionLayout(
                component: component,
                dataSource: dataSource,
                sections: sections,
                cellIdProperty: cellIdProperty,
                scrollPublisher: scrollPublisher,
                scrollAnchorPoint: scrollAnchorPoint,
                data: data,
                viewId: viewId,
                onItemAppear: onItemAppearCallback
            )
        } else if globalColumns == 1 && !isHorizontal {
            // Legacy single column: List
            result = buildListLayout(
                component: component,
                dataSource: dataSource,
                sections: sections,
                cellIdProperty: cellIdProperty,
                data: data,
                viewId: viewId,
                onItemAppear: onItemAppearCallback
            )
        } else if isHorizontal && component.paging == true {
            // Paging horizontal: TabView with page style
            result = buildPagingHorizontalLayout(
                component: component,
                dataSource: dataSource,
                sections: sections,
                cellIdProperty: cellIdProperty,
                data: data,
                viewId: viewId,
                onItemAppear: onItemAppearCallback
            )
        } else if isHorizontal {
            // Horizontal: ScrollView + LazyHStack
            result = buildHorizontalLayout(
                component: component,
                dataSource: dataSource,
                sections: sections,
                cellIdProperty: cellIdProperty,
                scrollPublisher: scrollPublisher,
                scrollAnchorPoint: scrollAnchorPoint,
                data: data,
                viewId: viewId,
                onItemAppear: onItemAppearCallback
            )
        } else {
            // Multiple columns: ScrollView + LazyVGrid
            result = buildGridLayout(
                component: component,
                dataSource: dataSource,
                sections: sections,
                cellIdProperty: cellIdProperty,
                globalColumns: globalColumns,
                scrollPublisher: scrollPublisher,
                scrollAnchorPoint: scrollAnchorPoint,
                data: data,
                viewId: viewId,
                onItemAppear: onItemAppearCallback
            )
        }

        // 2. .disabled(true) when scrollEnabled == false
        // Resolve scrollEnabled from binding if present
        var scrollEnabled = component.scrollEnabled
        if let scrollEnabledBinding = component.rawData["scrollEnabled"] as? String,
           scrollEnabledBinding.hasPrefix("@{") && scrollEnabledBinding.hasSuffix("}") {
            let propName = String(scrollEnabledBinding.dropFirst(2).dropLast())
            if let value = data[propName] as? Bool {
                scrollEnabled = value
            }
        }
        if scrollEnabled == false {
            result = AnyView(result.disabled(true))
        }

        // 2.5. .defaultScrollAnchor for iOS 17+
        var resolvedDefaultScrollAnchor = component.defaultScrollAnchor
        if let binding = component.rawData["defaultScrollAnchor"] as? String,
           binding.hasPrefix("@{") && binding.hasSuffix("}") {
            let propName = String(binding.dropFirst(2).dropLast())
            if let value = data[propName] as? String {
                resolvedDefaultScrollAnchor = value
            }
        }
        if let anchorStr = resolvedDefaultScrollAnchor {
            if #available(iOS 17.0, *) {
                let anchor: UnitPoint
                switch anchorStr {
                case "top": anchor = .top
                case "center": anchor = .center
                case "bottom": anchor = .bottom
                default: anchor = .top
                }
                result = AnyView(result.defaultScrollAnchor(anchor))
            }
        }

        // 3. applyStandardModifiers()
        let _ = Logger.debug("[Collection] id=\(component.id ?? "?") width=\(String(describing: component.width)) height=\(String(describing: component.height)) widthRaw=\(component.widthRaw ?? "nil") heightRaw=\(component.heightRaw ?? "nil")")
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data, skipInsets: true)

        return result
    }

    // MARK: - Cell Identity Helper

    /// Create IdentifiedCellItem array from cell data, matching generated code's identity pattern.
    /// Uses cellIdProperty (e.g., "cellId") from cell data for stable identity.
    /// Falls back to index-based identity if cellIdProperty is not available.
    ///
    /// When the dataSource was `reconfigured(autoChangeTrackingId: true)`, each
    /// dict already has a `"cellId"` key — prefer it so ForEach identity matches
    /// the enriched primary + hash.
    private static func identifiedItems(
        from cellsData: [[String: Any]],
        cellIdProperty: String?
    ) -> [IdentifiedCellItem] {
        cellsData.enumerated().map { index, data in
            let cellId: String
            if let enriched = data["cellId"] as? String {
                cellId = enriched
            } else if let prop = cellIdProperty, let id = data[prop] as? String {
                cellId = id
            } else {
                cellId = "\(index)"
            }
            return IdentifiedCellItem(id: cellId, index: index, data: data)
        }
    }

    // Guard so we only log the misconfiguration once per component id per launch.
    private static var loggedMisconfiguredComponentIds = Set<String>()
    private static let misconfigLogLock = NSLock()

    private static func logAutoTrackingMisconfiguration(componentId: String?) {
        let key = componentId ?? "(unnamed)"
        misconfigLogLock.lock()
        let firstTime = loggedMisconfiguredComponentIds.insert(key).inserted
        misconfigLogLock.unlock()
        guard firstTime else { return }
        Logger.log("[CollectionConverter] Collection \(key): autoChangeTrackingId is true but cellIdProperty is missing. Auto cellId generation is disabled; cells fall back to index-based identity.")
    }

    // MARK: - Paging Page Item Helper

    /// Flatten all cells from all sections into a single array of page items for paging layout.
    /// Each item carries its cellClassName (from the section config) and cellData.
    private static func flattenedPageItems(
        sections: [[String: Any]],
        dataSource: CollectionDataSource,
        cellIdProperty: String?
    ) -> [PagingPageItem] {
        var pages: [PagingPageItem] = []
        let sectionCount = min(sections.count, dataSource.sections.count)
        for sectionIndex in 0..<sectionCount {
            let sectionConfig = sections[sectionIndex]
            let sectionData = dataSource.sections[sectionIndex]
            guard let cellName = sectionConfig["cell"] as? String,
                  let cellsData = sectionData.cells else { continue }
            for (index, cellData) in cellsData.data.enumerated() {
                let cellId: String
                if let prop = cellIdProperty, let id = cellData[prop] as? String {
                    cellId = id
                } else {
                    cellId = "s\(sectionIndex)_\(index)"
                }
                pages.append(PagingPageItem(
                    id: cellId,
                    index: pages.count,
                    cellClassName: cellName,
                    data: cellData
                ))
            }
        }
        return pages
    }

    // MARK: - Layout Builders

    /// Vertical section-based: ScrollView(.vertical) + LazyVStack
    private static func buildVerticalSectionLayout(
        component: DynamicComponent,
        dataSource: CollectionDataSource,
        sections: [[String: Any]],
        cellIdProperty: String?,
        scrollPublisher: AnyPublisher<Int, Never>?,
        scrollAnchorPoint: UnitPoint,
        data: [String: Any],
        viewId: String?,
        onItemAppear: ((Int) -> Void)? = nil
    ) -> AnyView {
        let showsIndicators = component.showsVerticalScrollIndicator ?? true
        let lineSpacing = component.lineSpacing ?? component.itemSpacing ?? component.spacing ?? 0
        let vstackAlignment = getVStackAlignment(from: component)

        return AnyView(
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: showsIndicators) {
                    LazyVStack(alignment: vstackAlignment, spacing: lineSpacing) {
                        ForEach(
                            0..<min(sections.count, dataSource.sections.count),
                            id: \.self
                        ) { sectionIndex in
                            let sectionConfig = sections[sectionIndex]
                            let sectionData = dataSource.sections[sectionIndex]

                            // Header
                            if let headerName = sectionConfig["header"] as? String,
                               let headerData = sectionData.header {
                                buildHeaderView(
                                    headerClassName: headerName,
                                    headerData: headerData.data,
                                    data: data,
                                    viewId: viewId
                                )
                            }

                            // Cells
                            if let cellName = sectionConfig["cell"] as? String,
                               let cellsData = sectionData.cells {
                                let items = identifiedItems(from: cellsData.data, cellIdProperty: cellIdProperty)
                                ForEach(items) { cell in
                                    buildCellView(
                                        cellClassName: cellName,
                                        cellData: cell.data,
                                        cellIndex: cell.index,
                                        component: component,
                                        data: data,
                                        viewId: viewId,
                                        onItemAppear: onItemAppear
                                    )
                                    .id(cell.id)
                                }
                            }

                            // Footer
                            if let footerName = sectionConfig["footer"] as? String,
                               let footerData = sectionData.footer {
                                buildFooterView(
                                    footerClassName: footerName,
                                    footerData: footerData.data,
                                    data: data,
                                    viewId: viewId
                                )
                            }
                        }
                    }
                }
                .ifLet(scrollPublisher) { view, publisher in
                    view.onReceive(publisher) { index in
                        withAnimation {
                            scrollProxy.scrollTo(index, anchor: scrollAnchorPoint)
                        }
                    }
                }
            }
        )
    }

    /// Legacy single column List
    private static func buildListLayout(
        component: DynamicComponent,
        dataSource: CollectionDataSource,
        sections: [[String: Any]],
        cellIdProperty: String?,
        data: [String: Any],
        viewId: String?,
        onItemAppear: ((Int) -> Void)? = nil
    ) -> AnyView {
        // For legacy List, use first section's cells
        guard let firstSection = dataSource.sections.first,
              let cellsData = firstSection.cells,
              let sectionConfig = sections.first,
              let cellName = sectionConfig["cell"] as? String else {
            return AnyView(
                List {
                    Text("No data")
                }
                .listStyle(PlainListStyle())
            )
        }

        let hasHeader = sectionConfig["header"] != nil && firstSection.header != nil
        let hasFooter = sectionConfig["footer"] != nil && firstSection.footer != nil
        let hideSeparator = component.rawData["hideSeparator"] as? Bool ?? false

        let items = identifiedItems(from: cellsData.data, cellIdProperty: cellIdProperty)

        return AnyView(
            List {
                if hasHeader,
                   let headerName = sectionConfig["header"] as? String,
                   let headerData = firstSection.header {
                    Section {
                        ForEach(items) { cell in
                            buildCellView(
                                cellClassName: cellName,
                                cellData: cell.data,
                                cellIndex: cell.index,
                                component: component,
                                data: data,
                                viewId: viewId,
                                onItemAppear: onItemAppear
                            )
                        }
                    } header: {
                        buildHeaderView(
                            headerClassName: headerName,
                            headerData: headerData.data,
                            data: data,
                            viewId: viewId
                        )
                    }

                    if hasFooter,
                       let footerName = sectionConfig["footer"] as? String,
                       let footerData = firstSection.footer {
                        Section {
                            buildFooterView(
                                footerClassName: footerName,
                                footerData: footerData.data,
                                data: data,
                                viewId: viewId
                            )
                        }
                    }
                } else {
                    ForEach(items) { cell in
                        buildCellView(
                            cellClassName: cellName,
                            cellData: cell.data,
                            cellIndex: cell.index,
                            component: component,
                            data: data,
                            viewId: viewId,
                            onItemAppear: onItemAppear
                        )
                    }

                    if hasFooter,
                       let footerName = sectionConfig["footer"] as? String,
                       let footerData = firstSection.footer {
                        buildFooterView(
                            footerClassName: footerName,
                            footerData: footerData.data,
                            data: data,
                            viewId: viewId
                        )
                    }
                }
            }
            .listStyle(PlainListStyle())
            .modifier(ListSeparatorModifier(hide: hideSeparator))
        )
    }

    /// Horizontal: ScrollView(.horizontal) + LazyHStack
    private static func buildHorizontalLayout(
        component: DynamicComponent,
        dataSource: CollectionDataSource,
        sections: [[String: Any]],
        cellIdProperty: String?,
        scrollPublisher: AnyPublisher<Int, Never>?,
        scrollAnchorPoint: UnitPoint,
        data: [String: Any],
        viewId: String?,
        onItemAppear: ((Int) -> Void)? = nil
    ) -> AnyView {
        let showsIndicators = component.showsHorizontalScrollIndicator ?? true
        let columnSpacing = component.columnSpacing ?? component.itemSpacing ?? component.lineSpacing ?? component.spacing ?? 0
        let insetHorizontal = component.insetHorizontal ?? 0
        let hstackAlignment = getHStackAlignment(from: component)

        return AnyView(
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: showsIndicators) {
                    HStack(spacing: 0) {
                        // Leading inset spacer
                        if insetHorizontal > 0 {
                            Color.clear.frame(width: insetHorizontal)
                        }

                        // Content LazyHStack
                        LazyHStack(alignment: hstackAlignment, spacing: columnSpacing) {
                            ForEach(
                                0..<min(sections.count, dataSource.sections.count),
                                id: \.self
                            ) { sectionIndex in
                                let sectionConfig = sections[sectionIndex]
                                let sectionData = dataSource.sections[sectionIndex]

                                // Header
                                if let headerName = sectionConfig["header"] as? String,
                                   let headerData = sectionData.header {
                                    buildHeaderView(
                                        headerClassName: headerName,
                                        headerData: headerData.data,
                                        data: data,
                                        viewId: viewId
                                    )
                                }

                                // Cells
                                if let cellName = sectionConfig["cell"] as? String,
                                   let cellsData = sectionData.cells {
                                    let items = identifiedItems(from: cellsData.data, cellIdProperty: cellIdProperty)
                                    ForEach(items) { cell in
                                        buildCellView(
                                            cellClassName: cellName,
                                            cellData: cell.data,
                                            cellIndex: cell.index,
                                            component: component,
                                            data: data,
                                            viewId: viewId,
                                            onItemAppear: onItemAppear
                                        )
                                        .id(cell.id)
                                    }
                                }

                                // Footer
                                if let footerName = sectionConfig["footer"] as? String,
                                   let footerData = sectionData.footer {
                                    buildFooterView(
                                        footerClassName: footerName,
                                        footerData: footerData.data,
                                        data: data,
                                        viewId: viewId
                                    )
                                }
                            }
                        }

                        // Trailing inset spacer
                        if insetHorizontal > 0 {
                            Color.clear.frame(width: insetHorizontal)
                        }
                    }
                }
                .ifLet(scrollPublisher) { view, publisher in
                    view.onReceive(publisher) { index in
                        withAnimation {
                            scrollProxy.scrollTo(index, anchor: scrollAnchorPoint)
                        }
                    }
                }
            }
        )
    }

    /// Paging horizontal: TabView with .page style
    /// Flattens all cells from all sections into pages.
    /// Supports currentPage binding and onPageChanged callback.
    private static func buildPagingHorizontalLayout(
        component: DynamicComponent,
        dataSource: CollectionDataSource,
        sections: [[String: Any]],
        cellIdProperty: String?,
        data: [String: Any],
        viewId: String?,
        onItemAppear: ((Int) -> Void)? = nil
    ) -> AnyView {
        let pageItems = flattenedPageItems(
            sections: sections,
            dataSource: dataSource,
            cellIdProperty: cellIdProperty
        )
        let itemSpacing = component.columnSpacing ?? component.itemSpacing ?? component.spacing ?? 0

        // Resolve currentPage binding
        let currentPageRaw = component.rawData["currentPage"] as? String
        let currentPageBinding: SwiftUI.Binding<Int>? = {
            if let raw = currentPageRaw,
               let propName = DynamicEventHelper.extractPropertyName(from: raw) {
                if let binding = data[propName] as? SwiftUI.Binding<Int> {
                    return binding
                }
            }
            return nil
        }()

        // Resolve onPageChanged callback
        var onPageChangedCallback: ((Int) -> Void)? = nil
        if let onPageChangedRaw = component.rawData["onPageChanged"] as? String,
           let propName = DynamicEventHelper.extractPropertyName(from: onPageChangedRaw) {
            onPageChangedCallback = data[propName] as? ((Int) -> Void)
        }

        return AnyView(
            PagingCollectionWrapperView(
                pageItems: pageItems,
                itemSpacing: itemSpacing,
                currentPageBinding: currentPageBinding,
                onPageChangedCallback: onPageChangedCallback,
                onItemAppearCallback: onItemAppear,
                component: component,
                data: data,
                viewId: viewId
            )
        )
    }

    /// Multiple columns: ScrollView(.vertical) + LazyVGrid
    private static func buildGridLayout(
        component: DynamicComponent,
        dataSource: CollectionDataSource,
        sections: [[String: Any]],
        cellIdProperty: String?,
        globalColumns: Int,
        scrollPublisher: AnyPublisher<Int, Never>?,
        scrollAnchorPoint: UnitPoint,
        data: [String: Any],
        viewId: String?,
        onItemAppear: ((Int) -> Void)? = nil
    ) -> AnyView {
        let showsIndicators = component.showsVerticalScrollIndicator ?? true
        let itemSpacing = component.itemSpacing ?? component.columnSpacing ?? component.spacing ?? 10
        let lineSpacing = component.lineSpacing ?? component.itemSpacing ?? component.spacing ?? 10
        // `cellWidth` / `cellHeight` pin each cell to a fixed size inside the grid.
        // When absent the existing flexible sizing path is preserved.
        let cellWidth = cgFloatFromRaw(component.rawData["cellWidth"])
        let cellHeight = cgFloatFromRaw(component.rawData["cellHeight"])

        return AnyView(
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: showsIndicators) {
                    ForEach(
                        0..<min(sections.count, dataSource.sections.count),
                        id: \.self
                    ) { sectionIndex in
                        let sectionConfig = sections[sectionIndex]
                        let sectionData = dataSource.sections[sectionIndex]
                        let sectionColumns = sectionConfig["columns"] as? Int ?? globalColumns

                        // Header
                        if let headerName = sectionConfig["header"] as? String,
                           let headerData = sectionData.header {
                            buildHeaderView(
                                headerClassName: headerName,
                                headerData: headerData.data,
                                data: data,
                                viewId: viewId
                            )
                            .padding(.horizontal)
                        }

                        // Grid of cells
                        if let cellName = sectionConfig["cell"] as? String,
                           let cellsData = sectionData.cells {
                            let gridItemSize: GridItem.Size = cellWidth.map { .fixed($0) } ?? .flexible()
                            let gridColumns = Array(
                                repeating: GridItem(gridItemSize, spacing: itemSpacing),
                                count: sectionColumns
                            )
                            let items = identifiedItems(from: cellsData.data, cellIdProperty: cellIdProperty)
                            LazyVGrid(columns: gridColumns, spacing: lineSpacing) {
                                ForEach(items) { cell in
                                    buildCellView(
                                        cellClassName: cellName,
                                        cellData: cell.data,
                                        cellIndex: cell.index,
                                        component: component,
                                        data: data,
                                        viewId: viewId,
                                        onItemAppear: onItemAppear
                                    )
                                    .frame(maxWidth: cellWidth ?? .infinity, minHeight: cellHeight, maxHeight: cellHeight)
                                    .id(cell.id)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Footer
                        if let footerName = sectionConfig["footer"] as? String,
                           let footerData = sectionData.footer {
                            buildFooterView(
                                footerClassName: footerName,
                                footerData: footerData.data,
                                data: data,
                                viewId: viewId
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                .ifLet(scrollPublisher) { view, publisher in
                    view.onReceive(publisher) { index in
                        withAnimation {
                            scrollProxy.scrollTo(index, anchor: scrollAnchorPoint)
                        }
                    }
                }
            }
        )
    }

    /// Flow layout: ScrollView(.vertical) + FlowLayout (wrapping)
    private static func buildFlowLayout(
        component: DynamicComponent,
        dataSource: CollectionDataSource,
        sections: [[String: Any]],
        cellIdProperty: String?,
        scrollPublisher: AnyPublisher<Int, Never>?,
        scrollAnchorPoint: UnitPoint,
        data: [String: Any],
        viewId: String?,
        onItemAppear: ((Int) -> Void)? = nil
    ) -> AnyView {
        let showsIndicators = component.showsVerticalScrollIndicator ?? true
        let hSpacing = component.columnSpacing ?? component.itemSpacing ?? component.spacing ?? 8
        let vSpacing = component.lineSpacing ?? component.itemSpacing ?? 8

        return AnyView(
            ScrollView(.vertical, showsIndicators: showsIndicators) {
                ForEach(
                    0..<min(sections.count, dataSource.sections.count),
                    id: \.self
                ) { sectionIndex in
                    let sectionConfig = sections[sectionIndex]
                    let sectionData = dataSource.sections[sectionIndex]

                    if let cellName = sectionConfig["cell"] as? String,
                       let cellsData = sectionData.cells {
                        let items = identifiedItems(from: cellsData.data, cellIdProperty: cellIdProperty)
                        FlowLayout(
                            alignment: getFlowAlignment(from: component),
                            horizontalSpacing: hSpacing,
                            verticalSpacing: vSpacing
                        ) {
                            ForEach(items) { cell in
                                buildCellView(
                                    cellClassName: cellName,
                                    cellData: cell.data,
                                    cellIndex: cell.index,
                                    component: component,
                                    data: data,
                                    viewId: viewId,
                                    onItemAppear: onItemAppear
                                )
                                .id(cell.id)
                            }
                        }
                    }
                }
            }
        )
    }

    /// Non-lazy layout: no ScrollView, no Lazy* containers. Expects a parent
    /// that already provides scrolling. Sticky headers, scrollTo, and page
    /// anchors are not supported here.
    private static func buildNonLazyLayout(
        component: DynamicComponent,
        dataSource: CollectionDataSource,
        sections: [[String: Any]],
        cellIdProperty: String?,
        isHorizontal: Bool,
        isFlow: Bool,
        globalColumns: Int,
        data: [String: Any],
        viewId: String?,
        onItemAppear: ((Int) -> Void)? = nil
    ) -> AnyView {
        let itemSpacing = component.itemSpacing ?? component.spacing ?? 0
        let lineSpacing = component.lineSpacing ?? component.itemSpacing ?? component.spacing ?? 0
        let columnSpacing = component.columnSpacing ?? component.itemSpacing ?? component.spacing ?? 0
        let cellWidth = cgFloatFromRaw(component.rawData["cellWidth"])
        let cellHeight = cgFloatFromRaw(component.rawData["cellHeight"])

        let sectionBodies: (Int) -> AnyView = { sectionIndex in
            let sectionConfig = sections[sectionIndex]
            let sectionData = dataSource.sections[sectionIndex]
            return AnyView(
                Group {
                    if let headerName = sectionConfig["header"] as? String,
                       let headerData = sectionData.header {
                        buildHeaderView(
                            headerClassName: headerName,
                            headerData: headerData.data,
                            data: data,
                            viewId: viewId
                        )
                    }

                    if let cellName = sectionConfig["cell"] as? String,
                       let cellsData = sectionData.cells {
                        let items = identifiedItems(from: cellsData.data, cellIdProperty: cellIdProperty)
                        if isFlow {
                            FlowLayout(
                                alignment: getFlowAlignment(from: component),
                                horizontalSpacing: columnSpacing > 0 ? columnSpacing : 8,
                                verticalSpacing: lineSpacing > 0 ? lineSpacing : 8
                            ) {
                                ForEach(items) { cell in
                                    buildCellView(
                                        cellClassName: cellName,
                                        cellData: cell.data,
                                        cellIndex: cell.index,
                                        component: component,
                                        data: data,
                                        viewId: viewId,
                                        onItemAppear: onItemAppear
                                    )
                                    .id(cell.id)
                                }
                            }
                        } else if !isHorizontal && globalColumns > 1 {
                            let sectionColumns = sectionConfig["columns"] as? Int ?? globalColumns
                            let gridItemSize: GridItem.Size = cellWidth.map { .fixed($0) } ?? .flexible()
                            let gridColumns = Array(
                                repeating: GridItem(gridItemSize, spacing: itemSpacing),
                                count: sectionColumns
                            )
                            LazyVGrid(columns: gridColumns, spacing: lineSpacing) {
                                ForEach(items) { cell in
                                    buildCellView(
                                        cellClassName: cellName,
                                        cellData: cell.data,
                                        cellIndex: cell.index,
                                        component: component,
                                        data: data,
                                        viewId: viewId,
                                        onItemAppear: onItemAppear
                                    )
                                    .frame(maxWidth: cellWidth ?? .infinity, minHeight: cellHeight, maxHeight: cellHeight)
                                    .id(cell.id)
                                }
                            }
                        } else {
                            ForEach(items) { cell in
                                buildCellView(
                                    cellClassName: cellName,
                                    cellData: cell.data,
                                    cellIndex: cell.index,
                                    component: component,
                                    data: data,
                                    viewId: viewId,
                                    onItemAppear: onItemAppear
                                )
                                .id(cell.id)
                            }
                        }
                    }

                    if let footerName = sectionConfig["footer"] as? String,
                       let footerData = sectionData.footer {
                        buildFooterView(
                            footerClassName: footerName,
                            footerData: footerData.data,
                            data: data,
                            viewId: viewId
                        )
                    }
                }
            )
        }

        let sectionCount = min(sections.count, dataSource.sections.count)

        if isHorizontal {
            let hstackAlignment = getHStackAlignment(from: component)
            return AnyView(
                HStack(alignment: hstackAlignment, spacing: columnSpacing) {
                    ForEach(0..<sectionCount, id: \.self) { sectionIndex in
                        sectionBodies(sectionIndex)
                    }
                }
            )
        } else {
            let vstackAlignment = getVStackAlignment(from: component)
            return AnyView(
                VStack(alignment: vstackAlignment, spacing: lineSpacing) {
                    ForEach(0..<sectionCount, id: \.self) { sectionIndex in
                        sectionBodies(sectionIndex)
                    }
                }
            )
        }
    }

    // MARK: - Cell/Header/Footer View Builders

    @ViewBuilder
    private static func buildCellView(
        cellClassName: String,
        cellData: [String: Any],
        cellIndex: Int = 0,
        component: DynamicComponent,
        data: [String: Any],
        viewId: String?,
        onItemAppear: ((Int) -> Void)? = nil
    ) -> some View {
        let jsonFileName = resolveJsonFileName(from: cellClassName)

        let _ = Logger.debug("[CollectionConverter] buildCellView: jsonFileName=\(jsonFileName), cellClassName=\(cellClassName), cellData keys=\(Array(cellData.keys).sorted())")
        let visKeys = cellData.filter { $0.key.lowercased().contains("visibility") }
        let _ = Logger.debug("[CollectionConverter] cellData visibility keys: \(visKeys)")

        DynamicView(
            jsonName: jsonFileName,
            viewId: cellClassName,
            data: cellData
        )
        .onAppear {
            onItemAppear?(cellIndex)
        }
    }

    @ViewBuilder
    private static func buildHeaderView(
        headerClassName: String,
        headerData: [String: Any],
        data: [String: Any],
        viewId: String?
    ) -> some View {
        let jsonFileName = resolveJsonFileName(from: headerClassName)

        DynamicView(
            jsonName: jsonFileName,
            viewId: headerClassName,
            data: headerData
        )
    }

    @ViewBuilder
    private static func buildFooterView(
        footerClassName: String,
        footerData: [String: Any],
        data: [String: Any],
        viewId: String?
    ) -> some View {
        let jsonFileName = resolveJsonFileName(from: footerClassName)

        DynamicView(
            jsonName: jsonFileName,
            viewId: footerClassName,
            data: footerData
        )
    }

    // MARK: - Alignment Helpers

    private static func getHStackAlignment(from component: DynamicComponent) -> VerticalAlignment {
        guard let gravity = component.gravity else { return .top }
        if gravity.contains("bottom") { return .bottom }
        if gravity.contains("center") || gravity.contains("centerVertical") { return .center }
        return .top
    }

    private static func getVStackAlignment(from component: DynamicComponent) -> HorizontalAlignment {
        guard let gravity = component.gravity else { return .leading }
        if gravity.contains("right") { return .trailing }
        if gravity.contains("center") || gravity.contains("centerHorizontal") { return .center }
        return .leading
    }

    private static func getFlowAlignment(from component: DynamicComponent) -> HorizontalAlignment {
        guard let gravity = component.gravity else { return .leading }
        if gravity.contains("right") { return .trailing }
        if gravity.contains("center") || gravity.contains("centerHorizontal") { return .center }
        return .leading
    }

    // MARK: - Name Resolution

    /// Resolve JSON file name from section cell/header/footer value.
    /// In Dynamic mode, section values are JSON file names (snake_case) possibly with subdirectory.
    /// Bundle flattens directories so we strip the path prefix.
    /// e.g. "Chat/candidate_card" -> "candidate_card"
    /// e.g. "whisky_card" -> "whisky_card"
    fileprivate static func resolveJsonFileName(from name: String) -> String {
        // Strip directory path if present
        if name.contains("/") {
            return (name as NSString).lastPathComponent
        }
        return name
    }
}

// MARK: - Paging Page Item Model

/// Represents a single page in a paging horizontal collection.
/// Each page carries the cell class name and cell data needed to render the cell view.
private struct PagingPageItem: Identifiable {
    let id: String
    let index: Int
    let cellClassName: String
    let data: [String: Any]
}

// MARK: - Paging Collection Wrapper View

/// Wrapper view that manages @State for paging TabView selection.
/// Similar to TabViewWrapperView pattern - holds @State internally
/// and syncs with optional external Binding<Int>.
private struct PagingCollectionWrapperView: View {
    let pageItems: [PagingPageItem]
    let itemSpacing: CGFloat
    let currentPageBinding: SwiftUI.Binding<Int>?
    let onPageChangedCallback: ((Int) -> Void)?
    let onItemAppearCallback: ((Int) -> Void)?
    let component: DynamicComponent
    let data: [String: Any]
    let viewId: String?

    @State private var internalCurrentPage: Int = 0

    private var effectiveSelection: SwiftUI.Binding<Int> {
        if let binding = currentPageBinding {
            return binding
        }
        return $internalCurrentPage
    }

    var body: some View {
        TabView(selection: effectiveSelection) {
            ForEach(pageItems) { page in
                let jsonFileName = CollectionConverter.resolveJsonFileName(from: page.cellClassName)
                DynamicView(
                    jsonName: jsonFileName,
                    viewId: page.cellClassName,
                    data: page.data
                )
                .padding(.horizontal, itemSpacing > 0 ? itemSpacing / 2 : 0)
                .tag(page.index)
                .onAppear {
                    onItemAppearCallback?(page.index)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onChange(of: effectiveSelection.wrappedValue) { newValue in
            onPageChangedCallback?(newValue)
        }
    }
}

/// Coerce a JSON-parsed value to `CGFloat?` regardless of whether it decoded
/// into Int, Double, or CGFloat. Used for attributes like `cellWidth` /
/// `cellHeight` that the tool emits as plain numbers.
fileprivate func cgFloatFromRaw(_ value: Any?) -> CGFloat? {
    if let v = value as? CGFloat { return v }
    if let v = value as? Double { return CGFloat(v) }
    if let v = value as? Int { return CGFloat(v) }
    if let v = value as? NSNumber { return CGFloat(truncating: v) }
    return nil
}

/// Apply `.listRowSeparator(.hidden)` across all rows when `hideSeparator: true`.
/// Used by the Collection legacy single-column List path to honor the tool's
/// `hideSeparator` attribute.
private struct ListSeparatorModifier: ViewModifier {
    let hide: Bool

    func body(content: Content) -> some View {
        if hide {
            content.listRowSeparator(.hidden)
        } else {
            content
        }
    }
}

#endif // DEBUG
