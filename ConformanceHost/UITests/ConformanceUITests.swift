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
        let attribute: String
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

// MARK: - Runner

final class ConformanceUITests: XCTestCase {

    /// Fixtures per app launch. Batching is relaunch-free within a batch via
    /// the Darwin advance notification.
    private let batchSize = 40

    /// Seconds to wait for the fixture marker element after launch/advance.
    private let markerTimeout: TimeInterval = 15.0

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

        try writeResults(ordered, manifestHash: manifestHash)

        let counts = Dictionary(grouping: ordered, by: { $0.status }).mapValues { $0.count }
        print("[conformance] finished: \(counts)")
    }

    // MARK: Skip policy

    /// This host renders SwiftUI dynamic mode only.
    private func skipReason(for fixture: ConformanceManifest.Fixture) -> String? {
        if !fixture.platforms.contains("ios") {
            return "not applicable to ios"
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

    private func writeResults(_ results: [FixtureResult], manifestHash: String) throws {
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
            let results: [FixtureResult]
        }

        let file = ResultsFile(
            platform: "ios",
            manifestHash: manifestHash,
            runner: .init(name: "xcuitest", version: xcTestFrameworkVersion()),
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
