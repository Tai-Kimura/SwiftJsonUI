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
//  2. .onChange(of: scrollTo) (if a scrollTo binding is present)
//  3. applyStandardModifiers()
//

import SwiftUI
// Combine is gone with the publisher: `scrollTo` is a plain value now.

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
        let sections = component.sections ?? []
        let attrs = component.typedAttributes(CollectionAttributes.self)
        // `horizontalScroll: true` is the declared boolean spelling of the
        // same direction fact (ScrollView's vocabulary — real carousels use
        // it). The static codegens honor it; the android dynamic renderer
        // gained the same reading in the F4-P2 parity cycle.
        let isHorizontal = component.layout == "horizontal"
            || component.orientation == "horizontal"
            || attrs.horizontalScroll == true
        // Case-insensitive: the declared enum admits 'Flow' as well as
        // 'flow' (the static codegens compare casecmp since the F4-P2
        // parity cycle). 'leftAligned' is an alias spelling of flow (SSoT
        // valueAliases, 2026-08-03 unification — the generated enum folds
        // it the same way).
        let isFlow = ["flow", "leftaligned"].contains(component.layout?.lowercased() ?? "")
        let hasSections = !sections.isEmpty
        // `columns` accepts a literal number or a `@{binding}` (canonical
        // kind: number | binding — the contract the static codegens already
        // implement). Bindings resolve from `data` at render time and fall
        // back to 1 when unresolved; per the shared contract a bound column
        // count always renders on the grid path (LazyVGrid), even when it
        // resolves to 1, so the container stays stable across runtime
        // column-count changes.
        let (globalColumns, columnsIsBinding) = resolveGlobalColumns(
            attrs.columns,
            legacyColumns: component.int(CollectionAttributes.self, \.columns, data: data),
            data: data
        )
        let cellIdProperty = attrs.cellIdProperty
        let autoChangeTrackingId = attrs.autoChangeTrackingId ?? false

        if autoChangeTrackingId && (cellIdProperty == nil || cellIdProperty!.isEmpty) {
            logAutoTrackingMisconfiguration(componentId: component.id)
        }

        // Resolve data source from items binding
        var dataSource: CollectionDataSource? = nil
        if let propertyName = attrs.items?.bindingExpression {
            if let resolved = data[propertyName] as? CollectionDataSource {
                dataSource = resolved.reconfigured(
                    cellIdProperty: cellIdProperty,
                    autoChangeTrackingId: autoChangeTrackingId
                )
            }
        }

        guard let dataSource = dataSource, hasSections else {
            // Declaration-faithful (2026-08-02 ruling): no declared data
            // source → no items rendered, but the container still carries
            // its declared frame/background — route the empty view through
            // the same standard-modifier chain as every populated path.
            // The old early return skipped it, so the whole container
            // vanished (and the still-older "No collection data" debug text
            // was undeclared behavior).
            return DynamicModifierHelper.applyStandardModifiers(
                AnyView(Color.clear), component: component, data: data
            )
        }

        // Resolve onItemAppear callback
        var onItemAppearCallback: ((Int) -> Void)? = nil
        if let onItemAppearRaw = component.string(CollectionAttributes.self, \.onItemAppear),
           let propName = DynamicEventHelper.extractPropertyName(from: onItemAppearRaw) {
            onItemAppearCallback = data[propName] as? ((Int) -> Void)
        }

        // Resolve the programmatic scroll request.
        //
        // `scrollTo` is declared as a PLAIN VALUE — `String` when
        // `cellIdProperty` is set (scroll to that cell id), `Int` otherwise.
        // This used to require a `PassthroughSubject<Int, Never>` in the data
        // dictionary, which is the Combine transport 49-E withdrew from the
        // declaration on 2026-08-05: naming a Swift type in a cross-platform
        // declaration is what made kjui's map_to_kotlin_type pass it through
        // verbatim and kill the Kotlin build. How the request travels is each
        // platform's own business, and codegen moved to `.onChange(of:)`
        // (collection_converter.rb:1165). This is the dynamic half.
        //
        // A value that changes has nothing to throttle, and re-sending the
        // SAME value does not re-scroll — that is publisher behaviour a plain
        // value cannot express, which is exactly what the declaration gave up.
        let scrollTarget: CollectionScrollTarget? = {
            guard let raw = component.typedAttributes(CollectionAttributes.self)
                .scrollTo?.rawRepresentation as? String,
                  let propName = DynamicBindingResolver.inner(of: raw) else { return nil }
            let value = DynamicBindingResolver.lookupRaw(path: propName, in: data)
            guard let value else { return nil }
            // cellIdProperty decides which spelling the layout is sending.
            if cellIdProperty?.isEmpty == false {
                guard let id = DynamicBindingResolver.unwrap(value) as? String else { return nil }
                return .cellId(id)
            }
            guard let index = DynamicBindingResolver.unwrap(value) as? Int else { return nil }
            return .index(index)
        }()
        let scrollAnimated = component.typedAttributes(CollectionAttributes.self).scrollAnimated ?? true

        let scrollAnchorPoint: UnitPoint = {
            switch component.scrollAnchor {
            case "top": return .top
            case "center": return .center
            default: return .bottom
            }
        }()

        // `lazy` may be a boolean (legacy) or one of "lazy" / "eager" / "none".
        // For binding values we resolve at runtime via DynamicBindingHelper so a
        // toggle propagates through the same CollectionStackView wrapper without
        // changing modifier-chain shape. Paging always wins (HorizontalPager is
        // inherently lazy).
        // `lazy` accepts a legacy boolean besides the declared enum —
        // wider than the declared kind, so raw passthrough.
        let resolvedLazy: Any? = DynamicBindingHelper.resolveValue(
            component.rawAttribute("lazy"),
            data: data
        )
        let collectionMode = CollectionStackMode(json: resolvedLazy)

        // 1. Build collection content based on layout type
        var result: AnyView
        // The horizontal CollectionStackView carries `insetHorizontal` on its
        // insetLeading/insetTrailing params (buildHorizontalLayout), so the
        // content-padding channel must exclude it there — the codegen makes
        // the same split (collection_content_insets_swift_expr
        // include_horizontal: axis == :vertical). Both channels applying it
        // is what doubled the leading gap on horizontal collections.
        var horizontalStackCarriesInsetH = false

        if collectionMode == .none && !(isHorizontal && component.paging == true) {
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
            // Collection insets are CONTENT padding: applied to the content
            // before frame/background so cells inset within the declared
            // container, exactly what the sjui codegen emits. The generic
            // applyInsets pads before background in the standard chain and
            // GROWS the container instead (measured: d=134 on
            // Collection/contentInsets__static) — hence skipInsets.
            result = applyCollectionContentInsets(result, component: component)
            result = applyContainerInset(result, component: component)
            result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data, skipInsets: true)
            return result
        }

        if isFlow {
            result = buildFlowLayout(
                component: component,
                dataSource: dataSource,
                sections: sections,
                cellIdProperty: cellIdProperty,
                scrollTarget: scrollTarget,
                scrollAnimated: scrollAnimated,
                scrollAnchorPoint: scrollAnchorPoint,
                data: data,
                viewId: viewId,
                onItemAppear: onItemAppearCallback
            )
        } else if globalColumns == 1 && !isHorizontal && !columnsIsBinding && hasSections {
            // Section-based vertical: CollectionStackView delegates the
            // outer container choice (lazy/eager/none) so the JSON `lazy`
            // value (literal or binding-resolved) becomes a parameter.
            result = buildVerticalSectionLayout(
                component: component,
                dataSource: dataSource,
                sections: sections,
                cellIdProperty: cellIdProperty,
                scrollTarget: scrollTarget,
                scrollAnimated: scrollAnimated,
                scrollAnchorPoint: scrollAnchorPoint,
                data: data,
                viewId: viewId,
                onItemAppear: onItemAppearCallback,
                mode: collectionMode
            )
        } else if globalColumns == 1 && !isHorizontal && !columnsIsBinding {
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
            // Horizontal: CollectionStackView(axis: .horizontal) selects between
            // LazyHStack / HStack / no-scroll based on `lazy`.
            horizontalStackCarriesInsetH = true
            result = buildHorizontalLayout(
                component: component,
                dataSource: dataSource,
                sections: sections,
                cellIdProperty: cellIdProperty,
                scrollTarget: scrollTarget,
                scrollAnimated: scrollAnimated,
                scrollAnchorPoint: scrollAnchorPoint,
                data: data,
                viewId: viewId,
                onItemAppear: onItemAppearCallback,
                mode: collectionMode
            )
        } else {
            // Multiple columns: ScrollView + LazyVGrid
            result = buildGridLayout(
                component: component,
                dataSource: dataSource,
                sections: sections,
                cellIdProperty: cellIdProperty,
                globalColumns: globalColumns,
                scrollTarget: scrollTarget,
                scrollAnimated: scrollAnimated,
                scrollAnchorPoint: scrollAnchorPoint,
                data: data,
                viewId: viewId,
                onItemAppear: onItemAppearCallback
            )
        }

        // 2. .scrollDisabled(_:) when scrollEnabled == false
        // Use scrollDisabled (not disabled) so an in-flight pan / deceleration
        // is not killed when the binding flips to false, and so the modifier
        // chain shape stays the same regardless of value (preserves
        // ScrollViewReader / view identity across toggles).
        var scrollEnabled: Bool = component.typedAttributes(CollectionAttributes.self)
            .scrollEnabled?.value ?? true
        if let expr = component.typedAttributes(CollectionAttributes.self)
            .scrollEnabled?.bindingExpression {
            // Canonical bool value context (coercion table / dot-path / default)
            if let value = DynamicBindingResolver.resolveBool(expression: expr, data: data) {
                scrollEnabled = value
            }
        }
        result = AnyView(result.scrollDisabled(!scrollEnabled))

        // 2.5. .defaultScrollAnchor for iOS 17+
        var resolvedDefaultScrollAnchor = component.defaultScrollAnchor
        // `defaultScrollAnchor` is declared `string` + enum with no binding
        // form, but both halves accept one (scrollview_converter.rb:209).
        // `AttrEnum` is an OPEN enum, so the bound spelling survives as
        // `.unknown("@{x}")` — the raw read was never needed.
        if let binding = component.enumString(CollectionAttributes.self, \.defaultScrollAnchor),
           let inner = DynamicBindingResolver.inner(of: binding) {
            // Canonical string value context (dot-path / `??` default)
            if let value = DynamicBindingResolver.resolveString(expression: inner, data: data) {
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

        // 3. applyStandardModifiers() — insets excluded: Collection insets
        // are content padding (see applyCollectionContentInsets), not the
        // container-growing pre-background padding the generic chain applies.
        let _ = Logger.debug("[Collection] id=\(component.id ?? "?") width=\(String(describing: component.declaredWidth)) height=\(String(describing: component.declaredHeight)) widthRaw=\(component.widthRaw ?? "nil") heightRaw=\(component.heightRaw ?? "nil")")
        result = applyCollectionContentInsets(
            result, component: component,
            includeInsetHorizontal: !horizontalStackCarriesInsetH
        )
        result = applyContainerInset(result, component: component)
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data, skipInsets: true)

        return result
    }

    /// `itemWeight` — the fraction of the container width one item takes
    /// (canonical UIKit semantics: `itemSize.width = containerWidth * weight`,
    /// SJUICollectionView.getCollectionViewLayout). Declared `number` with no
    /// binding form, and the codegen reads `.to_f` — literal-only on purpose.
    /// 0 < w <= 1; anything else is inert, same as apply_item_weight.
    static func itemWeightCount(_ component: DynamicComponent) -> Int? {
        guard let weight = component.itemWeight.map(Double.init),
              weight > 0, weight <= 1.0 else { return nil }
        return Int((1.0 / weight).rounded())
    }

    /// The grid's column count once `itemWeight` has its say. A weight is a
    /// per-ITEM width, and in a spacing-0 grid "each item is W×w wide" IS
    /// "round(1/w) flexible columns" — so the weight wins over a conflicting
    /// `columns` declaration, the same way the UIKit layout never consults
    /// `columns` for item sizing.
    ///
    /// Round 5 measured the alternative reading (mirror the codegen emit,
    /// a containerRelativeFrame on the whole content): the codegen face
    /// renders ZERO cells with its own modifier (0 cell px vs 43k on
    /// neighbouring Collection fixtures) and the mirrored dynamic squeezed
    /// its grid into the halved content. The emit's comment declares the
    /// per-item intent; its placement is the codegen-side bug.
    static func effectiveGridColumns(_ component: DynamicComponent, declared: Int) -> Int {
        itemWeightCount(component) ?? declared
    }

    /// insets / contentInsets / insetHorizontal / insetVertical as CONTENT
    /// padding — applied to the collection content before frame/background
    /// so cells inset within the declared container, mirroring the sjui
    /// codegen (`apply_grid_padding`: `insets` wins over the declared
    /// `contentInsets` alias, matching the UIKit runtime's order; the
    /// scalar pair adds on top).
    /// `includeInsetHorizontal: false` when the layout path already carries
    /// `insetHorizontal` on the CollectionStackView's insetLeading/Trailing
    /// params (the horizontal stack), mirroring the codegen's
    /// `include_horizontal: axis == :vertical` split.
    private static func applyCollectionContentInsets(
        _ view: AnyView,
        component: DynamicComponent,
        includeInsetHorizontal: Bool = true
    ) -> AnyView {
        var top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0
        if let edges = DynamicDecodingHelper.edgeInsetsFromAnyCodable(component.insets)
            ?? DynamicDecodingHelper.edgeInsetsFromAnyCodable(component.contentInsets) {
            top += edges.top
            leading += edges.leading
            bottom += edges.bottom
            trailing += edges.trailing
        }
        if includeInsetHorizontal, let h = component.insetHorizontal {
            leading += h
            trailing += h
        }
        if let v = component.insetVertical {
            top += v
            bottom += v
        }
        guard top != 0 || leading != 0 || bottom != 0 || trailing != 0 else { return view }
        return AnyView(view.padding(EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)))
    }

    /// `containerInset` — container-level insets on the scroll content
    /// (`.contentMargins(for: .scrollContent)`), the mapping sjui codegen
    /// emits. The dynamic path never read the attribute — measured as
    /// parity d=63 on Collection/containerInset__static. The decoder
    /// expands a scalar to [v,v,v,v]; a 2-element array is [vertical,
    /// horizontal], 4 is [top, leading, bottom, trailing].
    private static func applyContainerInset(_ view: AnyView, component: DynamicComponent) -> AnyView {
        guard let inset = component.containerInset else { return view }
        let edges: EdgeInsets
        switch inset.count {
        case 2:
            edges = EdgeInsets(top: inset[0], leading: inset[1], bottom: inset[0], trailing: inset[1])
        case 4:
            edges = EdgeInsets(top: inset[0], leading: inset[1], bottom: inset[2], trailing: inset[3])
        default:
            return view
        }
        return AnyView(view.contentMargins(.all, edges, for: .scrollContent))
    }

    // MARK: - Columns Resolution

    /// Resolve the effective global column count from the typed `columns`
    /// attribute (`number | binding` per the shared catalog).
    ///
    /// - `.value(n)`   → literal count.
    /// - `.binding(e)` → resolved from `data[e]` (Int / Double /
    ///   `SwiftUI.Binding<Int>`), falling back to 1 when unresolved.
    /// - `nil`         → legacy decoded Int (or 1).
    ///
    /// The count is clamped to `>= 1`. `isBinding` lets the caller keep
    /// binding-driven Collections on the grid path even when the value
    /// resolves to 1 (same contract as static emit, where the LazyVGrid
    /// container must stay stable across runtime column-count changes).
    static func resolveGlobalColumns(
        _ columns: AttrValue<Double>?,
        legacyColumns: Int?,
        data: [String: Any]
    ) -> (count: Int, isBinding: Bool) {
        switch columns {
        case .some(.value(let number)):
            return (max(1, Int(number)), false)
        case .some(.binding(let expression)):
            let resolved: Int? = {
                guard let raw = data[expression] else { return nil }
                if let binding = raw as? SwiftUI.Binding<Int> { return binding.wrappedValue }
                if let intValue = raw as? Int { return intValue }
                if let doubleValue = raw as? Double { return Int(doubleValue) }
                return nil
            }()
            return (max(1, resolved ?? 1), true)
        case nil:
            return (max(1, legacyColumns ?? 1), false)
        }
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

    /// Vertical section-based: CollectionStackView dispatches between
    /// lazy / eager / none modes for the outer container.
    private static func buildVerticalSectionLayout(
        component: DynamicComponent,
        dataSource: CollectionDataSource,
        sections: [[String: Any]],
        cellIdProperty: String?,
        scrollTarget: CollectionScrollTarget?,
        scrollAnimated: Bool,
        scrollAnchorPoint: UnitPoint,
        data: [String: Any],
        viewId: String?,
        onItemAppear: ((Int) -> Void)? = nil,
        mode: CollectionStackMode = .lazy
    ) -> AnyView {
        let showsIndicators = component.showsVerticalScrollIndicator ?? true
        let lineSpacing = component.typedAttributes(CollectionAttributes.self).lineSpacing.map { CGFloat($0) } ?? component.itemSpacing ?? 0
        let vstackAlignment = getVStackAlignment(from: component)

        return AnyView(
            ScrollViewReader { scrollProxy in
                CollectionStackView(
                    mode: mode,
                    axis: .vertical,
                    horizontalAlignment: vstackAlignment,
                    spacing: lineSpacing,
                    showsIndicators: showsIndicators
                ) {
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
                                applyDeclaredCellFrame(
                                    AnyView(buildCellView(
                                        cellClassName: cellName,
                                        cellData: cell.data,
                                        cellIndex: cell.index,
                                        component: component,
                                        data: data,
                                        viewId: viewId,
                                        onItemAppear: onItemAppear
                                    )),
                                    component: component
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
                .ifLet(scrollTarget) { view, target in
                    // Keyed on the value: SwiftUI re-runs this when it
                    // changes, the same shape as Compose's LaunchedEffect and
                    // web's useEffect on the same property.
                    view.onChange(of: target) { _, newTarget in
                        if scrollAnimated {
                            withAnimation { newTarget.scroll(with: scrollProxy, anchor: scrollAnchorPoint) }
                        } else {
                            newTarget.scroll(with: scrollProxy, anchor: scrollAnchorPoint)
                        }
                    }
                }
            }
        )
    }

    /// Codegen's apply_cell_frame, non-grid dialect: a declared cellWidth /
    /// cellHeight pins the cell's frame anchored at .topLeading and clips
    /// the overflow — a declared size can UNDER-fit the cell's content, and
    /// the default .center frame let it spill half out of its lane
    /// (Collection_cellWidth/cellHeight__static parity d=50/41, run
    /// 31202080745; web anchors at the leading edge and hides the overflow).
    /// The grid path sizes its cells through GridItem and its own frame and
    /// does not use this.
    private static func applyDeclaredCellFrame(
        _ view: AnyView,
        component: DynamicComponent
    ) -> AnyView {
        let attrs = component.typedAttributes(CollectionAttributes.self)
        let cellWidth = attrs.cellWidth.map { CGFloat($0) }
        let cellHeight = attrs.cellHeight.map { CGFloat($0) }
        guard cellWidth != nil || cellHeight != nil else { return view }
        var result = view
        if let cellWidth {
            result = AnyView(result.frame(width: cellWidth, alignment: .topLeading))
        }
        if let cellHeight {
            result = AnyView(result.frame(height: cellHeight, alignment: .topLeading))
        }
        return AnyView(result.clipped())
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
        // `listStyle` picks the chrome; the generated code reads the same
        // attribute onto SwiftUI's concrete styles, so the hardcoded
        // PlainListStyle here was a parity drift the moment codegen stopped
        // hardcoding its own.
        let listStyle = component.enumString(CollectionAttributes.self, \.listStyle) ?? "plain"

        guard let firstSection = dataSource.sections.first,
              let cellsData = firstSection.cells,
              let sectionConfig = sections.first,
              let cellName = sectionConfig["cell"] as? String else {
            return applyListStyle(
                AnyView(
                    List {
                        Text("No data")
                    }
                ),
                style: listStyle
            )
        }

        let hasHeader = sectionConfig["header"] != nil && firstSection.header != nil
        let hasFooter = sectionConfig["footer"] != nil && firstSection.footer != nil
        let hideSeparator = component.typedAttributes(CollectionAttributes.self).hideSeparator ?? false

        let items = identifiedItems(from: cellsData.data, cellIdProperty: cellIdProperty)

        // The Group is how the generated code forwards `.listRowSeparator` to
        // every row — the modifier styles ROWS, not the List, so applying it
        // to the List itself (the old ListSeparatorModifier) never hid
        // anything.
        return applyListStyle(AnyView(
            List {
                Group {
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
                .listRowSeparator(hideSeparator ? .hidden : .automatic)
            }
        ), style: listStyle)
    }

    /// Declared `listStyle` -> SwiftUI list chrome, the same mapping the
    /// generated code and TableConverter use; an unrecognised value falls
    /// back to plain, which is also the declared default.
    private static func applyListStyle(_ view: AnyView, style: String) -> AnyView {
        switch style {
        case "grouped":
            return AnyView(view.listStyle(.grouped))
        case "insetGrouped":
            return AnyView(view.listStyle(.insetGrouped))
        case "sidebar":
            return AnyView(view.listStyle(.sidebar))
        default:
            return AnyView(view.listStyle(.plain))
        }
    }

    /// Horizontal: CollectionStackView(axis: .horizontal) wraps the cell ForEach.
    private static func buildHorizontalLayout(
        component: DynamicComponent,
        dataSource: CollectionDataSource,
        sections: [[String: Any]],
        cellIdProperty: String?,
        scrollTarget: CollectionScrollTarget?,
        scrollAnimated: Bool,
        scrollAnchorPoint: UnitPoint,
        data: [String: Any],
        viewId: String?,
        onItemAppear: ((Int) -> Void)? = nil,
        mode: CollectionStackMode = .lazy
    ) -> AnyView {
        let showsIndicators = component.showsHorizontalScrollIndicator ?? true
        let columnSpacing = component.columnSpacing ?? component.itemSpacing ?? component.typedAttributes(CollectionAttributes.self).lineSpacing.map { CGFloat($0) } ?? 0
        let insetHorizontal = component.insetHorizontal ?? 0
        let hstackAlignment = getHStackAlignment(from: component)

        return AnyView(
            ScrollViewReader { scrollProxy in
                CollectionStackView(
                    mode: mode,
                    axis: .horizontal,
                    verticalAlignment: hstackAlignment,
                    spacing: columnSpacing,
                    showsIndicators: showsIndicators,
                    insetLeading: CGFloat(insetHorizontal),
                    insetTrailing: CGFloat(insetHorizontal)
                ) {
                    ForEach(
                        0..<min(sections.count, dataSource.sections.count),
                        id: \.self
                    ) { sectionIndex in
                        let sectionConfig = sections[sectionIndex]
                        let sectionData = dataSource.sections[sectionIndex]

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
                            ForEach(items) { cell in
                                applyDeclaredCellFrame(
                                    AnyView(buildCellView(
                                        cellClassName: cellName,
                                        cellData: cell.data,
                                        cellIndex: cell.index,
                                        component: component,
                                        data: data,
                                        viewId: viewId,
                                        onItemAppear: onItemAppear
                                    )),
                                    component: component
                                )
                                .id(cell.id)
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
                }
                .ifLet(scrollTarget) { view, target in
                    // Keyed on the value: SwiftUI re-runs this when it
                    // changes, the same shape as Compose's LaunchedEffect and
                    // web's useEffect on the same property.
                    view.onChange(of: target) { _, newTarget in
                        if scrollAnimated {
                            withAnimation { newTarget.scroll(with: scrollProxy, anchor: scrollAnchorPoint) }
                        } else {
                            newTarget.scroll(with: scrollProxy, anchor: scrollAnchorPoint)
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
        let itemSpacing = component.columnSpacing ?? component.itemSpacing ?? 0

        // Resolve currentPage binding
        let currentPageRaw = component.typedAttributes(CollectionAttributes.self)
            .currentPage?.bindingString
        let currentPageBinding: SwiftUI.Binding<Int>? = {
            if let raw = currentPageRaw,
               let propName = DynamicEventHelper.extractPropertyName(from: raw) {
                if let binding = data[propName] as? SwiftUI.Binding<Int> {
                    return binding
                }
            }
            return nil
        }()

        // Resolve page-change callback. onValueChange is the canonical
        // name; onValueChanged / onPageChanged are the definitions
        // aliases (consulted only for raw L0 layouts).
        var onPageChangedCallback: ((Int) -> Void)? = nil
        // onValueChanged / onPageChanged aliases are resolved inside the
        // generated extraction (raw L0 layouts only)
        let pageChangedRaw = component.typedAttributes(CollectionAttributes.self)
            .onValueChange?.rawRepresentation as? String
        if let pageChangedRaw = pageChangedRaw,
           let propName = DynamicEventHelper.extractPropertyName(from: pageChangedRaw) {
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
        scrollTarget: CollectionScrollTarget?,
        scrollAnimated: Bool,
        scrollAnchorPoint: UnitPoint,
        data: [String: Any],
        viewId: String?,
        onItemAppear: ((Int) -> Void)? = nil
    ) -> AnyView {
        let showsIndicators = component.showsVerticalScrollIndicator ?? true
        // Declaration-faithful: undeclared spacing is 0, matching Compose
        // (no Arrangement.spacedBy) and the static codegens. The old `?? 10`
        // was an iOS-only implicit default. Chain order mirrors kjui:
        // inter-column prefers columnSpacing, inter-row prefers lineSpacing.
        let itemSpacing = component.columnSpacing ?? component.itemSpacing ?? 0
        let lineSpacing = component.typedAttributes(CollectionAttributes.self).lineSpacing.map { CGFloat($0) } ?? component.itemSpacing ?? 0
        // `cellWidth` / `cellHeight` pin each cell to a fixed size inside the grid.
        // When absent the existing flexible sizing path is preserved.
        let cellAttrs = component.typedAttributes(CollectionAttributes.self)
        let cellWidth = cellAttrs.cellWidth.map { CGFloat($0) }
        let cellHeight = cellAttrs.cellHeight.map { CGFloat($0) }

        return AnyView(
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: showsIndicators) {
                    ForEach(
                        0..<min(sections.count, dataSource.sections.count),
                        id: \.self
                    ) { sectionIndex in
                        let sectionConfig = sections[sectionIndex]
                        let sectionData = dataSource.sections[sectionIndex]
                        let sectionColumns = effectiveGridColumns(
                            component,
                            declared: sectionConfig["columns"] as? Int ?? globalColumns
                        )

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
                .ifLet(scrollTarget) { view, target in
                    // Keyed on the value: SwiftUI re-runs this when it
                    // changes, the same shape as Compose's LaunchedEffect and
                    // web's useEffect on the same property.
                    view.onChange(of: target) { _, newTarget in
                        if scrollAnimated {
                            withAnimation { newTarget.scroll(with: scrollProxy, anchor: scrollAnchorPoint) }
                        } else {
                            newTarget.scroll(with: scrollProxy, anchor: scrollAnchorPoint)
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
        scrollTarget: CollectionScrollTarget?,
        scrollAnimated: Bool,
        scrollAnchorPoint: UnitPoint,
        data: [String: Any],
        viewId: String?,
        onItemAppear: ((Int) -> Void)? = nil
    ) -> AnyView {
        let showsIndicators = component.showsVerticalScrollIndicator ?? true
        let hSpacing = component.columnSpacing ?? component.itemSpacing ?? 8
        let vSpacing = component.typedAttributes(CollectionAttributes.self).lineSpacing.map { CGFloat($0) } ?? component.itemSpacing ?? 8

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
        let itemSpacing = component.itemSpacing ?? 0
        let lineSpacing = component.typedAttributes(CollectionAttributes.self).lineSpacing.map { CGFloat($0) } ?? component.itemSpacing ?? 0
        let columnSpacing = component.columnSpacing ?? component.itemSpacing ?? 0
        let cellAttrs = component.typedAttributes(CollectionAttributes.self)
        let cellWidth = cellAttrs.cellWidth.map { CGFloat($0) }
        let cellHeight = cellAttrs.cellHeight.map { CGFloat($0) }

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
                            let sectionColumns = effectiveGridColumns(
                                component,
                                declared: sectionConfig["columns"] as? Int ?? globalColumns
                            )
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
    /// e.g. "item_card" -> "item_card"
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

#endif // DEBUG
