import XCTest
@testable import SwiftJsonUI

/// Why the deprecated `contentEdgeInsets` arm could be removed without changing a
/// pixel: it was unreachable.
///
/// It sat behind `#available(iOS 15, *), b.configuration != nil`. The deployment floor
/// is iOS 17, so the availability half was always true, and the configuration is
/// assigned on every path above — a declared style picks one, and the else there
/// assigns `.plain()`. These arms hold that second half in place: if a future change
/// lets a button reach padding with a nil configuration, the padding silently stops
/// being applied, and the first arm here goes red rather than a screen losing its
/// insets quietly.
final class SJUIButtonInsetsProbe: XCTestCase {

    private func button(_ json: [String: Any]) -> UIButton {
        var views = [String: UIView]()
        return SJUIButton.createFromJSON(attr: JSON(json), target: self, views: &views)
    }

    /// A button with NO style declared and padding set — the case the deprecated
    /// branch was believed to serve.
    func testAStylelessPaddedButtonStillHasAConfiguration() {
        let b = button(["type": "Button", "leftPadding": 12, "rightPadding": 12,
                        "paddingTop": 8, "paddingBottom": 8])
        XCTAssertNotNil(b.configuration,
                        "a styleless button has no configuration — the deprecated branch IS reachable")
    }

    /// And with a style, for the control side.
    func testAStyledButtonHasAConfiguration() {
        let b = button(["type": "Button", "config": ["style": "filled"],
                        "leftPadding": 12])
        XCTAssertNotNil(b.configuration)
    }

    /// The padding lands in the configuration. Asserted on the configuration
    /// specifically, not "somewhere": the earlier version accepted either destination,
    /// which would have stayed green if the insets stopped being applied to the one
    /// that ships.
    func testThePaddingLandsInTheConfiguration() {
        let b = button(["type": "Button", "leftPadding": 12, "paddingTop": 8])
        let insets = b.configuration?.contentInsets
        XCTAssertEqual(insets?.leading, 12)
        XCTAssertEqual(insets?.top, 8)
    }
}
