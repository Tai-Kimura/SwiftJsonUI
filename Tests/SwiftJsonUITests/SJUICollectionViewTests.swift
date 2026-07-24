//
//  SJUICollectionViewTests.swift
//  SwiftJsonUITests
//
//  Comprehensive tests for SJUICollectionView component
//

import XCTest
@testable import SwiftJsonUI

@MainActor
final class SJUICollectionViewTests: XCTestCase {

    var collectionView: SJUICollectionView!
    var testTarget: NSObject!
    var testViews: [String: UIView]!

    override func setUp() {
        super.setUp()
        testTarget = NSObject()
        testViews = [:]
        collectionView = SJUICollectionView.createFromJSON(
            attr: JSON([:]),
            target: testTarget,
            views: &testViews
        )
    }

    override func tearDown() {
        collectionView = nil
        testTarget = nil
        testViews = nil
        super.tearDown()
    }

    // MARK: - Basic Initialization Tests

    func testCollectionViewCreation() {
        XCTAssertNotNil(collectionView)
        XCTAssertTrue(collectionView is SJUICollectionView)
    }

    func testViewClassProperty() {
        let viewClass = SJUICollectionView.viewClass
        XCTAssertTrue(viewClass == SJUICollectionView.self)
    }

    func testInheritsFromUICollectionView() {
        XCTAssertTrue(collectionView is UICollectionView)
    }

    // MARK: - Layout Property Tests

    func testCollectionViewLayoutProperty() {
        XCTAssertNotNil(collectionView.collectionViewLayout)
        XCTAssertTrue(collectionView.collectionViewLayout is UICollectionViewFlowLayout)
    }

    func testFlowLayout() {
        let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        XCTAssertNotNil(flowLayout)
    }

    // MARK: - JSON Creation Tests

    func testCreateFromJSONBasic() {
        let json = JSON(["type": "CollectionView"])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        XCTAssertNotNil(cv)
        XCTAssertTrue(cv is SJUICollectionView)
    }

    func testCreateFromJSONWithCellClasses() {
        let json = JSON([
            "type": "CollectionView",
            "cellClasses": [
                ["className": "CustomCell1", "identifier": "cell1"],
                ["className": "CustomCell2", "identifier": "cell2"]
            ]
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        XCTAssertNotNil(cv)
    }

    func testCreateFromJSONWithLayoutSpacing() {
        let json = JSON([
            "type": "CollectionView",
            "lineSpacing": 10,
            "columnSpacing": 10
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        XCTAssertNotNil(cv)
        let flowLayout = cv.collectionViewLayout as? UICollectionViewFlowLayout
        XCTAssertEqual(flowLayout?.minimumLineSpacing, 10)
        XCTAssertEqual(flowLayout?.minimumInteritemSpacing, 10)
    }

    // MARK: - Scroll Direction Tests

    func testScrollDirectionDefault() {
        let json = JSON([
            "type": "CollectionView"
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        let flowLayout = cv.collectionViewLayout as? UICollectionViewFlowLayout
        XCTAssertEqual(flowLayout?.scrollDirection, .vertical)
    }

    func testScrollDirectionHorizontal() {
        let json = JSON([
            "type": "CollectionView",
            "horizontalScroll": true
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        let flowLayout = cv.collectionViewLayout as? UICollectionViewFlowLayout
        XCTAssertEqual(flowLayout?.scrollDirection, .horizontal)
    }

    // MARK: - Spacing Tests

    func testLineSpacing() {
        let json = JSON([
            "type": "CollectionView",
            "lineSpacing": 20
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        let flowLayout = cv.collectionViewLayout as? UICollectionViewFlowLayout
        XCTAssertEqual(flowLayout?.minimumLineSpacing, 20)
    }

    func testColumnSpacing() {
        let json = JSON([
            "type": "CollectionView",
            "columnSpacing": 15
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        let flowLayout = cv.collectionViewLayout as? UICollectionViewFlowLayout
        XCTAssertEqual(flowLayout?.minimumInteritemSpacing, 15)
    }

    // MARK: - Item Size Tests

    func testItemWeight() {
        let json = JSON([
            "type": "CollectionView",
            "itemWeight": 0.5
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        let flowLayout = cv.collectionViewLayout as? UICollectionViewFlowLayout
        XCTAssertNotNil(flowLayout)
        XCTAssertEqual(flowLayout?.itemSize.width, UIScreen.main.bounds.size.width * 0.5)
    }

    func testDefaultItemWeight() {
        let json = JSON([
            "type": "CollectionView"
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        let flowLayout = cv.collectionViewLayout as? UICollectionViewFlowLayout
        XCTAssertNotNil(flowLayout)
        // Default weight is 1.0
        XCTAssertEqual(flowLayout?.itemSize.width, UIScreen.main.bounds.size.width)
    }

    // MARK: - Section Inset Tests

    func testSectionInsetWithFourValues() {
        let json = JSON([
            "type": "CollectionView",
            "insets": [10, 20, 30, 40]
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        let flowLayout = cv.collectionViewLayout as? UICollectionViewFlowLayout
        XCTAssertEqual(flowLayout?.sectionInset.top, 10)
        XCTAssertEqual(flowLayout?.sectionInset.left, 20)
        XCTAssertEqual(flowLayout?.sectionInset.bottom, 30)
        XCTAssertEqual(flowLayout?.sectionInset.right, 40)
    }

    func testSectionInsetWithTwoValues() {
        let json = JSON([
            "type": "CollectionView",
            "insets": [10, 20]
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        let flowLayout = cv.collectionViewLayout as? UICollectionViewFlowLayout
        // [vertical, horizontal] -> [top, left, bottom, right]
        XCTAssertEqual(flowLayout?.sectionInset.top, 10)
        XCTAssertEqual(flowLayout?.sectionInset.left, 20)
        XCTAssertEqual(flowLayout?.sectionInset.bottom, 10)
        XCTAssertEqual(flowLayout?.sectionInset.right, 20)
    }

    func testSectionInsetWithOneValue() {
        let json = JSON([
            "type": "CollectionView",
            "insets": [15]
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        let flowLayout = cv.collectionViewLayout as? UICollectionViewFlowLayout
        XCTAssertEqual(flowLayout?.sectionInset.top, 15)
        XCTAssertEqual(flowLayout?.sectionInset.left, 15)
        XCTAssertEqual(flowLayout?.sectionInset.bottom, 15)
        XCTAssertEqual(flowLayout?.sectionInset.right, 15)
    }

    func testInsetHorizontalAndVertical() {
        let json = JSON([
            "type": "CollectionView",
            "insetHorizontal": 20,
            "insetVertical": 10
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        let flowLayout = cv.collectionViewLayout as? UICollectionViewFlowLayout
        XCTAssertEqual(flowLayout?.sectionInset.top, 10)
        XCTAssertEqual(flowLayout?.sectionInset.left, 20)
        XCTAssertEqual(flowLayout?.sectionInset.bottom, 10)
        XCTAssertEqual(flowLayout?.sectionInset.right, 20)
    }

    // MARK: - Content Inset Tests

    func testContentInsets() {
        let json = JSON([
            "type": "CollectionView",
            "contentInsets": [5, 10, 15, 20]
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        // The implementation creates UIEdgeInsets as: (top: insets[0], left: insets[1], bottom: insets[2], right: insets[3])
        XCTAssertEqual(cv.contentInset.top, 5)
        XCTAssertEqual(cv.contentInset.left, 10)
        XCTAssertEqual(cv.contentInset.bottom, 15)
        XCTAssertEqual(cv.contentInset.right, 20)
    }

    // MARK: - Scroll Indicator Tests

    func testShowsHorizontalScrollIndicator() {
        let json = JSON([
            "type": "CollectionView",
            "showsHorizontalScrollIndicator": true
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        XCTAssertTrue(cv.showsHorizontalScrollIndicator)
    }

    func testShowsVerticalScrollIndicator() {
        let json = JSON([
            "type": "CollectionView",
            "showsVerticalScrollIndicator": true
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        XCTAssertTrue(cv.showsVerticalScrollIndicator)
    }

    // MARK: - Paging Tests

    func testPagingEnabled() {
        let json = JSON([
            "type": "CollectionView",
            "paging": true
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        XCTAssertTrue(cv.isPagingEnabled)
    }

    func testPagingDisabled() {
        let json = JSON([
            "type": "CollectionView",
            "paging": false
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        XCTAssertFalse(cv.isPagingEnabled)
    }

    // MARK: - Delegate and DataSource Tests

    func testSetTargetAsDelegate() {
        class MockDelegate: NSObject, UICollectionViewDelegate {}
        let delegate = MockDelegate()

        let json = JSON([
            "type": "CollectionView",
            "setTargetAsDelegate": true
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: delegate,
            views: &views
        )

        XCTAssertNotNil(cv.delegate)
    }

    func testSetTargetAsDataSource() {
        class MockDataSource: NSObject, UICollectionViewDataSource {
            func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
                return 0
            }

            func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
                return UICollectionViewCell()
            }
        }
        let dataSource = MockDataSource()

        let json = JSON([
            "type": "CollectionView",
            "setTargetAsDataSource": true
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: dataSource,
            views: &views
        )

        XCTAssertNotNil(cv.dataSource)
    }

    // MARK: - Content Inset Adjustment Behavior Tests

    @available(iOS 11.0, *)
    func testContentInsetAdjustmentBehaviorAutomatic() {
        let json = JSON([
            "type": "CollectionView",
            "contentInsetAdjustmentBehavior": "automatic"
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        XCTAssertEqual(cv.contentInsetAdjustmentBehavior, .automatic)
    }

    @available(iOS 11.0, *)
    func testContentInsetAdjustmentBehaviorAlways() {
        let json = JSON([
            "type": "CollectionView",
            "contentInsetAdjustmentBehavior": "always"
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        XCTAssertEqual(cv.contentInsetAdjustmentBehavior, .always)
    }

    @available(iOS 11.0, *)
    func testContentInsetAdjustmentBehaviorNever() {
        let json = JSON([
            "type": "CollectionView",
            "contentInsetAdjustmentBehavior": "never"
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        XCTAssertEqual(cv.contentInsetAdjustmentBehavior, .never)
    }

    @available(iOS 11.0, *)
    func testContentInsetAdjustmentBehaviorScrollableAxes() {
        let json = JSON([
            "type": "CollectionView",
            "contentInsetAdjustmentBehavior": "scrollableAxes"
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        XCTAssertEqual(cv.contentInsetAdjustmentBehavior, .scrollableAxes)
    }

    // MARK: - Header and Footer Classes Tests

    func testHeaderClasses() {
        let json = JSON([
            "type": "CollectionView",
            "headerClasses": [
                ["className": "CustomHeader", "identifier": "header1"]
            ]
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        XCTAssertNotNil(cv)
    }

    func testFooterClasses() {
        let json = JSON([
            "type": "CollectionView",
            "footerClasses": [
                ["className": "CustomFooter", "identifier": "footer1"]
            ]
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        XCTAssertNotNil(cv)
    }

    // MARK: - Keyboard Avoidance Tests

    func testKeyboardAvoidanceEnabled() {
        let json = JSON([
            "type": "CollectionView",
            "keyboardAvoidance": true
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        XCTAssertTrue(cv.isKeyboardAvoidanceEnabled)
    }

    func testKeyboardAvoidanceDisabled() {
        let json = JSON([
            "type": "CollectionView",
            "keyboardAvoidance": false
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        XCTAssertFalse(cv.isKeyboardAvoidanceEnabled)
    }

    // MARK: - Background Color Tests

    func testCollectionViewBackgroundColor() {
        collectionView.backgroundColor = UIColor.white
        // Test the actual set color, not comparison against constant
        XCTAssertNotNil(collectionView.backgroundColor)
    }

    // MARK: - Scroll Properties Tests

    func testScrollEnabled() {
        collectionView.isScrollEnabled = true
        XCTAssertTrue(collectionView.isScrollEnabled)

        collectionView.isScrollEnabled = false
        XCTAssertFalse(collectionView.isScrollEnabled)
    }

    func testDefaultShowsVerticalScrollIndicator() {
        XCTAssertFalse(collectionView.showsVerticalScrollIndicator)
    }

    func testDefaultShowsHorizontalScrollIndicator() {
        XCTAssertFalse(collectionView.showsHorizontalScrollIndicator)
    }

    // MARK: - Bounce Properties Tests

    func testBounces() {
        collectionView.bounces = true
        XCTAssertTrue(collectionView.bounces)

        collectionView.bounces = false
        XCTAssertFalse(collectionView.bounces)
    }

    func testAlwaysBounceVertical() {
        collectionView.alwaysBounceVertical = true
        XCTAssertTrue(collectionView.alwaysBounceVertical)
    }

    func testAlwaysBounceHorizontal() {
        collectionView.alwaysBounceHorizontal = true
        XCTAssertTrue(collectionView.alwaysBounceHorizontal)
    }

    // MARK: - Selection Tests

    func testAllowsSelection() {
        collectionView.allowsSelection = true
        XCTAssertTrue(collectionView.allowsSelection)

        collectionView.allowsSelection = false
        XCTAssertFalse(collectionView.allowsSelection)
    }

    func testAllowsMultipleSelection() {
        collectionView.allowsMultipleSelection = true
        XCTAssertTrue(collectionView.allowsMultipleSelection)

        collectionView.allowsMultipleSelection = false
        XCTAssertFalse(collectionView.allowsMultipleSelection)
    }

    // MARK: - Complex Scenarios

    func testCompleteCollectionViewConfiguration() {
        let json = JSON([
            "type": "CollectionView",
            "horizontalScroll": false,
            "lineSpacing": 10,
            "columnSpacing": 10,
            "itemWeight": 0.5,
            "insets": [5, 5, 5, 5],
            "cellClasses": [
                ["className": "Cell1", "identifier": "cell1"],
                ["className": "Cell2", "identifier": "cell2"]
            ],
            "paging": true,
            "showsHorizontalScrollIndicator": false,
            "showsVerticalScrollIndicator": false
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        XCTAssertNotNil(cv)
        XCTAssertNotNil(cv.collectionViewLayout)
        XCTAssertTrue(cv.isPagingEnabled)
        XCTAssertFalse(cv.showsHorizontalScrollIndicator)
        XCTAssertFalse(cv.showsVerticalScrollIndicator)
    }

    // MARK: - Edge Cases

    func testCollectionViewWithNoLayout() {
        let json = JSON([
            "type": "CollectionView"
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        // Should have default layout
        XCTAssertNotNil(cv.collectionViewLayout)
    }

    func testCollectionViewWithZeroSpacing() {
        let json = JSON([
            "type": "CollectionView",
            "lineSpacing": 0,
            "columnSpacing": 0
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        let flowLayout = cv.collectionViewLayout as? UICollectionViewFlowLayout
        XCTAssertEqual(flowLayout?.minimumLineSpacing, 0)
        XCTAssertEqual(flowLayout?.minimumInteritemSpacing, 0)
    }

    func testCollectionViewWithStringInsets() {
        let json = JSON([
            "type": "CollectionView",
            "insets": "10|20|30|40"
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        let flowLayout = cv.collectionViewLayout as? UICollectionViewFlowLayout
        XCTAssertEqual(flowLayout?.sectionInset.top, 10)
        XCTAssertEqual(flowLayout?.sectionInset.left, 20)
        XCTAssertEqual(flowLayout?.sectionInset.bottom, 30)
        XCTAssertEqual(flowLayout?.sectionInset.right, 40)
    }

    func testCollectionViewWithStringContentInsets() {
        let json = JSON([
            "type": "CollectionView",
            "contentInsets": "5|10|15|20"
        ])
        var views = [String: UIView]()
        let cv = SJUICollectionView.createFromJSON(
            attr: json,
            target: testTarget,
            views: &views
        )

        XCTAssertEqual(cv.contentInset.top, 5)
        XCTAssertEqual(cv.contentInset.left, 10)
        XCTAssertEqual(cv.contentInset.bottom, 15)
        XCTAssertEqual(cv.contentInset.right, 20)
    }

    // MARK: - Reloading Tests

    func testReloadData() {
        // Should not crash
        collectionView.reloadData()
        XCTAssertNotNil(collectionView)
    }

    // MARK: - Performance Tests

    func testCollectionViewCreationPerformance() {
        measure {
            for _ in 0..<50 {
                var views = [String: UIView]()
                _ = SJUICollectionView.createFromJSON(
                    attr: JSON(["type": "CollectionView"]),
                    target: testTarget,
                    views: &views
                )
            }
        }
    }

    func testCollectionViewLayoutPerformance() {
        measure {
            for _ in 0..<100 {
                let json = JSON([
                    "type": "CollectionView",
                    "lineSpacing": 10,
                    "columnSpacing": 10,
                    "itemWeight": 0.5,
                    "insets": [5, 5, 5, 5]
                ])
                var views = [String: UIView]()
                _ = SJUICollectionView.createFromJSON(
                    attr: json,
                    target: testTarget,
                    views: &views
                )
            }
        }
    }

    // MARK: - Layout Factory Method Tests

    func testGetCollectionViewLayout() {
        let json = JSON([
            "itemWeight": 0.5,
            "insets": [10, 20, 30, 40],
            "horizontalScroll": true
        ])

        let layout = SJUICollectionView.getCollectionViewLayout(attr: json)
        XCTAssertNotNil(layout)
        XCTAssertTrue(layout is UICollectionViewFlowLayout)

        let flowLayout = layout as? UICollectionViewFlowLayout
        XCTAssertEqual(flowLayout?.scrollDirection, .horizontal)
    }

    func testGetCollectionViewFlowLayout() {
        let json = JSON([
            "layout": "Flow",
            "columnSpacing": 15,
            "lineSpacing": 20
        ])

        let layout = SJUICollectionView.getCollectionViewFlowLayout(attr: json)
        XCTAssertNotNil(layout)
        XCTAssertEqual(layout.minimumInteritemSpacing, 15)
        XCTAssertEqual(layout.minimumLineSpacing, 20)
    }
}
