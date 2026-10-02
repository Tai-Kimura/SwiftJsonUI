//
//  BareHandlerNameTests.swift
//  SwiftJsonUITests
//
//  A Collection's onValueChange (onPageChanged) and onItemAppear, and a
//  TabView's onValueChange, are declared with a "string" type
//  (attribute_definitions): the bare name is a declared form, as the binding
//  is. Until 10.29.2 Dynamic read the binding form only and dropped a bare
//  name, as jsonui-cli's generators did until 1.9.6 (ticket
//  bare-event-handler-is-dropped-without-a-warning).
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class BareHandlerNameTests: XCTestCase {

    private func component(_ json: [String: Any]) throws -> DynamicComponent {
        try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: json))
    }

    private func pager(_ extra: [String: Any]) throws -> DynamicComponent {
        var json: [String: Any] = ["type": "Collection", "id": "pager", "items": "@{rows}",
                                   "layout": "horizontal", "paging": true]
        json.merge(extra) { _, new in new }
        return try component(json)
    }

    /// The closure the name resolves to, called once: the page it got, or nil.
    private func called(_ resolve: ([String: Any]) -> ((Int) -> Void)?) -> Int? {
        var got: Int?
        let data: [String: Any] = ["h": { (page: Int) in got = page } as (Int) -> Void]
        resolve(data)?(2)
        return got
    }

    func testThePageChangeCallbackTakesTheBindingOrTheBareName() throws {
        for key in ["onValueChange", "onPageChanged", "onValueChanged"] {
            for value in ["@{h}", "h"] {
                let c = try pager([key: value])
                XCTAssertEqual(called { CollectionConverter.pageChangeCallback(component: c, data: $0) }, 2, "\(key): \(value)")
            }
        }
    }

    func testTheItemAppearCallbackTakesTheBindingOrTheBareName() throws {
        for value in ["@{h}", "h"] {
            let c = try pager(["onItemAppear": value])
            XCTAssertEqual(called { CollectionConverter.itemAppearCallback(component: c, data: $0) }, 2, value)
        }
    }

    func testATabViewsChangeCallbackTakesTheBindingOrTheBareName() throws {
        for value in ["@{h}", "h"] {
            let c = try component(["type": "TabView", "id": "t", "tabs": [["title": "One"]], "onValueChange": value])
            XCTAssertEqual(called { TabViewConverter.tabChangeCallback(component: c, data: $0) }, 2, value)
        }
    }

    // Control: no handler, or a name the data does not hold, calls nothing.
    func testNoHandlerOrAnUnknownNameIsNil() throws {
        XCTAssertNil(CollectionConverter.pageChangeCallback(component: try pager([:]), data: [:]))
        XCTAssertNil(called { CollectionConverter.pageChangeCallback(component: try! self.pager(["onPageChanged": "other"]), data: $0) })
        XCTAssertNil(called { CollectionConverter.itemAppearCallback(component: try! self.pager(["onItemAppear": ""]), data: $0) })
        XCTAssertNil(TabViewConverter.tabChangeCallback(component: try component(["type": "TabView", "id": "t", "tabs": [["title": "One"]]]), data: [:]))
    }
}
#endif
