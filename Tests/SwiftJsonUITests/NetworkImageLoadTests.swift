//
//  NetworkImageLoadTests.swift
//  SwiftJsonUITests
//
//  NetworkImage's loads (ticket jui-networkimage-load-listener, the
//  requester's ruling 2026-11-15): the events in order and how many, one read
//  per URL, the read stopped when no frame watches it, an image the memory
//  cache holds drawn with no renderer and "loaded" alone, the fades' table,
//  and the renderer put on after loadingDelay.
//

import XCTest
import UIKit
import QuartzCore
@testable import SwiftJsonUI

/// Serves `png` for host nwload.test in `chunks` pieces, `gap` apart, with a
/// Content-Length; counts requests and stops per path.
private final class SlowImageProtocol: URLProtocol {
    static let host = "nwload.test"
    private static let lock = NSLock()
    private static var _requests: [String] = []
    private static var _stops: [String] = []
    static var chunks = 8
    /// The status of each answer in turn (the last repeats); 200 by default.
    static var statuses: [Int] = [200]
    /// The body of an answer that is not 200; nil sends the image.
    static var errorBody: Data? = nil
    /// A connection that is cut: every request fails with this error.
    static var failWith: URLError? = nil
    static var gap: TimeInterval = 0.02
    static var png: Data = {
        let size = CGSize(width: 64, height: 64)
        return UIGraphicsImageRenderer(size: size).pngData { ctx in
            for i in 0..<64 {
                UIColor(hue: CGFloat(i) / 64, saturation: 1, brightness: 1, alpha: 1).setFill()
                ctx.fill(CGRect(x: CGFloat(i), y: 0, width: 1, height: 64))
            }
        }
    }()
    static var requests: [String] { lock.lock(); defer { lock.unlock() }; return _requests }
    static var stops: [String] { lock.lock(); defer { lock.unlock() }; return _stops }
    static func reset() { lock.lock(); _requests = []; _stops = []; statuses = [200]; errorBody = nil; failWith = nil; lock.unlock() }

    private var stopped = false
    private let stateLock = NSLock()

    override class func canInit(with request: URLRequest) -> Bool { request.url?.host == host }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let url = request.url!
        Self.lock.lock(); Self._requests.append(url.path); let n = Self._requests.count; Self.lock.unlock()
        if let error = Self.failWith {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let status = Self.statuses[min(n, Self.statuses.count) - 1]
        let body = status == 200 ? Self.png : (Self.errorBody ?? Self.png)
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1",
                                       headerFields: ["Content-Type": "image/png", "Content-Length": "\(body.count)"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        let pieces = max(1, Self.chunks)
        let size = (body.count + pieces - 1) / pieces
        let gap = Self.gap
        DispatchQueue.global().async {
            var offset = 0
            while offset < body.count {
                if self.isStopped { return }
                let end = min(body.count, offset + size)
                self.client?.urlProtocol(self, didLoad: body.subdata(in: offset..<end))
                offset = end
                Thread.sleep(forTimeInterval: gap)
            }
            if self.isStopped { return }
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }

    private var isStopped: Bool { stateLock.lock(); defer { stateLock.unlock() }; return stopped }

    override func stopLoading() {
        stateLock.lock(); let was = stopped; stopped = true; stateLock.unlock()
        if !was { Self.lock.lock(); Self._stops.append(request.url!.path); Self.lock.unlock() }
    }
}

@MainActor
private final class CountingRenderer: NetworkImageLoadingRenderer {
    static var made = 0
    static var attached = 0
    static var finished: [NetworkImageSource] = []
    func attach(to layer: CALayer, load: NetworkImageLoad, size: CGSize, context: NetworkImageRendererContext) { Self.attached += 1 }
    func finish(source: NetworkImageSource, transition: CFTimeInterval) { Self.finished.append(source) }
    func fail(transition: CFTimeInterval) {}
    func detach() {}
}

@MainActor
final class NetworkImageLoadTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(SlowImageProtocol.self)
        SlowImageProtocol.reset()
        SlowImageProtocol.chunks = 8
        SlowImageProtocol.gap = 0.02
        CountingRenderer.made = 0
        CountingRenderer.attached = 0
        CountingRenderer.finished = []
        NetworkImageLoadingRenderers.register("counting") { CountingRenderer.made += 1; return CountingRenderer() }
    }

    override func tearDown() {
        NetworkImageLoadTable.retryStepNanoseconds = 2_000_000_000
        URLProtocol.unregisterClass(SlowImageProtocol.self)
        NetworkImageLoadingRenderers.unregister("counting")
        super.tearDown()
    }

    private func freshURL(_ name: String = "img") -> String {
        "https://\(SlowImageProtocol.host)/\(name)-\(UUID().uuidString).png"
    }

    private func name(_ e: NetworkImageLoadEvent) -> String {
        switch e {
        case .requesting: return "requesting"
        case .responded: return "responded"
        case .progress: return "progress"
        case .retrying: return "retrying"
        case .finished(let s): return "finished(\(s.rawValue))"
        case .failed: return "failed"
        case .cancelled: return "cancelled"
        }
    }

    private func spin(until done: () -> Bool, timeout: TimeInterval = 10) {
        let end = Date().addingTimeInterval(timeout)
        while !done() && Date() < end { RunLoop.main.run(until: Date().addingTimeInterval(0.01)) }
    }

    func testTheEventsComeInOrderAndProgressIsThinnedTo64() {
        SlowImageProtocol.chunks = 400
        SlowImageProtocol.gap = 0.001
        let urlString = freshURL()
        let load = NetworkImageLoadTable.shared.acquire(urlString, url: URL(string: urlString)!, headers: [:])
        var events: [NetworkImageLoadEvent] = []
        let observation = load.observe { events.append($0) }
        spin(until: { load.isDone })
        observation.cancel()
        let names = events.map(name)
        XCTAssertEqual(names.first, "requesting")
        XCTAssertEqual(names.dropFirst().first, "responded")
        XCTAssertEqual(names.last, "finished(network)")
        let progress = events.compactMap { e -> Int64? in if case .progress(let r, _) = e { return r }; return nil }
        XCTAssertGreaterThan(progress.count, 1)
        XCTAssertLessThanOrEqual(progress.count, 64, "progress is thinned to 64 a read")
        XCTAssertLessThanOrEqual(events.count, 67)
        XCTAssertEqual(progress, progress.sorted(), "progress only rises")
        XCTAssertEqual(progress.last, Int64(SlowImageProtocol.png.count), "the last progress is every byte")
        XCTAssertEqual(load.phase, .finished)
        XCTAssertNotNil(load.respondedAt)
        XCTAssertNotNil(load.lastByteAt)
        XCTAssertNotNil(SwiftUIImageCache.shared.get(urlString), "the prepared image is in the memory cache")
        XCTAssertEqual(SlowImageProtocol.requests.count, 1)
    }

    func testOnlyA2xxAnswerIsTheImage() {
        for code in [200, 204, 299] {
            XCTAssertNil(NetworkImageLoadTable.rejectedStatus(HTTPURLResponse(url: URL(string: "https://a.test/")!, statusCode: code, httpVersion: nil, headerFields: nil)), "\(code)")
        }
        for code in [100, 301, 302, 304, 400, 404, 410, 429, 500, 503] {
            XCTAssertEqual(NetworkImageLoadTable.rejectedStatus(HTTPURLResponse(url: URL(string: "https://a.test/")!, statusCode: code, httpVersion: nil, headerFields: nil)), code)
        }
        XCTAssertNil(NetworkImageLoadTable.rejectedStatus(URLResponse(url: URL(string: "file:///a.png")!, mimeType: "image/png", expectedContentLength: 1, textEncodingName: nil)), "not HTTP")
        XCTAssertNil(NetworkImageLoadTable.rejectedStatus(nil))
    }

    /// An answer that is not the image (here a 404 whose body IS a PNG, the
    /// sharpest case: it used to be shown) tells the renderer neither
    /// `responded` nor progress and fails at once — a 4xx is not retried; the
    /// ViewModel is told loading, failed.
    func testAnErrorAnswerIsNeverProgressNorTheImage() {
        NetworkImageLoadTable.retryStepNanoseconds = 10_000_000
        SlowImageProtocol.statuses = [404]
        let urlString = freshURL("nf")
        let load = NetworkImageLoadTable.shared.acquire(urlString, url: URL(string: urlString)!, headers: [:])
        var events: [String] = []
        let observation = load.observe { events.append(self.name($0)) }
        let loader = NetworkImageLoader()
        var states: [String] = []
        loader.onLoadStateChange = { states.append($0) }
        loader.loadIfNeeded(url: urlString, headers: [:])
        spin(until: { load.isDone && states.last == "failed" })
        observation.cancel()
        XCTAssertEqual(events, ["requesting", "failed"])
        XCTAssertEqual(states, ["loading", "failed"])
        XCTAssertNil(load.respondedAt)
        XCTAssertNil(load.lastByteAt)
        XCTAssertNil(SwiftUIImageCache.shared.get(urlString), "the 404's PNG body is not the image")
        XCTAssertEqual(SlowImageProtocol.requests.count, 1)
        NetworkImageLoadTable.shared.release(load)
    }

    /// Ruling 2026-11-15: 408, 429, 5xx and a cut connection are retried twice
    /// (retrying 1, 2); any other rejected answer (a 4xx, a 304 nobody asked
    /// for, an unfollowed 3xx) fails at once; the
    /// ViewModel is told loading until the end either way.
    func testOnlyAPassingFailureIsRetried() {
        NetworkImageLoadTable.retryStepNanoseconds = 10_000_000
        var cases: [(String, Int?, URLError?, Int)] = []
        for code in [400, 401, 403, 404, 410, 451, 304] { cases.append(("\(code)", code, nil, 1)) }
        for code in [408, 429, 500, 502, 503] { cases.append(("\(code)", code, nil, 3)) }
        cases.append(("connection lost", nil, URLError(.networkConnectionLost), 3))
        cases.append(("timed out", nil, URLError(.timedOut), 3))
        for (label, code, error, tries) in cases {
            SlowImageProtocol.reset()
            if let code { SlowImageProtocol.statuses = [code] }
            SlowImageProtocol.failWith = error
            let urlString = freshURL("retry")
            let load = NetworkImageLoadTable.shared.acquire(urlString, url: URL(string: urlString)!, headers: [:])
            var events: [String] = []
            let observation = load.observe { e in
                if case .retrying(let a) = e { events.append("retrying(\(a))") } else { events.append(self.name(e)) }
            }
            let loader = NetworkImageLoader()
            var states: [String] = []
            loader.onLoadStateChange = { states.append($0) }
            loader.loadIfNeeded(url: urlString, headers: [:])
            spin(until: { load.isDone && states.last == "failed" })
            observation.cancel()
            let expected = tries == 1 ? ["requesting", "failed"]
                : ["requesting", "retrying(1)", "requesting", "retrying(2)", "requesting", "failed"]
            XCTAssertEqual(events, expected, label)
            XCTAssertEqual(states, ["loading", "failed"], label)
            XCTAssertEqual(SlowImageProtocol.requests.count, tries, label)
            NetworkImageLoadTable.shared.release(load)
        }
    }

    func testWhichStatusesArePermanent() {
        for code in [100, 300, 302, 304, 400, 401, 403, 404, 405, 410, 422, 451, 499] { XCTAssertTrue(NetworkImageLoadTable.isPermanent(status: code), "\(code)") }
        for code in [408, 429, 500, 502, 503, 504, 599] { XCTAssertFalse(NetworkImageLoadTable.isPermanent(status: code), "\(code)") }
    }

    /// 503 then 200: only the attempt that brings the image is told as
    /// responded and progress.
    func testOnlyTheAttemptThatBringsTheImageIsProgress() {
        NetworkImageLoadTable.retryStepNanoseconds = 10_000_000
        SlowImageProtocol.statuses = [503, 200]
        SlowImageProtocol.errorBody = Data("busy".utf8)
        let urlString = freshURL("flaky")
        let load = NetworkImageLoadTable.shared.acquire(urlString, url: URL(string: urlString)!, headers: [:])
        var events: [String] = []
        let observation = load.observe { events.append(self.name($0)) }
        spin(until: { load.isDone })
        observation.cancel()
        let folded = events.reduce(into: [String]()) { r, e in if !(e == "progress" && r.last == "progress") { r.append(e) } }
        XCTAssertEqual(folded, ["requesting", "retrying", "requesting", "responded", "progress", "finished(network)"])
        XCTAssertEqual(load.phase, .finished)
        NetworkImageLoadTable.shared.release(load)
    }

    // MARK: - No src (networkImage.noSrc = defaultImage)

    /// What a frame shows: defaultImage for no src, errorImage for a read
    /// that failed (the body's face; the renderer's layer view shows the
    /// error image over itself once failed).
    private func shown(_ loader: NetworkImageLoader) -> String {
        switch loader.face {
        case .noSrc: return "defaultImage"
        case .failed: return "errorImage"
        case .image: return "image"
        case .loading: return "loading"
        case .renderer: return loader.hasFailed ? "errorImage" : (loader.loadedImage != nil ? "image" : "renderer")
        }
    }

    /// The urls a frame is given in turn (the first at onAppear, the rest at
    /// onChange, as the body calls loadIfNeeded), with a renderer named.
    private func run(_ urls: [String?]) -> (shown: String, states: [String], events: [String], renderers: Int) {
        let loader = NetworkImageLoader()
        loader.rendererFactory = NetworkImageLoadingRenderers.factory(for: "counting")
        var states: [String] = []
        var events: [String] = []
        loader.onLoadStateChange = { states.append($0) }
        loader.onLoadEvent = { if !$0.isProgress { events.append(self.name($0)) } }
        for (i, url) in urls.enumerated() {
            loader.loadIfNeeded(url: url, headers: [:])
            spin(until: { loader.load == nil || loader.load!.isDone }, timeout: 5)
            if i < urls.count - 1 { spin(until: { false }, timeout: 0.05) }
        }
        spin(until: { false }, timeout: 0.1)
        let made = CountingRenderer.made
        loader.disappear()
        return (shown(loader), states, events, made)
    }

    private func dynamicURL(_ json: String, _ data: [String: Any]) throws -> String? {
        let c = try JSONDecoder().decode(DynamicComponent.self, from: json.data(using: .utf8)!)
        return NetworkImageConverter.declaredURL(c, data: data)
    }

    func testNoSrcFamily() throws {
        NetworkImageLoadTable.retryStepNanoseconds = 10_000_000
        let good = freshURL("good")
        var rows: [(String, [String?])] = [
            ("static nil", [nil]),
            ("static \"\"", [""]),
            ("static blank", ["   "]),
            ("static bound \"\"", [String?.some("")]),
            ("static url then \"\"", [good, ""]),
            ("static url then blank", [freshURL("good2"), "  "]),
            ("static url then nil", [freshURL("good3"), nil]),
        ]
        let base = #"{ "type": "NetworkImage", "defaultImage": "d", "errorImage": "e""#
        rows += [
            ("dynamic absent", [try dynamicURL(base + "}", [:])]),
            ("dynamic \"\"", [try dynamicURL(base + #", "src": "" }"#, [:])]),
            ("dynamic blank", [try dynamicURL(base + #", "src": "   " }"#, [:])]),
            ("dynamic @{img} \"\"", [try dynamicURL(base + #", "src": "@{img}" }"#, ["img": ""])]),
            ("dynamic @{img} missing", [try dynamicURL(base + #", "src": "@{img}" }"#, [:])]),
            ("dynamic @{img} url then \"\"", [try dynamicURL(base + #", "src": "@{img}" }"#, ["img": freshURL("good4")]),
                                               try dynamicURL(base + #", "src": "@{img}" }"#, ["img": ""])]),
        ]
        for (label, urls) in rows {
            SlowImageProtocol.reset()
            CountingRenderer.made = 0
            let r = run(urls)
            print("NOSRC \(label) | shown=\(r.shown) | states=\(r.states.joined(separator: ",")) | events=\(r.events.joined(separator: ",")) | renderers=\(r.renderers) | requests=\(SlowImageProtocol.requests.count)")
            // No src draws defaultImage and tells nothing; a src that went
            // away drops the image it had and tells nothing more.
            XCTAssertEqual(r.shown, "defaultImage", label)
            if urls.count == 1 {
                XCTAssertEqual(r.states, [], label)
                XCTAssertEqual(r.events, [], label)
                XCTAssertEqual(SlowImageProtocol.requests.count, 0, label)
            } else {
                XCTAssertEqual(r.states, ["loading", "loaded"], label)
                XCTAssertEqual(r.events, ["requesting", "responded", "finished(network)"], label)
            }
        }
        SlowImageProtocol.reset()
        SlowImageProtocol.statuses = [404]
        CountingRenderer.made = 0
        let failed = run([freshURL("nf")])
        print("NOSRC failed read | shown=\(failed.shown) | states=\(failed.states.joined(separator: ",")) | events=\(failed.events.joined(separator: ",")) | renderers=\(failed.renderers) | requests=\(SlowImageProtocol.requests.count)")
        XCTAssertEqual(failed.shown, "errorImage", "a read that failed draws errorImage")
        XCTAssertEqual(failed.states, ["loading", "failed"])
    }

    /// A src that goes away and comes back is read and reported again.
    func testASrcThatComesBackIsReportedFromLoading() {
        let url = freshURL("back")
        let r = run([url, "", url])
        XCTAssertEqual(r.shown, "image")
        XCTAssertEqual(r.states, ["loading", "loaded", "loaded"], "back from the memory cache: loaded again")
    }

    func testTwoFramesOfOneURLShareOneRead() {
        let urlString = freshURL()
        let url = URL(string: urlString)!
        let a = NetworkImageLoadTable.shared.acquire(urlString, url: url, headers: [:])
        let b = NetworkImageLoadTable.shared.acquire(urlString, url: url, headers: [:])
        XCTAssertTrue(a === b, "the second frame joins the first frame's load")
        spin(until: { a.isDone })
        XCTAssertEqual(SlowImageProtocol.requests.filter { urlString.hasSuffix($0) }.count, 1)
        NetworkImageLoadTable.shared.release(a)
        NetworkImageLoadTable.shared.release(b)
    }

    func testTheReadStopsWhenNoFrameWatchesIt() {
        SlowImageProtocol.chunks = 50
        SlowImageProtocol.gap = 0.05
        let urlString = freshURL()
        let url = URL(string: urlString)!
        let a = NetworkImageLoadTable.shared.acquire(urlString, url: url, headers: [:])
        let b = NetworkImageLoadTable.shared.acquire(urlString, url: url, headers: [:])
        var events: [String] = []
        let observation = a.observe { events.append(self.name($0)) }
        spin(until: { a.phase == .receiving })
        NetworkImageLoadTable.shared.release(a)
        spin(until: { false }, timeout: 0.2)
        XCTAssertTrue(SlowImageProtocol.stops.isEmpty, "one frame still watches: the read goes on")
        NetworkImageLoadTable.shared.release(b)
        spin(until: { a.isDone })
        XCTAssertEqual(a.phase, .cancelled)
        XCTAssertEqual(events.last, "cancelled")
        // URLProtocol's stopLoading comes on the session's own queue, a moment
        // after the cancel reaches the task.
        spin(until: { SlowImageProtocol.stops.count == 1 }, timeout: 3)
        XCTAssertEqual(SlowImageProtocol.stops.count, 1, "the URLSessionTask was cancelled")
        XCTAssertEqual(NetworkImageLoadTable.shared.inFlightCount, 0)
        observation.cancel()
    }

    func testTheLoaderReportsLoadingThenLoadedAndNothingOnAProgress() {
        let urlString = freshURL()
        let loader = NetworkImageLoader()
        var states: [String] = []
        var publishes = 0
        let sub = loader.objectWillChange.sink { publishes += 1 }
        loader.onLoadStateChange = { states.append($0) }
        SlowImageProtocol.chunks = 200
        SlowImageProtocol.gap = 0.002
        loader.loadIfNeeded(url: urlString, headers: [:])
        spin(until: { loader.loadedImage != nil })
        XCTAssertEqual(states, ["loading", "loaded"])
        XCTAssertLessThan(publishes, 10, "progress never touches the published states")
        sub.cancel()
    }

    func testAnImageTheMemoryCacheHoldsIsLoadedAloneWithNoRenderer() {
        let urlString = freshURL()
        SwiftUIImageCache.shared.set(urlString, image: UIImage(data: SlowImageProtocol.png)!)
        let loader = NetworkImageLoader()
        loader.rendererFactory = NetworkImageLoadingRenderers.factory(for: "counting")
        var states: [String] = []
        var events: [String] = []
        loader.onLoadStateChange = { states.append($0) }
        loader.onLoadEvent = { events.append(self.name($0)) }
        loader.loadIfNeeded(url: urlString, headers: [:])
        XCTAssertNotNil(loader.loadedImage, "drawn from the first frame")
        XCTAssertFalse(loader.hostActive, "no layer view")
        XCTAssertEqual(states, ["loaded"])
        XCTAssertEqual(events, ["finished(memory)"])
        XCTAssertEqual(CountingRenderer.made, 0)
        XCTAssertTrue(SlowImageProtocol.requests.isEmpty)
    }

    func testAFrameThatLeavesReportsNothingAndReadsAgainWhenItComesBack() {
        SlowImageProtocol.chunks = 50
        SlowImageProtocol.gap = 0.05
        let urlString = freshURL()
        let loader = NetworkImageLoader()
        var states: [String] = []
        loader.onLoadStateChange = { states.append($0) }
        loader.loadIfNeeded(url: urlString, headers: [:])
        spin(until: { (loader.load?.received ?? 0) > 0 })
        loader.disappear()
        spin(until: { SlowImageProtocol.stops.count == 1 })
        XCTAssertEqual(states, ["loading"], "a cancel calls nothing")
        SlowImageProtocol.chunks = 4
        SlowImageProtocol.gap = 0.01
        loader.loadIfNeeded(url: urlString, headers: [:])
        spin(until: { loader.loadedImage != nil })
        XCTAssertEqual(states, ["loading", "loaded"], "the next appearance ends it")
        XCTAssertEqual(SlowImageProtocol.requests.count, 2)
    }

    func testAnUnknownRendererNameIsNoRenderer() {
        XCTAssertNil(NetworkImageLoadingRenderers.factory(for: nil))
        XCTAssertNil(NetworkImageLoadingRenderers.factory(for: ""))
        XCTAssertNil(NetworkImageLoadingRenderers.factory(for: "nothing-registered"))
        XCTAssertNotNil(NetworkImageLoadingRenderers.factory(for: "counting"))
    }

    func testTheFadesFollowTheRulingsTable() {
        let t: CFTimeInterval = 0.24
        typealias F = NetworkImageFade
        XCTAssertEqual(F.fade(.image, transition: t, rendererNamed: true, rendererAttached: true, fromMemory: false),
                       F(delay: 0, duration: 0.24, curve: F.easeInOutCubic))
        XCTAssertEqual(F.fade(.image, transition: t, rendererNamed: true, rendererAttached: false, fromMemory: false),
                       F(delay: 0, duration: 0.12, curve: F.easeOutQuad))
        XCTAssertEqual(F.fade(.error, transition: t, rendererNamed: true, rendererAttached: true, fromMemory: false),
                       F(delay: 0.04, duration: 0.2, curve: F.easeInOutCubic))
        XCTAssertEqual(F.fade(.error, transition: t, rendererNamed: true, rendererAttached: false, fromMemory: false),
                       F(delay: 0, duration: 0.12, curve: F.easeOutQuad))
        XCTAssertEqual(F.fade(.image, transition: t, rendererNamed: true, rendererAttached: true, fromMemory: true), .none)
        XCTAssertEqual(F.fade(.image, transition: 0.3, rendererNamed: false, rendererAttached: false, fromMemory: false),
                       F(delay: 0, duration: 0.3, curve: F.easeOutQuad))
        XCTAssertEqual(F.fade(.image, transition: 0, rendererNamed: false, rendererAttached: false, fromMemory: false), .none)
        // The defaults and the ranges.
        XCTAssertEqual(NetworkImageTiming.transition(nil, rendererFound: true), 0.24)
        XCTAssertEqual(NetworkImageTiming.transition(nil, rendererFound: false), 0)
        XCTAssertEqual(NetworkImageTiming.transition(5000, rendererFound: false), 1)
        XCTAssertEqual(NetworkImageTiming.loadingDelay(nil), 0.2)
        XCTAssertEqual(NetworkImageTiming.loadingDelay(-5), 0)
        XCTAssertEqual(NetworkImageTiming.loadingDelay(9000), 2)
    }

    func testTheRendererIsPutOnAfterTheDelayCountedFromTheLoadsStart() {
        let factory = NetworkImageLoadingRenderers.factory(for: "counting")!
        let fresh = NetworkImageLoad(url: URL(string: freshURL())!, key: "fresh")
        let view = NetworkImageLayerView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        view.begin(load: fresh, factory: factory, delay: 0.3, transition: 0.24, gravity: .resizeAspect, colorScheme: .light)
        spin(until: { false }, timeout: 0.1)
        XCTAssertFalse(view.rendererAttached, "inside loadingDelay: no renderer yet")
        spin(until: { view.rendererAttached }, timeout: 2)
        XCTAssertTrue(view.rendererAttached)

        let old = NetworkImageLoad(url: URL(string: freshURL())!, key: "old", startedAt: CACurrentMediaTime() - 5)
        let joined = NetworkImageLayerView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        joined.begin(load: old, factory: factory, delay: 0.3, transition: 0.24, gravity: .resizeAspect, colorScheme: .light)
        spin(until: { joined.rendererAttached }, timeout: 0.15)
        XCTAssertTrue(joined.rendererAttached, "a load past its delay gets the renderer on the next frame")

        let quick = NetworkImageLoad(url: URL(string: freshURL())!, key: "quick")
        let done = NetworkImageLayerView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        done.begin(load: quick, factory: factory, delay: 0.3, transition: 0.24, gravity: .resizeAspect, colorScheme: .light)
        var finished = false
        done.finish(image: UIImage(data: SlowImageProtocol.png)!, source: .network) { finished = true }
        spin(until: { finished }, timeout: 1)
        spin(until: { false }, timeout: 0.4)
        XCTAssertFalse(done.rendererAttached, "a load done inside the delay never gets a renderer")
        XCTAssertTrue(finished)
        view.takeOff(); joined.takeOff()
    }

    func testAtMostFourRenderersArePutOnInOneFrame() {
        let factory = NetworkImageLoadingRenderers.factory(for: "counting")!
        let old = NetworkImageLoad(url: URL(string: freshURL())!, key: "many", startedAt: CACurrentMediaTime() - 5)
        let views = (0..<12).map { _ in NetworkImageLayerView(frame: CGRect(x: 0, y: 0, width: 20, height: 20)) }
        views.forEach { $0.begin(load: old, factory: factory, delay: 0.2, transition: 0.24, gravity: .resizeAspect, colorScheme: .light) }
        var perTick: [Int] = []
        var last = 0
        let link = TickCounter { perTick.append(CountingRenderer.attached - last); last = CountingRenderer.attached }
        spin(until: { CountingRenderer.attached >= 12 }, timeout: 3)
        link.stop()
        XCTAssertEqual(CountingRenderer.attached, 12)
        XCTAssertLessThanOrEqual(perTick.max() ?? 0, 4, "four a frame: \(perTick)")
        views.forEach { $0.takeOff() }
    }

    func testTheCacheCountsDecodedBytes() {
        let image = UIImage(data: SlowImageProtocol.png)!
        XCTAssertEqual(SwiftUIImageCache.decodedBytes(image), image.cgImage!.bytesPerRow * image.cgImage!.height)
        XCTAssertEqual(SwiftUIImageCache.defaultTotalCostLimit, 64 * 1024 * 1024)
        XCTAssertEqual(SwiftUIImageCache.shared.totalCostLimit, SwiftUIImageCache.defaultTotalCostLimit)
    }
}

/// Counts display frames (the attach queue's ticks run on the same link mode).
@MainActor
private final class TickCounter: NSObject {
    private var link: CADisplayLink?
    private let onTick: () -> Void
    init(_ onTick: @escaping () -> Void) {
        self.onTick = onTick
        super.init()
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        self.link = link
    }
    @objc private func tick() { onTick() }
    func stop() { link?.invalidate(); link = nil }
}
