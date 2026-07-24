//
//  ConformanceHostApp.swift
//  ConformanceHost
//
//  Renders a single conformance fixture layout through the SwiftJsonUI
//  SwiftUI dynamic component system (Dynamic mode, DEBUG only).
//
//  Fixture selection (checked in this order):
//    1. Launch argument  -fixtureId <id>          — single fixture
//    2. Launch env       CONFORMANCE_FIXTURE_IDS  — comma-separated batch;
//       the UITest runner advances through the batch by posting the Darwin
//       notification "jsonui.conformance.advance" (relaunch-free batching).
//
//  Fixture ids look like "Label/text__static" and map to the bundled
//  resource "fixtures/<id>.layout.json" (synced by scripts/sync_fixtures.sh).
//
//  Test hooks exposed to XCUITest (all invisible, zero screenshot impact):
//    - accessibilityIdentifier "conformance_current_<id>" on the fixture
//      wrapper — signals which fixture is currently displayed
//    - accessibilityIdentifier "conformance_load_error" — layout failed to
//      load or decode
//    - accessibilityIdentifier "conformance_done" — batch exhausted
//

import SwiftUI
import SwiftJsonUI

@main
struct ConformanceHostApp: App {
    var body: some Scene {
        WindowGroup {
            ConformanceRootView()
        }
    }
}

/// Batch state driven by the "jsonui.conformance.advance" Darwin notification.
final class FixtureBatchModel: ObservableObject {
    static let advanceNotification = "jsonui.conformance.advance" as CFString

    let fixtureIds: [String]
    @Published var currentIndex: Int = 0

    var currentFixtureId: String? {
        guard currentIndex < fixtureIds.count else { return nil }
        return fixtureIds[currentIndex]
    }

    init() {
        var ids: [String] = []
        let arguments = ProcessInfo.processInfo.arguments
        if let flagIndex = arguments.firstIndex(of: "-fixtureId"), flagIndex + 1 < arguments.count {
            ids = [arguments[flagIndex + 1]]
        } else if let batch = ProcessInfo.processInfo.environment["CONFORMANCE_FIXTURE_IDS"] {
            ids = batch.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        }
        self.fixtureIds = ids
        registerAdvanceObserver()
    }

    private func registerAdvanceObserver() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observer, _, _, _ in
                guard let observer = observer else { return }
                let model = Unmanaged<FixtureBatchModel>.fromOpaque(observer).takeUnretainedValue()
                DispatchQueue.main.async {
                    model.currentIndex += 1
                }
            },
            FixtureBatchModel.advanceNotification,
            nil,
            .deliverImmediately
        )
    }
}

struct ConformanceRootView: View {
    @StateObject private var batch = FixtureBatchModel()

    var body: some View {
        Group {
            if ProcessInfo.processInfo.arguments.contains("-gestureProbe") {
                GestureProbeView()
            } else if batch.fixtureIds.isEmpty {
                Text("ConformanceHost: pass -fixtureId <id> or CONFORMANCE_FIXTURE_IDS")
                    .padding()
                    .accessibilityIdentifier("conformance_idle")
            } else if let fixtureId = batch.currentFixtureId {
                FixtureScreen(fixtureId: fixtureId)
                    // Force full teardown/rebuild between fixtures so no state leaks.
                    .id(fixtureId)
            } else {
                Text("Conformance batch complete")
                    .padding()
                    .accessibilityIdentifier("conformance_done")
            }
        }
    }
}

/// Loads one fixture layout from the bundle and renders it via Dynamic mode.
struct FixtureScreen: View {
    let fixtureId: String

    /// Generic interactive-fixture state (INTERACTIVE_HOST_CONTRACT.md):
    /// bindings + declared handler closures for `class: interactive`
    /// fixtures, empty for everything else. Identity is per-fixture via
    /// `.id(fixtureId)` on this view, so the store resets between fixtures.
    @StateObject private var state: ConformanceStateStore

    init(fixtureId: String) {
        self.fixtureId = fixtureId
        _state = StateObject(wrappedValue: ConformanceStateStore(fixtureId: fixtureId))
    }

    var body: some View {
        ZStack {
            if let component = FixtureLoader.loadComponent(fixtureId: fixtureId) {
                DynamicView(component: component, viewId: "conformance", data: state.externalData)
            } else {
                Text("Failed to load fixture: \(fixtureId)")
                    .foregroundColor(.red)
                    .padding()
                    .accessibilityIdentifier("conformance_load_error")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Marker for the UITest runner: which fixture is on screen right now.
        // The marker is its own (invisible, 1x1) accessibility element — an
        // identifier on the wrapper itself would not surface as an element and
        // would be pushed down onto the fixture content, clobbering its ids.
        .overlay(alignment: .bottomTrailing) {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("conformance_current_\(FixtureLoader.markerSafe(fixtureId))")
        }
    }
}

enum FixtureLoader {
    /// "Label/text__static" -> marker-safe "Label_text__static"
    /// (XCUITest identifier matching is exact-string, slashes are fine, but a
    /// flat token keeps logs/queries unambiguous and matches artifact naming.)
    static func markerSafe(_ fixtureId: String) -> String {
        fixtureId.replacingOccurrences(of: "/", with: "_")
    }

    /// Locate the fixture's layout inside the app bundle (the fixtures
    /// directory is bundled as a folder reference, preserving subdirectories).
    /// The path comes from the manifest `layout` field — it is NOT always
    /// "fixtures/<id>.layout.json": the generator appends `_N` to filenames
    /// when two ids collide case-insensitively (onclick vs onClick).
    static func layoutURL(fixtureId: String) -> URL? {
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        let relativePath = ConformanceStateIndex.layoutPath(for: fixtureId)
            ?? "fixtures/\(fixtureId).layout.json"
        let direct = resourceURL.appendingPathComponent(relativePath)
        if FileManager.default.fileExists(atPath: direct.path) {
            return direct
        }
        // Fallback: flattened bundling (group reference)
        let basename = relativePath.split(separator: "/").map(String.init).last?
            .replacingOccurrences(of: ".layout.json", with: "") ?? fixtureId
        return Bundle.main.url(forResource: "\(basename).layout", withExtension: "json")
    }

    static func loadComponent(fixtureId: String) -> DynamicComponent? {
        guard let url = layoutURL(fixtureId: fixtureId),
              let data = try? Data(contentsOf: url),
              let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        // Same pre-processing pipeline as JSONLayoutLoader.loadComponent
        // (styles applied; conformance fixtures contain no includes).
        let processed = StyleProcessor.processStyles(jsonObject)
        return JSONLayoutLoader.decodeComponent(from: processed)
    }
}
