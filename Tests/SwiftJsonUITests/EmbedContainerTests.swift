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
}
#endif
