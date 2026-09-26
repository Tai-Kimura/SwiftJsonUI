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

    /// The codegen's paging route reads `sections[].cell` only.
    func testThePagingRouteDrawsNothingWithoutSections() throws {
        XCTAssertEqual(try draw(items + ", \"layout\": \"horizontal\", \"paging\": true"), [])
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
        XCTAssertEqual(try draw(headed + ", \"layout\": \"horizontal\", \"paging\": true"), [])
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

    /// Control: declared sections keep a grid per section (b starts a row).
    func testDeclaredSectionsKeepAGridEach() throws {
        let sectioned = ", \"items\": \"@{items}\", \"columns\": 2, \"sections\": [{\"cell\": \"\(Self.cell)\"}, {\"cell\": \"\(Self.cell)\"}]"
        for route in ["", ", \"lazy\": \"none\""] {
            let p = try placement(sectioned + route)
            XCTAssertFalse(p.bBesideA, "sectioned\(route)")
        }
    }
}
#endif
