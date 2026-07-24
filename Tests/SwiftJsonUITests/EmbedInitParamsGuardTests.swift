//
//  EmbedInitParamsGuardTests.swift
//  SwiftJsonUITests
//
//  Tests for the embed init-params double-drive guard and the type-erased
//  `.receiveEmbedInitParams(to:)` overload (renderer-ssot-15-3: codegen
//  emits the wiring unconditionally; legacy manual wiring coexists).
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

final class EmbedInitParamsGuardTests: XCTestCase {

    private final class ReceiverVM: EmbeddedInitParamsReceiver {
        var received: [[String: Any]] = []
        func applyInitParams(_ params: [String: Any]) {
            received.append(params)
        }
    }

    private final class PlainVM {}

    // MARK: - Fingerprint

    func testFingerprintIsKeyOrderStable() {
        let a = EmbedInitParamsApplyGuard.fingerprint(["a": 1, "b": "x"])
        let b = EmbedInitParamsApplyGuard.fingerprint(["b": "x", "a": 1])
        XCTAssertEqual(a, b)
    }

    func testFingerprintReflectsNestedLeafChanges() {
        let a = EmbedInitParamsApplyGuard.fingerprint(["profile": ["name": "Ada"]])
        let b = EmbedInitParamsApplyGuard.fingerprint(["profile": ["name": "Grace"]])
        XCTAssertNotEqual(a, b)
    }

    // MARK: - Consecutive-apply suppression

    func testConsecutiveSameParamsAreSuppressed() {
        let vm = ReceiverVM()
        let params: [String: Any] = ["orderId": "a", "count": 5]

        XCTAssertTrue(EmbedInitParamsApplyGuard.shouldApply(params, to: vm))
        // Second identical apply (generated wiring + legacy manual wiring
        // both firing on appear) must be suppressed.
        XCTAssertFalse(EmbedInitParamsApplyGuard.shouldApply(params, to: vm))
    }

    func testChangedParamsApplyAgain() {
        let vm = ReceiverVM()
        XCTAssertTrue(EmbedInitParamsApplyGuard.shouldApply(["orderId": "a"], to: vm))
        XCTAssertTrue(EmbedInitParamsApplyGuard.shouldApply(["orderId": "b"], to: vm))
        // A change BACK is a change — only consecutive-identical is suppressed
        XCTAssertTrue(EmbedInitParamsApplyGuard.shouldApply(["orderId": "a"], to: vm))
        XCTAssertFalse(EmbedInitParamsApplyGuard.shouldApply(["orderId": "a"], to: vm))
    }

    func testGuardIsScopedPerVMInstance() {
        let params: [String: Any] = ["orderId": "a"]
        let first = ReceiverVM()
        let second = ReceiverVM()
        XCTAssertTrue(EmbedInitParamsApplyGuard.shouldApply(params, to: first))
        // A different VM instance with the same params is NOT suppressed
        XCTAssertTrue(EmbedInitParamsApplyGuard.shouldApply(params, to: second))
    }

    // MARK: - Type-erased overload dispatch

    func testErasedOverloadAcceptsNonConformingVM() {
        // Codegen emits this unconditionally: a plain VM must compile and
        // be a silent no-op (dynamic cast fails inside the overload).
        let view = Text("embedded").receiveEmbedInitParams(to: PlainVM() as Any)
        XCTAssertNotNil(view)
    }

    func testErasedOverloadAcceptsConformingVMDynamically() {
        let vm: Any = ReceiverVM()
        let view = Text("embedded").receiveEmbedInitParams(to: vm)
        XCTAssertNotNil(view)
    }

    func testGenericOverloadStillAvailable() {
        // Legacy manual wiring keeps compiling against the generic overload
        let vm = ReceiverVM()
        let view = Text("embedded").receiveEmbedInitParams(to: vm)
        XCTAssertNotNil(view)
    }
}
