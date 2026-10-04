//
//  TapDiagnosis.swift
//  ConformanceHostUITests
//
//  What a tap met, shared by every UITest that taps — the fixture runner
//  (ConformanceUITests.runFixture) and the probes. jsonui-cli ticket
//  ios-dynamic-interactive-fixture-tap-not-delivered-intermittently: a tap
//  sometimes has no effect, in a fixture (twice) and possibly in a probe
//  (CellDataRefresh, codegen host). One helper, so every report reads the
//  same and a fix lands in one place.
//

import XCTest

enum TapDiagnosis {

    /// The run's staging directory (run_conformance.sh exports it).
    static var stagingDir: URL {
        let path = ProcessInfo.processInfo.environment["CONFORMANCE_STAGING_DIR"]
            ?? "/tmp/jsonui-conformance-ios"
        return URL(fileURLWithPath: path)
    }

    /// `exists / hittable / frame` of the first element with this identifier.
    static func elementState(_ id: String, in app: XCUIApplication) -> String {
        let element = app.descendants(matching: .any).matching(identifier: id).firstMatch
        guard element.exists else { return "exists=false" }
        return "exists=true hittable=\(element.isHittable) frame=\(element.frame)"
    }

    /// Writes app.screenshot() to `artifacts/ios/<name>.png` under the staging
    /// directory (collect_results.sh uploads it) and returns that relative path.
    @discardableResult
    static func screenshot(named name: String, app: XCUIApplication) throws -> String {
        let screenshot = app.screenshot()
        let relative = "artifacts/ios/\(name).png"
        let url = stagingDir.appendingPathComponent(relative)
        try screenshot.pngRepresentation.write(to: url, options: .atomic)
        return relative
    }

    /// One line for an error, for a detail string.
    static func shortError(_ error: Error) -> String {
        let description = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        return description.replacingOccurrences(of: "\n", with: " ")
    }

    /// Taps once more (`retap`) and asks `effectShows` whether the effect is
    /// there now: it returns nil when it is, or the reason it is not. A second
    /// tap whose effect shows means the first touch was not delivered; one
    /// whose effect does not show either means the handler (or the drawing)
    /// did not answer. The caller's verdict stays the first tap's — this is a
    /// measurement, never a retry that turns a red check green.
    ///
    /// Not for a non-idempotent tap judged by the first tap's expectation: a
    /// second tap there has its own effect (a counter goes to 3, not 2), so
    /// pass a check for the second tap's OWN effect (e.g. "the version went up").
    static func secondTap(_ retap: () throws -> Void, effectShows: () throws -> String?) -> String {
        do {
            try retap()
            if let failure = try effectShows() {
                return "a second tap did not either: \(failure)"
            }
            return "a second tap made it pass (touch not delivered)"
        } catch {
            return "a second tap did not either: \(shortError(error))"
        }
    }
}
