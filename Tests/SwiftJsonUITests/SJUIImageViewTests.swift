//
//  SJUIImageViewTests.swift
//  SwiftJsonUITests
//
//  Tests for the SJUIImageView class
//

import XCTest
@testable import SwiftJsonUI

final class SJUIImageViewTests: XCTestCase {

    // MARK: - Basic Tests

    func testImageViewInitialization() {
        let imageView = SJUIImageView()

        XCTAssertNotNil(imageView)
        // canTap defaults to false on init, but createFromJSON sets it to true by default
        XCTAssertFalse(imageView.canTap)
        XCTAssertNil(imageView.image)
    }

    func testViewClassProperty() {
        let viewClass = SJUIImageView.viewClass
        XCTAssertTrue(viewClass == SJUIImageView.self)
    }

    // MARK: - Mask Tests

    func testSetMask() {
        let imageView = SJUIImageView()
        imageView.setMask()

        XCTAssertNotNil(imageView.filter)
        XCTAssertTrue(imageView.subviews.contains(imageView.filter!))
    }

    func testMaskConstraints() {
        let imageView = SJUIImageView()
        imageView.setMask()

        XCTAssertNotNil(imageView.filter)
        XCTAssertFalse(imageView.filter!.translatesAutoresizingMaskIntoConstraints)
    }

    func testMaskProperties() {
        let imageView = SJUIImageView()
        imageView.setMask()

        XCTAssertNotNil(imageView.filter)
        XCTAssertTrue(imageView.filter!.canTap)
        XCTAssertEqual(imageView.filter!.defaultBackgroundColor, .clear)
    }

    // MARK: - Touch Handling Tests

    func testOnBeginTapWithCanTap() {
        let imageView = SJUIImageView()
        imageView.canTap = true
        imageView.setMask()

        // Should not crash
        imageView.onBeginTap()

        XCTAssertTrue(true)
    }

    func testOnBeginTapWithoutCanTap() {
        let imageView = SJUIImageView()
        imageView.canTap = false
        imageView.setMask()

        // Should not crash
        imageView.onBeginTap()

        XCTAssertTrue(true)
    }

    func testOnEndTapWithCanTap() {
        let imageView = SJUIImageView()
        imageView.canTap = true
        imageView.setMask()

        // Should not crash
        imageView.onEndTap()

        XCTAssertTrue(true)
    }

    func testOnEndTapWithoutCanTap() {
        let imageView = SJUIImageView()
        imageView.canTap = false
        imageView.setMask()

        // Should not crash
        imageView.onEndTap()

        XCTAssertTrue(true)
    }

    // MARK: - CreateFromJSON Tests

    func testCreateFromJSONBasic() {
        let json = JSON([:])

        let target = NSObject()
        var views = [String: UIView]()

        let imageView = SJUIImageView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNotNil(imageView)
        XCTAssertTrue(imageView.clipsToBounds)
        XCTAssertNotNil(imageView.filter)
    }

    func testCreateFromJSONWithSrc() {
        let json = JSON([
            "src": "test_image"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let imageView = SJUIImageView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNotNil(imageView)
        // Image will be nil if test_image doesn't exist, which is expected
    }

    func testCreateFromJSONWithHighlightSrc() {
        let json = JSON([
            "src": "normal_image",
            "highlightSrc": "highlight_image"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let imageView = SJUIImageView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNotNil(imageView)
        // Images will be nil if they don't exist, which is expected
    }

    func testCreateFromJSONWithContentModeAspectFill() {
        let json = JSON([
            "contentMode": "AspectFill"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let imageView = SJUIImageView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(imageView.contentMode, .scaleAspectFill)
    }

    func testCreateFromJSONWithContentModeAspectFit() {
        let json = JSON([
            "contentMode": "AspectFit"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let imageView = SJUIImageView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(imageView.contentMode, .scaleAspectFit)
    }

    func testCreateFromJSONWithContentModeDefault() {
        let json = JSON([
            "contentMode": "Center"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let imageView = SJUIImageView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(imageView.contentMode, .center)
    }

    func testCreateFromJSONWithoutContentMode() {
        let json = JSON([:])

        let target = NSObject()
        var views = [String: UIView]()

        let imageView = SJUIImageView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(imageView.contentMode, .center)
    }

    func testCreateFromJSONWithCanTapTrue() {
        let json = JSON([
            "canTap": true
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let imageView = SJUIImageView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertTrue(imageView.canTap)
    }

    func testCreateFromJSONWithCanTapFalse() {
        let json = JSON([
            "canTap": false
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let imageView = SJUIImageView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertFalse(imageView.canTap)
    }

    func testCreateFromJSONDefaultCanTap() {
        let json = JSON([:])

        let target = NSObject()
        var views = [String: UIView]()

        let imageView = SJUIImageView.createFromJSON(attr: json, target: target, views: &views)

        // Default is true when using createFromJSON (line 104 in SJUIImageView.swift)
        XCTAssertTrue(imageView.canTap)
    }

    func testCreateFromJSONWithWrapContentWidth() {
        let json = JSON([
            "width": "wrapContent"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let imageView = SJUIImageView.createFromJSON(attr: json, target: target, views: &views)

        let priority = imageView.contentCompressionResistancePriority(for: .horizontal)
        XCTAssertEqual(priority, .required)
    }

    func testCreateFromJSONWithWrapContentHeight() {
        let json = JSON([
            "height": "wrapContent"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let imageView = SJUIImageView.createFromJSON(attr: json, target: target, views: &views)

        let priority = imageView.contentCompressionResistancePriority(for: .vertical)
        XCTAssertEqual(priority, .required)
    }

    func testCreateFromJSONWithHuggingPriorityWidth() {
        let json = JSON([
            "width": "wrapContent"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let imageView = SJUIImageView.createFromJSON(attr: json, target: target, views: &views)

        let priority = imageView.contentHuggingPriority(for: .horizontal)
        XCTAssertEqual(priority, .required)
    }

    func testCreateFromJSONWithHuggingPriorityHeight() {
        let json = JSON([
            "height": "wrapContent"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let imageView = SJUIImageView.createFromJSON(attr: json, target: target, views: &views)

        let priority = imageView.contentHuggingPriority(for: .vertical)
        XCTAssertEqual(priority, .required)
    }

    // MARK: - Edge Cases

    func testClipsToBoundsAlwaysEnabled() {
        let json = JSON([:])

        let target = NSObject()
        var views = [String: UIView]()

        let imageView = SJUIImageView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertTrue(imageView.clipsToBounds)
    }

    func testMultipleMaskCalls() {
        let imageView = SJUIImageView()

        imageView.setMask()
        let firstFilter = imageView.filter

        imageView.setMask()
        let secondFilter = imageView.filter

        // Each call should create a new filter
        XCTAssertNotNil(firstFilter)
        XCTAssertNotNil(secondFilter)
    }
}
