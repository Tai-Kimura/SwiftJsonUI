import QuartzCore
import UIKit
import XCTest
@testable import SwiftJsonUI

/// The image fading in on the layer view moves by the fade alone (ticket
/// sjui-networkimage-load-complete-flickers): with a load done before the
/// renderer came, the fade is T/2 (120 ms), and the layer's own 0.25 s
/// animations of contents and opacity outlived it — the image dimmed for a
/// frame and faded in again.
@MainActor
final class NetworkImageLayerFadeTests: XCTestCase {
    private func image() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { ctx in
            UIColor.white.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }

    /// A bare CALayer on screen animates each of these by itself for 0.25 s
    /// when it changes (measured on a simulator recording; a test process
    /// draws nothing, so it answers no implicit animation here): the image
    /// layer turns them off.
    func testTheImageLayerDoesNotAnimateByItself() {
        let view = NetworkImageLayerView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let actions = view.imageLayerForTesting.actions ?? [:]
        for key in ["contents", "opacity", "contentsScale", "bounds", "position"] {
            XCTAssertTrue(actions[key] is NSNull, "the image layer animates \(key) by itself")
        }
    }

    func testTheFadeIsTheOnlyAnimation() throws {
        let view = NetworkImageLayerView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        CATransaction.begin()
        view.finish(image: image(), source: .network) {}
        let keys = view.imageLayerForTesting.animationKeys() ?? []
        CATransaction.commit()
        XCTAssertEqual(keys, ["networkImageFade"], "the image layer animated by itself too: \(keys)")
        let fade = try XCTUnwrap(view.imageLayerForTesting.animation(forKey: "networkImageFade"))
        XCTAssertEqual(fade.duration, 0.12, accuracy: 1e-9, "a load done before the renderer came fades over T/2")
    }
}
