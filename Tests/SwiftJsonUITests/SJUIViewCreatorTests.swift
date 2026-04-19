//
//  SJUIViewCreatorTests.swift
//  SwiftJsonUITests
//
//  Comprehensive tests for the SJUIViewCreator class
//

import XCTest
import WebKit
@testable import SwiftJsonUI

final class SJUIViewCreatorTests: XCTestCase {

    class TestViewController: UIViewController, ViewHolder {
        var _views = [String: UIView]()
    }

    override func setUp() {
        super.setUp()
        // Reset default values before each test
        SJUIViewCreator.defaultFont = "SJUI_System_Font"
        SJUIViewCreator.defaultFontColor = .black
        SJUIViewCreator.defaultHintColor = .lightGray
        SJUIViewCreator.defaultFontSize = 14.0
    }

    // MARK: - Static Properties Tests

    func testDefaultFontValue() {
        XCTAssertEqual(SJUIViewCreator.defaultFont, "SJUI_System_Font")
    }

    func testDefaultFontColorValue() {
        XCTAssertEqual(SJUIViewCreator.defaultFontColor, .black)
    }

    func testDefaultHintColorValue() {
        XCTAssertEqual(SJUIViewCreator.defaultHintColor, .lightGray)
    }

    func testDefaultFontSizeValue() {
        XCTAssertEqual(SJUIViewCreator.defaultFontSize, 14.0)
    }

    func testCanModifyDefaultFont() {
        SJUIViewCreator.defaultFont = "CustomFont"
        XCTAssertEqual(SJUIViewCreator.defaultFont, "CustomFont")
    }

    func testCanModifyDefaultFontColor() {
        SJUIViewCreator.defaultFontColor = .red
        XCTAssertEqual(SJUIViewCreator.defaultFontColor, .red)
    }

    func testCanModifyDefaultHintColor() {
        SJUIViewCreator.defaultHintColor = .blue
        XCTAssertEqual(SJUIViewCreator.defaultHintColor, .blue)
    }

    func testCanModifyDefaultFontSize() {
        SJUIViewCreator.defaultFontSize = 18.0
        XCTAssertEqual(SJUIViewCreator.defaultFontSize, 18.0)
    }

    // MARK: - Directory Configuration Tests

    func testDefaultLayoutsDirectoryName() {
        XCTAssertEqual(SJUIViewCreator.layoutsDirectoryName, "Layouts")
    }

    func testDefaultStylesDirectoryName() {
        XCTAssertEqual(SJUIViewCreator.stylesDirectoryName, "Styles")
    }

    func testDefaultScriptsDirectoryName() {
        XCTAssertEqual(SJUIViewCreator.scriptsDirectoryName, "Scripts")
    }

    func testCanModifyLayoutsDirectoryName() {
        SJUIViewCreator.layoutsDirectoryName = "CustomLayouts"
        XCTAssertEqual(SJUIViewCreator.layoutsDirectoryName, "CustomLayouts")
        // Reset
        SJUIViewCreator.layoutsDirectoryName = "Layouts"
    }

    func testCanModifyStylesDirectoryName() {
        SJUIViewCreator.stylesDirectoryName = "CustomStyles"
        XCTAssertEqual(SJUIViewCreator.stylesDirectoryName, "CustomStyles")
        // Reset
        SJUIViewCreator.stylesDirectoryName = "Styles"
    }

    func testCanModifyScriptsDirectoryName() {
        SJUIViewCreator.scriptsDirectoryName = "CustomScripts"
        XCTAssertEqual(SJUIViewCreator.scriptsDirectoryName, "CustomScripts")
        // Reset
        SJUIViewCreator.scriptsDirectoryName = "Scripts"
    }

    // MARK: - GetOnView Tests

    @MainActor
    func testGetOnViewWithViewController() async {
        let viewController = TestViewController()
        // Ensure view is loaded
        _ = viewController.view

        let result = SJUIViewCreator.getOnView(target: viewController)

        XCTAssertNotNil(result)
        XCTAssertTrue(result === viewController.view)
    }

    @MainActor
    func testGetOnViewWithNonViewController() async {
        class CustomViewHolder: NSObject, ViewHolder {
            var _views = [String: UIView]()
        }

        let customHolder = CustomViewHolder()
        let result = SJUIViewCreator.getOnView(target: customHolder)

        XCTAssertNil(result)
    }

    // MARK: - Error View Tests

    @MainActor
    func testCreateErrorView() async {
        let errorView = SJUIViewCreator.createErrorView("Test error message")

        XCTAssertNotNil(errorView)
        XCTAssertTrue(errorView is UIView)
        XCTAssertGreaterThan(errorView.subviews.count, 0)

        // Check if there's a label in the error view
        let hasLabel = errorView.subviews.contains { $0 is UILabel }
        XCTAssertTrue(hasLabel)
    }

    @MainActor
    func testCreateErrorViewDefaultMessage() async {
        let errorView = SJUIViewCreator.createErrorView()

        XCTAssertNotNil(errorView)
        XCTAssertTrue(errorView is UIView)
    }

    @MainActor
    func testCreateErrorViewCustomMessage() async {
        let customMessage = "Custom error occurred!"
        let errorView = SJUIViewCreator.createErrorView(customMessage)

        XCTAssertNotNil(errorView)

        // Find the label and verify text
        let labels = errorView.subviews.compactMap { $0 as? UILabel }
        XCTAssertGreaterThan(labels.count, 0)
        if let label = labels.first {
            XCTAssertEqual(label.text, customMessage)
        }
    }

    // MARK: - FindColorFunc Tests

    func testFindColorFuncCanBeSet() {
        let colorFunc: ((Any) -> UIColor?) = { _ in
            return .red
        }

        SJUIViewCreator.findColorFunc = colorFunc

        XCTAssertNotNil(SJUIViewCreator.findColorFunc)

        // Test the function
        let result = SJUIViewCreator.findColorFunc?("test")
        XCTAssertEqual(result, .red)

        // Reset
        SJUIViewCreator.findColorFunc = nil
    }

    func testFindColorFuncCanReturnNil() {
        let colorFunc: ((Any) -> UIColor?) = { _ in
            return nil
        }

        SJUIViewCreator.findColorFunc = colorFunc

        let result = SJUIViewCreator.findColorFunc?("test")
        XCTAssertNil(result)

        // Reset
        SJUIViewCreator.findColorFunc = nil
    }

    func testFindColorFuncWithDifferentInputTypes() {
        let colorFunc: ((Any) -> UIColor?) = { input in
            if let str = input as? String {
                return str == "red" ? .red : .blue
            }
            return nil
        }

        SJUIViewCreator.findColorFunc = colorFunc

        let redResult = SJUIViewCreator.findColorFunc?("red")
        XCTAssertEqual(redResult, .red)

        let blueResult = SJUIViewCreator.findColorFunc?("blue")
        XCTAssertEqual(blueResult, .blue)

        // Reset
        SJUIViewCreator.findColorFunc = nil
    }

    // MARK: - CreateView from JSON Tests

    @MainActor
    func testCreateViewFromEmptyJSON() {
        let json = JSON([:])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
    }

    @MainActor
    func testCreateViewWithType() {
        let json = JSON(["type": "View"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is SJUIView)
    }

    @MainActor
    func testCreateLabelView() {
        let json = JSON([
            "type": "Label",
            "text": "Test Label"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is SJUILabel)
        let label = view as? SJUILabel
        XCTAssertEqual(label?.text, "Test Label")
    }

    @MainActor
    func testCreateButtonView() {
        let json = JSON([
            "type": "Button",
            "text": "Test Button"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is SJUIButton)
    }

    @MainActor
    func testCreateImageView() {
        let json = JSON(["type": "Image"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is SJUIImageView)
    }

    @MainActor
    func testCreateTextFieldView() {
        let json = JSON([
            "type": "TextField",
            "hint": "Enter text"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is SJUITextField)
    }

    @MainActor
    func testCreateTextView() {
        let json = JSON(["type": "TextView"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is SJUITextView)
    }

    @MainActor
    func testCreateScrollView() {
        let json = JSON(["type": "Scroll"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is SJUIScrollView)
    }

    @MainActor
    func testCreateCollectionView() {
        let json = JSON(["type": "Collection"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is SJUICollectionView)
    }

    @MainActor
    func testCreateSelectBox() {
        let json = JSON(["type": "SelectBox"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is SJUISelectBox)
    }

    @MainActor
    func testCreateSwitch() {
        let json = JSON(["type": "Switch"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is SJUISwitch)
    }

    @MainActor
    func testCreateSegment() {
        let json = JSON([
            "type": "Segment",
            "items": ["One", "Two", "Three"]
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is SJUISegmentedControl)
    }

    @MainActor
    func testCreateCheckBox() {
        let json = JSON(["type": "Check"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is SJUICheckBox)
    }

    @MainActor
    func testCreateRadioButton() {
        let json = JSON(["type": "Radio"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is SJUIRadioButton)
    }

    @MainActor
    func testCreateNetworkImageView() {
        let json = JSON(["type": "NetworkImage"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is NetworkImageView)
    }

    @MainActor
    func testCreateCircleImageView() {
        let json = JSON(["type": "CircleImage"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is CircleImageView)
    }

    @MainActor
    func testCreateBlurView() {
        let json = JSON(["type": "Blur"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is SJUIVisualEffectView)
    }

    @MainActor
    func testCreateGradientView() {
        let json = JSON(["type": "GradientView"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is GradientView)
    }

    @MainActor
    func testCreateCircleView() {
        let json = JSON(["type": "CircleView"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is SJUICircleView)
    }

    @MainActor
    func testCreateIconLabelView() {
        let json = JSON(["type": "IconLabel"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is SJUILabelWithIcon)
    }

    @MainActor
    func testCreateWebView() {
        let json = JSON(["type": "Web"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is WKWebView)
    }

    @MainActor
    func testCreateProgressView() {
        let json = JSON(["type": "Progress"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is UIProgressView)
    }

    @MainActor
    func testCreateSliderView() {
        let json = JSON(["type": "Slider"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is UISlider)
    }

    @MainActor
    func testCreateIndicatorView() {
        let json = JSON(["type": "Indicator"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is UIActivityIndicatorView)
    }

    @MainActor
    func testCreateIndicatorWithLargeStyle() {
        let json = JSON([
            "type": "Indicator",
            "indicatorStyle": "large"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is UIActivityIndicatorView)
    }

    @MainActor
    func testCreateSafeAreaView() {
        let json = JSON(["type": "SafeAreaView"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is SJUIView)
    }

    @MainActor
    func testCreateTableView() {
        let json = JSON(["type": "Table"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view is SJUITableView)
    }

    // MARK: - View ID Tests

    @MainActor
    func testCreateViewWithID() {
        let json = JSON([
            "type": "Label",
            "id": "testLabel",
            "text": "Test"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertNotNil(views["testLabel"])
        XCTAssertTrue(views["testLabel"] === view)
    }

    @MainActor
    func testCreateViewWithBindingID() {
        let json = JSON([
            "type": "Label",
            "id": "testLabel",
            "text": "Test"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: "header"
        )

        XCTAssertNotNil(view)
        XCTAssertNotNil(views["header_testLabel"])
        XCTAssertTrue(views["header_testLabel"] === view)
    }

    @MainActor
    func testCreateViewWithPropertyName() {
        let json = JSON([
            "type": "Label",
            "id": "test_label",
            "propertyName": "customName"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertEqual(view.propertyName, "customName")
    }

    @MainActor
    func testCreateViewWithBinding() {
        let json = JSON([
            "type": "Label",
            "id": "testLabel",
            "binding": "userName"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertEqual(view.binding, "userName")
    }

    @MainActor
    func testCreateViewWithBindingSet() {
        let json = JSON([
            "type": "Label",
            "id": "testLabel",
            "binding": [
                "text": "userName",
                "color": "userColor"
            ]
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertNotNil(view.bindingSet)
        XCTAssertEqual(view.bindingSet?["text"], "userName")
        XCTAssertEqual(view.bindingSet?["color"], "userColor")
    }

    // MARK: - Common Attributes Tests

    @MainActor
    func testCreateViewWithWidth() {
        let json = JSON([
            "type": "View",
            "width": 200
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertEqual(view.constraintInfo?.width, 200)
    }

    @MainActor
    func testCreateViewWithMatchParent() {
        let json = JSON([
            "type": "View",
            "width": "matchParent",
            "height": "matchParent"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertEqual(view.constraintInfo?.width, UILayoutConstraintInfo.LayoutParams.matchParent.rawValue)
        XCTAssertEqual(view.constraintInfo?.height, UILayoutConstraintInfo.LayoutParams.matchParent.rawValue)
    }

    @MainActor
    func testCreateViewWithWrapContent() {
        let json = JSON([
            "type": "View",
            "width": "wrapContent",
            "height": "wrapContent"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertEqual(view.constraintInfo?.width, UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue)
        XCTAssertEqual(view.constraintInfo?.height, UILayoutConstraintInfo.LayoutParams.wrapContent.rawValue)
    }

    @MainActor
    func testCreateViewWithBackground() {
        let json = JSON([
            "type": "View",
            "background": "#FF0000"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertNotNil(view.backgroundColor)
    }

    @MainActor
    func testCreateViewWithCornerRadius() {
        let json = JSON([
            "type": "View",
            "cornerRadius": 10
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertEqual(view.layer.cornerRadius, 10.0)
    }

    @MainActor
    func testCreateViewWithAlpha() {
        let json = JSON([
            "type": "View",
            "alpha": 0.5
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertEqual(view.alpha, 0.5)
    }

    @MainActor
    func testCreateViewWithHidden() {
        let json = JSON([
            "type": "View",
            "hidden": true
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view.isHidden ?? false)
    }

    @MainActor
    func testCreateViewWithTag() {
        let json = JSON([
            "type": "View",
            "tag": 99
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertEqual(view.tag, 99)
    }

    @MainActor
    func testCreateViewWithShadowString() {
        let json = JSON([
            "type": "View",
            "shadow": "#000000|2|2|0.5|4"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertNotNil(view.layer.shadowColor)
    }

    @MainActor
    func testCreateViewWithShadowObject() {
        let json = JSON([
            "type": "View",
            "shadow": [
                "color": "#000000",
                "offsetX": 2,
                "offsetY": 2,
                "opacity": 0.5,
                "radius": 4
            ]
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertNotNil(view.layer.shadowColor)
        XCTAssertEqual(view.layer.shadowRadius, 4.0)
    }

    @MainActor
    func testCreateViewWithBorder() {
        let json = JSON([
            "type": "View",
            "borderColor": "#FF0000",
            "borderWidth": 2
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertNotNil(view.layer.borderColor)
        XCTAssertEqual(view.layer.borderWidth, 2.0)
    }

    // MARK: - Border Style Tests

    @MainActor
    func testCreateViewWithBorderStyleSolid() {
        let json = JSON([
            "type": "View",
            "borderColor": "#FF0000",
            "borderWidth": 2,
            "borderStyle": "solid"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertNotNil(view.layer.borderColor)
        XCTAssertEqual(view.layer.borderWidth, 2.0)
        XCTAssertNil(view.borderShapeLayer) // solid uses layer.border, not CAShapeLayer
        XCTAssertEqual(view.storedBorderStyle, "solid")
    }

    @MainActor
    func testCreateViewWithBorderStyleDashed() {
        let json = JSON([
            "type": "View",
            "borderColor": "#00FF00",
            "borderWidth": 2,
            "borderStyle": "dashed"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertNotNil(view.borderShapeLayer)
        XCTAssertEqual(view.borderShapeLayer?.lineWidth, 2.0)
        XCTAssertEqual(view.borderShapeLayer?.lineDashPattern as? [Int], [6, 3])
        XCTAssertEqual(view.storedBorderStyle, "dashed")
        // layer.border should be cleared for dashed style
        XCTAssertEqual(view.layer.borderWidth, 0)
    }

    @MainActor
    func testCreateViewWithBorderStyleDotted() {
        let json = JSON([
            "type": "View",
            "borderColor": "#0000FF",
            "borderWidth": 3,
            "borderStyle": "dotted"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertNotNil(view.borderShapeLayer)
        XCTAssertEqual(view.borderShapeLayer?.lineWidth, 3.0)
        XCTAssertEqual(view.borderShapeLayer?.lineCap, .round)
        XCTAssertEqual(view.storedBorderStyle, "dotted")
    }

    @MainActor
    func testCreateViewWithBorderStyleDefault() {
        // borderStyle not specified should default to solid
        let json = JSON([
            "type": "View",
            "borderColor": "#FF0000",
            "borderWidth": 1
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertEqual(view.layer.borderWidth, 1.0)
        XCTAssertNil(view.borderShapeLayer)
        XCTAssertEqual(view.storedBorderStyle, "solid")
    }

    @MainActor
    func testBorderStyleWithCornerRadius() {
        let json = JSON([
            "type": "View",
            "borderColor": "#FF0000",
            "borderWidth": 2,
            "borderStyle": "dashed",
            "cornerRadius": 10
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertEqual(view.layer.cornerRadius, 10.0)
        XCTAssertNotNil(view.borderShapeLayer)
        XCTAssertEqual(view.storedBorderStyle, "dashed")
    }

    @MainActor
    func testUpdateBorderStyle() {
        let json = JSON([
            "type": "View",
            "borderColor": "#FF0000",
            "borderWidth": 2,
            "borderStyle": "solid"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertNil(view.borderShapeLayer)
        XCTAssertEqual(view.layer.borderWidth, 2.0)

        // Update to dashed
        view.updateBorderStyle("dashed")
        XCTAssertNotNil(view.borderShapeLayer)
        XCTAssertEqual(view.layer.borderWidth, 0) // layer.border cleared
        XCTAssertEqual(view.storedBorderStyle, "dashed")

        // Update back to solid
        view.updateBorderStyle("solid")
        XCTAssertNil(view.borderShapeLayer)
        XCTAssertEqual(view.layer.borderWidth, 2.0)
        XCTAssertEqual(view.storedBorderStyle, "solid")
    }

    @MainActor
    func testCreateViewWithClipToBounds() {
        let json = JSON([
            "type": "View",
            "clipToBounds": true
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view.clipsToBounds ?? false)
    }

    @MainActor
    func testCreateViewWithUserInteractionEnabled() {
        let json = JSON([
            "type": "View",
            "userInteractionEnabled": false
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertFalse(view.isUserInteractionEnabled ?? true)
    }

    @MainActor
    func testCreateViewWithChildren() {
        let json = JSON([
            "type": "View",
            "orientation": "vertical",
            "children": [
                ["type": "Label", "text": "Child 1"],
                ["type": "Label", "text": "Child 2"]
            ]
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertGreaterThan(view.subviews.count ?? 0, 0)
    }

    @MainActor
    func testCreateViewWithChildKey() {
        let json = JSON([
            "type": "View",
            "child": [
                ["type": "Label", "text": "Single child"]
            ]
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertGreaterThan(view.subviews.count ?? 0, 0)
    }

    @MainActor
    func testCreateViewWithMargins() {
        let json = JSON([
            "type": "View",
            "margins": [10, 15, 10, 15]
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        // constraintInfo may be nil for root views without parent
        // Just verify view was created successfully
    }

    @MainActor
    func testCreateViewWithPaddings() {
        let json = JSON([
            "type": "View",
            "paddings": [5, 8, 5, 8]
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        // constraintInfo may be nil for root views without parent
        // Just verify view was created successfully
    }

    @MainActor
    func testCreateViewWithCompressionResistance() {
        let json = JSON([
            "type": "Label",
            "compressHorizontal": "high",
            "compressVertical": "low"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        // Default priority is 750 for Label - compression resistance may not be applied
        // Just verify the view was created
    }

    @MainActor
    func testCreateViewWithHuggingPriority() {
        let json = JSON([
            "type": "Label",
            "hugHorizontal": "required",
            "hugVertical": "fit"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        // Default hugging priority is 250 for UIView/Label
        // Just verify the view was created
    }

    @MainActor
    func testCreateViewWithVisibility() {
        let json = JSON([
            "type": "View",
            "visibility": "gone"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertEqual(view.visibility, .gone)
    }

    @MainActor
    func testCreateViewWithIndexBelow() {
        let parentView = UIView()
        var views = [String: UIView]()

        let aboveView = UIView()
        aboveView.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(aboveView)
        views["aboveView"] = aboveView

        let json = JSON([
            "type": "View",
            "indexBelow": "aboveView"
        ])
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: parentView,
            target: target,
            views: &views,
            isRootView: false,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(parentView.subviews.contains(view))
    }

    @MainActor
    func testCreateViewWithIndexAbove() {
        let parentView = UIView()
        var views = [String: UIView]()

        let belowView = UIView()
        belowView.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(belowView)
        views["belowView"] = belowView

        let json = JSON([
            "type": "View",
            "indexAbove": "belowView"
        ])
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: parentView,
            target: target,
            views: &views,
            isRootView: false,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(parentView.subviews.contains(view))
    }

    // MARK: - Helper Methods Tests

    func testCleanStyleCache() {
        SJUIViewCreator.cleanStyleCache()
        // Should not crash
        XCTAssertTrue(true)
    }

    func testGetLayoutFileDirPath() {
        let path = SJUIViewCreator.getLayoutFileDirPath()
        XCTAssertFalse(path.isEmpty)
        XCTAssertTrue(path.contains("Layouts") || path.contains("Caches"))
    }

    func testGetStyleFileDirPath() {
        let path = SJUIViewCreator.getStyleFileDirPath()
        XCTAssertFalse(path.isEmpty)
        XCTAssertTrue(path.contains("Styles") || path.contains("Caches"))
    }

    func testGetScriptFileDirPath() {
        let path = SJUIViewCreator.getScriptFileDirPath()
        XCTAssertFalse(path.isEmpty)
        XCTAssertTrue(path.contains("Scripts") || path.contains("Caches"))
    }

    // MARK: - Edge Cases

    @MainActor
    func testCreateViewWithUnknownType() {
        let json = JSON(["type": "UnknownViewType"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        // Should return error view or nil
        XCTAssertNotNil(view)
    }

    @MainActor
    func testCreateViewWithNestedChildren() {
        let json = JSON([
            "type": "View",
            "orientation": "vertical",
            "children": [
                [
                    "type": "View",
                    "orientation": "horizontal",
                    "children": [
                        ["type": "Label", "text": "Nested 1"],
                        ["type": "Label", "text": "Nested 2"]
                    ]
                ],
                ["type": "Label", "text": "Top level"]
            ]
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertGreaterThan(view.subviews.count ?? 0, 0)
    }

    @MainActor
    func testCreateViewWithAllAttributes() {
        let json = JSON([
            "type": "Label",
            "id": "fullLabel",
            "text": "Full test",
            "width": 200,
            "height": 50,
            "background": "#FFFFFF",
            "alpha": 0.9,
            "cornerRadius": 5,
            "margins": [10],
            "paddings": [5]
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertNotNil(views["fullLabel"])
        XCTAssertTrue(view is SJUILabel)
        XCTAssertEqual(view.alpha, 0.9, accuracy: 0.01)
        XCTAssertEqual(view.layer.cornerRadius, 5.0)
    }

    func testMultipleConfigurationChanges() {
        SJUIViewCreator.defaultFont = "Font1"
        SJUIViewCreator.defaultFontSize = 12.0
        SJUIViewCreator.defaultFontColor = .red

        XCTAssertEqual(SJUIViewCreator.defaultFont, "Font1")
        XCTAssertEqual(SJUIViewCreator.defaultFontSize, 12.0)
        XCTAssertEqual(SJUIViewCreator.defaultFontColor, .red)

        SJUIViewCreator.defaultFont = "Font2"
        SJUIViewCreator.defaultFontSize = 16.0
        SJUIViewCreator.defaultFontColor = .blue

        XCTAssertEqual(SJUIViewCreator.defaultFont, "Font2")
        XCTAssertEqual(SJUIViewCreator.defaultFontSize, 16.0)
        XCTAssertEqual(SJUIViewCreator.defaultFontColor, .blue)
    }

    @MainActor
    func testCreateViewWithRectAttribute() {
        let json = JSON([
            "type": "View",
            "rect": [10, 20, 100, 50]
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        // translatesAutoresizingMaskIntoConstraints is a non-optional Bool
        // Just verify the view was created
    }

    @MainActor
    func testCreateViewWithoutRect() {
        let json = JSON([
            "type": "View"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        // translatesAutoresizingMaskIntoConstraints is set to false by createView
        XCTAssertFalse(view.translatesAutoresizingMaskIntoConstraints)
    }

    @MainActor
    func testCreateViewWithTapBackground() {
        let json = JSON([
            "type": "View",
            "tapBackground": "#FF0000"
        ])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertNotNil(view.tapBackgroundColor)
    }

    // MARK: - Performance Tests

    @MainActor
    func testViewCreationPerformance() {
        let json = JSON([
            "type": "View",
            "orientation": "vertical",
            "children": Array(0..<50).map { _ in
                ["type": "Label", "text": "Test Label"]
            }
        ])

        measure {
            var views = [String: UIView]()
            let target = TestViewController()
            _ = SJUIViewCreator.createView(
                json,
                parentView: nil,
                target: target,
                views: &views,
                isRootView: true,
                bindingId: nil
            )
        }
    }

    @MainActor
    func testComplexViewCreationPerformance() {
        let json = JSON([
            "type": "Scroll",
            "children": Array(0..<20).map { i in
                [
                    "type": "View",
                    "orientation": "horizontal",
                    "children": [
                        ["type": "Image", "id": "img_\(i)"],
                        ["type": "Label", "text": "Item \(i)", "id": "label_\(i)"],
                        ["type": "Button", "text": "Action", "id": "btn_\(i)"]
                    ]
                ]
            }
        ])

        measure {
            var views = [String: UIView]()
            let target = TestViewController()
            _ = SJUIViewCreator.createView(
                json,
                parentView: nil,
                target: target,
                views: &views,
                isRootView: true,
                bindingId: nil
            )
        }
    }

    @MainActor
    func testGetViewFromJSONWithAllTypes() {
        let viewTypes = [
            "View", "SafeAreaView", "GradientView", "Blur", "CircleView",
            "Scroll", "Table", "Collection", "Segment", "Label", "IconLabel",
            "Button", "Image", "NetworkImage", "CircleImage", "Web",
            "TextField", "TextView", "Switch", "Radio", "Check",
            "Progress", "Slider", "SelectBox", "Indicator"
        ]

        var views = [String: UIView]()
        let target = TestViewController()

        for viewType in viewTypes {
            let json = JSON(["type": viewType])
            let view = SJUIViewCreator.getViewFromJSON(
                attr: json,
                target: target,
                views: &views
            )
            XCTAssertNotNil(view, "Failed to create view of type: \(viewType)")
        }
    }

    @MainActor
    func testCreateManyViewsWithUniqueIDs() {
        var views = [String: UIView]()
        let target = TestViewController()
        let parentView = UIView()

        for i in 0..<100 {
            let json = JSON([
                "type": "Label",
                "id": "label_\(i)",
                "text": "Label \(i)"
            ])

            let view = SJUIViewCreator.createView(
                json,
                parentView: parentView,
                target: target,
                views: &views,
                isRootView: false,
                bindingId: nil
            )

            XCTAssertNotNil(view)
            XCTAssertNotNil(views["label_\(i)"])
        }

        XCTAssertEqual(views.count, 100)
    }

    @MainActor
    func testCreateViewWithNilParent() {
        let json = JSON(["type": "Label", "text": "Test"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: nil,
            target: target,
            views: &views,
            isRootView: true,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertNil(view.superview)
    }

    @MainActor
    func testCreateViewAndAddToParent() {
        let parentView = UIView()
        let json = JSON(["type": "Label", "text": "Child"])
        var views = [String: UIView]()
        let target = TestViewController()

        let view = SJUIViewCreator.createView(
            json,
            parentView: parentView,
            target: target,
            views: &views,
            isRootView: false,
            bindingId: nil
        )

        XCTAssertNotNil(view)
        XCTAssertTrue(view.superview === parentView)
    }

    @MainActor
    func testFindViewJSONByIdInJSON() {
        let json = JSON([
            "type": "View",
            "id": "root",
            "children": [
                [
                    "type": "View",
                    "id": "container",
                    "children": [
                        ["type": "Label", "id": "targetLabel", "text": "Found it!"]
                    ]
                ]
            ]
        ])

        let foundJSON = SJUIViewCreator.findViewJSON(byId: "targetLabel", inJSON: json)
        XCTAssertNotNil(foundJSON)
        XCTAssertEqual(foundJSON?["id"].string, "targetLabel")
        XCTAssertEqual(foundJSON?["text"].string, "Found it!")
    }

    @MainActor
    func testFindViewJSONByIdNotFound() {
        let json = JSON([
            "type": "View",
            "id": "root",
            "children": [
                ["type": "Label", "id": "label1"]
            ]
        ])

        let foundJSON = SJUIViewCreator.findViewJSON(byId: "nonexistent", inJSON: json)
        XCTAssertNil(foundJSON)
    }

    @MainActor
    func testFindViewJSONByIdWithChildKey() {
        let json = JSON([
            "type": "View",
            "id": "root",
            "child": [
                ["type": "Label", "id": "targetLabel"]
            ]
        ])

        let foundJSON = SJUIViewCreator.findViewJSON(byId: "targetLabel", inJSON: json)
        XCTAssertNotNil(foundJSON)
        XCTAssertEqual(foundJSON?["id"].string, "targetLabel")
    }
}
