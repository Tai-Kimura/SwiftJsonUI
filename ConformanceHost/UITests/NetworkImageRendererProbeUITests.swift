//
//  NetworkImageRendererProbeUITests.swift
//  ConformanceHostUITests
//
//  NetworkImageRendererProbeView against a local server (OPT-IN:
//  CONFORMANCE_NW_RENDERER_URL names it; skipped without). The slow frames
//  are read once per URL and end "loaded", the failing one "failed"; while a
//  frame draws its renderer it is still one image element read with its alt;
//  the second screen's frames come from the memory cache, "loaded" alone at
//  once. The video the requester sees is recorded around this run (ticket
//  jui-networkimage-load-listener).
//

import XCTest

final class NetworkImageRendererProbeUITests: XCTestCase {
    func testTheRendererProbe() throws {
        guard let base = ProcessInfo.processInfo.environment["CONFORMANCE_NW_RENDERER_URL"], !base.isEmpty else {
            throw XCTSkip("CONFORMANCE_NW_RENDERER_URL is not set (opt-in: needs a local server)")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-networkImageRendererProbe", base]
        app.launch()
        XCTAssertTrue(app.staticTexts["nwr_ready"].waitForExistence(timeout: 15))
        let states = app.staticTexts["nwr_states"]
        sleep(1)
        // The film for the requester: a screenshot about every 0.1 s, named
        // by the milliseconds since the tap, when a directory is given.
        let filmDir = ProcessInfo.processInfo.environment["CONFORMANCE_NW_RENDERER_FILM"].flatMap { $0.isEmpty ? nil : $0 }
        let filmStart = Date()
        func film(for seconds: TimeInterval) {
            guard let dir = filmDir else { return }
            let until = Date().addingTimeInterval(seconds)
            while Date() < until {
                let ms = Int(Date().timeIntervalSince(filmStart) * 1000)
                try? XCUIScreen.main.screenshot().pngRepresentation
                    .write(to: URL(fileURLWithPath: dir).appendingPathComponent(String(format: "%06d.png", ms)))
                usleep(60_000)
            }
        }
        app.buttons["nwr_start"].tap()

        // While the renderer is drawn the frame is one image read with its alt.
        if filmDir != nil { film(for: 1) } else { sleep(1) }
        let slow = app.descendants(matching: .any).matching(identifier: "nwr_slow_a").firstMatch
        XCTAssertTrue(slow.exists)
        XCTAssertEqual(slow.label, "slow A photo", "the alt is read while the renderer is drawn")
        XCTAssertFalse((states.label).contains("nwr_slow_a:loaded"), "still loading at 1 s")
        film(for: 9)

        let done = NSPredicate { _, _ in
            let s = states.label
            return ["nwr_slow_a:loaded", "nwr_slow_a2:loaded", "nwr_slow_b:loaded", "nwr_fast:loaded",
                    "nwr_fail:failed", "nwr_slow_e:loaded"].allSatisfy { s.contains($0) }
        }
        XCTAssertEqual(XCTWaiter().wait(for: [expectation(for: done, evaluatedWith: nil)], timeout: 40), .completed,
                       "every frame ended: \(states.label)")
        print("NWR first \(states.label)")
        XCTAssertEqual(slow.label, "slow A photo", "the alt stays on the loaded image")
        for state in ["loading", "loaded"] {
            XCTAssertEqual(states.label.components(separatedBy: " ").filter { $0 == "nwr_slow_a:\(state)" }.count, 1,
                           "\(state) once for a frame")
        }
        film(for: 1)
        app.buttons["nwr_toggle"].tap()
        film(for: 2)
        let memory = NSPredicate { _, _ in
            let s = states.label
            return ["nwr_mem_a:loaded", "nwr_mem_b:loaded", "nwr_mem_fast:loaded"].allSatisfy { s.contains($0) }
        }
        XCTAssertEqual(XCTWaiter().wait(for: [expectation(for: memory, evaluatedWith: nil)], timeout: 2), .completed)
        XCTAssertFalse(states.label.contains("nwr_mem_a:loading"), "a memory-cache frame says loaded alone")
        print("NWR second \(states.label)")
        sleep(2)
    }
}
