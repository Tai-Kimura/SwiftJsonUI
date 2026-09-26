//
//  PressedBackgroundTests.swift
//  SwiftJsonUITests
//
//  tapBackground is the background while pressed, on every node with a tap
//  (onClick) and on a Button (jsonui-cli 1.9.0). Dynamic drew it on a View
//  only — any View with a tapBackground, tap or none, around the content alone
//  (inside the padding and the frame) — and on no other type.
//
//  Here: which nodes draw it (DynamicEventHelper.pressedBackgroundColor, the
//  one question the background slot and the tap both ask), what the background
//  slot draws pressed and at rest, and a built View at rest. Whether a real
//  touch presses it — and still taps — is the ConformanceHost probe's
//  (PressedBackgroundProbeUITests), which touches the screen.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
@MainActor
final class PressedBackgroundTests: XCTestCase {

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: json.data(using: .utf8)!)
    }

    private func pressedColor(_ json: String, data: [String: Any] = [:]) throws -> Color? {
        DynamicEventHelper.pressedBackgroundColor(try component(json), data: data)
    }

    func testEveryTypeWithATapHasIt() throws {
        for type in ["View", "Label", "Image", "IconLabel", "GradientView"] {
            XCTAssertNotNil(try pressedColor(##"{"type":"\##(type)","onClick":"@{t}","tapBackground":"#FF0000"}"##), type)
        }
    }

    func testANodeWithoutATapHasNone() throws {
        XCTAssertNil(try pressedColor(##"{"type":"View","tapBackground":"#FF0000"}"##), "no handler")
        XCTAssertNil(try pressedColor(##"{"type":"View","onClick":"@{t}","canTap":false,"tapBackground":"#FF0000"}"##), "canTap false")
        XCTAssertNil(try pressedColor(##"{"type":"View","onClick":"@{t}","enabled":false,"tapBackground":"#FF0000"}"##), "disabled")
        XCTAssertNil(try pressedColor(##"{"type":"View","onClick":"@{t}","canTap":"@{gate}","tapBackground":"#FF0000"}"##, data: ["gate": false]),
                     "a bound canTap that is false")
        // A control calls its onClick from its operation; a text field never
        // does. Neither gets a tap, so neither is pressed.
        XCTAssertNil(try pressedColor(##"{"type":"Switch","onClick":"@{t}","tapBackground":"#FF0000"}"##))
        XCTAssertNil(try pressedColor(##"{"type":"TextField","onClick":"@{t}","tapBackground":"#FF0000"}"##))
        XCTAssertNil(try pressedColor(##"{"type":"View","onClick":"@{t}"}"##), "no tapBackground")
    }

    func testABoundTapBackgroundResolves() throws {
        XCTAssertNotNil(try pressedColor(##"{"type":"Label","onClick":"@{t}","tapBackground":"@{tb}"}"##, data: ["tb": "#FF0000"]))
    }

    // MARK: - What the background slot draws

    // Pure channels: the system `.red` is (255, 56, 60) in sRGB here.
    private let pureRed = Color(red: 1, green: 0, blue: 0)
    private let pureBlue = Color(red: 0, green: 0, blue: 1)

    private func centrePixel<V: View>(_ view: V, width: CGFloat = 40, height: CGFloat = 40,
                                      at point: (x: Int, y: Int)? = nil) throws -> (r: UInt8, g: UInt8, b: UInt8) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(width: width, height: height)
        guard let image = renderer.cgImage else { throw XCTSkip("render produced no image") }
        let w = image.width, h = image.height
        var buffer = [UInt8](repeating: 0, count: w * h * 4)
        let context = CGContext(data: &buffer, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        let (x, y) = point ?? (w / 2, h / 2)
        let i = (y * w + x) * 4
        return (buffer[i], buffer[i + 1], buffer[i + 2])
    }

    /// Pressed, the pressed colour replaces the base; at rest the base shows.
    /// The state is the environment's, which `tracksPress()` sets.
    func testTheSlotDrawsThePressedColourOnlyWhilePressed() throws {
        let slot = Color.clear.frame(width: 40, height: 40).pressedBackground(pureRed, base: pureBlue)
        let pressed = try centrePixel(slot.environment(\.jsonUIPressed, true))
        let rest = try centrePixel(slot.environment(\.jsonUIPressed, false))
        XCTAssertTrue(pressed.r > 200 && pressed.b < 60, "pressed: \(pressed)")
        XCTAssertTrue(rest.b > 200 && rest.r < 60, "at rest: \(rest)")
    }

    /// A node that tracks its press hands down its own state: a pressed node
    /// around it does not press it, and `enabled: false` hands down "not
    /// pressed".
    func testTracksPressHandsDownItsOwnState() throws {
        let inner = Color.clear.frame(width: 40, height: 40).pressedBackground(pureRed, base: pureBlue)
        let tracked = try centrePixel(inner.tracksPress().environment(\.jsonUIPressed, true))
        let gatedOff = try centrePixel(inner.tracksPress(enabled: false).environment(\.jsonUIPressed, true))
        XCTAssertTrue(tracked.b > 200 && tracked.r < 60, "its own press, not the one around it: \(tracked)")
        XCTAssertTrue(gatedOff.b > 200 && gatedOff.r < 60, "gated off: \(gatedOff)")
    }

    /// A built View with a tap, a background and a tapBackground: at rest it
    /// draws its background, not the pressed colour, over the whole framed
    /// box. (The old StateAwareContainer did too at rest; what it left out of
    /// the padding was the PRESSED colour, which only a touch shows — the
    /// probe's.)
    func testABuiltViewAtRestDrawsItsBackground() throws {
        let node = try component(##"{"type":"View","width":40,"height":40,"paddings":[12,12,12,12],"background":"#0000FF","tapBackground":"#FF0000","onClick":"@{t}","child":[{"type":"View","width":4,"height":4}]}"##)
        let view = DynamicComponentBuilder(component: node, data: ["t": { () -> Void in }], viewId: nil)
        let centre = try centrePixel(view)
        let inPadding = try centrePixel(view, at: (4, 4))
        XCTAssertTrue(centre.b > 200 && centre.r < 60, "at rest: \(centre)")
        XCTAssertTrue(inPadding.b > 200 && inPadding.r < 60, "at rest, in the padding: \(inPadding)")
    }
}
#endif
