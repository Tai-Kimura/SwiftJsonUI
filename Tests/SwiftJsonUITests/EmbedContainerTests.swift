//
//  EmbedContainerTests.swift
//  SwiftJsonUITests
//
//  Tests for the non-view Embed primitives. SwiftUI body composition is
//  not exercised here (that lives in the integration test app under
//  Example/Tests); these tests cover the contracts that don't need a
//  UI host: event routing, navigation boundary, init-params receiver.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class EmbedContainerTests: XCTestCase {

    // MARK: - EmbeddedEvent

    func testEmbeddedEvent_named_carriesNameAndPayload() {
        let event = EmbeddedEvent.named(name: "onOrderUpdated", payload: ["id": 42])
        guard case .named(let name, let payload) = event else {
            return XCTFail("Expected .named")
        }
        XCTAssertEqual(name, "onOrderUpdated")
        XCTAssertEqual(payload["id"] as? Int, 42)
    }

    // MARK: - EmbeddedNavigationDelegate

    func testNavigationDelegate_delegateMode_boundsPopAtRoot() {
        let d = EmbeddedNavigationDelegate(boundedAtEmbed: true)
        XCTAssertTrue(d.shouldBoundPop(internalPushDepth: 0),
                      "delegate mode + at embed root → pop bounded")
    }

    func testNavigationDelegate_delegateMode_doesNotBoundPushedScreens() {
        let d = EmbeddedNavigationDelegate(boundedAtEmbed: true)
        XCTAssertFalse(d.shouldBoundPop(internalPushDepth: 1))
        XCTAssertFalse(d.shouldBoundPop(internalPushDepth: 5))
    }

    func testNavigationDelegate_isolatedMode_neverBoundsPop() {
        let d = EmbeddedNavigationDelegate(boundedAtEmbed: false)
        XCTAssertFalse(d.shouldBoundPop(internalPushDepth: 0))
        XCTAssertFalse(d.shouldBoundPop(internalPushDepth: 3))
    }

    // MARK: - EmbeddedScreenContext.emit

    func testEmit_routesNamedEventToBridge() {
        var captured: EmbeddedEvent?
        let ctx = EmbeddedScreenContext(
            embedId: "detail",
            screen: "order_detail",
            params: ["orderId": "abc"],
            navigationDelegate: EmbeddedNavigationDelegate(boundedAtEmbed: true),
            eventBridge: { captured = $0 }
        )
        ctx.emit("onOrderUpdated", payload: ["id": 7])

        guard case .named(let name, let payload) = captured else {
            return XCTFail("emit must produce .named")
        }
        XCTAssertEqual(name, "onOrderUpdated")
        XCTAssertEqual(payload["id"] as? Int, 7)
    }

    func testEmit_withoutBridge_isNoop() {
        let ctx = EmbeddedScreenContext(
            embedId: "standalone",
            screen: "foo",
            params: [:],
            navigationDelegate: EmbeddedNavigationDelegate(boundedAtEmbed: true),
            eventBridge: nil
        )
        // Should not crash, should not emit anywhere.
        ctx.emit("onAnything")
    }

    func testEmit_defaultPayloadIsEmpty() {
        var captured: [String: Any]?
        let ctx = EmbeddedScreenContext(
            embedId: "x",
            screen: "x",
            params: [:],
            navigationDelegate: EmbeddedNavigationDelegate(boundedAtEmbed: false),
            eventBridge: { event in
                if case .named(_, let p) = event { captured = p }
            }
        )
        ctx.emit("onTap")
        XCTAssertEqual(captured?.count, 0)
    }

    // MARK: - EmbeddedInitParamsReceiver

    final class TestVm: EmbeddedInitParamsReceiver {
        var lastParams: [String: Any] = [:]
        var callCount = 0
        func applyInitParams(_ params: [String: Any]) {
            lastParams = params
            callCount += 1
        }
    }

    func testInitParamsReceiver_canBeCalledRepeatedly() {
        let vm = TestVm()
        vm.applyInitParams(["orderId": "a"])
        vm.applyInitParams(["orderId": "b"])
        XCTAssertEqual(vm.callCount, 2)
        XCTAssertEqual(vm.lastParams["orderId"] as? String, "b")
    }

    // MARK: - EmbedNavigationMode enum sanity

    func testEmbedNavigationMode_hasDelegateAndIsolated() {
        let modes: Set<String> = [
            String(describing: EmbedNavigationMode.delegate),
            String(describing: EmbedNavigationMode.isolated)
        ]
        XCTAssertEqual(modes, ["delegate", "isolated"])
    }

    // MARK: - EmbedNavigator (isolated private stack, 10.5.0)

    func testNavigator_pushIncreasesDepth() {
        let nav = EmbedNavigator()
        XCTAssertEqual(nav.depth, 0)
        nav.push(screen: "order_detail")
        XCTAssertEqual(nav.depth, 1)
        nav.push(screen: "order_history", params: ["orderId": "a"])
        XCTAssertEqual(nav.depth, 2)
    }

    func testNavigator_popStopsAtRoot() {
        let nav = EmbedNavigator()
        nav.push(screen: "a")
        nav.pop()
        XCTAssertEqual(nav.depth, 0)
        // Bounded at the embed stack root: extra pops are no-ops, never
        // negative, never escape the embed.
        nav.pop()
        nav.pop()
        XCTAssertEqual(nav.depth, 0)
    }

    func testNavigator_popToRootClearsAllPushedEntries() {
        let nav = EmbedNavigator()
        nav.push(screen: "a")
        nav.push(screen: "b")
        nav.push(screen: "c")
        nav.popToRoot()
        XCTAssertEqual(nav.depth, 0)
        nav.popToRoot() // no-op at root
        XCTAssertEqual(nav.depth, 0)
    }

    func testNavigator_supportsAppDefinedHashableRoutes() {
        struct Route: Hashable { let id: Int }
        let nav = EmbedNavigator()
        nav.push(Route(id: 1))
        XCTAssertEqual(nav.depth, 1)
        nav.pop()
        XCTAssertEqual(nav.depth, 0)
    }

    // MARK: - EmbedDestination hashability

    func testEmbedDestination_equalityIncludesParams() {
        let a = EmbedDestination(screen: "detail", params: ["id": "1"])
        let b = EmbedDestination(screen: "detail", params: ["id": "1"])
        let c = EmbedDestination(screen: "detail", params: ["id": "2"])
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func testEmbedDestination_nestedParamsAffectFingerprint() {
        let a = EmbedDestination(screen: "s", params: ["profile": ["name": "Ada"]])
        let b = EmbedDestination(screen: "s", params: ["profile": ["name": "Bob"]])
        XCTAssertNotEqual(a, b)
    }

    // MARK: - EmbeddedScreenContext.navigator plumbing

    func testContext_carriesNavigatorInIsolatedMode() {
        let nav = EmbedNavigator()
        let ctx = EmbeddedScreenContext(
            embedId: "pane",
            screen: "order_detail",
            params: [:],
            navigationDelegate: EmbeddedNavigationDelegate(boundedAtEmbed: false),
            eventBridge: nil,
            navigator: nav
        )
        XCTAssertTrue(ctx.navigator === nav)
    }

    func testContext_navigatorDefaultsToNilForDelegateMode() {
        let ctx = EmbeddedScreenContext(
            embedId: "pane",
            screen: "order_detail",
            params: [:],
            navigationDelegate: EmbeddedNavigationDelegate(boundedAtEmbed: true),
            eventBridge: nil
        )
        XCTAssertNil(ctx.navigator)
    }
}
#endif
