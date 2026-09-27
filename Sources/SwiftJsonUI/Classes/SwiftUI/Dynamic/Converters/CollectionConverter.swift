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
        // Ruling (2026-09-03): a flow Collection with `lazy` in effect
        // scrolls inside its own bounds — and a wrapping one has none. The
        // flow arm wrapped its FlowLayout in a ScrollView unconditionally,
        // so under a scrolling ancestor a wrapContent flow became an inner
        // ScrollView grown to the outer viewport (the corpus's
        // flowOverflow__wrap picture on iOS) while Android wraps and lets the
        // parent scroll. Whether there IS a scrolling ancestor is a fact of
        // the render context (a cell layout is another file), so both shapes
        // are built and the environment picks: under a scrolling ancestor
        // the non-scroll container, otherwise the ScrollView it always had —
        // a full-screen chip destination relies on that one.
        if flowDefersToScrollingAncestor(component, data: data, insideScrollingAncestor: true) {
            // `CollectionStackMode.none`, spelled out: against an Optional
            // parameter a bare `.none` is `Optional.none` — nil — and both
            // shapes silently become the ScrollView one (the compiler only
            // warns; measured as byte-identical pictures with the switch
            // logging `inside=1`).
            return AnyView(ScrollingAncestorSwitch(
                underScrollingAncestor: render(component: component, data: data, viewId: viewId, forcedMode: CollectionStackMode.none),
                otherwise: render(component: component, data: data, viewId: viewId, forcedMode: nil)
            ))
        }
        return render(component: component, data: data, viewId: viewId, forcedMode: nil)
    }

    /// `forcedMode` overrides the declared `lazy` for the container choice
    /// only — the deferred flow above renders as `.none` without the
    /// declaration saying so, which is why that shape also has to be made
    /// an accessibility container by hand below.
    private static func render(
        component: DynamicComponent,
        data: [String: Any],
        viewId: String?,
        forcedMode: CollectionStackMode?
    ) -> AnyView {
        let sections = component.sections ?? []
        let attrs = component.typedAttributes(CollectionAttributes.self)
        let isHorizontal = Self.isHorizontal(component)
        let isFlow = Self.isFlowLayout(component)
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
            } else if !hasSections, let list = data[propertyName] as? [Any], let cell = singleDeclaredCell(attrs) {
                // Collection.items is a CollectionDataSource or an array
                // (attribute_definitions.json; 4f ruling, 2026-09-26): with
                // no `sections`, an array is ONE section of the declared
                // cell, drawn on the routes a one-section data source takes.
                // The codegens decide by the layout's data declaration; this
                // renderer by the value's shape. An array was not a
                // CollectionDataSource, so it drew no cell (measured on
                // b314fd2: 0 of 3 on every route).
                dataSource = Self.oneSection(
                    of: list, cell: cell,
                    cellIdProperty: cellIdProperty, autoChangeTrackingId: autoChangeTrackingId
                )
            }
        }
        if !hasSections, let declared = attrs.cellClasses, declared.count > 1 {
            logSeveralCellClasses(componentId: component.id, count: declared.count)
        }

        // The legacy shape: no `sections`, and the cells / header / footer
        // named on the Collection itself. SSoT `/Collection/cellClasses`:
        // "With `items` and no `sections`, a single cellClass renders every
        // item" — what sjui's SwiftUI codegen emits for it. This renderer
        // decoded the three attributes and never read them, and the guard
        // below returned before any route when `sections` was absent, so a
        // Collection declared this way drew no cells at all (measured:
        // CollectionDeclaredCellsTests, 0 of 3 items on every route).
        // `sections` decide when both are declared, as on the codegen.
        let legacyCell = hasSections ? nil : singleDeclaredCell(attrs)
        let legacyHeader = hasSections ? nil : attrs.headerClasses?.first.flatMap(declaredClassName)
        let legacyFooter = hasSections ? nil : attrs.footerClasses?.first.flatMap(declaredClassName)
        let isLegacyShape = !hasSections && (legacyCell != nil || legacyHeader != nil || legacyFooter != nil)
        let drawsSomething = hasSections || isLegacyShape
        // No data source (no `items`, or nothing bound yet): the legacy shape
        // still draws its container — the codegen's legacy List / grid /
        // stack is emitted whatever `items` says, and its headerClasses /
        // footerClasses with it (the header of an items-less Collection is
        // on screen in the release build). An empty source reaches the same
        // routes with no cells. A sectioned Collection keeps the empty view
        // below, as before.
        let resolvedSource = dataSource ?? (isLegacyShape ? CollectionDataSource() : nil)

        guard let dataSource = resolvedSource, drawsSomething else {
            // Declaration-faithful (2026-08-02 ruling): no declared data
            // source → no items rendered, but the container still carries
            // its declared frame/background — route the empty view through
            // the same standard-modifier chain as every populated path.
            // The old early return skipped it, so the whole container
            // vanished (and the still-older "No collection data" debug text
            // was undeclared behavior).
            //
            // A declared listStyle still draws its chrome: the chrome belongs
            // to the CONTAINER (web's list_style_classes, android's
            // container-level chrome), so the section-less shape renders a
            // chromed EMPTY List — no invented rows — instead of nothing
            // (Collection/listStyle__* were inert on this face while the
            // codegen face drew the chrome, run 31243724782).
            if let declaredStyle = component.enumString(CollectionAttributes.self, \.listStyle) {
                return DynamicModifierHelper.applyStandardModifiers(
                    applyScrollContainerSafeArea(
                        applyListStyle(AnyView(List {}), style: declaredStyle),
                        component: component
                    ),
                    component: component, data: data
                )
            }
            return DynamicModifierHelper.applyStandardModifiers(
                applyScrollContainerSafeArea(AnyView(Color.clear), component: component),
                component: component, data: data
            )
        }

        // The section configs the cell routes read. With `sections` they are
        // the declared ones. Without, the declared cell stands in for a
        // `sections[].cell` on every section of the data source — the
        // codegen's List and grid routes draw every section with it
        // (`generate_fallback_foreach`); its horizontal and flow routes read
        // `sections.first?.cells` only, hence `firstSectionOnly` — which the
        // paging route takes too (4f ruling, 2026-09-26, round 6: a page per
        // cell, the class-list shape one section; it read declared
        // `sections` only and drew no page, on every face).
        let cellSections: [[String: Any]] = {
            if hasSections { return sections }
            guard let legacyCell else { return [] }
            return Array(repeating: ["cell": legacyCell], count: dataSource.sections.count)
        }()
        let firstSectionOnly: [[String: Any]] = hasSections ? sections : Array(cellSections.prefix(1))

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
            // The value says what it names (the SSoT's Collection.scrollTo): a
            // String is a key — a cell's cellId, else its cellIdProperty value
            // (scrollID(for:…)) — an Int a cell counted across the sections,
            // whatever cellIdProperty says; anything else scrolls nowhere.
            // Until jsonui-cli 1.9.0 cellIdProperty decided: with none a
            // String was dropped, so a cellId was never matched.
            let unwrapped = DynamicBindingResolver.unwrap(value)
            if let key = unwrapped as? String { return .cellId(key) }
            if let index = unwrapped as? Int { return .index(index) }
            return nil
        }()
        let scrollAnimated = component.typedAttributes(CollectionAttributes.self).scrollAnimated ?? true

        let scrollAnchorPoint = Self.scrollAnchorPoint(component.scrollAnchor, horizontal: isHorizontal)

        // `lazy` may be a boolean (legacy) or one of "lazy" / "eager" / "none".
        // For binding values we resolve at runtime via DynamicBindingHelper so a
        // toggle propagates through the same CollectionStackView wrapper without
        // changing modifier-chain shape. Paging always wins (HorizontalPager is
        // inherently lazy).
        let collectionMode = forcedMode ?? stackMode(component, data: data)

        // 1. Build collection content based on layout type
        var result: AnyView
        // The horizontal CollectionStackView carries `insetHorizontal` on its
        // insetLeading/insetTrailing params (buildHorizontalLayout), so the
        // content-padding channel must exclude it there — the codegen makes
        // the same split (collection_content_insets_swift_expr
        // include_horizontal: axis == :vertical). Both channels applying it
        // is what doubled the leading gap on horizontal collections.
        var horizontalStackCarriesInsetH = false
        // True on the grid route: buildGridLayout applies the collection
        // insets to the scroll CONTENT itself.
        var gridCarriesContentInsets = false
        // The List routes (buildSectionedListLayout, buildListLayout).
        var isListRoute = false

        if collectionMode == .none && !(isHorizontal && component.paging == true) {
            result = buildNonLazyLayout(
                component: component,
                dataSource: dataSource,
                sections: (isHorizontal || isFlow) ? firstSectionOnly : cellSections,
                cellIdProperty: cellIdProperty,
                isHorizontal: isHorizontal,
                isFlow: isFlow,
                globalColumns: globalColumns,
                data: data,
                viewId: viewId,
                onItemAppear: onItemAppearCallback,
                legacyHeader: legacyHeader,
                legacyFooter: legacyFooter,
                oneGridForAllSections: !hasSections,
                columnsIsBinding: columnsIsBinding
            )
            if forcedMode == CollectionStackMode.none {
                // The deferred flow: a non-scroll container that the declared
                // `lazy` does not announce, so the standard chain's
                // isAccessibilityContainer says no and would apply a bare
                // identifier — pushed down onto the cells, renaming them
                // (the defect f419093 closed for the declared shape). Make it
                // an element first; the chain's identifier then lands on it.
                result = DynamicModifierHelper.makeAccessibilityContainer(result, component: component)
            }
            // Collection insets are CONTENT padding: applied to the content
            // before frame/background so cells inset within the declared
            // container, exactly what the sjui codegen emits. The generic
            // applyInsets pads before background in the standard chain and
            // GROWS the container instead (measured: d=134 on
            // Collection/contentInsets__static) — hence skipInsets.
            result = applyCollectionContentInsets(result, component: component)
            result = applyContainerInset(result, component: component)
            result = applyScrollContainerSafeArea(result, component: component)
            result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data, skipInsets: true)
            return result
        }

        if isFlow {
            result = buildFlowLayout(
                component: component,
                dataSource: dataSource,
                sections: firstSectionOnly,
                cellIdProperty: cellIdProperty,
                scrollTarget: scrollTarget,
                scrollAnimated: scrollAnimated,
                scrollAnchorPoint: scrollAnchorPoint,
                data: data,
                viewId: viewId,
                onItemAppear: onItemAppearCallback
            )
        } else if globalColumns == 1 && !isHorizontal && !columnsIsBinding && hasSections &&
                  component.enumString(CollectionAttributes.self, \.listStyle) != nil {
            // Sectioned vertical WITH list chrome: `listStyle` is what opts a
            // collection into list-ness (the same gate the codegen face and
            // web use). The CollectionStackView route below has no List, so
            // a declared chrome drew nothing here while codegen drew a real
            // List (Collection_hideSeparator/listStyle families, d≈94, runs
            // 31202080745 → 31234163967 unchanged).
            isListRoute = true
            result = buildSectionedListLayout(
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
            // Legacy single column (no `sections` — every sectioned shape
            // took a branch above): List
            isListRoute = true
            result = buildListLayout(
                component: component,
                dataSource: dataSource,
                cellName: legacyCell,
                headerName: legacyHeader,
                footerName: legacyFooter,
                cellIdProperty: cellIdProperty,
                sections: cellSections,
                scrollTarget: scrollTarget,
                scrollAnimated: scrollAnimated,
                scrollAnchorPoint: scrollAnchorPoint,
                data: data,
                viewId: viewId,
                onItemAppear: onItemAppearCallback
            )
        } else if isHorizontal && component.paging == true {
            // Paging horizontal: TabView with page style
            result = buildPagingHorizontalLayout(
                component: component,
                dataSource: dataSource,
                sections: firstSectionOnly,
                cellIdProperty: cellIdProperty,
                scrollTarget: scrollTarget,
                scrollAnimated: scrollAnimated,
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
                sections: firstSectionOnly,
                cellIdProperty: cellIdProperty,
                scrollTarget: scrollTarget,
                scrollAnimated: scrollAnimated,
                scrollAnchorPoint: scrollAnchorPoint,
                data: data,
                viewId: viewId,
                onItemAppear: onItemAppearCallback,
                mode: collectionMode,
                globalColumns: globalColumns,
                columnsIsBinding: columnsIsBinding
            )
        } else {
            // Multiple columns: ScrollView + LazyVGrid. The grid pads its
            // CONTENT with the collection insets (inside the full-bleed
            // scroll, like the codegen face) — the shared tail below must
            // not pad the ScrollView a second time.
            gridCarriesContentInsets = true
            result = buildGridLayout(
                component: component,
                dataSource: dataSource,
                sections: cellSections,
                cellIdProperty: cellIdProperty,
                globalColumns: globalColumns,
                scrollTarget: scrollTarget,
                scrollAnimated: scrollAnimated,
                scrollAnchorPoint: scrollAnchorPoint,
                data: data,
                viewId: viewId,
                onItemAppear: onItemAppearCallback,
                legacyHeader: legacyHeader,
                legacyFooter: legacyFooter,
                oneGridForAllSections: !hasSections
            )
        }

        // A wrapContent (or undeclared) Collection sizes to its content along
        // its scroll axis, up to its parent's bound (CollectionContentFit
        // around the route's scroll container) — 4f ruling 2026-09-27, the
        // user's "size to content". Not the pager, whose TabView is its
        // pages, and not a List: a List reports no content height to size
        // to (measured: CollectionContentFit drew it 0pt tall), so a
        // wrapContent List still fills its parent.
        if !(isHorizontal && component.paging == true), !isListRoute,
           Self.fitsContent(component, horizontal: isHorizontal, data: data) {
            let container = result
            result = AnyView(CollectionContentFit(axis: isHorizontal ? .horizontal : .vertical) { container })
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
                result = AnyView(result.defaultScrollAnchor(Self.defaultScrollAnchorPoint(anchorStr, horizontal: isHorizontal)))
            }
        }

        // 3. applyStandardModifiers() — insets excluded: Collection insets
        // are content padding (see applyCollectionContentInsets), not the
        // container-growing pre-background padding the generic chain applies.
        let _ = Logger.debug("[Collection] id=\(component.id ?? "?") width=\(String(describing: component.declaredWidth)) height=\(String(describing: component.declaredHeight)) widthRaw=\(component.widthRaw ?? "nil") heightRaw=\(component.heightRaw ?? "nil")")
        if !gridCarriesContentInsets {
            result = applyCollectionContentInsets(
                result, component: component,
                includeInsetHorizontal: !horizontalStackCarriesInsetH
            )
        }
        result = applyContainerInset(result, component: component)
        result = applyScrollContainerSafeArea(result, component: component)
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
        guard let edges = collectionContentEdgeInsets(
            component: component, includeInsetHorizontal: includeInsetHorizontal
        ) else { return view }
        return AnyView(view.padding(edges))
    }

    /// The combined insets/contentInsets/insetHorizontal/insetVertical
    /// value, or nil when everything is zero. Split out so scroll-bearing
    /// layouts can pad their CONTENT with it: padding the ScrollView itself
    /// shrinks the viewport — a visible band on every inset edge and no
    /// native under-safe-area scroll — while the codegen face pads the
    /// LazyVGrid inside the full-bleed scroll (a downstream home screen, the
    /// dynamic-only bottom band, 2026-08-10).
    private static func collectionContentEdgeInsets(
        component: DynamicComponent,
        includeInsetHorizontal: Bool = true
    ) -> EdgeInsets? {
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
        guard top != 0 || leading != 0 || bottom != 0 || trailing != 0 else { return nil }
        return EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
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

    /// `contentInsetAdjustmentBehavior` and `keyboardAvoidance` on the
    /// Collection's container — sjui's codegen emits them in the same
    /// component-specific stage as `containerInset`, right after it
    /// (collection_converter.rb apply_scroll_container_attrs): `never` →
    /// `.ignoresSafeArea()`, `scrollableAxes` → `.ignoresSafeArea(edges:
    /// .horizontal)`, the other values are the system behaviour and emit
    /// nothing; `keyboardAvoidance: false` → `.ignoresSafeArea(.keyboard)`,
    /// true (the default) is the system behaviour. Only this renderer's
    /// ScrollView read the first, and nothing here read the second.
    static func applyScrollContainerSafeArea(_ view: AnyView, component: DynamicComponent) -> AnyView {
        let attrs = component.typedAttributes(CollectionAttributes.self)
        var result = view
        switch attrs.contentInsetAdjustmentBehavior {
        case "never":
            result = AnyView(result.ignoresSafeArea())
        case "scrollableAxes":
            result = AnyView(result.ignoresSafeArea(edges: .horizontal))
        default:
            break
        }
        if attrs.keyboardAvoidance == false {
            result = AnyView(result.ignoresSafeArea(.keyboard))
        }
        return result
    }

    // MARK: - Declared cell / header / footer classes (the legacy shape)

    /// The layout a `cellClasses` / `headerClasses` / `footerClasses` entry
    /// names: a string, or `{"className": …}` (the codegen's
    /// `extract_view_name` accepts both). This renderer loads it by name,
    /// as it loads a `sections[].cell`.
    static func declaredClassName(_ entry: Any?) -> String? {
        let name: String?
        if let string = entry as? String {
            name = string
        } else if let dict = entry as? [String: Any] {
            name = dict["className"] as? String
        } else {
            name = nil
        }
        guard let name, !name.isEmpty else { return nil }
        return name
    }

    /// The one declared cell that draws every item, or nil. Several
    /// cellClasses with no `sections` say nothing about which item takes
    /// which; the build refuses that layout (LayoutValidator
    /// check_collection, level error), so there is no release drawing to
    /// follow and no cell is guessed here.
    static func singleDeclaredCell(_ attrs: CollectionAttributes) -> String? {
        guard let declared = attrs.cellClasses, declared.count == 1 else { return nil }
        return declaredClassName(declared[0])
    }

    /// An array bound to a class-list Collection's `items`, as one section
    /// of `cell`. An element is a cell's data: a dictionary as it is, any
    /// other value by its stored properties (a generated Data struct — what
    /// the codegen turns into a dictionary with `toDictionary()`); a value
    /// with no properties draws no cell.
    static func oneSection(
        of list: [Any], cell: String, cellIdProperty: String?, autoChangeTrackingId: Bool
    ) -> CollectionDataSource {
        var section = CollectionDataSection(cellIdProperty: cellIdProperty, autoChangeTrackingId: autoChangeTrackingId)
        section.setCells(viewName: cell, data: list.compactMap(cellDictionary))
        return CollectionDataSource(sections: [section])
    }

    static func cellDictionary(_ element: Any) -> [String: Any]? {
        if let dictionary = element as? [String: Any] { return dictionary }
        let mirror = Mirror(reflecting: element)
        guard mirror.displayStyle == .struct || mirror.displayStyle == .class else { return nil }
        var dictionary: [String: Any] = [:]
        for child in mirror.children {
            if let label = child.label { dictionary[label] = child.value }
        }
        return dictionary.isEmpty ? nil : dictionary
    }

    /// A section's own `columns` as declared (attribute_definitions.json,
    /// Collection.sections.items.properties.columns: number), or nil.
    static func declaredSectionColumns(_ sectionConfig: [String: Any]) -> Int? {
        switch sectionConfig["columns"] {
        case let n as Int: return n
        case let d as Double: return Int(d)
        case let n as NSNumber: return n.intValue
        default: return nil
        }
    }

    /// The columns a section's own grid has, when the section declares
    /// `columns` > 1 — on the routes where a 1-column Collection draws its
    /// sections one cell per row (the section stack, the sectioned List,
    /// the `lazy: none` stack). The declaration is honoured (4f ruling,
    /// 2026-09-26): those routes ignored it, so the section was one cell
    /// per row on iOS and a grid on Android. The other sections stay as
    /// they are. `itemWeight` has its say, as on the grid route.
    static func sectionOwnGridColumns(_ sectionConfig: [String: Any], component: DynamicComponent) -> Int? {
        guard let declared = declaredSectionColumns(sectionConfig), declared > 1 else { return nil }
        return effectiveGridColumns(component, declared: declared)
    }

    /// A section's cells as a grid of `columns`: columnSpacing between the
    /// cells of a row and lineSpacing between rows, each falling back to
    /// itemSpacing — the SSoT's roles ("Spacing between columns" / "Spacing
    /// between rows" / "used for both grid spacing and list item spacing")
    /// and the lazy grid route's reading (buildGridLayout). Cell sizing as
    /// there.
    private static func sectionGrid(
        columns: Int,
        items: [CollectionCellItem],
        cellName: String,
        component: DynamicComponent,
        data: [String: Any],
        viewId: String?,
        onItemAppear: ((Int) -> Void)?
    ) -> AnyView {
        let attrs = component.typedAttributes(CollectionAttributes.self)
        let columnSpacing = component.columnSpacing ?? component.itemSpacing ?? 0
        let lineSpacing = attrs.lineSpacing.map { CGFloat($0) } ?? component.itemSpacing ?? 0
        let cellWidth = attrs.cellWidth.map { CGFloat($0) }
        let cellHeight = attrs.cellHeight.map { CGFloat($0) }
        let gridItemSize: GridItem.Size = cellWidth.map { .fixed($0) } ?? .flexible()
        let gridColumns = Array(repeating: GridItem(gridItemSize, spacing: columnSpacing), count: columns)
        return AnyView(
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
        )
    }

    /// The lanes of a horizontal Collection's section (4f ruling,
    /// 2026-09-26): `columns` on a horizontal Collection is its number of
    /// lanes — the SSoT names LazyHorizontalGrid / LazyHGrid for it — and a
    /// section's own `columns` is that section block's lanes. nil for one
    /// lane, which keeps the single-lane stack. A bound `columns` keeps the
    /// grid even at 1 (SSoT Collection.columns: "always renders on the
    /// multi-column grid path"), unless the section declares its own.
    static func horizontalLanes(_ sectionConfig: [String: Any], globalColumns: Int, columnsIsBinding: Bool) -> Int? {
        let own = declaredSectionColumns(sectionConfig)
        let lanes = own ?? globalColumns
        if lanes > 1 { return lanes }
        return (columnsIsBinding && own == nil) ? 1 : nil
    }

    /// Spacing on a horizontal Collection — every one, a single lane
    /// included, its stack, its lanes and its pages (4f ruling, 2026-09-26).
    /// The SSoT describes lineSpacing as
    /// "Spacing between rows" and columnSpacing as "Spacing between columns"
    /// in a vertical grid's words; they were declared from UIKit's flow
    /// layout (SJUICollectionView: lineSpacing -> minimumLineSpacing,
    /// columnSpacing -> minimumInteritemSpacing), where a horizontally
    /// scrolling grid's lines are its columns. So, on a horizontal grid:
    /// lineSpacing (else itemSpacing) between successive columns of cells,
    /// along the scroll axis; columnSpacing (else itemSpacing) between the
    /// lanes. Android's horizontal grids space the scroll axis by lineSpacing
    /// first too.
    static func horizontalGridSpacing(_ component: DynamicComponent) -> (betweenLanes: CGFloat, alongScroll: CGFloat) {
        let attrs = component.typedAttributes(CollectionAttributes.self)
        let alongScroll = attrs.lineSpacing.map { CGFloat($0) } ?? component.itemSpacing ?? 0
        let betweenLanes = component.columnSpacing ?? component.itemSpacing ?? 0
        return (betweenLanes, alongScroll)
    }

    /// A flow Collection's three gaps (jsonui-cli attribute_semantics.json ->
    /// collectionSpacing, 4f ruling 2026-09-26): between the cells of a line
    /// columnSpacing, else itemSpacing; between lines lineSpacing (its alias
    /// sectionSpacing folds here), else itemSpacing; between the section
    /// blocks as between lines. Undeclared, each is 0; a declared value is
    /// drawn as declared, 0 included. Until jsonui-cli 1.9.0 the lazy flow
    /// drew 8 for an undeclared gap and left the blocks to the ScrollView's
    /// own stack spacing, and the `lazy: none` flow drew 8 for anything not
    /// above 0 — a declared 0 included.
    static func flowSpacing(_ component: DynamicComponent) -> (cells: CGFloat, lines: CGFloat, sections: CGFloat) {
        let lines = component.typedAttributes(CollectionAttributes.self).lineSpacing.map { CGFloat($0) } ?? component.itemSpacing ?? 0
        let cells = component.columnSpacing ?? component.itemSpacing ?? 0
        return (cells, lines, lines)
    }

    /// A section's cells as a horizontal grid of `lanes` rows (LazyHGrid):
    /// cells fill a column top to bottom, then the next column — the order
    /// of Android's LazyHorizontalGrid. Each section is a block of its own,
    /// starting a new column.
    private static func sectionHGrid(
        lanes: Int,
        items: [CollectionCellItem],
        cellName: String,
        component: DynamicComponent,
        data: [String: Any],
        viewId: String?,
        onItemAppear: ((Int) -> Void)?
    ) -> AnyView {
        let spacing = horizontalGridSpacing(component)
        let rows = Array(repeating: GridItem(.flexible(), spacing: spacing.betweenLanes), count: lanes)
        return AnyView(
            LazyHGrid(rows: rows, alignment: getHStackAlignment(from: component), spacing: spacing.alongScroll) {
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
        )
    }

    /// The codegen's apply_header_footer_padding: a legacy header / footer
    /// sits outside the grid and follows the declared insets' horizontal
    /// edges only, so it lines up with the grid body.
    private static func legacyHeaderFooterEdges(component: DynamicComponent) -> EdgeInsets {
        guard let edges = DynamicDecodingHelper.edgeInsetsFromAnyCodable(component.insets)
            ?? DynamicDecodingHelper.edgeInsetsFromAnyCodable(component.contentInsets) else {
            return EdgeInsets()
        }
        return EdgeInsets(top: 0, leading: edges.leading, bottom: 0, trailing: edges.trailing)
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

    /// A cell's key: its `"cellId"` — autoChangeTrackingId's enriched one
    /// when the dataSource was `reconfigured(autoChangeTrackingId: true)` —
    /// else its cellIdProperty value; nil for a cell with neither.
    static func cellKey(_ data: [String: Any], cellIdProperty: String?) -> String? {
        (data["cellId"] as? String) ?? cellIdProperty.flatMap { data[$0] as? String }
    }

    /// A section's cells, each with its id — the cell loop's identity and its
    /// scroll target at once (4f ruling 2026-09-27, round 14): its key,
    /// qualified by its section (CollectionCellItem.Key), when no earlier cell
    /// of the section has that key; else its place, IndexPath(item:section:).
    /// A cell with no key is its place, which no String equals; a later cell
    /// with a key already taken is its place too, so no two cells share an id
    /// and the first with a key is the one a scrollTo reaches
    /// (scrollID(for:…)) — by construction, not by SwiftUI's choice. The key
    /// keeps a cell's identity where its place moves.
    ///
    /// Until jsonui-cli 1.9.0 the id was a String — the key, else
    /// "\(index)" — with "<section>:" before the `.id` after section 0: a
    /// cell with no key at 3 and a cell keyed "3" in one section were one id,
    /// as two cells of one section with one key were, and which of them a
    /// scroll reached was SwiftUI's choice.
    static func identifiedItems(
        from cellsData: [[String: Any]],
        cellIdProperty: String?,
        section: Int
    ) -> [CollectionCellItem] {
        var seen = Set<String>()
        return cellsData.enumerated().map { index, data in
            if let key = cellKey(data, cellIdProperty: cellIdProperty), seen.insert(key).inserted {
                return CollectionCellItem(id: AnyHashable(CollectionCellItem.Key(section: section, key: key)), index: index, data: data)
            }
            return CollectionCellItem(id: AnyHashable(IndexPath(item: index, section: section)), index: index, data: data)
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

    /// What this renderer has named, in order (read by the tests).
    static var named: [String] = []
    static var loggedSeveralCellClassesIds = Set<String>()

    /// Several cellClasses and no `sections`: the build refuses that layout
    /// (LayoutValidator check_collection, level error, "N cellClasses declared
    /// without sections"), and this renderer draws no cell for it — said once
    /// per Collection, since a Dynamic layout does not pass the build. It drew
    /// nothing and said nothing.
    private static func logSeveralCellClasses(componentId: String?, count: Int) {
        let key = componentId ?? "(unnamed)"
        misconfigLogLock.lock()
        let firstTime = loggedSeveralCellClassesIds.insert(key).inserted
        misconfigLogLock.unlock()
        guard firstTime else { return }
        let sentence = "[CollectionConverter] Collection (id=\(key)): \(count) cellClasses declared without sections — no cell is drawn. Fix: assign cells via sections[].cell, or declare a single cellClass."
        named.append(sentence)
        Logger.log(sentence)
    }

    // MARK: - Scroll Target

    /// Whether a scrolling Collection sizes to its content along its scroll
    /// axis: its size there wrapContent or undeclared, and not the main axis
    /// of a weighted stack (which fills it). The SSoT's wrapContent is "size
    /// to content, up to the parent's bound, then scroll", as web and Compose
    /// draw it; a ScrollView takes every point offered, so until jsonui-cli
    /// 1.9.0 a wrapContent Collection filled its parent (120 of a 120pt
    /// parent) and pushed the views after it to the parent's end.
    static func fitsContent(_ component: DynamicComponent, horizontal: Bool, data: [String: Any]) -> Bool {
        let raw = horizontal ? component.widthRaw : component.heightRaw
        let declared = horizontal ? component.declaredWidth : component.declaredHeight
        let wraps = raw.map { ["wrapcontent", "wrap_content"].contains($0.lowercased()) } ?? (declared == nil)
        guard wraps else { return false }
        if data["__isWeightedChild"] as? Bool == true,
           (data["__weightedParentOrientation"] as? String) == (horizontal ? "horizontal" : "vertical") {
            return false
        }
        return true
    }

    /// Where a scrollTo's target lands along the scroll axis (the SSoT's
    /// Collection.scrollAnchor): top — its leading edge at the viewport's;
    /// center — its middle at the middle; bottom, the default — its trailing
    /// edge at the trailing edge. On a horizontal Collection those are
    /// `.leading` / `.center` / `.trailing` (4f ruling 2026-09-27). Until
    /// jsonui-cli 1.9.0 they were `.top` / `.bottom` there too, whose x is
    /// 0.5: every anchor put the target's middle at the viewport's middle.
    static func scrollAnchorPoint(_ anchor: String?, horizontal: Bool) -> UnitPoint {
        switch anchor {
        case "top": return horizontal ? .leading : .top
        case "center": return .center
        default: return horizontal ? .trailing : .bottom
        }
    }

    /// Where a Collection starts, along its scroll axis (the SSoT's
    /// Collection.defaultScrollAnchor): top / center / bottom, `.top`
    /// otherwise; on a horizontal Collection `.leading` / `.center` /
    /// `.trailing` (4f ruling 2026-09-27), as scrollAnchorPoint. Until
    /// jsonui-cli 1.9.0 it was `.top` / `.center` / `.bottom` there too, whose
    /// x is 0.5: a horizontal Collection started at its middle whatever the
    /// anchor said.
    static func defaultScrollAnchorPoint(_ anchor: String, horizontal: Bool) -> UnitPoint {
        switch anchor {
        case "center": return .center
        case "bottom": return horizontal ? .trailing : .bottom
        default: return horizontal ? .leading : .top
        }
    }

    /// The id of the cell a scrollTo names (4f ruling 2026-09-27; jsonui-cli
    /// 1.9.0, the SSoT's Collection.scrollTo): `.index(n)` is a cell counted
    /// across the drawn sections in section order — a header or a footer is
    /// not a cell; `.cellId(key)` is the first cell, in section order, whose
    /// key (its "cellId", else its cellIdProperty value) it is. nil when no
    /// cell answers. The id is the cell's own (identifiedItems), which no
    /// other cell has. `sections` is the route's (declared sections, or the
    /// class-list shape's one per data section); a section is drawn when it
    /// names a cell and its data has cells.
    ///
    /// Until jsonui-cli 1.9.0 the value went to ScrollViewProxy as it was:
    /// an Int against String cell ids named no cell (but the section of
    /// that number, the outer ForEach's id), and a key two sections share
    /// named whichever view SwiftUI found.
    static func scrollID(
        for target: CollectionScrollTarget,
        sections: [[String: Any]],
        dataSource: CollectionDataSource,
        cellIdProperty: String?
    ) -> AnyHashable? {
        var place = 0
        for sectionIndex in 0..<min(sections.count, dataSource.sections.count) {
            guard sections[sectionIndex]["cell"] is String,
                  let cells = dataSource.sections[sectionIndex].cells else { continue }
            for item in identifiedItems(from: cells.data, cellIdProperty: cellIdProperty, section: sectionIndex) {
                switch target {
                case .index(let index):
                    if place == index { return item.id }
                case .cellId(let key):
                    if cellKey(item.data, cellIdProperty: cellIdProperty) == key { return item.id }
                }
                place += 1
            }
        }
        return nil
    }

    /// The scrollTo request on a route's scroll container (4f ruling
    /// 2026-09-27; jsonui-cli 1.9.0, the SSoT's Collection.scrollTo): a CHANGE
    /// of the value scrolls to the cell it names (scrollID(for:…)) — keyed on
    /// the value, the same shape as Compose's LaunchedEffect and web's effect —
    /// and the value the Collection is drawn with scrolls nowhere
    /// (`.onChange(of:)` does not fire for it). The value is optional here, so a
    /// value arriving where there was none is a change like any other. Until
    /// jsonui-cli 1.9.0 the modifier was attached only while there was a value
    /// (`ifLet`), so the first value to arrive scrolled nowhere — and, switching
    /// the view's branch, rebuilt the scroll container.
    static func scrollOnChange<Content: View>(
        _ view: Content,
        target: CollectionScrollTarget?,
        proxy: ScrollViewProxy,
        sections: [[String: Any]],
        dataSource: CollectionDataSource,
        cellIdProperty: String?,
        animated: Bool,
        anchor: UnitPoint
    ) -> some View {
        view.onChange(of: target) { _, newTarget in
            guard let newTarget,
                  let id = scrollID(for: newTarget, sections: sections, dataSource: dataSource, cellIdProperty: cellIdProperty)
            else { return }
            if animated {
                withAnimation { proxy.scrollTo(id, anchor: anchor) }
            } else {
                proxy.scrollTo(id, anchor: anchor)
            }
        }
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
            // A page's identity: its cell's id (identifiedItems) — its key
            // qualified by its section, else its place. Two pages with one id
            // left the TabView unable to turn to the second or, measured, to
            // the first (jsonui-cli 1.9.0: a scrollTo naming a shared key
            // stayed on page 0); until 1.9.0 (round 14) a String id could
            // still repeat — a key "1:k" in section 0 and "k" in section 1,
            // a key "s1_0" and section 1's first cell with no key, two cells
            // of one section with one key.
            for item in identifiedItems(from: cellsData.data, cellIdProperty: cellIdProperty, section: sectionIndex) {
                pages.append(PagingPageItem(
                    id: item.id,
                    index: pages.count,
                    cellClassName: cellName,
                    data: item.data
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
                            let items = identifiedItems(from: cellsData.data, cellIdProperty: cellIdProperty, section: sectionIndex)
                            // A section that declares its own `columns` > 1
                            // is a grid of them (sectionOwnGridColumns).
                            if let ownColumns = sectionOwnGridColumns(sectionConfig, component: component) {
                                sectionGrid(
                                    columns: ownColumns,
                                    items: items,
                                    cellName: cellName,
                                    component: component,
                                    data: data,
                                    viewId: viewId,
                                    onItemAppear: onItemAppear
                                )
                            } else {
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
                .collectionScrollOnChange(scrollTarget, proxy: scrollProxy, sections: sections, dataSource: dataSource,
                                          cellIdProperty: cellIdProperty, animated: scrollAnimated, anchor: scrollAnchorPoint)
            }
        )
    }

    /// Sectioned vertical collection WITH list chrome — the dynamic half of
    /// codegen's sectioned List branch (`List { Group { sections } }` with
    /// `.listRowSeparator` on the Group and the declared listStyle on the
    /// List). SwiftUI's List holds Sections natively; a chrome-less sectioned
    /// collection stays on the CollectionStackView route.
    private static func buildSectionedListLayout(
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
        let listStyle = component.enumString(CollectionAttributes.self, \.listStyle) ?? "plain"
        let hideSeparator = component.typedAttributes(CollectionAttributes.self).hideSeparator ?? false

        // The scrollTo reaches the List's cells by their scroll ids (as on the
        // CollectionStackView route); until jsonui-cli 1.9.0 this route had no
        // ScrollViewReader and a scrollTo drew nothing.
        return AnyView(ScrollViewReader { scrollProxy in
            scrollOnChange(applyListStyle(AnyView(
            List {
                Group {
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
                            let items = identifiedItems(from: cellsData.data, cellIdProperty: cellIdProperty, section: sectionIndex)
                            // A section that declares its own `columns` > 1
                            // is a grid of them (sectionOwnGridColumns).
                            if let ownColumns = sectionOwnGridColumns(sectionConfig, component: component) {
                                sectionGrid(
                                    columns: ownColumns,
                                    items: items,
                                    cellName: cellName,
                                    component: component,
                                    data: data,
                                    viewId: viewId,
                                    onItemAppear: onItemAppear
                                )
                            } else {
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
                .listRowSeparator(hideSeparator ? .hidden : .automatic)
            }
        ), style: listStyle), target: scrollTarget, proxy: scrollProxy, sections: sections, dataSource: dataSource,
            cellIdProperty: cellIdProperty, animated: scrollAnimated, anchor: scrollAnchorPoint)
        })
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

    /// The legacy single-column List: no `sections`, the cells, header and
    /// footer named on the Collection (cellClasses / headerClasses /
    /// footerClasses) — the codegen's legacy List branch. Every section of
    /// the data source is drawn with the one declared cell
    /// (`generate_fallback_foreach`); the header and footer are drawn once,
    /// without data, as the codegen's `Header()` / `Footer()` are. With a
    /// header the cells sit in a Section under it and a footer takes a
    /// Section of its own; without one the footer is the last row.
    ///
    /// This route was unreachable until the legacy shape was read: every
    /// Collection without `sections` returned before any route.
    private static func buildListLayout(
        component: DynamicComponent,
        dataSource: CollectionDataSource,
        cellName: String?,
        headerName: String?,
        footerName: String?,
        cellIdProperty: String?,
        sections: [[String: Any]],
        scrollTarget: CollectionScrollTarget?,
        scrollAnimated: Bool,
        scrollAnchorPoint: UnitPoint,
        data: [String: Any],
        viewId: String?,
        onItemAppear: ((Int) -> Void)? = nil
    ) -> AnyView {
        // `listStyle` picks the chrome; the generated code reads the same
        // attribute onto SwiftUI's concrete styles, so the hardcoded
        // PlainListStyle here was a parity drift the moment codegen stopped
        // hardcoding its own.
        let listStyle = component.enumString(CollectionAttributes.self, \.listStyle) ?? "plain"
        let hideSeparator = component.typedAttributes(CollectionAttributes.self).hideSeparator ?? false

        let cells = AnyView(
            ForEach(0..<dataSource.sections.count, id: \.self) { sectionIndex in
                if let cellName, let cellsData = dataSource.sections[sectionIndex].cells {
                    let items = identifiedItems(from: cellsData.data, cellIdProperty: cellIdProperty, section: sectionIndex)
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
            }
        )

        // The Group is how the generated code forwards `.listRowSeparator` to
        // every row — the modifier styles ROWS, not the List, so applying it
        // to the List itself (the old ListSeparatorModifier) never hid
        // anything. The codegen hides row separators on the header-less
        // shape only, and hides the section separator between the cells'
        // Section and the footer's.
        let list = applyListStyle(AnyView(
            List {
                if let headerName {
                    Section {
                        cells
                    } header: {
                        buildHeaderView(headerClassName: headerName, headerData: [:], data: data, viewId: viewId)
                    }
                    .listSectionSeparator(footerName != nil ? .hidden : .automatic)
                    if let footerName {
                        Section {
                            buildFooterView(footerClassName: footerName, footerData: [:], data: data, viewId: viewId)
                        }
                    }
                } else {
                    Group {
                        cells
                    }
                    .listRowSeparator(hideSeparator ? .hidden : .automatic)
                    if let footerName {
                        buildFooterView(footerClassName: footerName, footerData: [:], data: data, viewId: viewId)
                    }
                }
            }
        ), style: listStyle)

        // A scrollTo reaches the cells by their scroll ids — every data
        // section's (`sections`, the class-list shape's one per data section)
        // — as on the other lists; until jsonui-cli 1.9.0 this route had no
        // ScrollViewReader and a scrollTo drew nothing. Only a Collection that
        // declares scrollTo takes the reader: any other stays the List it was
        // (CollectionDeclaredCellsTests finds it by walking the view).
        guard component.typedAttributes(CollectionAttributes.self).scrollTo != nil else { return list }
        return AnyView(ScrollViewReader { scrollProxy in
            scrollOnChange(list, target: scrollTarget, proxy: scrollProxy, sections: sections, dataSource: dataSource,
                           cellIdProperty: cellIdProperty, animated: scrollAnimated, anchor: scrollAnchorPoint)
        })
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
        mode: CollectionStackMode = .lazy,
        globalColumns: Int = 1,
        columnsIsBinding: Bool = false
    ) -> AnyView {
        let showsIndicators = component.showsHorizontalScrollIndicator ?? true
        // Along the scroll axis: lineSpacing, else itemSpacing (the one rule
        // for every horizontal Collection — horizontalGridSpacing). This
        // read columnSpacing, else itemSpacing, else lineSpacing.
        let alongScroll = horizontalGridSpacing(component).alongScroll
        let insetHorizontal = component.insetHorizontal ?? 0
        let hstackAlignment = getHStackAlignment(from: component)

        return AnyView(
            ScrollViewReader { scrollProxy in
                CollectionStackView(
                    mode: mode,
                    axis: .horizontal,
                    verticalAlignment: hstackAlignment,
                    spacing: alongScroll,
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
                            let items = identifiedItems(from: cellsData.data, cellIdProperty: cellIdProperty, section: sectionIndex)
                            // `columns` on a horizontal Collection is its lanes
                            // (horizontalLanes); one lane keeps the stack.
                            if let lanes = horizontalLanes(sectionConfig, globalColumns: globalColumns, columnsIsBinding: columnsIsBinding) {
                                sectionHGrid(
                                    lanes: lanes,
                                    items: items,
                                    cellName: cellName,
                                    component: component,
                                    data: data,
                                    viewId: viewId,
                                    onItemAppear: onItemAppear
                                )
                            } else {
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
                .collectionScrollOnChange(scrollTarget, proxy: scrollProxy, sections: sections, dataSource: dataSource,
                                          cellIdProperty: cellIdProperty, animated: scrollAnimated, anchor: scrollAnchorPoint)
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
        scrollTarget: CollectionScrollTarget?,
        scrollAnimated: Bool,
        data: [String: Any],
        viewId: String?,
        onItemAppear: ((Int) -> Void)? = nil
    ) -> AnyView {
        let pageItems = flattenedPageItems(
            sections: sections,
            dataSource: dataSource,
            cellIdProperty: cellIdProperty
        )
        // Between pages, along the scroll axis: the horizontal rule
        // (horizontalGridSpacing). This read columnSpacing, else itemSpacing.
        let itemSpacing = horizontalGridSpacing(component).alongScroll

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
                scrollTarget: scrollTarget,
                scrollAnimated: scrollAnimated,
                cellIdProperty: cellIdProperty,
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
        onItemAppear: ((Int) -> Void)? = nil,
        legacyHeader: String? = nil,
        legacyFooter: String? = nil,
        oneGridForAllSections: Bool = false
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

        // Content insets pad the grid INSIDE the full-bleed scroll (the
        // codegen face's `.padding` on the LazyVGrid). The caller must NOT
        // also pad the ScrollView — see collectionContentEdgeInsets.
        let contentEdges = collectionContentEdgeInsets(component: component)
        let headerFooterEdges = legacyHeaderFooterEdges(component: component)

        return AnyView(
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: showsIndicators) {
                    // The scroll's content is a column at the leading edge,
                    // its rows — a header, a grid, a footer — spaced as the
                    // grid's rows (collectionSpacing: lineSpacing, else
                    // itemSpacing, else 0), a header or footer a full-width
                    // row with the view at its start: sjui's grid, kjui's
                    // full-span items and the web's rows (4f ruling
                    // 2026-09-27, round 10). Until jsonui-cli 1.9.0 the
                    // ScrollView's implicit stack and a `VStack(spacing:
                    // nil)` centred them, the system's spacing between.
                    VStack(alignment: .leading, spacing: lineSpacing) {
                    // The legacy shape's headerClasses / footerClasses: once,
                    // without data, above and below the grid inside the
                    // scroll — the codegen's legacy grid branch. Absent, the
                    // content is the grid alone, as before.
                    if let legacyHeader {
                        buildHeaderView(headerClassName: legacyHeader, headerData: [:], data: data, viewId: viewId)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(headerFooterEdges)
                    }
                    Group {
                    if oneGridForAllSections {
                        singleGridForAllSections(
                            component: component,
                            dataSource: dataSource,
                            sections: sections,
                            cellIdProperty: cellIdProperty,
                            columns: effectiveGridColumns(component, declared: globalColumns),
                            columnSpacing: itemSpacing,
                            lineSpacing: lineSpacing,
                            cellWidth: cellWidth,
                            cellHeight: cellHeight,
                            data: data,
                            viewId: viewId,
                            onItemAppear: onItemAppear
                        )
                    } else {
                    VStack(alignment: .leading, spacing: lineSpacing) {
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
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Grid of cells
                        if let cellName = sectionConfig["cell"] as? String,
                           let cellsData = sectionData.cells {
                            let gridItemSize: GridItem.Size = cellWidth.map { .fixed($0) } ?? .flexible()
                            let gridColumns = Array(
                                repeating: GridItem(gridItemSize, spacing: itemSpacing),
                                count: sectionColumns
                            )
                            let items = identifiedItems(from: cellsData.data, cellIdProperty: cellIdProperty, section: sectionIndex)
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
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    }
                    }
                    }
                    .padding(contentEdges ?? EdgeInsets())
                    if let legacyFooter {
                        buildFooterView(footerClassName: legacyFooter, footerData: [:], data: data, viewId: viewId)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(headerFooterEdges)
                    }
                    }
                }
                .collectionScrollOnChange(scrollTarget, proxy: scrollProxy, sections: sections, dataSource: dataSource,
                                          cellIdProperty: cellIdProperty, animated: scrollAnimated, anchor: scrollAnchorPoint)
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
        let gaps = flowSpacing(component)

        // The scrollTo reaches the flow's cells by their scroll ids (as on the
        // other routes); until jsonui-cli 1.9.0 the flow had neither the ids
        // nor a ScrollViewReader, and a scrollTo drew nothing.
        return AnyView(ScrollViewReader { scrollProxy in
            scrollOnChange(
            ScrollView(.vertical, showsIndicators: showsIndicators) {
                VStack(spacing: gaps.sections) {
                    ForEach(
                        0..<min(sections.count, dataSource.sections.count),
                        id: \.self
                    ) { sectionIndex in
                        let sectionConfig = sections[sectionIndex]
                        let sectionData = dataSource.sections[sectionIndex]

                        // The section's declared header: a row of its own
                        // above its wrap, full width, leading (4f ruling
                        // 2026-09-26, round 7). The lazy flow drew none.
                        if let headerName = sectionConfig["header"] as? String,
                           let headerData = sectionData.header {
                            buildHeaderView(headerClassName: headerName, headerData: headerData.data, data: data, viewId: viewId)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let cellName = sectionConfig["cell"] as? String,
                           let cellsData = sectionData.cells {
                            let items = identifiedItems(from: cellsData.data, cellIdProperty: cellIdProperty, section: sectionIndex)
                            FlowLayout(
                                alignment: getFlowAlignment(from: component),
                                horizontalSpacing: gaps.cells,
                                verticalSpacing: gaps.lines
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

                        // …and its footer, a row below the wrap.
                        if let footerName = sectionConfig["footer"] as? String,
                           let footerData = sectionData.footer {
                            buildFooterView(footerClassName: footerName, footerData: footerData.data, data: data, viewId: viewId)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }, target: scrollTarget, proxy: scrollProxy, sections: sections, dataSource: dataSource,
               cellIdProperty: cellIdProperty, animated: scrollAnimated, anchor: scrollAnchorPoint)
        })
    }

    /// The legacy shape's grid (no `sections`): every data section's cells in
    /// ONE grid, as the codegen's legacy grid emits them — a single LazyVGrid
    /// around generate_fallback_foreach, on the lazy and the `lazy: none`
    /// routes alike. One grid per data section (what the sectioned route
    /// draws) broke the rows at every section boundary instead. A cell's
    /// index counts within its section, as there.
    private static func singleGridForAllSections(
        component: DynamicComponent,
        dataSource: CollectionDataSource,
        sections: [[String: Any]],
        cellIdProperty: String?,
        columns: Int,
        columnSpacing: CGFloat,
        lineSpacing: CGFloat,
        cellWidth: CGFloat?,
        cellHeight: CGFloat?,
        data: [String: Any],
        viewId: String?,
        onItemAppear: ((Int) -> Void)?
    ) -> AnyView {
        let gridItemSize: GridItem.Size = cellWidth.map { .fixed($0) } ?? .flexible()
        let gridColumns = Array(repeating: GridItem(gridItemSize, spacing: columnSpacing), count: columns)
        let sectionCount = min(sections.count, dataSource.sections.count)
        return AnyView(
            LazyVGrid(columns: gridColumns, spacing: lineSpacing) {
                ForEach(0..<sectionCount, id: \.self) { sectionIndex in
                    if let cellName = sections[sectionIndex]["cell"] as? String,
                       let cellsData = dataSource.sections[sectionIndex].cells {
                        ForEach(identifiedItems(from: cellsData.data, cellIdProperty: cellIdProperty, section: sectionIndex)) { cell in
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
        onItemAppear: ((Int) -> Void)? = nil,
        legacyHeader: String? = nil,
        legacyFooter: String? = nil,
        oneGridForAllSections: Bool = false,
        columnsIsBinding: Bool = false
    ) -> AnyView {
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
                        // A flow's header is a full-width row (round 7), as
                        // on the lazy flow.
                        .frame(maxWidth: isFlow ? .infinity : nil, alignment: .leading)
                    }

                    if let cellName = sectionConfig["cell"] as? String,
                       let cellsData = sectionData.cells {
                        let items = identifiedItems(from: cellsData.data, cellIdProperty: cellIdProperty, section: sectionIndex)
                        if isFlow {
                            // The declared gaps as declared, 0 included
                            // (flowSpacing; the blocks are the VStack below).
                            FlowLayout(
                                alignment: getFlowAlignment(from: component),
                                horizontalSpacing: flowSpacing(component).cells,
                                verticalSpacing: flowSpacing(component).lines
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
                        } else if isHorizontal,
                                  let lanes = horizontalLanes(sectionConfig, globalColumns: globalColumns, columnsIsBinding: columnsIsBinding) {
                            sectionHGrid(
                                lanes: lanes,
                                items: items,
                                cellName: cellName,
                                component: component,
                                data: data,
                                viewId: viewId,
                                onItemAppear: onItemAppear
                            )
                        } else if !isHorizontal && (globalColumns > 1 || sectionOwnGridColumns(sectionConfig, component: component) != nil) {
                            // A grid when the Collection has columns > 1, or
                            // when this section declares its own (the other
                            // sections of a 1-column Collection stay one cell
                            // per row). columnSpacing between cells, as on the
                            // lazy grid — this read itemSpacing and left a
                            // declared columnSpacing unread.
                            let sectionColumns = effectiveGridColumns(
                                component,
                                declared: declaredSectionColumns(sectionConfig) ?? globalColumns
                            )
                            let gridItemSize: GridItem.Size = cellWidth.map { .fixed($0) } ?? .flexible()
                            let gridColumns = Array(
                                repeating: GridItem(gridItemSize, spacing: columnSpacing),
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
                        .frame(maxWidth: isFlow ? .infinity : nil, alignment: .leading)
                    }
                }
            )
        }

        let sectionCount = min(sections.count, dataSource.sections.count)

        if isHorizontal {
            let hstackAlignment = getHStackAlignment(from: component)
            return AnyView(
                // Along the scroll axis: the horizontal rule
                // (horizontalGridSpacing); this read columnSpacing.
                HStack(alignment: hstackAlignment, spacing: horizontalGridSpacing(component).alongScroll) {
                    ForEach(0..<sectionCount, id: \.self) { sectionIndex in
                        sectionBodies(sectionIndex)
                    }
                }
            )
        } else if isFlow {
            let vstackAlignment = getVStackAlignment(from: component)
            return AnyView(
                VStack(alignment: vstackAlignment, spacing: flowSpacing(component).sections) {
                    ForEach(0..<sectionCount, id: \.self) { sectionIndex in
                        sectionBodies(sectionIndex)
                    }
                }
            )
        } else {
            // The single column and the grid: the legacy shape's
            // headerClasses / footerClasses are drawn once, without data,
            // before and after the cells — the codegen's non-lazy VStack
            // (and its non-lazy grid, which emits them as siblings of the
            // grid). Horizontal and flow have no place for them there.
            let vstackAlignment = getVStackAlignment(from: component)
            return AnyView(
                VStack(alignment: vstackAlignment, spacing: lineSpacing) {
                    if let legacyHeader {
                        buildHeaderView(headerClassName: legacyHeader, headerData: [:], data: data, viewId: viewId)
                    }
                    if oneGridForAllSections && globalColumns > 1 {
                        singleGridForAllSections(
                            component: component,
                            dataSource: dataSource,
                            sections: sections,
                            cellIdProperty: cellIdProperty,
                            columns: effectiveGridColumns(component, declared: globalColumns),
                            columnSpacing: columnSpacing,
                            lineSpacing: lineSpacing,
                            cellWidth: cellWidth,
                            cellHeight: cellHeight,
                            data: data,
                            viewId: viewId,
                            onItemAppear: onItemAppear
                        )
                    } else {
                        ForEach(0..<sectionCount, id: \.self) { sectionIndex in
                            sectionBodies(sectionIndex)
                        }
                    }
                    if let legacyFooter {
                        buildFooterView(footerClassName: legacyFooter, footerData: [:], data: data, viewId: viewId)
                    }
                }
            )
        }
    }

    // MARK: - Cell/Header/Footer View Builders

    /// The outer container shape this Collection renders as.
    ///
    /// `lazy` accepts a legacy boolean besides the declared enum — wider than
    /// the declared kind — so it is read raw here, which is the row the
    /// read-discipline allowlist carries for this file. Kept as the ONE place
    /// that reads it: `isAccessibilityContainer` needs the same answer, and a
    /// second raw read elsewhere would be a second unlisted violation and a
    /// second chance for the two to disagree about what shape is rendered.
    static func stackMode(_ component: DynamicComponent, data: [String: Any]) -> CollectionStackMode {
        let resolved: Any? = DynamicBindingHelper.resolveValue(
            component.rawAttribute("lazy"),
            data: data
        )
        return CollectionStackMode(json: resolved)
    }

    /// True when this Collection renders WITHOUT a scroll container — a bare
    /// VStack/HStack, which is not an accessibility element, so a bare
    /// identifier on it is pushed down onto its cells and renames them.
    static func rendersWithoutScrollContainer(_ component: DynamicComponent) -> Bool {
        stackMode(component, data: [:]) == .none
    }

    /// `horizontalScroll: true` is the declared boolean spelling of the
    /// same direction fact (ScrollView's vocabulary — real carousels use
    /// it). The static codegens honor it; the android dynamic renderer
    /// gained the same reading in the F4-P2 parity cycle.
    static func isHorizontal(_ component: DynamicComponent) -> Bool {
        component.layout == "horizontal"
            || component.orientation == "horizontal"
            || component.typedAttributes(CollectionAttributes.self).horizontalScroll == true
    }

    /// Case-insensitive: the declared enum admits 'Flow' as well as 'flow'
    /// (the static codegens compare casecmp since the F4-P2 parity cycle).
    /// 'leftAligned' is an alias spelling of flow (SSoT valueAliases,
    /// 2026-08-03 unification — the generated enum folds it the same way).
    static func isFlowLayout(_ component: DynamicComponent) -> Bool {
        ["flow", "leftaligned"].contains(component.layout?.lowercased() ?? "")
    }

    /// Would this flow Collection hand scrolling to a scrolling ancestor,
    /// given that it has one? The component half of the decision — the same
    /// table sjui's `flow_defers_to_scrolling_ancestor?` answers: `lazy` in
    /// effect (anything but "none"), a flow layout, and no bounds of its own
    /// (height undeclared or wrapContent). A numeric height clips and
    /// scrolls inside its box, matchParent fills the parent's — both keep
    /// the ScrollView; a bound height is unknown here and keeps it too.
    static func flowDefersToScrollingAncestor(
        _ component: DynamicComponent,
        data: [String: Any],
        insideScrollingAncestor: Bool
    ) -> Bool {
        guard insideScrollingAncestor else { return false }
        guard isFlowLayout(component) else { return false }
        guard stackMode(component, data: data) != .none else { return false }
        guard let height = component.typedAttributes(CommonAttributes.self).height else { return true }
        return height.value == .wrapContent
    }

    /// A vertically scrolling Collection is a scrolling ancestor for its
    /// cells, headers and footers — and the cell layout is another file, so
    /// only this context can tell it (the static codegen's known limit).
    /// Horizontal shapes scroll the other axis and `lazy: "none"` does not
    /// scroll at all: both leave the inherited mark alone.
    static func scrollsVertically(_ component: DynamicComponent, data: [String: Any]) -> Bool {
        stackMode(component, data: data) != .none && !isHorizontal(component)
    }

    // fileprivate, not private: PagingCollectionWrapperView (below, a type of
    // its own) draws its pages through it too.
    @ViewBuilder
    fileprivate static func buildCellView(
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

        // `{collectionId}_item_{index}` — the address the test drivers use
        // (`tapItem`, `waitFor`), and the same spelling the static codegens
        // emit. Dynamic emitted nothing here, on any layout, so a fixture —
        // which always runs through Dynamic — could never check the contract
        // that codegen is expected to keep. That is why two codegen arms
        // could go without it unnoticed.
        //
        // Placed on the one builder every cell path calls (nine sites) so a
        // tenth inherits it rather than having to remember, which is exactly
        // how the static side lost two arms.
        DynamicView(
            jsonName: jsonFileName,
            viewId: cellClassName,
            data: cellData
        )
        // The cell's own file cannot see that it sits inside a scrolling
        // Collection; the environment tells it (ScrollingAncestorContext).
        .modifier(ScrollingAncestorMark(active: scrollsVertically(component, data: data)))
        // The wrapper's identifier must land on an ELEMENT. A plain SwiftUI
        // container is not one, so a bare `.accessibilityIdentifier` here is
        // pushed down onto the nearest descendants — the cell's own direct
        // children — and they answer to `{collectionId}_item_{N}` instead of
        // the identifiers their layout declared (measured 2026-09-05 on the
        // static side: 8 of 8 cells in one consumer explained by whether the
        // cell root declared an `id`, because an id-bearing root already
        // became an explicit container).
        //
        // The static side fixes this at the cell ROOT, which it can do
        // because `sjui build` sees the whole project and marks the layouts
        // some Collection renders. Dynamic has no such pass here: the cell's
        // JSON is loaded inside DynamicView, so the root's `id` is not
        // knowable at this point without reading that file per cell. This
        // makes the WRAPPER the element instead, which reaches the same
        // outcome for the children.
        //
        // NOT settled by measurement yet, and deliberately not guessed at:
        // whether a single-child cell needs the anchor overlay the static
        // side emits (SwiftUI merges a container holding one accessibility
        // child, which would put `{id}_item_{N}` back on that child). The
        // conformance fixtures for an id-less cell root and a single-child
        // cell run through THIS renderer, so they are what decides it — see
        // the report for 2026-09-05.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(cellAccessibilityIdentifier(component: component, cellIndex: cellIndex))
        .onAppear {
            onItemAppear?(cellIndex)
        }
    }

    /// Empty when the Collection declares no id — there is nothing to build
    /// an address out of, and an empty identifier is what SwiftUI treats as
    /// "unset".
    static func cellAccessibilityIdentifier(component: DynamicComponent, cellIndex: Int) -> String {
        guard let collectionId = component.id, !collectionId.isEmpty else { return "" }
        return "\(collectionId)_item_\(cellIndex)"
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
        // Headers live in the vertical section route, under the same
        // scrolling ancestor as the cells (ScrollingAncestorContext).
        .modifier(ScrollingAncestorMark(active: true))
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
        .modifier(ScrollingAncestorMark(active: true))
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
    let id: AnyHashable
    let index: Int
    let cellClassName: String
    let data: [String: Any]
}

// MARK: - Cell Item

/// A Dynamic Collection's cell: its data, its place in its section, and its
/// id — its loop identity and its scroll target (CollectionConverter
/// .identifiedItems). The generated code's IdentifiedCellItem has a String id;
/// this one's is a key qualified by its section or a place, neither of which
/// a String equals.
struct CollectionCellItem: Identifiable {
    /// A cell's key in its section.
    struct Key: Hashable {
        let section: Int
        let key: String
    }

    let id: AnyHashable
    let index: Int
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
    let scrollTarget: CollectionScrollTarget?
    let scrollAnimated: Bool
    let cellIdProperty: String?
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
                // Through the one cell builder, as every other route draws its
                // cells: it gives the page its `{collectionId}_item_{index}`
                // address (a `.contain` element, so the cell's own children
                // keep theirs) and calls onItemAppear with the page's index.
                // The pager drew DynamicView directly and so had no address at
                // all — `pager_item_N` found nothing on any page (4f ruling
                // 2026-09-26, round 8). `page.index` is the page's place among
                // all the pages, across the sections, as sjui's page tag and
                // KotlinJsonUI's pager address count.
                CollectionConverter.buildCellView(
                    cellClassName: page.cellClassName,
                    cellData: page.data,
                    cellIndex: page.index,
                    component: component,
                    data: data,
                    viewId: viewId,
                    onItemAppear: onItemAppearCallback
                )
                .padding(.horizontal, itemSpacing > 0 ? itemSpacing / 2 : 0)
                .tag(page.index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onChange(of: effectiveSelection.wrappedValue) { _, newValue in
            onPageChangedCallback?(newValue)
        }
        // A scrollTo turns to the page the value names — its CHANGE, as on
        // every route (CollectionConverter.scrollOnChange): an Int is the
        // page, the cells counted across the drawn sections; a String the
        // first page whose key (its cellId, else its cellIdProperty value) it
        // is; none, no turn. Until jsonui-cli 1.9.0 the pager drew no scrollTo.
        .onChange(of: scrollTarget) { _, newTarget in
            guard let newTarget, let page = page(for: newTarget) else { return }
            if scrollAnimated {
                withAnimation { effectiveSelection.wrappedValue = page }
            } else {
                effectiveSelection.wrappedValue = page
            }
        }
    }

    private func page(for target: CollectionScrollTarget) -> Int? {
        switch target {
        case .index(let index):
            return pageItems.first { $0.index == index }?.index
        case .cellId(let key):
            return pageItems.first { page in
                ((page.data["cellId"] as? String) ?? cellIdProperty.flatMap { page.data[$0] as? String }) == key
            }?.index
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

/// CollectionConverter.scrollOnChange as a modifier, for the routes that
/// chain their scroll container's modifiers.
fileprivate extension View {
    func collectionScrollOnChange(
        _ target: CollectionScrollTarget?,
        proxy: ScrollViewProxy,
        sections: [[String: Any]],
        dataSource: CollectionDataSource,
        cellIdProperty: String?,
        animated: Bool,
        anchor: UnitPoint
    ) -> some View {
        CollectionConverter.scrollOnChange(self, target: target, proxy: proxy, sections: sections, dataSource: dataSource,
                                           cellIdProperty: cellIdProperty, animated: animated, anchor: anchor)
    }
}

#endif // DEBUG
