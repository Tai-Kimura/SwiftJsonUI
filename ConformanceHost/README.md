# ConformanceHost

A minimal SwiftUI host app + XCUITest runner that executes the JsonUI
renderer-conformance fixture suite (`jui conformance generate`) against
**SwiftJsonUI Dynamic mode** (runtime JSON interpretation, DEBUG-only) and
writes a `RESULTS_SCHEMA.md`-conformant `ios.results.json`.

## Layout

```
ConformanceHost/
├── App/                    host app: renders one fixture via DynamicView
├── UITests/
│   ├── ConformanceUITests.swift   manifest-driven suite runner
│   └── Vendor/JsonUITestRunner/   jsonui-test-runner iOS driver (synced, gitignored)
├── Resources/              fixtures + manifest (synced, gitignored)
├── scripts/                sync / generate / run / collect
└── ConformanceHost.xcodeproj      generated (gitignored)
```

The Xcode project is **generated** (via the `xcodeproj` gem, bundled with
CocoaPods) because the UITest target compiles driver sources that only exist
after syncing. Nothing machine-specific is committed; all external locations
come in through environment variables.

## Run the suite

```bash
cd ConformanceHost

# 1. Sync fixtures + vendor the iOS driver
CONFORMANCE_DIR=/path/to/conformance \
JSONUI_TEST_RUNNER_PATH=/path/to/jsonui-test-runner \
  ./scripts/sync_fixtures.sh

# 2. Generate the Xcode project + shared scheme
ruby ./scripts/generate_project.rb

# 3. Build, run headless on a simulator, collect results
CONFORMANCE_DIR=/path/to/conformance ./scripts/run_conformance.sh
```

- `CONFORMANCE_DIR` is the directory produced by `jui conformance generate`
  (contains `fixtures/`, `manifest.json`). Results land in
  `$CONFORMANCE_DIR/results/ios.results.json`, screenshots in
  `$CONFORMANCE_DIR/artifacts/ios/`.
- `SIMULATOR_NAME` (default `iPhone 16 Pro`) picks the destination. The run is
  fully headless (`xcodebuild test`); no Xcode UI or booted-Simulator app is
  required, so it is CI-ready.
- `CONFORMANCE_FILTER=<substring>` runs a subset; all other fixtures are
  reported as `skipped` / `not executed in this run` (the results file always
  contains one entry per manifest fixture).
- `SKIP_BUILD=1` reuses the previous build (`test-without-building`).

## How it works

- **Host app** (`App/ConformanceHostApp.swift`): takes `-fixtureId <id>` or a
  comma-separated `CONFORMANCE_FIXTURE_IDS` batch, loads the bundled
  `fixtures/<id>.layout.json`, applies `StyleProcessor`, decodes a
  `DynamicComponent` and renders it with `DynamicView` — the same pipeline
  Dynamic mode uses in real apps. Requires a Debug build (`#if DEBUG`).
- **Batching**: one app launch serves up to 40 fixtures. The UITest runner
  advances the app to the next fixture by posting the Darwin notification
  `jsonui.conformance.advance`; the app confirms by exposing an invisible
  `conformance_current_<id>` accessibility marker. A crash mid-batch marks
  the current fixture `error` and relaunches with the remainder.
- **Driver**: the UITest target compiles the jsonui-test-runner iOS driver
  sources verbatim from `UITests/Vendor/JsonUITestRunner/` (synced from
  `$JSONUI_TEST_RUNNER_PATH`, gitignored). Local fixes, if ever needed, live
  as `scripts/driver-patches/*.patch` and are applied at sync time.
- **Assertion capture**: the driver reports assertion failures through
  `XCTAssert*`. The test case overrides `record(_:)` to capture those issues
  per step, so one failing fixture becomes `"status": "fail"` instead of
  aborting the suite. Thrown driver errors (element not found, timeout)
  become `"status": "error"`.
- **Skips**: fixtures whose `platforms` lack `ios` → `not applicable to ios`;
  fixtures with a `mode` that does not include `swiftui` (e.g. `uikit`) →
  `mode <m> not hosted (SwiftUI dynamic host)`. Never silently dropped.
- **Output**: the UITest process writes `ios.results.json` (with
  `manifestHash` = SHA-256 of the manifest bytes it ran against) and PNG
  screenshots to a staging dir on the shared simulator/host filesystem
  (default `/tmp/jsonui-conformance-ios`), and `scripts/collect_results.sh`
  copies them into `$CONFORMANCE_DIR`.

## Assets

The app bundles the `conformance_sample` image asset that image-typed
fixtures reference (fixture convention from `RESULTS_SCHEMA.md`).
