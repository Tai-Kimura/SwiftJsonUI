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

    private struct Probe: CustomComponentAdapter {
        let componentType: String
        let record: ([String: Any]) -> String
        func buildView(component: DynamicComponent, data: [String: Any], viewId: String?, parentOrientation: String?) -> AnyView {
            CollectionDeclaredCellsTests.drawn.append(record(data))
            return AnyView(Text(componentType).frame(width: 40, height: 20))
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
}
#endif
