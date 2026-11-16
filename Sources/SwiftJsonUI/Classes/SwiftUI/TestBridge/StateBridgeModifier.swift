//
//  StateBridgeModifier.swift
//  SwiftJsonUI
//
//  Applies a UI test's initialState to a screen and publishes the screen's
//  Data for the driver's `state` assertion.
//
//  Canon: jsonui-test-runner specs/2026-07-08-advanced-test-features.md §10.3–10.4.
//

import SwiftUI

private struct StateBridgeModifier: ViewModifier {
    let screenId: String
    let snapshot: () -> [String: Any]
    let apply: ([String: Any]) -> [JsonUIRejectedKey]
    let store: TestInitialStateStore

    /// Set once this view has applied (or found the screen's receipt from an
    /// earlier instance in the same launch), so the bridge re-renders with it.
    @State private var receipt: JsonUITestReceipt?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topLeading) {
                // A separate leaf from the screen marker: the marker's
                // invariant is one per screen, and its position (centre) is
                // what makes it hittable. Hittability does not matter here —
                // the driver reads the value — so it sits in the corner,
                // clear of the marker.
                Color.clear
                    .frame(width: 0.5, height: 0.5)
                    .allowsHitTesting(false)
                    .accessibilityElement(children: .ignore)
                    .accessibilityIdentifier(stateBridgeIdentifier(screenId))
                    .accessibilityValue(Text(verbatim: StateBridgeJSON.encode(
                        launchId: store.launchId,
                        receipt: receipt ?? store.receipt(for: screenId),
                        data: snapshot()
                    )))
            }
            .onAppear {
                // Once per launchId × screenId (spec §10.3): `take` hands the
                // values out the first time only.
                if let values = store.take(screenId) {
                    receipt = store.apply(values, for: screenId, with: apply)
                } else if receipt == nil {
                    receipt = store.receipt(for: screenId)
                }
            }
    }
}

public extension View {
    /// Applies a UI test's initialState to this screen once, and publishes
    /// the screen's Data for the test driver (the state bridge).
    ///
    /// Emitted by `sjui build` next to ``jsonUIScreenMarker(_:)``, on the
    /// outer group that holds both the generated body and the Dynamic-mode
    /// branch, so both read and write the same `data`. A host that drives
    /// `DynamicView` directly builds `snapshot` / `apply` from its own store
    /// with ``JsonUITestValue/check(_:declaredClass:)``.
    ///
    /// - `snapshot`: the screen's Data as JSON values (fields whose class an
    ///   initialState can set; `NSNull()` for a nil optional). Read on every
    ///   render, so the bridge follows each change of the data.
    /// - `apply`: applies the payload's values for this screen and returns the
    ///   keys it rejected. Called at most once per launch.
    ///
    /// Same gate as the screen marker: a DEBUG build, or the Info.plist key
    /// `com.swiftjsonui.SCREEN_MARKER`. With the gate closed this adds
    /// nothing and applies nothing.
    @ViewBuilder
    func jsonUITestBridge(
        _ screenId: String,
        snapshot: @escaping () -> [String: Any],
        apply: @escaping ([String: Any]) -> [JsonUIRejectedKey]
    ) -> some View {
        if screenMarkerIsEnabled {
            modifier(StateBridgeModifier(screenId: screenId, snapshot: snapshot, apply: apply,
                                         store: TestInitialStateStore.shared))
        } else {
            self
        }
    }
}
