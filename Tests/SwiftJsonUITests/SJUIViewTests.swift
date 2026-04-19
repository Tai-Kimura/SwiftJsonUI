//
//  SJUIViewTests.swift
//  SwiftJsonUITests
//
//  Tests for the SJUIView class
//

import XCTest
@testable import SwiftJsonUI

@MainActor
final class SJUIViewTests: XCTestCase {

    // MARK: - Basic Tests

    func testViewInitialization() {
        let view = SJUIView()

        XCTAssertNotNil(view)
        XCTAssertFalse(view.highlighted)
        XCTAssertFalse(view.canTap)
        XCTAssertNil(view.highlightBackgroundColor)
        XCTAssertEqual(view.touchDisabledState, .none)
        XCTAssertEqual(view._views.count, 0)
    }

    func testViewClassProperty() {
        let viewClass = SJUIView.viewClass
        XCTAssertTrue(viewClass == SJUIView.self)
    }

    // MARK: - ViewHolder Protocol Tests

    func testViewsProperty() {
        let view = SJUIView()

        XCTAssertEqual(view._views.count, 0)

        let subview = UILabel()
        view._views["testView"] = subview

        XCTAssertEqual(view._views.count, 1)
        XCTAssertTrue(view._views["testView"] === subview)
    }

    // MARK: - Touch Handling Tests

    func testCanTapProperty() {
        let view = SJUIView()

        XCTAssertFalse(view.canTap)

        view.canTap = true
        XCTAssertTrue(view.canTap)
    }

    func testOnBeginTapWithoutCanTap() {
        let view = SJUIView()
        view.canTap = false
        view.tapBackgroundColor = .red

        let originalColor = view.backgroundColor

        view.onBeginTap()

        XCTAssertEqual(view.backgroundColor, originalColor)
    }

    func testOnBeginTapWithCanTap() {
        let view = SJUIView()
        view.canTap = true
        view.tapBackgroundColor = .red

        view.onBeginTap()

        XCTAssertEqual(view.backgroundColor, .red)
    }

    func testOnEndTapWithDefaultBackground() {
        let view = SJUIView()
        view.canTap = true
        view.defaultBackgroundColor = .white
        view.backgroundColor = .red

        view.onEndTap()

        XCTAssertEqual(view.backgroundColor, .white)
    }

    func testOnEndTapWithHighlightedState() {
        let view = SJUIView()
        view.canTap = true
        view.highlighted = true
        view.highlightBackgroundColor = .yellow
        view.backgroundColor = .red

        view.onEndTap()

        XCTAssertEqual(view.backgroundColor, .yellow)
    }

    // MARK: - Touch Disabled State Tests

    func testTouchDisabledStateNone() {
        let view = SJUIView()
        view.touchDisabledState = .none

        XCTAssertEqual(view.touchDisabledState, .none)
    }

    func testTouchDisabledStateOnlyMe() {
        let view = SJUIView()
        view.touchDisabledState = .onlyMe

        XCTAssertEqual(view.touchDisabledState, .onlyMe)
    }

    func testTouchDisabledStateViewsWithoutTouchEnabled() {
        let view = SJUIView()
        view.touchDisabledState = .viewsWithoutTouchEnabled

        XCTAssertEqual(view.touchDisabledState, .viewsWithoutTouchEnabled)
    }

    func testTouchDisabledStateViewsWithoutInList() {
        let view = SJUIView()
        view.touchDisabledState = .viewsWithoutInList

        XCTAssertEqual(view.touchDisabledState, .viewsWithoutInList)
    }

    // MARK: - Highlight Tests

    func testHighlightedProperty() {
        let view = SJUIView()

        XCTAssertFalse(view.highlighted)

        view.highlighted = true
        XCTAssertTrue(view.highlighted)
    }

    func testHighlightBackgroundColor() {
        let view = SJUIView()

        XCTAssertNil(view.highlightBackgroundColor)

        view.highlightBackgroundColor = .yellow
        XCTAssertEqual(view.highlightBackgroundColor, .yellow)
    }

    // MARK: - Orientation Tests

    func testOrientationVertical() {
        let view = SJUIView()
        view.orientation = .vertical

        XCTAssertEqual(view.orientation, .vertical)
    }

    func testOrientationHorizontal() {
        let view = SJUIView()
        view.orientation = .horizontal

        XCTAssertEqual(view.orientation, .horizontal)
    }

    func testOrientationNil() {
        let view = SJUIView()

        XCTAssertNil(view.orientation)
    }

    // MARK: - Direction Tests

    func testDirectionDefault() {
        let view = SJUIView()

        XCTAssertEqual(view.direction, .none)
    }

    func testDirectionTopToBottom() {
        let view = SJUIView()
        view.direction = .topToBottom

        XCTAssertEqual(view.direction, .topToBottom)
    }

    func testDirectionBottomToTop() {
        let view = SJUIView()
        view.direction = .bottomToTop

        XCTAssertEqual(view.direction, .bottomToTop)
    }

    func testDirectionLeftToRight() {
        let view = SJUIView()
        view.direction = .leftToRight

        XCTAssertEqual(view.direction, .leftToRight)
    }

    func testDirectionRightToLeft() {
        let view = SJUIView()
        view.direction = .rightToLeft

        XCTAssertEqual(view.direction, .rightToLeft)
    }

    // MARK: - CreateFromJSON Tests

    func testCreateFromJSONBasic() {
        let json = JSON([:])

        let target = NSObject()
        var views = [String: UIView]()

        let view = SJUIView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertNotNil(view)
        XCTAssertFalse(view.highlighted)
        XCTAssertFalse(view.canTap)
    }

    func testCreateFromJSONWithVerticalOrientation() {
        let json = JSON([
            "orientation": "vertical"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let view = SJUIView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(view.orientation, .vertical)
        XCTAssertEqual(view.direction, .topToBottom)
    }

    func testCreateFromJSONWithHorizontalOrientation() {
        let json = JSON([
            "orientation": "horizontal"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let view = SJUIView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(view.orientation, .horizontal)
        XCTAssertEqual(view.direction, .leftToRight)
    }

    func testCreateFromJSONWithBottomToTopDirection() {
        let json = JSON([
            "orientation": "vertical",
            "direction": "bottomToTop"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let view = SJUIView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(view.orientation, .vertical)
        XCTAssertEqual(view.direction, .bottomToTop)
    }

    func testCreateFromJSONWithRightToLeftDirection() {
        let json = JSON([
            "orientation": "horizontal",
            "direction": "rightToLeft"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let view = SJUIView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertEqual(view.orientation, .horizontal)
        XCTAssertEqual(view.direction, .rightToLeft)
    }

    func testCreateFromJSONWithHighlighted() {
        let json = JSON([
            "highlighted": true
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let view = SJUIView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertTrue(view.highlighted)
    }

    func testCreateFromJSONWithCanTap() {
        let json = JSON([
            "canTap": true
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let view = SJUIView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertTrue(view.canTap)
    }

    func testCreateFromJSONWithCanTapFalse() {
        let json = JSON([
            "canTap": false
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let view = SJUIView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertFalse(view.canTap)
    }

    // MARK: - Touch Enabled View IDs Tests

    func testTouchEnabledViewIdsDefault() {
        let view = SJUIView()

        XCTAssertEqual(view.touchEnabledViewIds.count, 0)
    }

    func testTouchEnabledViewIdsAdd() {
        let view = SJUIView()
        view.touchEnabledViewIds.append("view1")
        view.touchEnabledViewIds.append("view2")

        XCTAssertEqual(view.touchEnabledViewIds.count, 2)
        XCTAssertTrue(view.touchEnabledViewIds.contains("view1"))
        XCTAssertTrue(view.touchEnabledViewIds.contains("view2"))
    }

    // MARK: - Edge Cases

    func testMultipleOrientationChanges() {
        let view = SJUIView()

        view.orientation = .vertical
        XCTAssertEqual(view.orientation, .vertical)

        view.orientation = .horizontal
        XCTAssertEqual(view.orientation, .horizontal)

        view.orientation = nil
        XCTAssertNil(view.orientation)
    }

    func testMultipleHighlightStateChanges() {
        let view = SJUIView()

        for _ in 0..<5 {
            view.highlighted = true
            XCTAssertTrue(view.highlighted)

            view.highlighted = false
            XCTAssertFalse(view.highlighted)
        }
    }

    func testCreateFromJSONGradientView() {
        let json = JSON([
            "type": "GradientView"
        ])

        let target = NSObject()
        var views = [String: UIView]()

        let view = SJUIView.createFromJSON(attr: json, target: target, views: &views)

        XCTAssertTrue(view is GradientView)
    }
}
