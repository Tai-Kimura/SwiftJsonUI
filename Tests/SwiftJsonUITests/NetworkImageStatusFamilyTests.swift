import XCTest
@testable import SwiftJsonUI

/// The status-code family of a NetworkImage load, against a real local HTTP
/// server (ticket jui-networkimage-error-response-reported-as-progress): for
/// each answer the server gives, the events a renderer is told, the states the
/// ViewModel is told (onLoadStateChange), and the most body bytes a progress
/// carried. Opt-in: run with TEST_RUNNER_NW_STATUS_SERVER=http://127.0.0.1:<port>
/// pointing at the family server; skipped otherwise. Prints one FAMILY line a
/// case.
@MainActor
final class NetworkImageStatusFamilyTests: XCTestCase {
    private func name(_ e: NetworkImageLoadEvent) -> String {
        switch e {
        case .requesting: return "requesting"
        case .responded: return "responded"
        case .progress: return "progress"
        case .retrying(let a): return "retrying(\(a))"
        case .finished(let s): return "finished(\(s.rawValue))"
        case .failed: return "failed"
        case .cancelled: return "cancelled"
        }
    }

    private func spin(until done: () -> Bool, timeout: TimeInterval) {
        let end = Date().addingTimeInterval(timeout)
        while !done() && Date() < end { RunLoop.main.run(until: Date().addingTimeInterval(0.01)) }
    }

    /// One load of `path`: the events, folded so a run of progress reads as
    /// one `progress×n`, the loader's states, and the largest progress.
    /// Whether the events came in the order a renderer is promised: each try
    /// opens with `requesting`; `responded` comes at most once a try and
    /// before any progress; the try ends with retrying, finished or failed,
    /// and nothing follows the end.
    static func inOrder(_ events: [String]) -> Bool {
        var opened = false, responded = false, ended = false
        for e in events {
            if ended { return false }
            switch e {
            case "requesting":
                opened = true; responded = false
            case "responded":
                if !opened || responded { return false }
                responded = true
            case "progress":
                if !opened || !responded { return false }
            default:
                if !opened { return false }
                if e.hasPrefix("retrying") { opened = false } else { ended = true }
            }
        }
        return ended
    }

    private func measure(_ urlString: String) -> (events: String, states: String, maxBytes: Int64, inOrder: Bool) {
        let load = NetworkImageLoadTable.shared.acquire(urlString, url: URL(string: urlString)!, headers: [:])
        var events: [NetworkImageLoadEvent] = []
        let observation = load.observe { events.append($0) }
        let loader = NetworkImageLoader()
        var states: [String] = []
        loader.onLoadStateChange = { states.append($0) }
        loader.loadIfNeeded(url: urlString, headers: [:])
        spin(until: { load.isDone && !states.isEmpty && states.last != "loading" }, timeout: 20)
        observation.cancel()
        NetworkImageLoadTable.shared.release(load)
        var folded: [String] = []
        var run = 0
        for e in events.map(name) {
            if e == "progress" { run += 1; continue }
            if run > 0 { folded.append("progress×\(run)"); run = 0 }
            folded.append(e)
        }
        if run > 0 { folded.append("progress×\(run)") }
        let maxBytes = events.compactMap { e -> Int64? in if case .progress(let r, _) = e { return r }; return nil }.max() ?? 0
        return (folded.joined(separator: " "), states.joined(separator: " "), maxBytes, Self.inOrder(events.map(name)))
    }

    /// The order check itself, so a broken order is known to read as broken.
    func testTheOrderCheckReadsABrokenOrder() {
        XCTAssertTrue(Self.inOrder(["requesting", "responded", "progress", "progress", "finished(network)"]))
        XCTAssertTrue(Self.inOrder(["requesting", "retrying(1)", "requesting", "responded", "progress", "finished(disk)"]))
        XCTAssertTrue(Self.inOrder(["requesting", "retrying(1)", "requesting", "failed"]))
        XCTAssertFalse(Self.inOrder(["progress", "requesting", "responded", "finished(network)"]), "progress first")
        XCTAssertFalse(Self.inOrder(["requesting", "progress", "responded", "finished(network)"]), "progress before responded")
        XCTAssertFalse(Self.inOrder(["requesting", "responded", "responded", "finished(network)"]), "responded twice")
        XCTAssertFalse(Self.inOrder(["requesting", "finished(network)", "progress"]), "after the end")
        XCTAssertFalse(Self.inOrder(["requesting", "responded"]), "no end")
    }

    func testTheStatusFamily() throws {
        guard let server = ProcessInfo.processInfo.environment["NW_STATUS_SERVER"] else {
            throw XCTSkip("NW_STATUS_SERVER is not set: the status family runs against a local server")
        }
        let run = UUID().uuidString.prefix(8)
        for c in ["ok", "fast", "nffast", "html200", "moved", "movednf", "nf", "nfbig", "nfpng", "err", "flaky", "nm"] {
            let r = measure("\(server)/\(c)/\(run)")
            print("FAMILY \(c) | \(r.events) | \(r.states) | maxBytes=\(r.maxBytes) | order=\(r.inOrder ? "ok" : "BROKEN")")
            XCTAssertTrue(r.inOrder, "\(c): \(r.events)")
        }
        // 304: the first load stores the image with its ETag; the second,
        // with the memory cache emptied, revalidates and the server says 304.
        let etag = "\(server)/etag/\(run)"
        let first = measure(etag)
        print("FAMILY etag-first | \(first.events) | \(first.states) | maxBytes=\(first.maxBytes) | order=\(first.inOrder ? "ok" : "BROKEN")")
        XCTAssertTrue(first.inOrder, first.events)
        SwiftUIImageCache.shared.remove(etag)
        let second = measure(etag)
        print("FAMILY etag-304 | \(second.events) | \(second.states) | maxBytes=\(second.maxBytes) | order=\(second.inOrder ? "ok" : "BROKEN")")
        XCTAssertTrue(second.inOrder, second.events)
    }
}
