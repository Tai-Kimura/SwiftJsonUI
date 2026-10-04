import XCTest

/// PaddingsOrderProbeView: a four-value paddings is [top, right, bottom,
/// left]. Reads the child's offset inside each padded View; prints every
/// reading, so a red names the View and the edge.
///
/// Measured 2026-10-04 (iOS 26.5, Xcode 26.6), [0, 40, 0, 4] as leading /
/// trailing: the generated half with jsonui-cli v1.9.13 40 / 4; with the
/// order fixed (jsonui-cli ticket sjui-four-value-paddings-read-as-top-left-
/// bottom-right) 4 / 40; the Dynamic half 4 / 40. [6, 0, 30, 0] reads 6 / 30
/// on every one.
final class PaddingsOrderProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["po_ready"].waitForExistence(timeout: 15), "probe did not start")
        func frame(_ id: String) -> CGRect {
            let e = app.descendants(matching: .any).matching(identifier: id).firstMatch
            XCTAssertTrue(e.waitForExistence(timeout: 10), "\(id) is not drawn")
            return e.frame
        }
        var wrong: [String] = []
        // name: (leading, trailing, top, bottom) the declaration asks for
        let expected: [(String, CGFloat, CGFloat, CGFloat, CGFloat)] = [("lr", 4, 40, 0, 0), ("tb", 0, 0, 6, 30)]
        for (name, l, r, t, b) in expected {
            let box = frame("\(p)_po_\(name)"), child = frame("\(p)_po_\(name)_child")
            let got = (child.minX - box.minX, box.maxX - child.maxX, child.minY - box.minY, box.maxY - child.maxY)
            let ok = abs(got.0 - l) < 1 && abs(got.1 - r) < 1 && abs(got.2 - t) < 1 && abs(got.3 - b) < 1
            print("[PaddingsOrder] \(p) \(name): leading \(got.0) trailing \(got.1) top \(got.2) bottom \(got.3) (want \(l) \(r) \(t) \(b)) \(ok ? "ok" : "WRONG")")
            if !ok { wrong.append(name) }
        }
        XCTAssertEqual(wrong, [], "the child does not sit where [top, right, bottom, left] puts it: \(wrong)")
    }

    func testDynamicReadsTopRightBottomLeft() throws {
        try XCTSkipIf(codegenHost, "the Dynamic half runs in the Dynamic host")
        run(prefix: "dyn", argument: "-paddingsOrderProbe")
    }

    func testGeneratedReadsTopRightBottomLeft() throws {
        try XCTSkipUnless(codegenHost, "the generated half runs in the codegen host")
        run(prefix: "cg", argument: "-paddingsOrderProbeCodegen")
    }
}
