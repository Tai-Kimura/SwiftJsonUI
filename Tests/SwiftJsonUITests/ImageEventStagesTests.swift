//
//  ImageEventStagesTests.swift
//  SwiftJsonUITests
//
//  The events stage on Image and NetworkImage. Their chains were hand-picked,
//  and NetworkImage's never called the events stage: onClick, onLongPress,
//  onPan, onPinch, onAppear and onDisappear were all dropped in Dynamic while
//  codegen emitted every one (measured 2026-09-25, XCUITest: a NetworkImage
//  with onClick was an image that a tap did not reach). Image carried an
//  onClick tap of its own and dropped the rest. Both now run the standard
//  chain (ImageStandardChainTests holds every stage to it); these arms say
//  what the events stage does there.
//
//  Two arms, each red when the events stage leaves either converter:
//    - onAppear, rendered: the converted view goes into a window and its
//      handler has to be called. A plain view's onAppear in the same window
//      is the control that the window renders at all.
//    - the gestures, read from the converted view (`dump`): a tap for
//      onClick and a long press for onLongPress, none without a handler, and
//      none behind `canTap: false` or `enabled: false`. The same read on a
//      View, which reaches the events stage through applyStandardModifiers,
//      is the control that `dump` shows a gesture at all.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class ImageEventStagesTests: XCTestCase {

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }

    private func dumped<V>(_ view: V) -> String {
        var out = ""
        dump(view, to: &out)
        return out
    }

    /// Both converters, for the same attributes.
    private func converted(_ type: String, _ attributes: String, data: [String: Any]) throws -> AnyView {
        let json = #"{"type": "\#(type)", "id": "probe", "width": 40, "height": 40\#(attributes)}"#
        let c = try component(json)
        switch type {
        case "NetworkImage":
            return NetworkImageConverter.convert(component: c, data: data)
        default:
            return ImageViewConverter.convert(component: c, data: data)
        }
    }

    private static let types = ["Image", "CircleImage", "NetworkImage"]

    // MARK: - onAppear, rendered

    private static var hostWindow: UIWindow?

    /// Renders `view` in a key window until `done` holds or 10 s pass.
    private func render<V: View>(_ view: V, until done: @escaping () -> Bool) -> Bool {
        let window: UIWindow
        if let existing = Self.hostWindow {
            window = existing
        } else {
            let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
            window = scene.map { UIWindow(windowScene: $0) } ?? UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            window.makeKeyAndVisible()
            Self.hostWindow = window
        }
        window.rootViewController = UIHostingController(rootView: view)
        defer { window.rootViewController = nil }
        let deadline = Date().addingTimeInterval(10)
        while !done() && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        return done()
    }

    func testOnAppearIsCalledForEachImageType() throws {
        // Control: the window renders, and an onAppear in it is called.
        var plainAppeared = false
        XCTAssertTrue(render(Color.clear.frame(width: 40, height: 40).onAppear { plainAppeared = true },
                             until: { plainAppeared }),
                      "control: a plain view's onAppear was not called — the window rendered nothing, so the arm below measures nothing")

        for type in Self.types {
            var appeared = 0
            let data: [String: Any] = ["probeAppeared": { () -> Void in appeared += 1 }]
            let view = try converted(type, #", "url": "data:,", "srcName": "probe_asset", "onAppear": "probeAppeared""#, data: data)
            XCTAssertTrue(render(view, until: { appeared > 0 }), "\(type): onAppear was not called")
        }
    }

    // MARK: - The gestures, read

    private static let tap = "TapGesture"
    private static let longPress = "LongPressGesture"

    /// The handlers the layouts name. Image's own tap (before the events
    /// stage) attached only when the handler was in the data, so leaving them
    /// out would read a tap it did attach as missing.
    private static let handlers: [String: Any] = [
        "onProbe": { () -> Void in },
        "onLong": { () -> Void in },
    ]

    func testControlDumpShowsTheGesturesOfAViewThroughTheStandardChain() throws {
        let c = try component(#"{"type": "View", "id": "probe", "onClick": "@{onProbe}", "onLongPress": "@{onLong}"}"#)
        let text = dumped(DynamicModifierHelper.applyStandardModifiers(AnyView(Color.clear), component: c, data: Self.handlers))
        XCTAssertTrue(text.contains(Self.tap), "control: a View's onClick shows no tap in the dump — this read cannot see a gesture")
        XCTAssertTrue(text.contains(Self.longPress), "control: a View's onLongPress shows no long press in the dump")
    }

    func testOnClickAndOnLongPressAttachTheirGestures() throws {
        for type in Self.types {
            let none = dumped(try converted(type, "", data: Self.handlers))
            XCTAssertFalse(none.contains(Self.tap), "\(type): a tap with no handler")
            XCTAssertFalse(none.contains(Self.longPress), "\(type): a long press with no handler")

            let tapped = dumped(try converted(type, #", "onClick": "@{onProbe}""#, data: Self.handlers))
            XCTAssertTrue(tapped.contains(Self.tap), "\(type): onClick attached no tap")

            let selector = dumped(try converted(type, #", "onclick": "onProbe""#, data: Self.handlers))
            XCTAssertTrue(selector.contains(Self.tap), "\(type): the onclick selector attached no tap")

            let pressed = dumped(try converted(type, #", "onLongPress": "@{onLong}""#, data: Self.handlers))
            XCTAssertTrue(pressed.contains(Self.longPress), "\(type): onLongPress attached no long press")
        }
    }

    func testCanTapFalseAndEnabledFalseShutTheTap() throws {
        for type in Self.types {
            let gated = dumped(try converted(type, #", "onClick": "@{onProbe}", "canTap": false"#, data: Self.handlers))
            XCTAssertFalse(gated.contains(Self.tap), "\(type): canTap false still tapped")

            let bound = dumped(try converted(type, #", "onClick": "@{onProbe}", "canTap": "@{tappable}""#,
                                             data: Self.handlers.merging(["tappable": false]) { $1 }))
            XCTAssertFalse(bound.contains(Self.tap), "\(type): canTap bound to false still tapped")

            let disabled = dumped(try converted(type, #", "onClick": "@{onProbe}", "enabled": false"#, data: Self.handlers))
            XCTAssertFalse(disabled.contains(Self.tap), "\(type): enabled false still tapped")
        }
    }
}
#endif
