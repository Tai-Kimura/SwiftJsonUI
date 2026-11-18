//
//  NetworkImageLoad.swift
//  SwiftJsonUI
//
//  One read of one image URL, shared by every NetworkImage frame showing that
//  URL while it is read (NetworkImageLoadTable), and what it tells the frames
//  as it goes (ticket jui-networkimage-load-listener, the requester's ruling
//  2026-11-15).
//
//  A reference type, never an ObservableObject: progress reaches the frames'
//  renderers and onLoadEvent only, so it never redraws a SwiftUI body.
//

import Foundation
import QuartzCore
import UIKit

/// Where a shown image came from.
public enum NetworkImageSource: String, Sendable {
    case memory, disk, network
}

/// What a load tells its observers, on the main thread, in order. Only
/// `progress` is thinned (1/64 of the expected bytes or more since the last
/// one, and the last) and folded to at most one per main run loop turn; the
/// others always arrive, in the order they happened.
public enum NetworkImageLoadEvent {
    /// The request went out (each attempt).
    case requesting
    /// The response's head arrived; `expected` is its Content-Length.
    case responded(expected: Int64?)
    case progress(received: Int64, expected: Int64?)
    /// Waiting to try again; `attempt` is the next attempt (1, 2).
    case retrying(attempt: Int)
    /// Decoded and prepared for display.
    case finished(source: NetworkImageSource)
    case failed(Error?)
    /// Stopped because no frame shows the URL any more.
    case cancelled

    /// The load-state name the event moves the load to (`NetworkImageLoad.Phase`).
    var isProgress: Bool {
        if case .progress = self { return true }
        return false
    }
}

/// Stops an observation: on `cancel()` or when released.
public final class NetworkImageObservation {
    private var onCancel: (() -> Void)?

    init(_ onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    public func cancel() {
        let cancel = onCancel
        onCancel = nil
        cancel?()
    }

    deinit {
        let cancel = onCancel
        if let cancel {
            if Thread.isMainThread {
                cancel()
            } else {
                DispatchQueue.main.async(execute: cancel)
            }
        }
    }
}

@MainActor
public final class NetworkImageLoad {
    /// Where the load is. `receiving` starts with the first body byte;
    /// `retrying` is the wait before the next attempt.
    public enum Phase: String {
        case requesting, responded, receiving, retrying, finished, failed, cancelled
    }

    public let url: URL
    public private(set) var phase: Phase = .requesting
    public private(set) var received: Int64 = 0
    public private(set) var expected: Int64?
    /// The attempt the load is on, from 0.
    public private(set) var attempt: Int = 0
    /// `CACurrentMediaTime()` when the load started — loadingDelay and the
    /// renderer's `elapsedSinceStart` count from here, for every frame that
    /// joins the load later too.
    public let startedAt: CFTimeInterval
    /// `CACurrentMediaTime()` when the current attempt's response arrived.
    public private(set) var respondedAt: CFTimeInterval?
    /// `CACurrentMediaTime()` when the last body bytes arrived.
    public private(set) var lastByteAt: CFTimeInterval?
    public private(set) var source: NetworkImageSource?
    /// The decoded image, set when the load finishes. A frame shows this one,
    /// never the memory cache's copy: the cache may have let it go already
    /// (an image larger than its byte budget is never kept, and one near the
    /// budget can go before the frame looks), which drew the error image for
    /// an image that was read (ticket
    /// sjui-networkimage-finish-fails-when-cache-evicts-the-image).
    public private(set) var image: UIImage?
    /// The level a renderer is showing now, written by the renderer: a frame
    /// that joins the load later starts its renderer from it.
    public var displayLevel: CGFloat = 0

    private var observers: [UUID: (NetworkImageLoadEvent) -> Void] = [:]
    let key: String

    init(url: URL, key: String, startedAt: CFTimeInterval = CACurrentMediaTime()) {
        self.url = url
        self.key = key
        self.startedAt = startedAt
    }

    public var isDone: Bool {
        phase == .finished || phase == .failed || phase == .cancelled
    }

    /// Tells `handler` every event from now on, on the main thread.
    public func observe(_ handler: @escaping (NetworkImageLoadEvent) -> Void) -> NetworkImageObservation {
        let id = UUID()
        observers[id] = handler
        return NetworkImageObservation { [weak self] in
            MainActor.assumeIsolated { _ = self?.observers.removeValue(forKey: id) }
        }
    }

    /// Moves the load to finished with `image` and tells the observers (main thread).
    func deliverFinished(_ image: UIImage, source: NetworkImageSource) {
        self.image = image
        deliver(.finished(source: source))
    }

    /// Moves the load and tells the observers (main thread).
    func deliver(_ event: NetworkImageLoadEvent) {
        let now = CACurrentMediaTime()
        switch event {
        case .requesting:
            phase = .requesting
            respondedAt = nil
            received = 0
            expected = nil
        case .responded(let e):
            phase = .responded
            expected = e
            respondedAt = now
        case .progress(let r, let e):
            if r > 0 && phase != .receiving { phase = .receiving }
            received = r
            if let e { expected = e }
            lastByteAt = now
        case .retrying(let a):
            phase = .retrying
            attempt = a
        case .finished(let s):
            phase = .finished
            source = s
        case .failed:
            phase = .failed
        case .cancelled:
            phase = .cancelled
        }
        for handler in Array(observers.values) { handler(event) }
        NetworkImageLoadTable.shared.tellGlobalObservers(url: url, event: event)
    }
}
