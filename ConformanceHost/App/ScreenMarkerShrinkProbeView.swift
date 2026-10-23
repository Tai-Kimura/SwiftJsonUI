//
//  ScreenMarkerShrinkProbeView.swift
//  ConformanceHost
//
//  Screen markers that leave while the driver reads them — NOT part of the
//  conformance suite. Launch the app with `-screenMarkerShrinkProbe`.
//
//  A screen that stays (`shrink_target`) and `leavingCount` screens that go
//  one by one, every `-shrinkIntervalMs` (default 100) from the tap on
//  `shrink_start`, until none is left. `shrink_remove_all` takes them all at
//  once. That is the shape of a pop or a dismiss under an `assert: screen`
//  poll: the driver counts the markers, then reads them one at a time, and
//  the hierarchy changes in between (jsonui-cli ticket
//  2026-10-23-test-ios-hittable-screens-index-race-on-shrinking-marker-query).
//
//  The probe asserts nothing on its own: ScreenMarkerShrinkProbeUITests does.
//

import SwiftUI
import SwiftJsonUI

struct ScreenMarkerShrinkProbeView: View {
    static let leavingCount = 12

    @State private var left = ScreenMarkerShrinkProbeView.leavingCount
    @State private var timer: Timer?

    private var intervalMs: Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let flag = arguments.firstIndex(of: "-shrinkIntervalMs"), flag + 1 < arguments.count,
           let value = Int(arguments[flag + 1]), value > 0 {
            return value
        }
        return 100
    }

    /// `-leavingRenamed`: a leaving screen's marker keeps its view and loses
    /// its identifier, the shape of SwiftJsonUI's marker (a 0.5 pt clear
    /// leaf) with the identifier the only thing that changes. The query
    /// shrinks as it does when a view is removed, but no element is caught
    /// in the moment of its removal, where `isHittable` can record
    /// "Activation point invalid".
    private var renamed: Bool { ProcessInfo.processInfo.arguments.contains("-leavingRenamed") }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Button("start") { start() }
                    .accessibilityIdentifier("shrink_start")
                Button("remove all") { stop(); left = 0 }
                    .accessibilityIdentifier("shrink_remove_all")
            }
            Text("left \(left)")
                .accessibilityIdentifier("shrink_left")
            if renamed {
                // Every row stays; a row past `left` keeps its marker's view and
                // loses the marker's identifier.
                ForEach(0..<Self.leavingCount, id: \.self) { index in
                    Text("leaving \(index)")
                        .frame(maxWidth: .infinity, minHeight: 24)
                        .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .allowsHitTesting(false)
                                .accessibilityElement(children: .ignore)
                                .accessibilityIdentifier(index < left ? "__screen_leaving_\(index)" : "renamed_\(index)")
                        }
                }
            } else {
                ForEach(0..<left, id: \.self) { index in
                    Text("leaving \(index)")
                        .frame(maxWidth: .infinity, minHeight: 24)
                        .accessibilityIdentifier("leaving_text_\(index)")
                        .jsonUIScreenMarker("leaving_\(index)")
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .jsonUIScreenMarker("shrink_target")
    }

    private func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: Double(intervalMs) / 1000, repeats: true) { _ in
            if left > 0 { left -= 1 } else { stop() }
        }
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
    }
}
