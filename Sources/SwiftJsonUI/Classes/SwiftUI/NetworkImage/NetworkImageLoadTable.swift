//
//  NetworkImageLoadTable.swift
//  SwiftJsonUI
//
//  The loads in flight, one per URL (and headers): every NetworkImage frame
//  showing a URL while it is read shares its NetworkImageLoad, and the read
//  stops — the network and the wait before a retry — only when no frame
//  watches it any more (ticket jui-networkimage-load-listener, the
//  requester's ruling 2026-11-15). Before SwiftJsonUI 10.41.0 every frame
//  read its URL on its own, two frames of one URL read it twice, and a frame
//  that left the screen kept reading.
//
//  The read is a data task on URLSession.shared whose bytes are watched
//  through KVO (countOfBytesReceived) — the same session, cache and
//  cancellation as the `data(for:)` it replaces: cancelling the Swift task
//  cancels the URLSessionTask.
//

import Foundation
import QuartzCore
import UIKit

@MainActor
public final class NetworkImageLoadTable {
    public static let shared = NetworkImageLoadTable()

    private struct Entry {
        let load: NetworkImageLoad
        var watchers: Int
        var task: Task<Void, Never>?
    }

    private var entries: [String: Entry] = [:]
    private var globalObservers: [UUID: (URL, NetworkImageLoadEvent) -> Void] = [:]

    /// How many tries a read gets (the first and 2 retries, 2 s and 4 s apart).
    nonisolated static let maxRetries = 2

    init() {}

    // MARK: - Every load's events in one place

    /// `handler` gets every load's events with its URL, on the main thread
    /// (progress thinned as for a frame) — the place an app logs when each
    /// image started, its first byte, when it finished and from where.
    public func addObserver(_ handler: @escaping (URL, NetworkImageLoadEvent) -> Void) -> NetworkImageObservation {
        let id = UUID()
        globalObservers[id] = handler
        return NetworkImageObservation { [weak self] in
            MainActor.assumeIsolated { _ = self?.globalObservers.removeValue(forKey: id) }
        }
    }

    func tellGlobalObservers(url: URL, event: NetworkImageLoadEvent) {
        for handler in Array(globalObservers.values) { handler(url, event) }
    }

    // MARK: - Watching a URL

    static func key(_ urlString: String, headers: [String: String]) -> String {
        guard !headers.isEmpty else { return urlString }
        return urlString + "\u{1}" + headers.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: "\u{1}")
    }

    /// The load of `urlString`, started when no frame was reading it. The
    /// caller watches it until `release`.
    func acquire(_ urlString: String, url: URL, headers: [String: String]) -> NetworkImageLoad {
        let key = Self.key(urlString, headers: headers)
        if var entry = entries[key], !entry.load.isDone {
            entry.watchers += 1
            entries[key] = entry
            return entry.load
        }
        let load = NetworkImageLoad(url: url, key: key)
        var entry = Entry(load: load, watchers: 1, task: nil)
        entry.task = Task { [weak self] in
            await Self.read(urlString: urlString, url: url, headers: headers, load: load)
            self?.finished(load)
        }
        entries[key] = entry
        return load
    }

    /// The caller stopped watching `load`; with no frame left, the read stops.
    func release(_ load: NetworkImageLoad) {
        guard var entry = entries[load.key], entry.load === load else { return }
        entry.watchers -= 1
        if entry.watchers > 0 {
            entries[load.key] = entry
            return
        }
        entries[load.key] = nil
        entry.task?.cancel()
    }

    /// A tap on the failed image: the URL's failed mark and its entry go, so
    /// the next acquire is a new read from level 0, attempt 0. Every other
    /// load of a failed URL still waits the cooldown out.
    func forget(_ urlString: String, headers: [String: String]) {
        SwiftUIImageCache.shared.clearFailed(urlString)
        let key = Self.key(urlString, headers: headers)
        if let entry = entries[key] {
            entries[key] = nil
            entry.task?.cancel()
        }
    }

    private func finished(_ load: NetworkImageLoad) {
        if let entry = entries[load.key], entry.load === load {
            entries[load.key] = nil
        }
    }

    /// Loads in flight (tests).
    var inFlightCount: Int { entries.count }

    // MARK: - The read

    /// Reads the URL with retries, decodes and prepares the image, puts it in
    /// the memory cache and tells the load. Runs off the main thread.
    nonisolated private static func read(urlString: String, url: URL, headers: [String: String], load: NetworkImageLoad) async {
        var request = URLRequest(url: url)
        for (k, v) in headers { request.setValue(v, forHTTPHeaderField: k) }
        let source: NetworkImageSource = URLCache.shared.cachedResponse(for: request) != nil ? .disk : .network
        let relay = EventRelay(load: load)
        var lastError: Error?

        for attempt in 0...maxRetries {
            if Task.isCancelled { relay.send(.cancelled); return }
            if attempt > 0 {
                relay.send(.retrying(attempt: attempt))
                do {
                    try await Task.sleep(nanoseconds: UInt64(attempt) * 2_000_000_000)
                } catch {
                    relay.send(.cancelled); return
                }
            }
            relay.send(.requesting)
            do {
                let data = try await fetch(request: request, relay: relay)
                if Task.isCancelled { relay.send(.cancelled); return }
                if let image = UIImage(data: data) {
                    let prepared = await image.byPreparingForDisplay() ?? image
                    if Task.isCancelled { relay.send(.cancelled); return }
                    SwiftUIImageCache.shared.set(urlString, image: prepared)
                    relay.send(.finished(source: source))
                    return
                }
                lastError = URLError(.cannotDecodeContentData)
            } catch {
                if Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled {
                    relay.send(.cancelled); return
                }
                lastError = error
                // A permanent failure cannot be retried into success — an
                // unresolvable host (NXDOMAIN) or malformed URL stays that
                // way, and the 2s+4s backoff only delayed the error face
                // past any observer.
                if let urlError = error as? URLError,
                   [.cannotFindHost, .unsupportedURL, .badURL].contains(urlError.code) {
                    break
                }
            }
        }
        SwiftUIImageCache.shared.markFailed(urlString)
        relay.send(.failed(lastError))
    }

    /// One attempt: a data task whose response and received bytes are
    /// watched through KVO. Cancelling the Swift task cancels the data task,
    /// also when the cancel comes before the task exists (the box's mark).
    nonisolated private static func fetch(request: URLRequest, relay: EventRelay) async throws -> Data {
        let box = TaskBox()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
                let task = URLSession.shared.dataTask(with: request) { data, _, error in
                    box.stopWatching()
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        relay.finalProgress()
                        continuation.resume(returning: data ?? Data())
                    }
                }
                guard box.set(task) else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                let responded = task.observe(\.response, options: [.new]) { task, _ in
                    guard let response = task.response else { return }
                    let length = response.expectedContentLength
                    relay.responded(expected: length >= 0 ? length : nil)
                }
                let bytes = task.observe(\.countOfBytesReceived, options: [.new]) { task, _ in
                    let expected = task.countOfBytesExpectedToReceive
                    relay.bytes(task.countOfBytesReceived, expected: expected > 0 ? expected : nil)
                }
                box.watch([responded, bytes])
                task.resume()
            }
        } onCancel: {
            box.cancel()
        }
    }
}

/// The data task and the cancel mark, behind one lock.
private final class TaskBox: @unchecked Sendable {
    private let lock = NSLock()
    private var task: URLSessionDataTask?
    private var cancelled = false
    private var observations: [NSKeyValueObservation] = []

    /// Holds `task`; false when the cancel came first (the task is not started).
    func set(_ task: URLSessionDataTask) -> Bool {
        lock.lock(); defer { lock.unlock() }
        if cancelled { return false }
        self.task = task
        return true
    }

    func watch(_ observations: [NSKeyValueObservation]) {
        lock.lock(); defer { lock.unlock() }
        self.observations = observations
    }

    func stopWatching() {
        lock.lock()
        let observations = self.observations
        self.observations = []
        lock.unlock()
        observations.forEach { $0.invalidate() }
    }

    func cancel() {
        lock.lock()
        cancelled = true
        let task = self.task
        lock.unlock()
        task?.cancel()
    }
}

/// Carries a read's events to the main thread in order, thinning progress
/// to at most 64 a read: the first body bytes (the load is `receiving`
/// from there), one each time the bytes cross a 63rd of the expected length
/// (at least the 1/64 the ruling asks; 16 KiB steps when the length is
/// unknown), and the last. At most one progress waits for the main thread at
/// a time, folded to the newest.
final class EventRelay: @unchecked Sendable {
    private let lock = NSLock()
    private let load: NetworkImageLoad
    private var sentReceived: Int64 = -1
    private var lastReceived: Int64 = 0
    private var lastExpected: Int64?
    private var respondedSent = false
    private var pending: (Int64, Int64?)?
    private var flushQueued = false

    nonisolated static let unknownLengthStep: Int64 = 16 * 1024

    init(load: NetworkImageLoad) {
        self.load = load
    }

    func send(_ event: NetworkImageLoadEvent) {
        if case .requesting = event {
            lock.lock()
            sentReceived = -1; lastReceived = 0; lastExpected = nil; respondedSent = false
            lock.unlock()
        }
        let load = self.load
        DispatchQueue.main.async {
            MainActor.assumeIsolated { load.deliver(event) }
        }
    }

    func responded(expected: Int64?) {
        lock.lock()
        if respondedSent { lock.unlock(); return }
        respondedSent = true
        lastExpected = expected
        lock.unlock()
        send(.responded(expected: expected))
    }

    func bytes(_ received: Int64, expected: Int64?) {
        lock.lock()
        lastReceived = received
        if let expected { lastExpected = expected }
        let due: Bool
        if received <= 0 {
            due = false
        } else if sentReceived < 0 {
            due = true
        } else if let e = lastExpected, e > 0 {
            due = received < e && Self.bucket(received, of: e) > Self.bucket(sentReceived, of: e)
        } else {
            due = received - sentReceived >= Self.unknownLengthStep
        }
        lock.unlock()
        if due { queueProgress(received, expected: lastExpected) }
    }

    /// The last progress, when the thinning held it back.
    func finalProgress() {
        lock.lock()
        let due = lastReceived > 0 && lastReceived != sentReceived
        let received = lastReceived, expected = lastExpected
        lock.unlock()
        if due { queueProgress(received, expected: expected) }
    }

    /// Which 63rd of `expected` the bytes are in (0...62 below the end).
    nonisolated static func bucket(_ received: Int64, of expected: Int64) -> Int64 {
        guard received > 0 else { return -1 }
        return min(62, received * 63 / expected)
    }

    private func queueProgress(_ received: Int64, expected: Int64?) {
        lock.lock()
        sentReceived = received
        pending = (received, expected)
        let queue = !flushQueued
        flushQueued = true
        lock.unlock()
        guard queue else { return }
        let load = self.load
        DispatchQueue.main.async { [self] in
            lock.lock()
            let value = pending
            pending = nil
            flushQueued = false
            lock.unlock()
            guard let value else { return }
            MainActor.assumeIsolated { load.deliver(.progress(received: value.0, expected: value.1)) }
        }
    }
}
