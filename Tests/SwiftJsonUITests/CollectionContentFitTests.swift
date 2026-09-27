//
//  CollectionContentFitTests.swift
//  SwiftJsonUITests
//
//  Which Dynamic Collections size to their content along their scroll axis
//  (CollectionConverter.fitsContent; 4f ruling 2026-09-27, the user's "size
//  to content"): the size there wrapContent or undeclared, and not the main
//  axis of a weighted stack. The drawing itself — a Collection its cells'
//  height, the view after it right under them, a bounded one still
//  scrolling — is CollectionFitProbeUITests in the ConformanceHost.
//

import XCTest
@testable import SwiftJsonUI

final class CollectionContentFitTests: XCTestCase {
    private func collection(_ attributes: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: Data(#"{"type": "Collection"\#(attributes)}"#.utf8))
    }

    func testAVerticalCollectionOfWrapContentOrUndeclaredHeightFits() throws {
        XCTAssertTrue(CollectionConverter.fitsContent(try collection(#", "height": "wrapContent""#), horizontal: false, data: [:]))
        XCTAssertTrue(CollectionConverter.fitsContent(try collection(""), horizontal: false, data: [:]))
    }

    func testANumberMatchParentOrBoundHeightDoesNotFit() throws {
        XCTAssertFalse(CollectionConverter.fitsContent(try collection(#", "height": 120"#), horizontal: false, data: [:]))
        XCTAssertFalse(CollectionConverter.fitsContent(try collection(#", "height": "matchParent""#), horizontal: false, data: [:]))
        XCTAssertFalse(CollectionConverter.fitsContent(try collection(#", "height": "@{h}""#), horizontal: false, data: [:]))
    }

    func testAHorizontalCollectionFitsOnItsWidth() throws {
        XCTAssertTrue(CollectionConverter.fitsContent(try collection(#", "width": "wrapContent", "height": 40"#), horizontal: true, data: [:]))
        XCTAssertFalse(CollectionConverter.fitsContent(try collection(#", "width": "matchParent""#), horizontal: true, data: [:]))
    }

    func testTheWeightedAxisFillsInstead() throws {
        let weighted: [String: Any] = ["__isWeightedChild": true, "__weightedParentOrientation": "vertical"]
        XCTAssertFalse(CollectionConverter.fitsContent(try collection(""), horizontal: false, data: weighted))
        XCTAssertTrue(CollectionConverter.fitsContent(try collection(""), horizontal: true, data: weighted))
    }
}
