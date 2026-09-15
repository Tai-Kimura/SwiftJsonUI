//
//  ConformanceUITests.swift
//  ConformanceHostUITests
//
//  Manifest-driven conformance runner.
//
//  Reads conformance/manifest.json (bundled by scripts/sync_fixtures.sh),
//  iterates every fixture, executes the fixture's .test.json steps via the
//  jsonui-test-runner iOS driver (vendored into UITests/Vendor/), captures
//  screenshots for visual fixtures, and writes a RESULTS_SCHEMA-conformant
//  ios.results.json.
//
//  Output goes to a staging directory on the host filesystem (simulator
//  processes share the host FS):
//      <staging>/results/ios.results.json
//      <staging>/artifacts/ios/<Section>_<attr>__<case>.png
//  Default staging dir: /tmp/jsonui-conformance-ios
//  Override with env CONFORMANCE_STAGING_DIR (pass through xcodebuild as
//  TEST_RUNNER_CONFORMANCE_STAGING_DIR). scripts/collect_results.sh copies
//  staging output into $CONFORMANCE_DIR.
//
//  Batching: fixtures run in batches of `batchSize` per app launch. The app
//  advances to the next fixture when this runner posts the Darwin
//  notification "jsonui.conformance.advance" (see ConformanceHostApp.swift),
//  so one launch serves a whole batch. A crash/hang inside a batch marks the
//  current fixture as "error" and relaunches for the remainder.
//

import XCTest
import CryptoKit

// MARK: - Manifest model (subset of jui conformance generate output)

struct ConformanceManifest: Decodable {
    struct Fixture: Decodable {
        let id: String
        let component: String
        /// The component whose view actually hosts this fixture. ⚠️ NOT the
        /// same as `component`: a control's component is `__control` while its
        /// host is the component it controls, so counting web-bearing fixtures
        /// by `component` silently drops `__control/Web`, which renders a web
        /// view exactly like the fixture it is the control for. Measured on
        /// the 1099-fixture manifest: host=="Web" gives 5 (2 runnable on ios),
        /// component=="Web" gives 4 (1 on ios).
        let host: String
        // null for __control fixtures — a control view belongs to no attribute
        let attribute: String?
        let `case`: String
        let `class`: String
        let aliasOf: String?
        let platforms: [String]
        let mode: Mode?
        let layout: String
        let test: String
    }

    /// mode is null | "swiftui" | "uikit" | ... | ["swiftui", "compose", ...]
    enum Mode: Decodable {
        case single(String)
        case multiple([String])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let s = try? container.decode(String.self) {
                self = .single(s)
            } else {
                self = .multiple(try container.decode([String].self))
            }
        }

        var values: [String] {
            switch self {
            case .single(let s): return [s]
            case .multiple(let m): return m
            }
        }
    }

    let schemaVersion: Int
    let fixtures: [Fixture]
}

// MARK: - Result model (RESULTS_SCHEMA.md)

struct FixtureResult: Encodable {
    let id: String
    let status: String
    let detail: String
    let screenshot: String?
}

/// 🔻 A RUN-LEVEL CENSUS OF THE WEB LOAD-MARKER PATH, BECAUSE THE WAIT'S OWN
/// FAILURE WEARS THE FACE OF THE BUG IT FIXES.
///
/// A web view exists the instant it is made, so a capture taken mid-load is
/// blank — and a blank fixture still DIFFERS from its control, so control_diff
/// calls the attribute active and a re-bake of the same race calls itself a
/// pass. No arm that looks at pixels can separate "waited and painted" from
/// "did not wait". Only the host knows, so the host counts.
///
/// ⚠️ THE FIRST VERSION OF THIS COUNTED THE WRONG THING AND REPORTED A FALSE
/// ALARM ON ITS FIRST REAL RUN. It used the presence of the PENDING marker as
/// the detector for "this fixture has a web view". Pending is a TRANSIENT
/// state: `loadHTMLString` is local and settles before the runner's first
/// query, so the tree already carried `sjui_web_loaded` and never
/// `sjui_web_pending`. Measured 2026-09-15 by dumping the element tree at the
/// exact query point — the 1x1 marker was present, as a child of the WebView,
/// already flipped to loaded, with the page's own StaticText beside it. The
/// census said 0 of 2 and the pictures were byte-identical to the baseline.
///
/// So the detector is now the DECLARED fact (`manifest.host == "Web"`, which is
/// stable and names the control too) and the markers are used only as the
/// wait's terminating condition. Every bucket below has an unambiguous zero.
struct WebMarkerCensus: Encodable {
    /// Runnable fixtures hosted by the Web component, from the manifest.
    /// Informational: a fixture that errors before its screen comes up never
    /// reaches the check, so this is not the denominator.
    var webFixturesRunnable = 0
    /// Web-hosted fixtures that reached the capture point. THE DENOMINATOR —
    /// the four buckets below sum to exactly this.
    var webFixturesReachedCapture = 0
    /// Already carrying the loaded marker on arrival: the page painted before
    /// the runner could look. Correct, and the common case locally.
    var alreadySettled = 0
    /// Found pending, then loaded arrived within the budget: the wait did work.
    var waitedThenSettled = 0
    /// Found pending, loaded never arrived. NOT a failure — the capture is
    /// still judged by fixture-vs-control, which is readable; a hang is not.
    var timedOut = 0
    /// Neither marker ever appeared, through the whole budget. This is the one
    /// that means the mechanism is gone — the env flag never reached the app,
    /// the linked library predates the markers, or they stopped surfacing.
    var markerAbsent = 0
}

// MARK: - Runner

final class ConformanceUITests: XCTestCase {

    /// Fixtures per app launch. Batching is relaunch-free within a batch via
    /// the Darwin advance notification.
    private let batchSize = 40

    /// Accumulated across every batch and relaunch; written into the results.
    private var webMarkerCensus = WebMarkerCensus()

    /// Seconds to wait for the fixture marker element after launch/advance.
    private let markerTimeout: TimeInterval = 15.0

    /// How long a Web fixture may take to finish painting after its screen is
    /// on. Local `loadHTMLString` with no network settles in milliseconds; the
    /// budget is generous because a timeout here is not an error, only a
    /// capture taken without the guarantee.
    ///
    /// ⚠️ AN EARLIER VERSION OF THIS COMMENT CITED A CONFOUNDED MEASUREMENT,
    /// and the number was carried into a commit message, a tag body and a
    /// closed bug report before the confound was noticed. It compared the wall
    /// clock of a run against a run with the LIBRARY MUTATED — and the wall
    /// clock includes the build, so a recompile sits inside the delta. It was
    /// evidence for "the wait blocks" only if build time is constant, which
    /// was never measured.
    ///
    /// The claim is now carried by a variant that cannot recompile anything:
    /// `CONFORMANCE_WEB_MARKERS_OFF=1` withholds the flag, so the same binary
    /// runs and the library simply builds no marker. Measured 2026-09-15:
    ///
    ///     markers ON   31.772s   markerAbsent=0   TEST SUCCEEDED
    ///     markers OFF  52.011s   markerAbsent=2   XCTAssertEqual failed
    ///
    /// +20.2s is two fixtures x this timeout, with no build in the delta.
    private let webLoadTimeout: TimeInterval = 10.0

    /// Optional filter for debugging: run only fixtures whose id contains one
    /// of these comma-separated substrings
    /// (env CONFORMANCE_FILTER via TEST_RUNNER_CONFORMANCE_FILTER).
    private var idFilters: [String] {
        guard let raw = ProcessInfo.processInfo.environment["CONFORMANCE_FILTER"] else { return [] }
        return raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private var stagingDir: URL {
        let path = ProcessInfo.processInfo.environment["CONFORMANCE_STAGING_DIR"]
            ?? "/tmp/jsonui-conformance-ios"
        return URL(fileURLWithPath: path)
    }

    // Issue capturing: driver assertions use XCTAssert*, which records
    // XCTIssues instead of throwing. While a fixture step runs we suppress
    // recording and collect the issues so a single assertion failure marks
    // that one fixture "fail" instead of aborting the whole suite.
    private var suppressIssues = false
    private var capturedIssues: [String] = []

    override func record(_ issue: XCTIssue) {
        if suppressIssues {
            capturedIssues.append(issue.compactDescription)
            return
        }
        super.record(issue)
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = true
    }

    // MARK: Main entry

    func testConformanceSuite() throws {
        let manifestData = try loadBundledData(relativePath: "manifest.json")
        let manifest = try JSONDecoder().decode(ConformanceManifest.self, from: manifestData)
        let manifestHash = SHA256.hash(data: manifestData)
            .map { String(format: "%02x", $0) }.joined()

        var results: [String: FixtureResult] = [:]
        var runnable: [ConformanceManifest.Fixture] = []

        for fixture in manifest.fixtures {
            if let skip = skipReason(for: fixture) {
                results[fixture.id] = FixtureResult(
                    id: fixture.id, status: "skipped", detail: skip, screenshot: nil)
            } else if !idFilters.isEmpty, !idFilters.contains(where: { fixture.id.contains($0) }) {
                results[fixture.id] = FixtureResult(
                    id: fixture.id, status: "skipped", detail: "not executed in this run", screenshot: nil)
            } else {
                runnable.append(fixture)
            }
        }

        webMarkerCensus.webFixturesRunnable =
            runnable.filter { $0.host == "Web" }.count

        try prepareStagingDirectories()

        var index = 0
        while index < runnable.count {
            let batch = Array(runnable[index..<min(index + batchSize, runnable.count)])
            let batchResults = runBatch(batch)
            for result in batchResults {
                results[result.id] = result
            }
            index += batch.count
        }

        // One entry per manifest fixture, in manifest order.
        let ordered = manifest.fixtures.compactMap { results[$0.id] }
        XCTAssertEqual(ordered.count, manifest.fixtures.count,
                       "every manifest fixture must have exactly one result")

        try writeResults(ordered, manifestHash: manifestHash, webMarkers: webMarkerCensus)

        // Two invariants, and they fail for different reasons.
        //
        // Conservation first: every Web-hosted fixture that reached capture
        // landed in exactly one bucket. Without this, a future branch that
        // falls through all four would shrink the population silently and the
        // check below would pass by having nothing to judge.
        let bucketed = webMarkerCensus.alreadySettled + webMarkerCensus.waitedThenSettled
            + webMarkerCensus.timedOut + webMarkerCensus.markerAbsent
        XCTAssertEqual(
            bucketed, webMarkerCensus.webFixturesReachedCapture,
            "web load-marker census does not add up: \(bucketed) bucketed vs "
            + "\(webMarkerCensus.webFixturesReachedCapture) reached capture")

        // Then the judgment. A timeout is deliberately NOT a failure — the
        // capture is still judged by fixture-vs-control, and failing here would
        // make a slow page indistinguishable from a broken marker. Never having
        // had a marker at all IS the failure.
        XCTAssertEqual(
            webMarkerCensus.markerAbsent, 0,
            "\(webMarkerCensus.markerAbsent) Web fixture(s) presented no load "
            + "marker at all, so their captures carry the blank-page race the "
            + "marker exists to remove. Check that "
            + "JSONUI_CONFORMANCE_WEB_MARKERS reached the app and that the "
            + "linked SwiftJsonUI is v10.23.0 or newer.")

        let counts = Dictionary(grouping: ordered, by: { $0.status }).mapValues { $0.count }
        print("[conformance] finished: \(counts) webMarkers: "
              + "runnable=\(webMarkerCensus.webFixturesRunnable) "
              + "reachedCapture=\(webMarkerCensus.webFixturesReachedCapture) "
              + "alreadySettled=\(webMarkerCensus.alreadySettled) "
              + "waitedThenSettled=\(webMarkerCensus.waitedThenSettled) "
              + "timedOut=\(webMarkerCensus.timedOut) "
              + "markerAbsent=\(webMarkerCensus.markerAbsent)")
    }

    // MARK: Skip policy

    /// codegen host mode (CONFORMANCE_HOST_MODE=codegen, forwarded to the app
    /// at launch): the fixture renders through the sjui-GENERATED SwiftUI view
    /// instead of DynamicView. Parity of the two pipelines is judged outside
    /// the run (`jui conformance parity`).
    private var isCodegenHostMode: Bool {
        ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen"
    }

    /// Fixture ids the codegen generator actually staged, with the reasons it
    /// skipped the rest (`codegen-map.json`, written next to the fixtures).
    /// Nil when the file is absent — a dynamic-mode run never needs it.
    private lazy var codegenMap: (hosted: Set<String>, skipped: [String: String])? = {
        guard let data = try? loadBundledData(relativePath: "codegen-map.json"),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        let hosted = Set((root["fixtures"] as? [String: Any])?.keys.map { $0 } ?? [])
        var reasons: [String: String] = [:]
        for entry in (root["skipped"] as? [[String: Any]]) ?? [] {
            if let id = entry["id"] as? String {
                reasons[id] = (entry["reason"] as? String) ?? "not staged"
            }
        }
        return (hosted, reasons)
    }()

    /// This host renders SwiftUI dynamic mode only.
    private func skipReason(for fixture: ConformanceManifest.Fixture) -> String? {
        if !fixture.platforms.contains("ios") {
            return "not applicable to ios"
        }
        // The generator decides what can run here, and this asks it. There is
        // deliberately no second predicate on this side: the staging rule reads
        // each fixture's steps for driver verbs (tap / input / swipe /
        // longPress / selectOption), and a copy of that verb list here would be
        // a second opinion that can disagree — staging a fixture this skips, or
        // the reverse, with the counts still adding up on both sides.
        //
        // A fixture the generator did not stage cannot be rendered here, and
        // attempting it produces "layout failed to load/decode in host" —
        // which reads as a defect in the layout instead of a fixture that
        // was never built. Ask the generator's own record.
        if isCodegenHostMode {
            // Absent map = the harness is misassembled, and the first version
            // of this guard failed OPEN: `let map = codegenMap` simply did not
            // match, every fixture fell through, and the run looked exactly
            // like one where nothing was excluded. Say it instead.
            guard let map = codegenMap else {
                return "codegen-map.json not bundled — regenerate the project (scripts/generate_project.rb)"
            }
            if !map.hosted.contains(fixture.id) {
                return "not staged for the codegen host: \(map.skipped[fixture.id] ?? "excluded by the generator")"
            }
        }
        if let mode = fixture.mode {
            let values = mode.values
            if !values.isEmpty && !values.contains("swiftui") {
                return "mode \(values.joined(separator: ",")) not hosted (SwiftUI dynamic host)"
            }
        }
        return nil
    }

    // MARK: Batch execution

    private func runBatch(_ batch: [ConformanceManifest.Fixture]) -> [FixtureResult] {
        var results: [FixtureResult] = []
        var remaining = batch[...]

        while !remaining.isEmpty {
            let app = XCUIApplication()
            app.launchEnvironment["CONFORMANCE_FIXTURE_IDS"] =
                remaining.map { $0.id }.joined(separator: ",")
            if isCodegenHostMode {
                app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen"
            }
            // 🔻 A HOOK FOR THE CENSUS'S OWN CONTROL, ON BY DEFAULT. The
            // `markerAbsent` bucket claims to detect "the marker mechanism is
            // gone", and a check nobody has ever seen fail is a claim, not a
            // gate. Withholding this flag is the one cheap way to produce that
            // state deliberately: the library builds no marker, every Web
            // fixture lands in `markerAbsent`, and the suite must go red.
            // Permanent rather than a temporary edit, so re-running the control
            // later costs one env var instead of rediscovering how.
            if ProcessInfo.processInfo.environment["CONFORMANCE_WEB_MARKERS_OFF"] != "1" {
                app.launchEnvironment["JSONUI_CONFORMANCE_WEB_MARKERS"] = "1"
            }
            app.launch()

            var crashed = false
            while let current = remaining.first {
                let marker = "conformance_current_\(current.id.replacingOccurrences(of: "/", with: "_"))"
                let markerElement = app.descendants(matching: .any)
                    .matching(identifier: marker).firstMatch

                guard markerElement.waitForExistence(timeout: markerTimeout) else {
                    if app.state != .runningForeground {
                        results.append(FixtureResult(
                            id: current.id, status: "error",
                            detail: "app not running (crash?) before fixture rendered",
                            screenshot: nil))
                        remaining = remaining.dropFirst()
                        crashed = true
                        break // relaunch with the rest of the batch
                    }
                    results.append(FixtureResult(
                        id: current.id, status: "error",
                        detail: "fixture marker did not appear within \(Int(markerTimeout))s",
                        screenshot: nil))
                    remaining = remaining.dropFirst()
                    advanceFixture()
                    continue
                }

                // 🔻 THE FIXTURE MARKER ANSWERS "the screen is on", NOT "the
                // content painted". A WKWebView exists the instant it is made,
                // so a Web fixture was screenshotted mid-load — and committed
                // baselines carry both sides of that race (the fixture blank in
                // one bake, its control blank in an earlier one). `control_diff`
                // called the fixture ACTIVE either way, because a race does
                // produce a difference; it just is not the attribute's.
                //
                // Self-describing rather than driven off the fixture id: only a
                // web view stamps `sjui_web_pending`, so a fixture without one
                // costs a single existence query. A timeout does NOT fail the
                // fixture — the capture proceeds and the fixture-vs-control arm
                // judges what was drawn, which is readable. Hanging is not.
                // 🔻 DRIVEN OFF THE DECLARED FACT, NOT OFF A TRANSIENT MARKER.
                // `host == "Web"` comes from the manifest, is stable, and names
                // the control (`__control/Web`, whose component is `__control`)
                // as well as the attribute fixtures. Only these fixtures pay
                // anything: 2 of 1099 on iOS, so the cheap-probe-for-everyone
                // design the transient detector was bought with is not needed.
                if current.host == "Web" {
                    webMarkerCensus.webFixturesReachedCapture += 1
                    let loaded = app.descendants(matching: .any)
                        .matching(identifier: "sjui_web_loaded").firstMatch
                    let pending = app.descendants(matching: .any)
                        .matching(identifier: "sjui_web_pending").firstMatch
                    if loaded.exists {
                        webMarkerCensus.alreadySettled += 1
                    } else if pending.exists {
                        if loaded.waitForExistence(timeout: webLoadTimeout) {
                            webMarkerCensus.waitedThenSettled += 1
                        } else {
                            webMarkerCensus.timedOut += 1
                        }
                    } else if loaded.waitForExistence(timeout: webLoadTimeout) {
                        // Neither marker yet: the representable's makeUIView may
                        // simply not have run at the instant the fixture marker
                        // appeared. Waiting for loaded covers that.
                        webMarkerCensus.waitedThenSettled += 1
                    } else {
                        // The whole budget with neither marker ever present. A
                        // page that never arrives would have shown pending the
                        // entire time, so this is the mechanism being gone.
                        webMarkerCensus.markerAbsent += 1
                    }
                }

                let loadError = app.descendants(matching: .any)
                    .matching(identifier: "conformance_load_error").firstMatch
                if loadError.exists {
                    results.append(FixtureResult(
                        id: current.id, status: "error",
                        detail: "layout failed to load/decode in host",
                        screenshot: nil))
                } else {
                    results.append(runFixture(current, app: app))
                }

                remaining = remaining.dropFirst()
                if remaining.first != nil {
                    advanceFixture()
                }
            }

            if !crashed {
                app.terminate()
                break
            }
            // crashed: loop relaunches with `remaining`
        }

        return results
    }

    /// Ask the host app to show the next fixture in the batch.
    private func advanceFixture() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName("jsonui.conformance.advance" as CFString),
            nil, nil, true
        )
    }

    // MARK: Single fixture execution

    private func runFixture(_ fixture: ConformanceManifest.Fixture, app: XCUIApplication) -> FixtureResult {
        let screenTest: ScreenTest
        do {
            // fixture.test is relative to the conformance dir, e.g.
            // "fixtures/Label/text__static.test.json" — same layout inside the bundle.
            let data = try loadBundledData(relativePath: fixture.test)
            screenTest = try JSONDecoder().decode(ScreenTest.self, from: data)
        } catch {
            return FixtureResult(
                id: fixture.id, status: "error",
                detail: "could not load test json: \(error.localizedDescription)",
                screenshot: nil)
        }

        let actionExecutor = XCUITestActionExecutor(platform: "ios")
        let assertionExecutor = XCUITestAssertionExecutor()
        var screenshotPath: String? = nil

        for testCase in screenTest.cases {
            if testCase.skip == true { continue }
            if let platform = testCase.platform, !platform.includes("ios") { continue }

            for step in testCase.steps {
                // Screenshot steps are handled here (the driver only attaches
                // to the xcresult; conformance needs a stable artifact file).
                if step.action == "screenshot", let name = step.name {
                    do {
                        screenshotPath = try captureScreenshot(named: name, app: app)
                    } catch {
                        return FixtureResult(
                            id: fixture.id, status: "error",
                            detail: "screenshot failed: \(error.localizedDescription)",
                            screenshot: nil)
                    }
                    continue
                }

                capturedIssues = []
                suppressIssues = true
                defer { suppressIssues = false }

                do {
                    if step.isAction {
                        try actionExecutor.execute(step: step, in: app)
                    } else if step.isAssertion {
                        try assertionExecutor.execute(step: step, in: app)
                    }
                } catch {
                    suppressIssues = false
                    return FixtureResult(
                        id: fixture.id, status: "error",
                        detail: stepLabel(step) + ": " + shortError(error),
                        screenshot: screenshotPath)
                }
                suppressIssues = false

                if !capturedIssues.isEmpty {
                    return FixtureResult(
                        id: fixture.id, status: "fail",
                        detail: stepLabel(step) + ": " + capturedIssues.joined(separator: " | "),
                        screenshot: screenshotPath)
                }
            }
        }

        return FixtureResult(id: fixture.id, status: "pass", detail: "", screenshot: screenshotPath)
    }

    private func stepLabel(_ step: TestStep) -> String {
        if let action = step.action {
            return "action \(action)" + (step.id.map { "(\($0))" } ?? "")
        }
        if let assertion = step.assert {
            return "assert \(assertion)" + (step.id.map { "(\($0))" } ?? "")
        }
        return "step"
    }

    private func shortError(_ error: Error) -> String {
        let description = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        return description.replacingOccurrences(of: "\n", with: " ")
    }

    // MARK: Artifacts / results IO

    private func prepareStagingDirectories() throws {
        let fileManager = FileManager.default
        for sub in ["results", "artifacts/ios"] {
            try fileManager.createDirectory(
                at: stagingDir.appendingPathComponent(sub),
                withIntermediateDirectories: true)
        }
    }

    /// Returns the artifact path relative to the conformance dir.
    private func captureScreenshot(named name: String, app: XCUIApplication) throws -> String {
        let screenshot = app.screenshot()
        let relative = "artifacts/ios/\(name).png"
        let url = stagingDir.appendingPathComponent(relative)
        try screenshot.pngRepresentation.write(to: url, options: .atomic)
        return relative
    }

    private func writeResults(_ results: [FixtureResult], manifestHash: String,
                              webMarkers: WebMarkerCensus) throws {
        // Build JSON by hand-encodable structure to guarantee key order stability
        // is not required by the schema; standard JSONEncoder output is fine.
        struct ResultsFile: Encodable {
            struct Runner: Encodable {
                let name: String
                let version: String
            }
            let platform: String
            let manifestHash: String
            let runner: Runner
            let webMarkers: WebMarkerCensus
            let results: [FixtureResult]
        }

        let file = ResultsFile(
            platform: "ios",
            manifestHash: manifestHash,
            runner: .init(name: "xcuitest", version: xcTestFrameworkVersion()),
            webMarkers: webMarkers,
            results: results
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(file)
        data.append(0x0A) // trailing newline per RESULTS_SCHEMA
        let url = stagingDir.appendingPathComponent("results/ios.results.json")
        try data.write(to: url, options: .atomic)
        print("[conformance] wrote \(url.path)")
    }

    private func xcTestFrameworkVersion() -> String {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        return "ios-\(os.majorVersion).\(os.minorVersion)"
    }

    // MARK: Bundle resources

    /// Load a file bundled into the UITest bundle. `relativePath` is relative
    /// to the conformance dir (e.g. "manifest.json", "fixtures/Label/x.test.json");
    /// sync_fixtures.sh mirrors that layout into the bundle resources.
    private func loadBundledData(relativePath: String) throws -> Data {
        let bundle = Bundle(for: ConformanceUITests.self)
        if let resourceURL = bundle.resourceURL {
            let direct = resourceURL.appendingPathComponent(relativePath)
            if FileManager.default.fileExists(atPath: direct.path) {
                return try Data(contentsOf: direct)
            }
        }
        throw NSError(
            domain: "ConformanceUITests", code: 1,
            userInfo: [NSLocalizedDescriptionKey:
                "bundled resource not found: \(relativePath) — run scripts/sync_fixtures.sh and regenerate the project"])
    }
}
