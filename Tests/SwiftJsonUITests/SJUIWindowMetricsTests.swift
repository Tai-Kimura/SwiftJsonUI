import XCTest
@testable import SwiftJsonUI

/// Both branches of the window/screen choice, including the one that only runs
/// where a unit test cannot go. That is why `resolve` is a pure function: a helper
/// that only reads the live scene graph has a fallback nobody measures.
final class SJUIWindowMetricsTests: XCTestCase {

    private let window = CGRect(x: 0, y: 0, width: 390, height: 844)
    private let sceneWindow = CGRect(x: 0, y: 0, width: 320, height: 1024)
    private let screen = CGRect(x: 0, y: 0, width: 1024, height: 1366)

    func testTheViewsOwnWindowWins() {
        XCTAssertEqual(
            SJUIWindowMetrics.resolve(viewWindow: window, activeSceneWindow: sceneWindow, fallback: screen),
            window)
    }

    /// The case the whole change exists for: a window narrower than the display.
    /// Answering with the screen here is what made keyboard avoidance read
    /// "dismissed" in Split View.
    func testASplitViewWindowIsNotTheScreen() {
        let resolved = SJUIWindowMetrics.resolve(
            viewWindow: nil, activeSceneWindow: sceneWindow, fallback: screen)
        XCTAssertEqual(resolved, sceneWindow)
        XCTAssertNotEqual(resolved, screen, "the scene's window must win over the display")
    }

    func testWithNoViewAndNoSceneItFallsBack() {
        XCTAssertEqual(
            SJUIWindowMetrics.resolve(viewWindow: nil, activeSceneWindow: nil, fallback: screen),
            screen)
    }

    /// An empty rect is what a detached view reports. Treating it as an answer
    /// gives every caller a zero height to compare against.
    func testAnEmptyRectIsNotAnAnswer() {
        XCTAssertEqual(
            SJUIWindowMetrics.resolve(viewWindow: .zero, activeSceneWindow: sceneWindow, fallback: screen),
            sceneWindow)
        XCTAssertEqual(
            SJUIWindowMetrics.resolve(viewWindow: .zero, activeSceneWindow: .zero, fallback: screen),
            screen)
    }

    /// The wiring, which the pure tests cannot see: `bounds()` must be the seam
    /// applied to the live inputs, not some other computation.
    ///
    /// ⚠️ This does NOT assert the result is non-empty. The unit-test host has no
    /// window scene, so "unknown" is the correct answer there — an arm demanding a
    /// number would be asserting the host's shape, not the helper's contract.
    /// (Measured: the first version of this arm did exactly that and failed.)
    @MainActor
    func testTheLiveCallIsTheSeamAppliedToLiveInputs() {
        let expected = SJUIWindowMetrics.resolve(
            viewWindow: nil,
            activeSceneWindow: SJUIWindowMetrics.activeSceneWindowBounds(),
            fallback: SJUIWindowMetrics.legacyScreenBounds())
        XCTAssertEqual(SJUIWindowMetrics.bounds(), expected)
    }

    /// A view inside a window must win over whatever the scene says.
    @MainActor
    func testAViewsWindowIsPreferredLive() {
        let host = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        let view = UIView(frame: .zero)
        host.addSubview(view)
        XCTAssertEqual(SJUIWindowMetrics.bounds(for: view), host.bounds)
    }

    /// With no scene the helper says "unknown" rather than inventing a size.
    func testNoSceneMeansUnknownNotAGuess() {
        XCTAssertTrue(
            SJUIWindowMetrics.resolve(viewWindow: nil, activeSceneWindow: nil, fallback: .zero).isEmpty,
            "an unknown area must stay empty so callers use their own bounds")
    }
}
