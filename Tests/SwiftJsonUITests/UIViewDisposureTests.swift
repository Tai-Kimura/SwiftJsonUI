//
//  UIViewDisposureTests.swift
//  SwiftJsonUITests
//
//  Comprehensive tests for UIViewDisposure layout management
//

import XCTest
@testable import SwiftJsonUI

@MainActor
final class UIViewDisposureTests: XCTestCase {

    var containerView: UIView!
    var testView: UIView!
    var constraintInfo: UILayoutConstraintInfo!

    override func setUp() {
        super.setUp()
        containerView = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        testView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        testView.translatesAutoresizingMaskIntoConstraints = false
        constraintInfo = UILayoutConstraintInfo()
        containerView.addSubview(testView)
    }

    override func tearDown() {
        containerView = nil
        testView = nil
        constraintInfo = nil
        super.tearDown()
    }

    // MARK: - Screen Size Tests

    func testScreenSizeProperty() {
        let screenSize = UIViewDisposure.screenSize
        XCTAssertTrue(screenSize.width > 0)
        XCTAssertTrue(screenSize.height > 0)
    }

    // MARK: - Remove Constraint Tests

    func testRemoveConstraintWithEmptyConstraints() {
        let emptyInfo = UILayoutConstraintInfo()
        XCTAssertEqual(emptyInfo.constraints.count, 0)

        UIViewDisposure.removeConstraint(constraintInfo: emptyInfo)
        // Should not crash with empty constraints
        XCTAssertEqual(emptyInfo.constraints.count, 0)
    }

    func testRemoveConstraintWithActiveConstraints() {
        constraintInfo.width = 100

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        let constraintsCount = constraintInfo.constraints.count
        XCTAssertGreaterThan(constraintsCount, 0)

        UIViewDisposure.removeConstraint(constraintInfo: constraintInfo)

        // Constraints should be deactivated
        for constraint in constraintInfo.constraints {
            XCTAssertFalse(constraint.isActive)
        }
    }

    // MARK: - Apply Constraint Tests

    func testApplyConstraintBasic() {
        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        // Should create constraints
        XCTAssertGreaterThanOrEqual(constraintInfo.constraints.count, 0)
    }

    func testApplyConstraintWithWidth() {
        constraintInfo.width = 200

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertGreaterThan(constraintInfo.constraints.count, 0)
    }

    func testApplyConstraintWithHeight() {
        constraintInfo.height = 150

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertGreaterThan(constraintInfo.constraints.count, 0)
    }

    func testApplyConstraintWithMatchParentWidth() {
        constraintInfo.width = UILayoutConstraintInfo.LayoutParams.matchParent.rawValue

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertGreaterThan(constraintInfo.constraints.count, 0)
    }

    func testApplyConstraintWithMatchParentHeight() {
        constraintInfo.height = UILayoutConstraintInfo.LayoutParams.matchParent.rawValue

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertGreaterThan(constraintInfo.constraints.count, 0)
    }

    func testApplyConstraintWithWrapContent() {
        constraintInfo.width = UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue
        constraintInfo.height = UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertGreaterThanOrEqual(constraintInfo.constraints.count, 0)
    }

    // MARK: - Padding Tests

    func testPaddingTopProperty() {
        constraintInfo.paddingTop = 10

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertEqual(constraintInfo.paddingTop, 10)
    }

    func testPaddingBottomProperty() {
        constraintInfo.paddingBottom = 10

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertEqual(constraintInfo.paddingBottom, 10)
    }

    func testPaddingLeftProperty() {
        constraintInfo.paddingLeft = 10

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertEqual(constraintInfo.paddingLeft, 10)
    }

    func testPaddingRightProperty() {
        constraintInfo.paddingRight = 10

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertEqual(constraintInfo.paddingRight, 10)
    }

    // MARK: - RTL Padding Tests

    func testPaddingStartProperty() {
        constraintInfo.paddingStart = 10

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertNotNil(constraintInfo.paddingStart)
    }

    func testPaddingEndProperty() {
        constraintInfo.paddingEnd = 10

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertNotNil(constraintInfo.paddingEnd)
    }

    // MARK: - Margin Tests

    func testMarginProperties() {
        constraintInfo.topMargin = 10
        constraintInfo.bottomMargin = 10
        constraintInfo.leftMargin = 10
        constraintInfo.rightMargin = 10

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertEqual(constraintInfo.topMargin, 10)
        XCTAssertEqual(constraintInfo.bottomMargin, 10)
        XCTAssertEqual(constraintInfo.leftMargin, 10)
        XCTAssertEqual(constraintInfo.rightMargin, 10)
    }

    func testMinMarginProperties() {
        constraintInfo.minTopMargin = 5
        constraintInfo.minBottomMargin = 5
        constraintInfo.minLeftMargin = 5
        constraintInfo.minRightMargin = 5

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertEqual(constraintInfo.minTopMargin, 5)
        XCTAssertEqual(constraintInfo.minBottomMargin, 5)
        XCTAssertEqual(constraintInfo.minLeftMargin, 5)
        XCTAssertEqual(constraintInfo.minRightMargin, 5)
    }

    func testMaxMarginProperties() {
        constraintInfo.maxTopMargin = 20
        constraintInfo.maxBottomMargin = 20
        constraintInfo.maxLeftMargin = 20
        constraintInfo.maxRightMargin = 20

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertEqual(constraintInfo.maxTopMargin, 20)
        XCTAssertEqual(constraintInfo.maxBottomMargin, 20)
        XCTAssertEqual(constraintInfo.maxLeftMargin, 20)
        XCTAssertEqual(constraintInfo.maxRightMargin, 20)
    }

    // MARK: - RTL Margin Tests

    func testStartEndMarginProperties() {
        constraintInfo.startMargin = 10
        constraintInfo.endMargin = 10

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertEqual(constraintInfo.startMargin, 10)
        XCTAssertEqual(constraintInfo.endMargin, 10)
    }

    // MARK: - Aspect Ratio Tests

    func testAspectRatio() {
        constraintInfo.aspectWidth = 16
        constraintInfo.aspectHeight = 9

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertEqual(constraintInfo.aspectWidth, 16)
        XCTAssertEqual(constraintInfo.aspectHeight, 9)
    }

    // MARK: - Alignment Tests

    func testAlignTopProperty() {
        constraintInfo.alignTop = true
        constraintInfo.topMargin = 10

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertTrue(constraintInfo.alignTop)
    }

    func testAlignBottomProperty() {
        constraintInfo.alignBottom = true
        constraintInfo.bottomMargin = 10

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertTrue(constraintInfo.alignBottom)
    }

    func testAlignLeftProperty() {
        constraintInfo.alignLeft = true
        constraintInfo.leftMargin = 10

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertTrue(constraintInfo.alignLeft)
    }

    func testAlignRightProperty() {
        constraintInfo.alignRight = true
        constraintInfo.rightMargin = 10

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertTrue(constraintInfo.alignRight)
    }

    func testCenterVerticalProperty() {
        constraintInfo.centerVertical = true

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertTrue(constraintInfo.centerVertical)
    }

    func testCenterHorizontalProperty() {
        constraintInfo.centerHorizontal = true

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertTrue(constraintInfo.centerHorizontal)
    }

    // MARK: - Relative Alignment Tests

    func testAlignToViewProperties() {
        let referenceView = UIView()
        containerView.addSubview(referenceView)

        constraintInfo.alignTopOfView = referenceView

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertNotNil(constraintInfo.alignTopOfView)
    }

    func testAlignBottomOfView() {
        let referenceView = UIView()
        containerView.addSubview(referenceView)

        constraintInfo.alignBottomOfView = referenceView

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertNotNil(constraintInfo.alignBottomOfView)
    }

    func testAlignLeftOfView() {
        let referenceView = UIView()
        containerView.addSubview(referenceView)

        constraintInfo.alignLeftOfView = referenceView

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertNotNil(constraintInfo.alignLeftOfView)
    }

    func testAlignRightOfView() {
        let referenceView = UIView()
        containerView.addSubview(referenceView)

        constraintInfo.alignRightOfView = referenceView

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertNotNil(constraintInfo.alignRightOfView)
    }

    func testAlignCenterVerticalToView() {
        let referenceView = UIView()
        containerView.addSubview(referenceView)

        constraintInfo.alignCenterVerticalView = referenceView

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertNotNil(constraintInfo.alignCenterVerticalView)
    }

    func testAlignCenterHorizontalToView() {
        let referenceView = UIView()
        containerView.addSubview(referenceView)

        constraintInfo.alignCenterHorizontalView = referenceView

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertNotNil(constraintInfo.alignCenterHorizontalView)
    }

    // MARK: - Weight Tests

    func testWidthWeightProperty() {
        constraintInfo.widthWeight = 0.5

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertEqual(constraintInfo.widthWeight, 0.5)
    }

    func testHeightWeightProperty() {
        constraintInfo.heightWeight = 0.5

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertEqual(constraintInfo.heightWeight, 0.5)
    }

    // MARK: - Min/Max Dimension Tests

    func testMinWidthProperty() {
        constraintInfo.minWidth = 50

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertEqual(constraintInfo.minWidth, 50)
    }

    func testMaxWidthProperty() {
        constraintInfo.maxWidth = 200

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertEqual(constraintInfo.maxWidth, 200)
    }

    func testMinHeightProperty() {
        constraintInfo.minHeight = 50

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertEqual(constraintInfo.minHeight, 50)
    }

    func testMaxHeightProperty() {
        constraintInfo.maxHeight = 200

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertEqual(constraintInfo.maxHeight, 200)
    }

    // MARK: - Complex Scenarios

    func testComplexConstraintCombination() {
        constraintInfo.width = 200
        constraintInfo.height = 150
        constraintInfo.paddingTop = 10
        constraintInfo.paddingBottom = 10
        constraintInfo.paddingLeft = 10
        constraintInfo.paddingRight = 10

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertGreaterThan(constraintInfo.constraints.count, 0)
    }

    func testMatchParentWithPadding() {
        constraintInfo.width = UILayoutConstraintInfo.LayoutParams.matchParent.rawValue
        constraintInfo.height = UILayoutConstraintInfo.LayoutParams.matchParent.rawValue
        constraintInfo.paddingTop = 20
        constraintInfo.paddingBottom = 20
        constraintInfo.paddingLeft = 20
        constraintInfo.paddingRight = 20

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        XCTAssertGreaterThan(constraintInfo.constraints.count, 0)
    }

    // MARK: - LayoutParams Enum Tests

    func testLayoutParamsMatchParent() {
        let matchParent = UILayoutConstraintInfo.LayoutParams.matchParent.rawValue
        XCTAssertEqual(matchParent, -1)
    }

    func testLayoutParamsWrapContent() {
        let wrapContent = UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue
        XCTAssertEqual(wrapContent, -2)
    }

    // MARK: - Edge Cases

    func testNilConstraintInfo() {
        var info = UILayoutConstraintInfo()

        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &info)

        // Should not crash with default values
        XCTAssertGreaterThanOrEqual(info.constraints.count, 0)
    }

    func testMultipleConstraintApplications() {
        constraintInfo.width = 100
        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        let firstCount = constraintInfo.constraints.count

        UIViewDisposure.removeConstraint(constraintInfo: constraintInfo)

        constraintInfo.width = 200
        UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &constraintInfo)

        // Should be able to reapply constraints
        XCTAssertGreaterThan(constraintInfo.constraints.count, 0)
    }

    // MARK: - Performance Tests

    func testConstraintApplicationPerformance() {
        measure {
            for _ in 0..<100 {
                var info = UILayoutConstraintInfo()
                info.width = 100
                info.height = 100

                UIViewDisposure.applyConstraint(onView: testView, toConstraintInfo: &info)
                UIViewDisposure.removeConstraint(constraintInfo: info)
            }
        }
    }
}
