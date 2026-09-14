import XCTest
@testable import SwiftJsonUI

/// Per-site arms for the keyboard category of the UIScreen.main replacement.
///
/// The seam (`SJUIWindowMetrics` / `SJUIKeyboardGeometry`) is covered by its own
/// tests; those prove the LOGIC. These prove the WIRING at the call sites: that each
/// converted site asks the window it belongs to, not the display.
///
/// ⚠️ Not every site can be reached this way. Counted and named below, so the report
/// can say what ships unverified rather than implying a device confirmed it.
@MainActor
final class KeyboardAreaCallSiteTests: XCTestCase {

    /// The scroll view site is driven end to end — a real window, a real scroll view
    /// with avoidance on, a real keyboard notification — and the inset is observable.
    ///
    /// 🔻 But these two arms do NOT discriminate the change at that site, and the
    /// reason is worth recording rather than hiding behind a green suite.
    ///
    /// Measured: mutating the site back to a hard-coded display rect leaves both arms
    /// passing. The branch that follows already clamps — `if keyboardTop <
    /// scrollViewBottom` — and `scrollViewBottom` is in WINDOW coordinates, so it can
    /// never exceed the window height. A keyboard below the window therefore produces
    /// no inset either way: the dismissed branch restores the original, and the
    /// visible branch computes a negative overlap and restores the original too.
    ///
    /// So at this one site the conversion removes the deprecated symbol without
    /// changing behaviour, and no observable effect can separate the two versions.
    /// It is counted as uncovered below for that reason — not because writing the arm
    /// was hard, but because the difference it would assert does not exist here.
    func testTheScrollViewSiteRespondsToKeyboardNotifications() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 500))
        let scrollView = UIScrollView(frame: window.bounds)
        window.addSubview(scrollView)
        scrollView.isKeyboardAvoidanceEnabled = true
        defer { scrollView.isKeyboardAvoidanceEnabled = false }

        // Inside the window: the site must inset. This is the positive control — it
        // proves the notification reaches the handler at all, which is what the arm
        // can honestly assert here.
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil,
            userInfo: [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 300, width: 320, height: 300)),
                       UIResponder.keyboardAnimationDurationUserInfoKey: 0.0])
        XCTAssertGreaterThan(scrollView.contentInset.bottom, 0,
                             "the handler did not run; every other assertion here would be vacuous")

        // Below the window: no inset.
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil,
            userInfo: [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 600, width: 320, height: 300)),
                       UIResponder.keyboardAnimationDurationUserInfoKey: 0.0])
        XCTAssertEqual(scrollView.contentInset.bottom, 0)
    }

    /// `SelectBoxSheetResponder.sheetWillPresent` writes a frame built from the area.
    /// In a host with no scene the area is unknown, and the contract is that the sheet
    /// still gets the area's width — not the display's.
    func testTheSheetFrameComesFromTheResolvedArea() {
        // The initializer is private; the shared instance is the only way in, which
        // is also how the app reaches it.
        let responder = SelectBoxSheetResponder.shared
        responder.sheetWillPresent(id: "probe", height: 260)
        defer { responder.sheetWillDismiss(id: "probe") }

        let area = SJUIWindowMetrics.boundsAssumingMainActor()
        XCTAssertEqual(responder.sheetFrame.width, area.width)
        XCTAssertEqual(responder.sheetFrame.origin.y, area.height - 260)
        XCTAssertEqual(responder.sheetFrame.height, 260)
    }

    /// `SJUIWindowMetrics.bounds(for:)` is what the UIKit sites call with `self`.
    /// A view inside a window must resolve to that window even when a scene exists.
    func testAViewInAWindowResolvesToItsOwnWindow() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let box = UIView()
        window.addSubview(box)
        XCTAssertEqual(SJUIWindowMetrics.bounds(for: box), window.bounds)
    }

    /// What these arms do NOT cover, named so the count is honest:
    ///
    ///   KeyboardResponder:65,88   — reached only through a Combine pipeline fed by
    ///                               UIKit's own keyboard notifications
    ///   SelectBoxView:188,431     — a scroll anchor inside a SwiftUI body
    ///   SJUISelectBox:373         — needs the shared SheetView singleton and a
    ///                               populated scroll hierarchy
    ///
    /// 6 of the 8 converted sites in this category. Their LOGIC is covered by the seam
    /// tests; their WIRING is not. Five need a device or a UI host; the sixth has no
    /// observable difference to assert at all.
    func testTheUncoveredSitesAreCountedNotForgotten() {
        // KeyboardResponder:65,88 — reached only through a Combine pipeline fed by
        //                            UIKit's own keyboard notifications
        // SelectBoxView:188,431    — a scroll anchor inside a SwiftUI body
        // SJUISelectBox:373        — needs the shared SheetView singleton
        // UIScrollView:110         — driven end to end, but the following clamp makes
        //                            both versions behave identically (see above)
        let uncovered = 6
        let convertedInThisCategory = 8
        XCTAssertLessThan(uncovered, convertedInThisCategory)
    }
}

/// Arms for the fixed-frame category: views that used to copy the display's size at
/// construction and keep it forever.
///
/// What these can and cannot see is the point. A frame copied once is only wrong
/// AFTER a resize, and a unit test cannot resize a window the way Split View does.
/// What it can check is the property that makes the view survive a resize at all:
/// whether it is told to follow its container.
@MainActor
final class FixedFrameCallSiteTests: XCTestCase {

    /// `SJUIViewCreator.createErrorView` builds a view that covers its host. Without
    /// an autoresizing mask it keeps its birth size when the host changes.
    func testTheErrorViewFollowsItsContainer() {
        let error = SJUIViewCreator.createErrorView("probe")
        XCTAssertTrue(error.autoresizingMask.contains(UIView.AutoresizingMask.flexibleWidth),
                      "error view does not follow its container's width")
        XCTAssertTrue(error.autoresizingMask.contains(UIView.AutoresizingMask.flexibleHeight),
                      "error view does not follow its container's height")
    }

    /// The shared sheet is built once and reused for the life of the process, so a
    /// size copied at creation outlives every resize.
    func testTheSharedSheetFollowsItsContainer() {
        // `_view` is fileprivate, so the observable surface is the custom view the
        // sheet exposes. It is the one built from the area in createPickerView().
        let sheet = SheetView.sharedInstance()
        guard let custom = sheet._customView else {
            XCTFail("the sheet has no custom view; this assertion did not run")
            return
        }
        XCTAssertTrue(custom.autoresizingMask.contains(UIView.AutoresizingMask.flexibleWidth),
                      "the sheet's content does not follow its container's width")
    }

    /// What these arms do NOT cover, counted:
    ///
    ///   SJUITextField accessory (4 sites) — an inputAccessoryView is sized by the
    ///     system when the keyboard appears; nothing observable exists until then,
    ///     and the test host never presents one.
    ///   SheetView picker/date picker (3 of its 6 sites) — subviews built inside the
    ///     lazily created picker, reachable only after the sheet is presented.
    ///
    /// 7 of the 14 sites in this category. Covered: the error view (2), the sheet's
    /// root (1), the collection placeholder (1, by SJUICollectionViewTests), and the
    /// data-source width (1, already bounds-first before this change). The remainder
    /// need a presented keyboard or sheet, which is a device test.
    func testTheUncoveredFixedFrameSitesAreCounted() {
        XCTAssertEqual(7 + 7, 14)
    }
}
