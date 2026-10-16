//
//  InitialStateDriverE2ETests.swift
//  ConformanceHostUITests
//
//  jsonui-test-runner spec §10 end to end through the DRIVER: a screen test
//  run by JsonUITestRunner.run, so the driver launches the app with the
//  payload, waits for the receipt and runs setup and the steps — the path the
//  conformance fixtures do not take (there the host delivers and checks).
//
//  The app shows the TestBridge fixture whose screen the test addresses: on
//  the Dynamic face the host attaches the bridge (App/TestBridgeFixture.swift),
//  on the codegen face the generated view carries it.
//
//  testAClosedGateConfirmsNothing runs only when CONFORMANCE_E2E_GATE_CLOSED=1:
//  in a build with the screen-marker gate closed (Release, no
//  com.swiftjsonui.SCREEN_MARKER), on the codegen face — the only face a
//  Release build hosts. The two arms that need an open gate skip there.
//

import XCTest

final class InitialStateDriverE2ETests: XCTestCase {
    private let fixtureId = "TestBridge/initialState__applied"

    private var isCodegen: Bool {
        ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen"
    }

    /// The screen id the face gives the fixture (INTERACTIVE_HOST_CONTRACT.md §6).
    private func screenId() throws -> String {
        guard isCodegen else { return "conformance_\(fixtureId.replacingOccurrences(of: "/", with: "_"))" }
        let url = try XCTUnwrap(Bundle(for: Self.self).resourceURL?.appendingPathComponent("codegen-map.json"))
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let entry = try XCTUnwrap((root["fixtures"] as? [String: Any])?[fixtureId] as? [String: Any])
        return try XCTUnwrap(entry["screenId"] as? String)
    }

    private func app(showing shown: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["CONFORMANCE_FIXTURE_IDS"] = shown ?? fixtureId
        if isCodegen { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        return app
    }

    /// A screen test whose screen under test is the fixture's (source.layout
    /// names it) with this initialState and these steps.
    private func screenTest(_ initialState: [String: Any], steps: [[String: Any]]) throws -> ScreenTest {
        let test: [String: Any] = [
            "type": "screen",
            "source": ["layout": "Layouts/\(try screenId()).json"],
            "metadata": ["name": "initialState e2e"],
            "initialState": ["viewModel": initialState],
            "cases": [["name": "case", "steps": [["action": "waitFor", "id": "root"]] + steps]],
        ]
        return try JSONDecoder().decode(ScreenTest.self, from: JSONSerialization.data(withJSONObject: test))
    }

    private var gateClosed: Bool {
        ProcessInfo.processInfo.environment["CONFORMANCE_E2E_GATE_CLOSED"] == "1"
    }

    private func run(_ test: ScreenTest, showing shown: String? = nil) -> TestRunResult {
        var config = TestRunnerConfig()
        config.screenshotOnFailure = false
        return JsonUITestRunner(app: app(showing: shown), config: config).run(screenTest: test)
    }

    func testTheAppConfirmsAndStateReadsIt() throws {
        try XCTSkipIf(gateClosed, "asserts an open gate; this build has it closed (testAClosedGateConfirmsNothing)")
        let result = run(try screenTest(
            ["tbEmail": "e2e@example.com", "tbCount": 7],
            steps: [
                ["assert": "text", "id": "label_email", "equals": "e2e@example.com"],
                ["assert": "state", "path": "tbEmail", "equals": "e2e@example.com"],
                ["assert": "state", "path": "tbCount", "equals": 7],
            ]))
        let row = try XCTUnwrap(result.caseResults.first)
        XCTAssertTrue(row.passed, row.error?.localizedDescription ?? "")
        print("E2E confirmed: passed=\(row.passed)")
    }

    func testARejectedKeyFailsTheCaseAsSetup() throws {
        try XCTSkipIf(gateClosed, "asserts an open gate; this build has it closed (testAClosedGateConfirmsNothing)")
        let result = run(try screenTest(["tbEmail": "x", "tbTypo": "y"],
                                        steps: [["assert": "text", "id": "label_email", "equals": "x"]]))
        let row = try XCTUnwrap(result.caseResults.first)
        XCTAssertFalse(row.passed, "a rejected key must fail the case")
        let message = row.error?.localizedDescription ?? ""
        XCTAssertTrue(message.contains("rejected") && message.contains("'tbTypo': not a data field"), message)
        XCTAssertEqual(FailureClassifier.classify(row.error)?.rawValue, "setup", message)
        print("E2E rejected: \(message)")
    }

    /// What a closed gate amounts to — the bridge modifier adds nothing — on a
    /// build this host can make: the app shows a fixture that carries no
    /// bridge, while the test addresses that screen with an initialState. The
    /// driver must fail the case as setup, naming the absent bridge, not run
    /// the steps against default values. The real closed gate is
    /// testAClosedGateConfirmsNothing, in a Release build.
    func testAScreenWithoutTheBridgeConfirmsNothing() throws {
        try XCTSkipIf(isCodegen, "every codegen fixture view carries the bridge")
        let other = "common/onclick__callback_fire"
        let test: [String: Any] = [
            "type": "screen",
            "source": ["layout": "Layouts/conformance_\(other.replacingOccurrences(of: "/", with: "_")).json"],
            "metadata": ["name": "no bridge e2e"],
            "initialState": ["viewModel": ["conformanceResult": "x"]],
            "cases": [["name": "case", "steps": [["action": "waitFor", "id": "root"]]]],
        ]
        let screenTest = try JSONDecoder().decode(ScreenTest.self, from: JSONSerialization.data(withJSONObject: test))
        let row = try XCTUnwrap(run(screenTest, showing: other).caseResults.first)
        XCTAssertFalse(row.passed, "nothing can be confirmed without a bridge")
        let message = row.error?.localizedDescription ?? ""
        XCTAssertTrue(message.contains("was not confirmed by the app") && message.contains("no state bridge"), message)
        XCTAssertEqual(FailureClassifier.classify(row.error)?.rawValue, "setup", message)
        print("E2E no bridge: \(message)")
    }

    func testAClosedGateConfirmsNothing() throws {
        try XCTSkipUnless(gateClosed,
                          "needs a build with the screen-marker gate closed")
        let result = run(try screenTest(["tbEmail": "e2e@example.com"],
                                        steps: [["assert": "text", "id": "label_email", "equals": "e2e@example.com"]]))
        let row = try XCTUnwrap(result.caseResults.first)
        XCTAssertFalse(row.passed, "nothing can be confirmed with the gate closed")
        let message = row.error?.localizedDescription ?? ""
        XCTAssertTrue(message.contains("was not confirmed by the app"), message)
        print("E2E gate closed: \(message)")
    }
}
