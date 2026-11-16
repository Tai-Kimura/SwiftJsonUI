//
//  TestInitialState.swift
//  SwiftJsonUI
//
//  Receiving a UI test's initialState, and remembering what was applied.
//
//  Canon: jsonui-test-runner specs/2026-07-08-advanced-test-features.md §10.2–10.4.
//

import Foundation

/// The launch environment key the drivers deliver the payload in.
public let testInitialStateEnvironmentKey = "JSONUI_TEST_INITIAL_STATE"

/// Prefix of the state bridge leaf's identifier: `__state_<screenId>`.
public let stateBridgePrefix = "__state_"

/// The state bridge identifier for a screen id.
public func stateBridgeIdentifier(_ screenId: String) -> String {
    "\(stateBridgePrefix)\(screenId)"
}

/// What a screen applied from the payload in this launch.
public struct JsonUITestReceipt: Equatable {
    public let applied: [String]
    public let rejected: [JsonUIRejectedKey]
}

/// The payload a driver sent with this launch, read once, and the receipts
/// of the screens that took their part of it.
///
/// One launch is one process on iOS (the environment is fixed when the app
/// starts), so consumption is kept in memory, keyed by `launchId × screenId`:
/// a screen built again in the same launch — navigated away and back,
/// recreated by its parent — does not apply it a second time, and still
/// reports the receipt it made.
final class TestInitialStateStore {
    let launchId: String?
    private let screens: [String: [String: Any]]
    private var consumed: Set<String> = []
    private var receipts: [String: JsonUITestReceipt] = [:]
    private let lock = NSLock()

    init(launchId: String?, screens: [String: [String: Any]]) {
        self.launchId = launchId
        self.screens = screens
    }

    /// Parses `JSONUI_TEST_INITIAL_STATE`. A payload that is not version 1,
    /// or not readable, is no payload — the driver then sees no receipt and
    /// says so, which is the signal a wrong payload should give.
    static func parse(_ raw: String?) -> TestInitialStateStore {
        guard let raw, let data = raw.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              (root["version"] as? NSNumber)?.intValue == 1,
              let launchId = root["launchId"] as? String else {
            return TestInitialStateStore(launchId: nil, screens: [:])
        }
        let screens = (root["screens"] as? [String: Any] ?? [:])
            .compactMapValues { $0 as? [String: Any] }
        return TestInitialStateStore(launchId: launchId, screens: screens)
    }

    /// The values for `screenId`, the first time this launch asks; nil after
    /// that, and nil for a screen the payload does not name.
    func take(_ screenId: String) -> [String: Any]? {
        lock.lock(); defer { lock.unlock() }
        guard let launchId, let values = screens[screenId] else { return nil }
        let key = "\(launchId)|\(screenId)"
        guard !consumed.contains(key) else { return nil }
        consumed.insert(key)
        return values
    }

    func record(_ receipt: JsonUITestReceipt, for screenId: String) {
        lock.lock(); defer { lock.unlock() }
        receipts[screenId] = receipt
    }

    func receipt(for screenId: String) -> JsonUITestReceipt? {
        lock.lock(); defer { lock.unlock() }
        return receipts[screenId]
    }

    /// Apply `values` with `apply` and record what it did. Applied keys are
    /// the payload's keys minus the rejected ones.
    func apply(_ values: [String: Any], for screenId: String,
               with apply: ([String: Any]) -> [JsonUIRejectedKey]) -> JsonUITestReceipt {
        let rejected = apply(values)
        let rejectedKeys = Set(rejected.map(\.key))
        let receipt = JsonUITestReceipt(
            applied: values.keys.filter { !rejectedKeys.contains($0) }.sorted(),
            rejected: rejected.sorted { $0.key < $1.key }
        )
        record(receipt, for: screenId)
        return receipt
    }

    /// The process's store: the environment is read once.
    static let shared: TestInitialStateStore = parse(
        ProcessInfo.processInfo.environment[testInitialStateEnvironmentKey]
    )
}

/// The state bridge's JSON for one screen (spec §10.4).
enum StateBridgeJSON {
    /// iOS publishes through an accessibility value, and XCUITest reads the
    /// whole tree on every query: past this, the value is a marker of its
    /// size instead, and `state` fails at once rather than slowing every step.
    static let byteLimit = 32 * 1024

    static func encode(launchId: String?, receipt: JsonUITestReceipt?, data: [String: Any]) -> String {
        var root: [String: Any] = [
            "launchId": launchId ?? NSNull(),
            "data": jsonSafe(data),
        ]
        if let receipt {
            root["initialState"] = [
                "applied": receipt.applied,
                "rejected": receipt.rejected.map { ["key": $0.key, "reason": $0.reason] },
            ]
        } else {
            root["initialState"] = NSNull()
        }
        guard JSONSerialization.isValidJSONObject(root),
              let encoded = try? JSONSerialization.data(withJSONObject: root, options: [.sortedKeys]),
              let text = String(data: encoded, encoding: .utf8) else {
            return #"{"launchId":null,"initialState":null,"data":{}}"#
        }
        if encoded.count > byteLimit {
            return #"{"truncated":\#(encoded.count)}"#
        }
        return text
    }

    /// Drops what JSON cannot hold (a snapshot is generated from Data and
    /// should hold only JSON values, but a value that slipped through must
    /// not take the whole bridge down).
    static func jsonSafe(_ data: [String: Any]) -> [String: Any] {
        data.filter { JSONSerialization.isValidJSONObject(["v": $0.value]) }
    }
}
