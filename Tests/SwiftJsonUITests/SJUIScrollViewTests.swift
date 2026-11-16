//
//  SJUIScrollViewTests.swift
//  SwiftJsonUITests
//
//  Tests for the SJUIScrollView class
//

import XCTest
@testable import SwiftJsonUI

final class SJUIScrollViewTests: XCTestCase {

    // MARK: - Basic Tests

    func testScrollViewInitialization() {
        let scrollView = SJUIScrollView()

        XCTAssertNotNil(scrollView)
    }

    func testViewClassProperty() {
        let viewClass = SJUIScrollView.viewClass
        XCTAssertTrue(viewClass == SJUIScrollView.self)
    }

    // MARK: - CreateFromJSON Tests

    func testCreateFromJSONBasic() {
        let json = JSON([:])

        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNotNil(scrollView)
    }

    func testCreateFromJSONWithShowsHorizontalScrollIndicatorTrue() {
        let json = JSON([
            "showsHorizontalScrollIndicator": true
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertTrue(scrollView.showsHorizontalScrollIndicator)
    }

    func testCreateFromJSONWithShowsHorizontalScrollIndicatorFalse() {
        let json = JSON([
            "showsHorizontalScrollIndicator": false
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertFalse(scrollView.showsHorizontalScrollIndicator)
    }

    func testCreateFromJSONWithShowsVerticalScrollIndicatorTrue() {
        let json = JSON([
            "showsVerticalScrollIndicator": true
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertTrue(scrollView.showsVerticalScrollIndicator)
    }

    func testCreateFromJSONWithShowsVerticalScrollIndicatorFalse() {
        let json = JSON([
            "showsVerticalScrollIndicator": false
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertFalse(scrollView.showsVerticalScrollIndicator)
    }

    func testCreateFromJSONDefaultScrollIndicators() {
        let json = JSON([:])

        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        // Default values should be false (JSON default is false)
        XCTAssertFalse(scrollView.showsHorizontalScrollIndicator)
        XCTAssertFalse(scrollView.showsVerticalScrollIndicator)
    }

    // MARK: - ContentInsetAdjustmentBehavior Tests

    @available(iOS 11.0, *)
    func testCreateFromJSONWithContentInsetAutomatic() {
        let json = JSON([
            "contentInsetAdjustmentBehavior": "automatic"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(scrollView.contentInsetAdjustmentBehavior, .automatic)
    }

    @available(iOS 11.0, *)
    func testCreateFromJSONWithContentInsetAlways() {
        let json = JSON([
            "contentInsetAdjustmentBehavior": "always"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(scrollView.contentInsetAdjustmentBehavior, .always)
    }

    @available(iOS 11.0, *)
    func testCreateFromJSONWithContentInsetNever() {
        let json = JSON([
            "contentInsetAdjustmentBehavior": "never"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(scrollView.contentInsetAdjustmentBehavior, .never)
    }

    @available(iOS 11.0, *)
    func testCreateFromJSONWithContentInsetScrollableAxes() {
        let json = JSON([
            "contentInsetAdjustmentBehavior": "scrollableAxes"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(scrollView.contentInsetAdjustmentBehavior, .scrollableAxes)
    }

    @available(iOS 11.0, *)
    func testCreateFromJSONWithInvalidContentInset() {
        let json = JSON([
            "contentInsetAdjustmentBehavior": "invalid"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(scrollView.contentInsetAdjustmentBehavior, .never)
    }

    // MARK: - Zoom Scale Tests

    func testCreateFromJSONWithMaximumZoomScale() {
        let json = JSON([
            "maxZoom": 3.0
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(scrollView.maximumZoomScale, 3.0)
    }

    func testCreateFromJSONWithMinimumZoomScale() {
        let json = JSON([
            "minZoom": 0.5
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(scrollView.minimumZoomScale, 0.5)
    }

    func testCreateFromJSONWithBothZoomScales() {
        let json = JSON([
            "minZoom": 0.25,
            "maxZoom": 4.0
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(scrollView.minimumZoomScale, 0.25)
        XCTAssertEqual(scrollView.maximumZoomScale, 4.0)
    }

    // MARK: - Corner Radius Tests

    func testCreateFromJSONWithCornerRadius() {
        let json = JSON([
            "cornerRadius": 12.0
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(scrollView.layer.cornerRadius, 12.0)
    }

    func testCreateFromJSONWithoutCornerRadius() {
        let json = JSON([:])

        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(scrollView.layer.cornerRadius, 0.0)
    }

    // MARK: - Delegate Tests

    func testCreateFromJSONWithDelegate() {
        class TestDelegate: NSObject, UIScrollViewDelegate {}

        let json = JSON([:])
        let target = TestDelegate()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNotNil(scrollView.delegate)
        XCTAssertTrue(scrollView.delegate === target)
    }

    func testCreateFromJSONWithoutDelegate() {
        let json = JSON([:])
        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNil(scrollView.delegate)
    }

    // MARK: - Edge Cases

    func testCreateFromJSONWithAllProperties() {
        let json = JSON([
            "showsHorizontalScrollIndicator": true,
            "showsVerticalScrollIndicator": false,
            "contentInsetAdjustmentBehavior": "never",
            "maxZoom": 5.0,
            "minZoom": 0.1,
            "cornerRadius": 8.0
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertTrue(scrollView.showsHorizontalScrollIndicator)
        XCTAssertFalse(scrollView.showsVerticalScrollIndicator)
        XCTAssertEqual(scrollView.maximumZoomScale, 5.0, accuracy: 0.0001)
        XCTAssertEqual(scrollView.minimumZoomScale, 0.1, accuracy: 0.0001)
        XCTAssertEqual(scrollView.layer.cornerRadius, 8.0, accuracy: 0.0001)

        if #available(iOS 11.0, *) {
            XCTAssertEqual(scrollView.contentInsetAdjustmentBehavior, .never)
        }
    }

    func testCreateFromJSONWithEmptyJSON() {
        let json = JSON([:])

        let target = NSObject()
        var views = [String: UIView]()

        let scrollView = SJUIScrollView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNotNil(scrollView)
        XCTAssertFalse(scrollView.showsHorizontalScrollIndicator)
        XCTAssertFalse(scrollView.showsVerticalScrollIndicator)
    }
}
