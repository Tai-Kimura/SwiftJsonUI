//
//  SelectBoxPickReportTests.swift
//  SwiftJsonUITests
//
//  What a SelectBox's onValueChange is handed on the Dynamic path, by the
//  closure the data holds for it (SelectBoxConverter.reportPick; 4f's ruling
//  on control-onclick-is-called-differently-on-every-path, 1.9.0): `(String)`
//  the picked item, even with selectedIndex bound; `(String, Int)` the viewId
//  and the index; `(String, String)` the viewId and the item; `(Int)` the
//  index; `()` nothing. A date has no index: a handler taking an Int is not
//  called for it, and is named once (4f's ruling, 1.9.0). End to end, on both
//  iOS paths: ConformanceHost PickArityProbeUITests.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class SelectBoxPickReportTests: XCTestCase {

    /// The calls one handler made, as `name(args)`.
    private var calls: [String] = []

    private func handlers() -> [String: Any] {
        [
            "item": { (item: String) -> Void in self.calls.append("item(\(item))") },
            "named": { (id: String, item: String) -> Void in self.calls.append("named(\(id),\(item))") },
            "indexed": { (id: String, index: Int) -> Void in self.calls.append("indexed(\(id),\(index))") },
            "index": { (index: Int) -> Void in self.calls.append("index(\(index))") },
            "bare": { () -> Void in self.calls.append("bare()") },
        ]
    }

    private func report(_ handler: String, index: Int?) -> [String] {
        calls = []
        SelectBoxConverter.reportPick("@{\(handler)}", id: "box", picked: "b", index: index, data: handlers())
        return calls
    }

    func testEachDeclarationIsHandedWhatItAsksFor() {
        // A list's pick: the item "b" at index 1.
        XCTAssertEqual(report("item", index: 1), ["item(b)"])
        XCTAssertEqual(report("named", index: 1), ["named(box,b)"])
        XCTAssertEqual(report("indexed", index: 1), ["indexed(box,1)"])
        XCTAssertEqual(report("index", index: 1), ["index(1)"])
        XCTAssertEqual(report("bare", index: 1), ["bare()"])
    }

    func testThePromptIsIndexMinusOne() {
        // The prompt: no item, index -1.
        XCTAssertEqual(report("indexed", index: -1), ["indexed(box,-1)"])
    }

    func testADateHasNoIndex() {
        XCTAssertEqual(report("item", index: nil), ["item(b)"])
        XCTAssertEqual(report("named", index: nil), ["named(box,b)"])
        XCTAssertEqual(report("indexed", index: nil), [])
        XCTAssertEqual(report("index", index: nil), [])
        XCTAssertEqual(report("bare", index: nil), ["bare()"])
    }

    /// A date's handler that takes an index is named, once per box and
    /// handler, in the build's sentence; a list's never is.
    func testADateHandlerTakingAnIndexIsNamedOnce() {
        var said: [String] = []
        SelectBoxConverter.warningHandler = { said.append($0) }
        defer { SelectBoxConverter.warningHandler = nil }
        let box = "date-\(UUID().uuidString)"
        for _ in 0..<3 {
            SelectBoxConverter.reportPick("@{indexed}", id: box, picked: "2026-01-03", index: nil, data: handlers())
        }
        SelectBoxConverter.reportPick("@{index}", id: box, picked: "2026-01-03", index: nil, data: handlers())
        SelectBoxConverter.reportPick("@{indexed}", id: box, picked: "b", index: 1, data: handlers())
        SelectBoxConverter.reportPick("@{named}", id: box, picked: "2026-01-03", index: nil, data: handlers())
        XCTAssertEqual(said, [
            "[SelectBox] \(box): onValueChange 'indexed' is not called: a date SelectBox has no index: declare onValueChange as (String) or (String, String)",
            "[SelectBox] \(box): onValueChange 'index' is not called: a date SelectBox has no index: declare onValueChange as (String) or (String, String)",
        ])
    }

    func testAHandlerTheDataDoesNotHoldIsNotCalled() {
        XCTAssertEqual(report("missing", index: 1), [])
        calls = []
        SelectBoxConverter.reportPick("@{item}", id: "box", picked: "b", index: 1, data: ["item": "not a closure"])
        XCTAssertEqual(calls, [])
    }

    /// `selectItemType` as declared: "Date" is a date picker, anything else
    /// — "date" too — a list (4f's ruling, 1.9.0; the codegen's comparison).
    func testSelectItemTypeIsReadAsDeclared() throws {
        func type(_ json: String) throws -> SelectBoxView.SelectItemType {
            SelectBoxConverter.itemType(of: try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8)))
        }
        XCTAssertEqual(try type(#"{"type":"SelectBox","selectItemType":"Date"}"#), .date)
        XCTAssertEqual(try type(#"{"type":"SelectBox","selectItemType":"Normal"}"#), .normal)
        XCTAssertEqual(try type(#"{"type":"SelectBox"}"#), .normal)
        XCTAssertEqual(try type(#"{"type":"SelectBox","selectItemType":"date"}"#), .normal)
    }
}
#endif
