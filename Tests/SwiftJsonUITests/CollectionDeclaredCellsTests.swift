//
//  CollectionDeclaredCellsTests.swift
//  SwiftJsonUITests
//
//  Which cell / header / footer layouts a Dynamic Collection draws, measured
//  by drawing it: each probe layout is an app-registered component that
//  records what it was built with.
//
//  SSoT `/Collection/cellClasses`: "With `items` and no `sections`, a single
//  cellClass renders every item" — what sjui's SwiftUI codegen emits for that
//  shape (collection_converter.rb: `single_declared_cell_view` on the List
//  and grid routes, `cellClasses.first` on the horizontal and flow routes).
//  Dynamic decoded `cellClasses` and never read it: every route drew from
//  `sections[].cell`, and a Collection with no `sections` returned before any
//  route, so it drew no cells at all (measured before this change: 0 of 3
//  items on every route below, while the same Collection with
//  `sections: [{cell}]` drew 3 of 3).
//
//  `headerClasses` / `footerClasses` are the same legacy shape: the codegen
//  draws them once around the cells, without data, on the routes that have a
//  place for them (the single-column List, the grid, and their `lazy: none`
//  stacks) and not on the horizontal, flow and paging routes.
//
//  The codegen emits that legacy container whatever `items` says, so an
//  items-less Collection still shows its header and footer (and a lone
//  cellClass is an empty List); and its legacy grid is ONE grid around every
//  data section's cells. Dynamic drew nothing without a source, and a grid
//  per data section (measured before the change: both red).
//
//  A section's own `columns` (declared: Collection.sections[].columns) is a
//  grid of them in a 1-column Collection too, on the section stack, the
//  sectioned List and the `lazy: none` stack, with columnSpacing between
//  cells and lineSpacing between rows; those routes drew it one cell per row.
//
//  On a horizontal Collection `columns` is its lanes (a LazyHGrid per
//  section block), spaced along the scroll axis by lineSpacing and between
//  lanes by columnSpacing; it was one lane whatever `columns` said.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class CollectionDeclaredCellsTests: XCTestCase {

    private static let cell = "declared_cells_probe_cell"
    private static let otherCell = "declared_cells_probe_other_cell"
    private static let header = "declared_cells_probe_header"
    private static let footer = "declared_cells_probe_footer"

    /// What was drawn, in build order: "cell:<title>", "other:<title>",
    /// "header", "footer".
    private static var drawn: [String] = []
    /// Where each of them landed, in window coordinates.
    private static var frames: [String: CGRect] = [:]

    private struct Probe: CustomComponentAdapter {
        let componentType: String
        let record: ([String: Any]) -> String
        func buildView(component: DynamicComponent, data: [String: Any], viewId: String?, parentOrientation: String?) -> AnyView {
            let key = record(data)
            CollectionDeclaredCellsTests.drawn.append(key)
            return AnyView(
                Text(componentType).frame(width: 40, height: 20)
                    .background(GeometryReader { g in
                        Color.clear.onAppear { CollectionDeclaredCellsTests.frames[key] = g.frame(in: .global) }
                    })
            )
        }
    }

    private var written: [URL] = []

    override func setUpWithError() throws {
        let dir = URL(fileURLWithPath: JSONLayoutLoader.getLayoutFileDirPath())
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let layouts: [String: String] = [
            Self.cell: #"{"type": "DeclaredCellsProbeCell"}"#,
            Self.otherCell: #"{"type": "DeclaredCellsProbeOther"}"#,
            Self.header: #"{"type": "DeclaredCellsProbeHeader"}"#,
            Self.footer: #"{"type": "DeclaredCellsProbeFooter"}"#,
        ]
        for (name, json) in layouts {
            let url = dir.appendingPathComponent("\(name).json")
            try Data(json.utf8).write(to: url)
            written.append(url)
            JSONLayoutLoader.clearComponentCache(for: name)
        }
        let title: ([String: Any]) -> String = { ($0["title"] as? String) ?? "?" }
        CustomComponentRegistry.shared.registerAll([
            Probe(componentType: "DeclaredCellsProbeCell", record: { "cell:" + title($0) }),
            Probe(componentType: "DeclaredCellsProbeOther", record: { "other:" + title($0) }),
            Probe(componentType: "DeclaredCellsProbeHeader", record: { _ in "header" }),
            Probe(componentType: "DeclaredCellsProbeFooter", record: { _ in "footer" }),
        ])
    }

    override func tearDown() {
        CustomComponentRegistry.shared.reset()
        for url in written { try? FileManager.default.removeItem(at: url) }
        for name in [Self.cell, Self.otherCell, Self.header, Self.footer] {
            JSONLayoutLoader.clearComponentCache(for: name)
        }
        written = []
    }

    private func dataSource(_ titles: [String] = ["a", "b", "c"]) -> CollectionDataSource {
        CollectionDataSource(sections: [
            CollectionDataSection(cells: (viewName: Self.cell, data: titles.map { ["title": $0] }))
        ])
    }

    /// Draws a Collection (`attrs` is the JSON after `"type": "Collection"`)
    /// and returns what the probes recorded. A set: SwiftUI may build a view
    /// more than once, and a List builds its rows in an order of its own.
    private func draw(_ attrs: String, data: [String: Any]? = nil) throws -> Set<String> {
        Self.drawn = []
        Self.frames = [:]
        let json = "{\"type\": \"Collection\", \"id\": \"c\", \"width\": \"matchParent\", \"height\": \"matchParent\"\(attrs)}"
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        let host = UIHostingController(rootView: DynamicComponentBuilder(
            component: component, data: data ?? ["items": dataSource()]
        ))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        window.isHidden = true
        return Set(Self.drawn)
    }

    private let abc: Set<String> = ["cell:a", "cell:b", "cell:c"]
    private var items: String { ", \"items\": \"@{items}\", \"cellClasses\": [\"\(Self.cell)\"]" }

    // MARK: - control: the shape every consumer Collection has

    /// `sections[].cell` names the cell: drawn before this change too.
    func testASectionsCellIsDrawn() throws {
        XCTAssertEqual(try draw(items + ", \"sections\": [{\"cell\": \"\(Self.cell)\"}]"), abc)
    }

    // MARK: - cellClasses with no sections, per route

    func testTheSingleColumnListDrawsEveryItemWithTheDeclaredCell() throws {
        XCTAssertEqual(try draw(items), abc)
        XCTAssertEqual(try draw(items + ", \"listStyle\": \"grouped\""), abc, "listStyle keeps the List route")
    }

    func testTheHorizontalRouteDrawsEveryItemWithTheDeclaredCell() throws {
        XCTAssertEqual(try draw(items + ", \"layout\": \"horizontal\""), abc)
        XCTAssertEqual(try draw(items + ", \"horizontalScroll\": true"), abc)
    }

    func testTheGridDrawsEveryItemWithTheDeclaredCell() throws {
        XCTAssertEqual(try draw(items + ", \"columns\": 2"), abc)
    }

    func testTheFlowDrawsEveryItemWithTheDeclaredCell() throws {
        XCTAssertEqual(try draw(items + ", \"layout\": \"flow\""), abc)
    }

    func testTheNonScrollingStacksDrawEveryItemWithTheDeclaredCell() throws {
        for route in ["", ", \"layout\": \"horizontal\"", ", \"columns\": 2", ", \"layout\": \"flow\""] {
            XCTAssertEqual(try draw(items + ", \"lazy\": \"none\"" + route), abc, "lazy none\(route)")
        }
    }

    /// The codegen's List and grid routes draw every section of the data
    /// source with the declared cell; its horizontal and flow routes the
    /// first section only.
    func testEverySectionOfTheDataIsDrawnWhereTheCodegenDrawsEverySection() throws {
        let two = CollectionDataSource(sections: [
            CollectionDataSection(cells: (viewName: Self.cell, data: [["title": "a"], ["title": "b"]])),
            CollectionDataSection(cells: (viewName: Self.cell, data: [["title": "c"]])),
        ])
        XCTAssertEqual(try draw(items, data: ["items": two]), abc, "List")
        XCTAssertEqual(try draw(items + ", \"columns\": 2", data: ["items": two]), abc, "grid")
        XCTAssertEqual(try draw(items + ", \"layout\": \"horizontal\"", data: ["items": two]),
                       ["cell:a", "cell:b"], "horizontal: first section")
        XCTAssertEqual(try draw(items + ", \"layout\": \"flow\"", data: ["items": two]),
                       ["cell:a", "cell:b"], "flow: first section")
    }

    /// The pager's pages, as it holds them: [(tag, the page's title)] from
    /// PagingCollectionWrapperView's page list (the TabView builds its pages
    /// lazily, so what the probes record is only the ones on screen).
    private func pages(_ attrs: String, _ source: Any) throws -> [(tag: Int, title: String)] {
        let json = "{\"type\": \"Collection\", \"id\": \"c\", \"items\": \"@{items}\", \"layout\": \"horizontal\", \"paging\": true\(attrs)}"
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        var found: [(tag: Int, title: String)]?
        func walk(_ value: Any, _ depth: Int) {
            guard found == nil, depth < 200 else { return }
            if value is DynamicComponent || value is [String: Any] { return }
            let mirror = Mirror(reflecting: value)
            if String(describing: type(of: value)).hasSuffix("PagingCollectionWrapperView") {
                let items = mirror.children.first { $0.label == "pageItems" }?.value as? [Any] ?? []
                found = items.map { item in
                    let fields = Dictionary(uniqueKeysWithValues: Mirror(reflecting: item).children.compactMap { c in c.label.map { ($0, c.value) } })
                    return ((fields["index"] as? Int) ?? -1, ((fields["data"] as? [String: Any])?["title"] as? String) ?? "?")
                }
                return
            }
            for child in mirror.children { walk(child.value, depth + 1) }
            var superMirror = mirror.superclassMirror
            while let m = superMirror {
                for child in m.children { walk(child.value, depth + 1) }
                superMirror = m.superclassMirror
            }
        }
        walk(CollectionConverter.convert(component: component, data: ["items": source]), 0)
        return found ?? []
    }

    /// 4f ruling (2026-09-26, round 6): paging draws the class-list shape as
    /// one section — the first data section, a page per cell — as the
    /// horizontal and flow routes do. It drew nothing (it read declared
    /// `sections` only).
    func testThePagingRouteDrawsTheFirstDataSectionWithoutSections() throws {
        let two = CollectionDataSource(sections: [
            CollectionDataSection(cells: (viewName: Self.cell, data: [["title": "a"], ["title": "b"]])),
            CollectionDataSection(cells: (viewName: Self.cell, data: [["title": "c"]])),
        ])
        let classList = ", \"cellClasses\": [\"\(Self.cell)\"]"
        XCTAssertEqual(try pages(classList, two).map(\.title), ["a", "b"])
        XCTAssertEqual(try pages(classList, arrayOfRows).map(\.title), ["a", "b", "c"], "an array: one section")
        XCTAssertTrue(try draw(items + ", \"layout\": \"horizontal\", \"paging\": true", data: ["items": two]).contains("cell:a"))
    }

    /// Every declared section's cells in order, each page's tag its place
    /// among all the pages — a bound currentPage names one page (the tags do
    /// not restart per section).
    func testPagingTagsCountAcrossTheSections() throws {
        let two = CollectionDataSource(sections: [
            CollectionDataSection(cells: (viewName: Self.cell, data: [["title": "a"], ["title": "b"]])),
            CollectionDataSection(cells: (viewName: Self.cell, data: [["title": "c"]])),
        ])
        let sectioned = ", \"sections\": [{\"cell\": \"\(Self.cell)\"}, {\"cell\": \"\(Self.cell)\"}]"
        let p = try pages(sectioned, two)
        XCTAssertEqual(p.map(\.title), ["a", "b", "c"])
        XCTAssertEqual(p.map(\.tag), [0, 1, 2])
    }

    /// No data source declared: nothing to draw, as before.
    func testNoItemsBindingDrawsNoCells() throws {
        XCTAssertEqual(try draw(", \"cellClasses\": [\"\(Self.cell)\"]"), [])
    }

    /// Several cellClasses and no sections: nothing says which cell an item
    /// takes. The build refuses that layout (LayoutValidator#check_collection,
    /// level error), so there is no release drawing to follow — Dynamic draws
    /// no cell rather than guess.
    func testSeveralCellClassesWithoutSectionsDrawNoCell() throws {
        let several = ", \"items\": \"@{items}\", \"cellClasses\": [\"\(Self.cell)\", \"\(Self.otherCell)\"]"
        XCTAssertEqual(try draw(several), [])
        XCTAssertEqual(try draw(several + ", \"layout\": \"horizontal\""), [])
    }

    /// `sections` decide when both are declared, as on the codegen: a
    /// section's cell is drawn even when cellClasses names another.
    func testSectionsWinOverCellClasses() throws {
        let attrs = ", \"items\": \"@{items}\", \"cellClasses\": [\"\(Self.otherCell)\"], \"sections\": [{\"cell\": \"\(Self.cell)\"}]"
        XCTAssertEqual(try draw(attrs), abc)
    }

    // MARK: - items bound to an array

    // Collection.items is a CollectionDataSource or an array
    // (attribute_definitions.json; 4f ruling, 2026-09-26). With no `sections`
    // an array is one section of the declared cell, on the routes a
    // one-section data source takes; the codegens decide by the layout's data
    // declaration, this renderer by the value's shape. Measured before the
    // change (b314fd2): an array drew 0 of 3 on every route.

    private let arrayOfRows: [Any] = [["title": "a"], ["title": "b"], ["title": "c"]]

    func testAnArrayIsOneSectionOnEveryRoute() throws {
        let routes = ["", ", \"columns\": 2", ", \"layout\": \"horizontal\"", ", \"layout\": \"flow\"",
                      ", \"lazy\": \"none\"", ", \"lazy\": \"none\", \"columns\": 2", ", \"lazy\": \"none\", \"layout\": \"horizontal\""]
        for route in routes {
            XCTAssertEqual(try draw(items + route, data: ["items": arrayOfRows]), abc, "route\(route)")
        }
        let paging = try draw(items + ", \"layout\": \"horizontal\", \"paging\": true", data: ["items": arrayOfRows])
        XCTAssertTrue(paging.contains("cell:a") && paging.isSubset(of: abc),
                      "paging: the array's cells (4f ruling, round 6; it drew none): \(paging)")
    }

    /// A generated Data struct's array — what the codegen reads with
    /// `toDictionary()` — is read by the struct's stored properties.
    func testAnArrayOfDataStructsIsReadByTheirProperties() throws {
        struct Row { let title: String }
        XCTAssertEqual(try draw(items, data: ["items": [Row(title: "a"), Row(title: "b"), Row(title: "c")]]), abc)
    }

    /// `sections` declared: a list is not a data source for them (the
    /// sectioned shape reads a CollectionDataSource), so nothing is drawn.
    func testDeclaredSectionsDoNotReadAnArray() throws {
        XCTAssertEqual(try draw(items + ", \"sections\": [{\"cell\": \"\(Self.cell)\"}]", data: ["items": arrayOfRows]), [])
    }

    /// Several cellClasses over an array: no cell, as over a data source —
    /// and named, once per Collection: a Dynamic layout does not pass the
    /// build that refuses it. It was drawn as nothing and said nothing.
    func testSeveralCellClassesOverAnArrayDrawNoCellAndAreNamed() throws {
        CollectionConverter.named = []
        CollectionConverter.loggedSeveralCellClassesIds = []
        let several = ", \"items\": \"@{items}\", \"cellClasses\": [\"\(Self.cell)\", \"\(Self.otherCell)\"]"
        XCTAssertEqual(try draw(several, data: ["items": arrayOfRows]), [])
        XCTAssertEqual(try draw(several), [])
        XCTAssertEqual(CollectionConverter.named, [
            "[CollectionConverter] Collection (id=c): 2 cellClasses declared without sections — no cell is drawn. " +
            "Fix: assign cells via sections[].cell, or declare a single cellClass."
        ])
    }

    // MARK: - headerClasses / footerClasses

    private var headed: String {
        items + ", \"headerClasses\": [\"\(Self.header)\"], \"footerClasses\": [\"\(Self.footer)\"]"
    }

    func testTheListDrawsTheDeclaredHeaderAndFooterAroundTheCells() throws {
        XCTAssertEqual(try draw(headed), abc.union(["header", "footer"]))
        XCTAssertEqual(try draw(items + ", \"headerClasses\": [\"\(Self.header)\"]"), abc.union(["header"]))
        XCTAssertEqual(try draw(items + ", \"footerClasses\": [\"\(Self.footer)\"]"), abc.union(["footer"]))
    }

    func testTheGridDrawsTheDeclaredHeaderAndFooterAroundTheCells() throws {
        XCTAssertEqual(try draw(headed + ", \"columns\": 2"), abc.union(["header", "footer"]))
    }

    func testTheNonScrollingStacksDrawTheDeclaredHeaderAndFooter() throws {
        XCTAssertEqual(try draw(headed + ", \"lazy\": \"none\""), abc.union(["header", "footer"]))
        XCTAssertEqual(try draw(headed + ", \"lazy\": \"none\", \"columns\": 2"), abc.union(["header", "footer"]))
    }

    /// Routes where the codegen has no place for them.
    func testTheHorizontalFlowAndPagingRoutesDrawNoHeaderOrFooter() throws {
        XCTAssertEqual(try draw(headed + ", \"layout\": \"horizontal\""), abc)
        XCTAssertEqual(try draw(headed + ", \"layout\": \"flow\""), abc)
        XCTAssertEqual(try draw(headed + ", \"lazy\": \"none\", \"layout\": \"horizontal\""), abc)
        XCTAssertEqual(try draw(headed + ", \"lazy\": \"none\", \"layout\": \"flow\""), abc)
        let paging = try draw(headed + ", \"layout\": \"horizontal\", \"paging\": true")
        XCTAssertFalse(paging.contains("header") || paging.contains("footer"), "\(paging)")
        XCTAssertFalse(paging.isEmpty, "paging draws the cells (4f ruling, round 6)")
    }

    /// With sections the codegen draws `sections[].header` / `.footer` only.
    func testSectionsIgnoreHeaderAndFooterClasses() throws {
        XCTAssertEqual(try draw(headed + ", \"sections\": [{\"cell\": \"\(Self.cell)\"}]"), abc)
    }

    // MARK: - no items source (the codegen still draws the container)

    private var headedNoItems: String {
        ", \"cellClasses\": [\"\(Self.cell)\"], \"headerClasses\": [\"\(Self.header)\"], \"footerClasses\": [\"\(Self.footer)\"]"
    }

    /// The codegen emits its legacy List / grid / stack whatever `items`
    /// says, header and footer included; only the cells need a source.
    /// Measured before: nothing drawn on any route.
    func testWithNoItemsTheHeaderAndFooterAreStillDrawn() throws {
        let both: Set<String> = ["header", "footer"]
        for route in ["", ", \"columns\": 2", ", \"lazy\": \"none\"", ", \"lazy\": \"none\", \"columns\": 2"] {
            XCTAssertEqual(try draw(headedNoItems + route, data: [:]), both, "no items\(route)")
            // `items` declared but nothing bound to it yet: the same.
            XCTAssertEqual(try draw(headedNoItems + ", \"items\": \"@{items}\"" + route, data: [:]), both,
                           "unbound items\(route)")
        }
    }

    /// Routes that have no place for them draw neither, with or without items.
    func testWithNoItemsTheHorizontalFlowAndPagingRoutesDrawNothing() throws {
        for route in [", \"layout\": \"horizontal\"", ", \"layout\": \"flow\"",
                      ", \"layout\": \"horizontal\", \"paging\": true",
                      ", \"lazy\": \"none\", \"layout\": \"horizontal\""] {
            XCTAssertEqual(try draw(headedNoItems + route, data: [:]), [], route)
        }
    }

    /// A sectioned Collection with no source draws nothing, as before.
    func testWithNoItemsASectionedCollectionDrawsNothing() throws {
        let attrs = ", \"sections\": [{\"cell\": \"\(Self.cell)\", \"header\": \"\(Self.header)\"}], \"items\": \"@{items}\""
        XCTAssertEqual(try draw(attrs, data: [:]), [])
    }

    /// The codegen's legacy List is emitted for a declared cellClass with no
    /// items too — an empty List, whose chrome is on screen. Found in what
    /// the converter builds (no hosting needed: nothing is drawn in it).
    func testWithNoItemsTheLegacyListIsStillAList() throws {
        func containsList(_ attrs: String) throws -> Bool {
            let json = "{\"type\": \"Collection\", \"id\": \"c\"\(attrs)}"
            let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
            let listName = String(String(describing: type(of: List<Never, EmptyView> { EmptyView() })).prefix { $0 != "<" })
            var found = false
            var visited = Set<ObjectIdentifier>()
            func walk(_ value: Any, _ depth: Int) {
                guard !found, depth < 200 else { return }
                if value is DynamicComponent || value is [String: Any] { return }
                if type(of: value) is AnyClass {
                    guard visited.insert(ObjectIdentifier(value as AnyObject)).inserted else { return }
                }
                if String(describing: type(of: value)).hasPrefix(listName + "<") { found = true; return }
                let mirror = Mirror(reflecting: value)
                for child in mirror.children { walk(child.value, depth + 1) }
                var superMirror = mirror.superclassMirror
                while let m = superMirror {
                    for child in m.children { walk(child.value, depth + 1) }
                    superMirror = m.superclassMirror
                }
            }
            walk(CollectionConverter.convert(component: component, data: [:]), 0)
            return found
        }
        XCTAssertTrue(try containsList(", \"cellClasses\": [\"\(Self.cell)\"]"))
        // Controls: nothing declared draws the empty view; a declared
        // listStyle draws its chrome List, as before.
        XCTAssertFalse(try containsList(""))
        XCTAssertTrue(try containsList(", \"listStyle\": \"grouped\""))
    }

    // MARK: - several data sections, no `sections`: one grid

    private var twoDataSections: CollectionDataSource {
        CollectionDataSource(sections: [
            CollectionDataSection(cells: (viewName: Self.cell, data: [["title": "a"]])),
            CollectionDataSection(cells: (viewName: Self.cell, data: [["title": "b"], ["title": "c"]])),
        ])
    }

    /// Two columns, data sections [a] and [b, c]. One grid (the codegen's
    /// legacy grid) puts b beside a and c under a; a grid per section puts
    /// b and c on a row of their own.
    private func placement(_ attrs: String) throws -> (bBesideA: Bool, cUnderA: Bool) {
        _ = try draw(attrs, data: ["items": twoDataSections])
        let a = try XCTUnwrap(Self.frames["cell:a"], "a not placed")
        let b = try XCTUnwrap(Self.frames["cell:b"], "b not placed")
        let c = try XCTUnwrap(Self.frames["cell:c"], "c not placed")
        // Rows touch (lineSpacing 0): c's top is a's bottom.
        return (abs(b.minY - a.minY) < 1 && b.minX > a.maxX,
                abs(c.minX - a.minX) < 1 && c.minY > a.maxY - 1)
    }

    func testSeveralDataSectionsWithoutSectionsShareOneGrid() throws {
        for route in [", \"columns\": 2", ", \"columns\": 2, \"lazy\": \"none\""] {
            let p = try placement(items + route)
            XCTAssertTrue(p.bBesideA, "b is not beside a\(route)")
            XCTAssertTrue(p.cUnderA, "c is not under a\(route)")
        }
    }

    // MARK: - a section's own `columns` in a 1-column Collection

    /// Data sections [a e] and [b c d].
    private var ownColumnsData: CollectionDataSource {
        CollectionDataSource(sections: [
            CollectionDataSection(cells: (viewName: Self.cell, data: [["title": "a"], ["title": "e"]])),
            CollectionDataSection(cells: (viewName: Self.cell, data: [["title": "b"], ["title": "c"], ["title": "d"]])),
        ])
    }

    private func frame(_ key: String) throws -> CGRect {
        try XCTUnwrap(Self.frames["cell:\(key)"], "\(key) not placed")
    }

    /// A section that declares `columns` (declared: Collection.sections[].columns)
    /// is a grid of them on every vertical route that draws sections; the
    /// other section stays one cell per row. Before: b, c, d one per row on
    /// every route here (the declaration was read on the grid route only,
    /// which a 1-column Collection never takes).
    func testASectionsOwnColumnsAreAGridInAOneColumnCollection() throws {
        let sectioned = ", \"items\": \"@{items}\", \"sections\": [{\"cell\": \"\(Self.cell)\"}, {\"cell\": \"\(Self.cell)\", \"columns\": 2}]"
        for route in ["", ", \"lazy\": \"eager\"", ", \"listStyle\": \"grouped\"", ", \"lazy\": \"none\""] {
            _ = try draw(sectioned + route, data: ["items": ownColumnsData])
            let (a, e, b, c, d) = (try frame("a"), try frame("e"), try frame("b"), try frame("c"), try frame("d"))
            XCTAssertTrue(abs(c.minY - b.minY) < 1 && c.minX > b.maxX, "c beside b\(route): \(b) \(c)")
            XCTAssertTrue(abs(d.minX - b.minX) < 1 && d.minY > b.maxY - 1, "d under b\(route): \(b) \(d)")
            XCTAssertTrue(abs(e.minX - a.minX) < 1 && e.minY > a.maxY - 1, "the other section stays one per row\(route): \(a) \(e)")
        }
    }

    /// Spacing in a section grid: columnSpacing between the cells of a row,
    /// lineSpacing between rows (the SSoT's "Spacing between columns" /
    /// "Spacing between rows"). Two flexible columns across 320pt put the
    /// second column (320 + s) / 2 to the right of the first; a 20pt cell
    /// puts the next row 20 + lineSpacing lower.
    private func spacing(_ attrs: String) throws -> (column: CGFloat, row: CGFloat) {
        let data = CollectionDataSource(sections: [
            CollectionDataSection(cells: (viewName: Self.cell, data: [["title": "b"], ["title": "c"], ["title": "d"]])),
        ])
        _ = try draw(", \"items\": \"@{items}\", \"columnSpacing\": 30, \"lineSpacing\": 12" + attrs, data: ["items": data])
        let (b, c, d) = (try frame("b"), try frame("c"), try frame("d"))
        return (2 * (c.minX - b.minX) - 320, d.minY - b.minY - 20)
    }

    func testASectionGridSpacesItsCellsByColumnSpacingAndItsRowsByLineSpacing() throws {
        let own = ", \"sections\": [{\"cell\": \"\(Self.cell)\", \"columns\": 2}]"
        for route in ["", ", \"lazy\": \"none\""] {
            let s = try spacing(own + route)
            XCTAssertEqual(s.column, 30, accuracy: 1, "between cells\(route)")
            XCTAssertEqual(s.row, 12, accuracy: 1, "between rows\(route)")
        }
    }

    /// The `lazy: none` grid of a columns-2 Collection read itemSpacing
    /// between its cells, leaving a declared columnSpacing unread; it reads
    /// columnSpacing now, as the lazy grid does (the control).
    func testTheNonLazyGridReadsColumnSpacingAsTheLazyGridDoes() throws {
        let grid = ", \"columns\": 2, \"sections\": [{\"cell\": \"\(Self.cell)\"}]"
        let nonLazy = try spacing(grid + ", \"lazy\": \"none\"")
        XCTAssertEqual(nonLazy.column, 30, accuracy: 1)
        XCTAssertEqual(nonLazy.row, 12, accuracy: 1)
        let lazy = try spacing(grid)
        XCTAssertEqual(lazy.column, 30, accuracy: 1, "control: the lazy grid")
        XCTAssertEqual(lazy.row, 12, accuracy: 1, "control: the lazy grid")
    }

    // MARK: - horizontal: `columns` is the number of lanes

    private func horizontal(_ sections: [[String]], attrs: String, sectionColumns: [Int?]? = nil) throws {
        let configs = sections.indices.map { i -> String in
            if let c = sectionColumns?[i] { return "{\"cell\": \"\(Self.cell)\", \"columns\": \(c)}" }
            return "{\"cell\": \"\(Self.cell)\"}"
        }
        let source = CollectionDataSource(sections: sections.map { titles in
            CollectionDataSection(cells: (viewName: Self.cell, data: titles.map { ["title": $0] }))
        })
        _ = try draw(", \"items\": \"@{items}\", \"sections\": [\(configs.joined(separator: ", "))]" + attrs,
                     data: ["items": source])
    }

    /// 4f ruling (2026-09-26): `columns` on a horizontal Collection is its
    /// lanes (LazyHGrid rows), cells filling a column top to bottom and then
    /// the next — Android's LazyHorizontalGrid order. Before: one lane
    /// whatever `columns` said (b beside a).
    func testHorizontalColumnsAreLanesFilledColumnByColumn() throws {
        for route in [", \"layout\": \"horizontal\"", ", \"horizontalScroll\": true",
                      ", \"layout\": \"horizontal\", \"lazy\": \"eager\"", ", \"layout\": \"horizontal\", \"lazy\": \"none\""] {
            try horizontal([["a", "b", "c"]], attrs: ", \"columns\": 2" + route)
            let (a, b, c) = (try frame("a"), try frame("b"), try frame("c"))
            XCTAssertTrue(abs(b.minX - a.minX) < 1 && b.minY > a.maxY, "b under a\(route): \(a) \(b)")
            XCTAssertTrue(abs(c.minY - a.minY) < 1 && c.minX > a.maxX - 1, "c starts the next column\(route): \(a) \(c)")
        }
    }

    /// (Cells 40pt wide with no spacing touch: "beside" is `minX > maxX - 1`.)
    ///
    /// A section's own `columns` is its block's lanes, and each section is a
    /// block starting a new column: in a 2-lane Collection, [a] then [b c]
    /// puts b at the top of a new column, c under it.
    func testEachSectionIsABlockOfItsOwnLanes() throws {
        try horizontal([["a"], ["b", "c"]], attrs: ", \"layout\": \"horizontal\", \"columns\": 2")
        var (a, b, c) = (try frame("a"), try frame("b"), try frame("c"))
        XCTAssertTrue(abs(b.minY - a.minY) < 1 && b.minX > a.maxX - 1, "b starts a new column: \(a) \(b)")
        XCTAssertTrue(abs(c.minX - b.minX) < 1 && c.minY > b.maxY, "c under b: \(b) \(c)")
        // A 1-lane Collection whose second section declares 2 lanes.
        try horizontal([["a"], ["b", "c"]], attrs: ", \"layout\": \"horizontal\"", sectionColumns: [nil, 2])
        (a, b, c) = (try frame("a"), try frame("b"), try frame("c"))
        XCTAssertTrue(b.minX > a.maxX - 1, "the block follows a: \(a) \(b)")
        XCTAssertTrue(abs(c.minX - b.minX) < 1 && c.minY > b.maxY, "c under b in the 2-lane block: \(b) \(c)")
    }

    /// The rule: along the scroll axis, lineSpacing (else itemSpacing)
    /// between successive columns of cells; between lanes, columnSpacing
    /// (else itemSpacing). The 40pt-wide cell puts the next column 40 +
    /// alongScroll to the right; two equal lanes put b (H + betweenLanes) / 2
    /// under a, so betweenLanes is twice the change against betweenLanes 0.
    func testAHorizontalGridSpacesTheScrollAxisByLineSpacingAndTheLanesByColumnSpacing() throws {
        let base = ", \"layout\": \"horizontal\", \"columns\": 2"
        try horizontal([["a", "b", "c"]], attrs: base + ", \"lineSpacing\": 12, \"columnSpacing\": 30")
        let (a, b, c) = (try frame("a"), try frame("b"), try frame("c"))
        try horizontal([["a", "b", "c"]], attrs: base + ", \"lineSpacing\": 12")
        let (a0, b0) = (try frame("a"), try frame("b"))
        XCTAssertEqual(c.minX - a.minX - 40, 12, accuracy: 1, "along the scroll axis: lineSpacing")
        XCTAssertEqual(2 * ((b.minY - a.minY) - (b0.minY - a0.minY)), 30, accuracy: 1, "between lanes: columnSpacing")
        // itemSpacing stands in for either.
        try horizontal([["a", "b", "c"]], attrs: base + ", \"itemSpacing\": 20")
        let (ai, ci) = (try frame("a"), try frame("c"))
        XCTAssertEqual(ci.minX - ai.minX - 40, 20, accuracy: 1, "itemSpacing along the scroll axis")
    }

    /// One rule for every horizontal Collection, a single lane included
    /// (4f ruling, 2026-09-26): along the scroll axis lineSpacing, else
    /// itemSpacing, else 0 — so columnSpacing alone spaces nothing along it.
    /// The single-lane stack read columnSpacing, else itemSpacing, else
    /// lineSpacing (measured before: 30 where lineSpacing said 12).
    func testOneLaneSpacesTheScrollAxisByTheSameRule() throws {
        for route in [", \"layout\": \"horizontal\"", ", \"horizontalScroll\": true",
                      ", \"layout\": \"horizontal\", \"lazy\": \"eager\"", ", \"layout\": \"horizontal\", \"lazy\": \"none\""] {
            func gap(_ spacing: String) throws -> CGFloat {
                try horizontal([["a", "b"]], attrs: route + spacing)
                let (a, b) = (try frame("a"), try frame("b"))
                XCTAssertEqual(b.minY, a.minY, accuracy: 1, "one lane\(route)")
                return b.minX - a.maxX
            }
            XCTAssertEqual(try gap(", \"columnSpacing\": 30, \"lineSpacing\": 12"), 12, accuracy: 1, "lineSpacing wins\(route)")
            XCTAssertEqual(try gap(", \"columnSpacing\": 30"), 0, accuracy: 1, "columnSpacing is not along the axis\(route)")
            XCTAssertEqual(try gap(", \"itemSpacing\": 20"), 20, accuracy: 1, "itemSpacing stands in\(route)")
            XCTAssertEqual(try gap(", \"lineSpacing\": 8"), 8, accuracy: 1, "lineSpacing alone (the faces' carousels)\(route)")
        }
    }

    /// Between pages, too: the page wrapper is built with the rule's value
    /// (read from what the converter builds — a page is full width, so its
    /// padding moves no cell).
    func testPagingSpacesItsPagesByTheSameRule() throws {
        func pageSpacing(_ spacing: String) throws -> CGFloat? {
            let json = "{\"type\": \"Collection\", \"id\": \"c\", \"items\": \"@{items}\", \"layout\": \"horizontal\", \"paging\": true, \"sections\": [{\"cell\": \"\(Self.cell)\"}]\(spacing)}"
            let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
            var found: CGFloat?
            func walk(_ value: Any, _ depth: Int) {
                guard found == nil, depth < 200 else { return }
                if value is DynamicComponent || value is [String: Any] { return }
                let mirror = Mirror(reflecting: value)
                if String(describing: type(of: value)).hasSuffix("PagingCollectionWrapperView") {
                    found = mirror.children.first { $0.label == "itemSpacing" }?.value as? CGFloat
                    return
                }
                for child in mirror.children { walk(child.value, depth + 1) }
                var superMirror = mirror.superclassMirror
                while let m = superMirror {
                    for child in m.children { walk(child.value, depth + 1) }
                    superMirror = m.superclassMirror
                }
            }
            walk(CollectionConverter.convert(component: component, data: ["items": dataSource()]), 0)
            return found
        }
        XCTAssertEqual(try pageSpacing(", \"columnSpacing\": 30, \"lineSpacing\": 12"), 12)
        XCTAssertEqual(try pageSpacing(", \"columnSpacing\": 30"), 0)
        XCTAssertEqual(try pageSpacing(", \"itemSpacing\": 8"), 8, "the face's paging carousel")
    }

    /// Control: declared sections keep a grid per section (b starts a row).
    func testDeclaredSectionsKeepAGridEach() throws {
        let sectioned = ", \"items\": \"@{items}\", \"columns\": 2, \"sections\": [{\"cell\": \"\(Self.cell)\"}, {\"cell\": \"\(Self.cell)\"}]"
        for route in ["", ", \"lazy\": \"none\""] {
            let p = try placement(sectioned + route)
            XCTAssertFalse(p.bBesideA, "sectioned\(route)")
        }
    }

    // MARK: - flow spacing (jsonui-cli attribute_semantics.json -> collectionSpacing)

    /// The three gaps a flow draws, measured: between the cells of a line,
    /// between lines, between the section blocks. The first section holds
    /// nine 40pt cells — more than a 320pt line holds at any gap here, so it
    /// wraps; the second holds one.
    private func flowGaps(_ attrs: String) throws -> (cells: CGFloat, lines: CGFloat, sections: CGFloat) {
        let first = (0..<9).map { "f\($0)" }
        let source = CollectionDataSource(sections: [
            CollectionDataSection(cells: (viewName: Self.cell, data: first.map { ["title": $0] })),
            CollectionDataSection(cells: (viewName: Self.cell, data: [["title": "z"]])),
        ])
        let flow = ", \"layout\": \"flow\", \"items\": \"@{items}\", \"sections\": [{\"cell\": \"\(Self.cell)\"}, {\"cell\": \"\(Self.cell)\"}]"
        _ = try draw(flow + attrs, data: ["items": source])
        let cells = try first.map { try frame($0) }
        let secondLine = try XCTUnwrap(cells.first { $0.minY > cells[0].minY + 1 }, "the first section did not wrap\(attrs)")
        let lastRow = try XCTUnwrap(cells.map(\.maxY).max())
        return (cells[1].minX - cells[0].maxX, secondLine.minY - cells[0].maxY, try frame("z").minY - lastRow)
    }

    /// 4f ruling (2026-09-26): an undeclared gap is 0 on every route, flow
    /// included. Before: the lazy flow drew 8 between cells and lines and
    /// left the blocks to the ScrollView's own stack spacing; the `lazy:
    /// none` flow drew 8 between cells and lines.
    func testAnUndeclaredFlowGapIsZero() throws {
        for route in ["", ", \"lazy\": \"none\""] {
            let g = try flowGaps(route)
            XCTAssertEqual(g.cells, 0, accuracy: 0.5, "between cells\(route)")
            XCTAssertEqual(g.lines, 0, accuracy: 0.5, "between lines\(route)")
            XCTAssertEqual(g.sections, 0, accuracy: 0.5, "between the section blocks\(route)")
        }
    }

    /// A declared gap is drawn as declared: columnSpacing between cells,
    /// lineSpacing between lines and blocks, itemSpacing the fallback for
    /// both — and a declared 0 is 0 (the `lazy: none` flow drew 8 for it).
    /// sectionSpacing is lineSpacing's alias (SSoT `aliases`), as a layout
    /// that has not been normalised may spell it: alone it is lineSpacing —
    /// the lines and the section blocks; with lineSpacing, the canonical
    /// lineSpacing wins (4f ruling 2026-09-26, round 6; the typed attribute
    /// reads the canonical key first — this pins it, as sjui codegen now
    /// reads it too).
    func testSectionSpacingIsLineSpacingsAlias() throws {
        for route in ["", ", \"lazy\": \"none\""] {
            let alone = try flowGaps(", \"sectionSpacing\": 12" + route)
            XCTAssertEqual(alone.lines, 12, accuracy: 0.5, "the alias alone: the lines\(route)")
            XCTAssertEqual(alone.sections, 12, accuracy: 0.5, "the alias alone: the blocks\(route)")
            let both = try flowGaps(", \"sectionSpacing\": 12, \"lineSpacing\": 4" + route)
            XCTAssertEqual(both.lines, 4, accuracy: 0.5, "both: the lines\(route)")
            XCTAssertEqual(both.sections, 4, accuracy: 0.5, "both: the blocks\(route)")
        }
    }

    /// A flow section's declared header and footer are rows of their own —
    /// the header above the section's wrap, the footer below, at the leading
    /// edge, spaced as the lines (4f ruling 2026-09-26, round 7). Measured
    /// frames: section 1 (header, cells a b, footer), section 2 (header h2 —
    /// the other probe, so it records apart — and cell c), lineSpacing 4.
    /// Before, the lazy flow drew no header or footer.
    func testAFlowSectionsHeaderAndFooterAreRowsAroundItsWrap() throws {
        let source = CollectionDataSource(sections: [
            CollectionDataSection(
                header: (viewName: Self.header, data: [:]),
                cells: (viewName: Self.cell, data: [["title": "a"], ["title": "b"]]),
                footer: (viewName: Self.footer, data: [:])
            ),
            CollectionDataSection(
                header: (viewName: Self.otherCell, data: ["title": "h2"]),
                cells: (viewName: Self.cell, data: [["title": "c"]])
            ),
        ])
        let flow = ", \"layout\": \"flow\", \"lineSpacing\": 4, \"items\": \"@{items}\", \"sections\": [" +
            "{\"cell\": \"\(Self.cell)\", \"header\": \"\(Self.header)\", \"footer\": \"\(Self.footer)\"}, " +
            "{\"cell\": \"\(Self.cell)\", \"header\": \"\(Self.otherCell)\"}]"
        for route in ["", ", \"lazy\": \"none\""] {
            let drawn = try draw(flow + route, data: ["items": source])
            XCTAssertTrue(drawn.isSuperset(of: ["header", "footer", "other:h2", "cell:a", "cell:b", "cell:c"]), "drawn\(route): \(drawn)")
            guard let header = Self.frames["header"], let footer = Self.frames["footer"], let h2 = Self.frames["other:h2"] else { continue }
            let (a, b, c) = (try frame("a"), try frame("b"), try frame("c"))
            XCTAssertEqual(header.minX, a.minX, accuracy: 0.5, "the header at the leading edge\(route)")
            XCTAssertEqual(a.minY - header.maxY, 4, accuracy: 0.5, "header, then the wrap, a line apart\(route)")
            XCTAssertEqual(b.minY, a.minY, accuracy: 0.5, "the cells share their line\(route)")
            XCTAssertEqual(footer.minY - max(a.maxY, b.maxY), 4, accuracy: 0.5, "the wrap, then the footer\(route)")
            XCTAssertEqual(h2.minY - footer.maxY, 4, accuracy: 0.5, "section 2's header under section 1's footer\(route)")
            XCTAssertEqual(c.minY - h2.maxY, 4, accuracy: 0.5, "section 2's wrap under its header\(route)")
        }
    }

    func testADeclaredFlowGapIsDrawnAsDeclared() throws {
        let cases: [(String, (CGFloat, CGFloat, CGFloat))] = [
            (", \"columnSpacing\": 10, \"lineSpacing\": 4", (10, 4, 4)),
            (", \"itemSpacing\": 6", (6, 6, 6)),
            (", \"lineSpacing\": 0, \"columnSpacing\": 0, \"itemSpacing\": 6", (0, 0, 0)),
        ]
        for route in ["", ", \"lazy\": \"none\""] {
            for (attrs, want) in cases {
                let g = try flowGaps(attrs + route)
                XCTAssertEqual(g.cells, want.0, accuracy: 0.5, "between cells\(attrs)\(route)")
                XCTAssertEqual(g.lines, want.1, accuracy: 0.5, "between lines\(attrs)\(route)")
                XCTAssertEqual(g.sections, want.2, accuracy: 0.5, "between the section blocks\(attrs)\(route)")
            }
        }
    }
}
#endif
