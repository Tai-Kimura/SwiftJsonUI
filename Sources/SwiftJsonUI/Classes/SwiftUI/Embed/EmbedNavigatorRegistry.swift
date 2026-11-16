//
//  EmbedNavigatorRegistry.swift
//  SwiftJsonUI
//
//  embedId-keyed lookup for the private navigators of isolated embeds
//  (SwiftJsonUI >= 10.5.0). Containers in `navigationMode: .isolated`
//  register their active navigator while mounted, so code OUTSIDE the embed
//  subtree (a parent VM resetting a pane on tab switch, the conformance
//  host's injected handlers) can drive push/pop imperatively without any
//  environment access.
//
//  Contract:
//  - Registration is library-internal: the container registers on appear
//    and unregisters on disappear. Only the lookup is public API.
//  - Navigators are held weakly — a container torn down without a
//    disappear callback never leaks its stack.
//  - Two mounted embeds sharing one embedId: last registration wins
//    (mirrors the "distinct embeds should use distinct ids" guidance).
//

import Foundation

public final class EmbedNavigatorRegistry {
    public static let shared = EmbedNavigatorRegistry()

    private final class WeakBox {
        weak var navigator: EmbedNavigator?
        init(_ navigator: EmbedNavigator) { self.navigator = navigator }
    }

    private var storage: [String: WeakBox] = [:]
    private let lock = NSLock()

    private init() {}

    /// The navigator of the currently mounted isolated embed with this id,
    /// or nil when no such embed is mounted.
    public func navigator(for embedId: String) -> EmbedNavigator? {
        lock.lock()
        defer { lock.unlock() }
        guard let box = storage[embedId] else { return nil }
        guard let navigator = box.navigator else {
            storage[embedId] = nil
            return nil
        }
        return navigator
    }

    func register(_ navigator: EmbedNavigator, for embedId: String) {
        lock.lock()
        defer { lock.unlock() }
        storage[embedId] = WeakBox(navigator)
    }

    /// Remove the registration only if this navigator is still the one
    /// registered — a later mount under the same id must not be clobbered
    /// by the earlier container's teardown.
    func unregister(_ embedId: String, ifCurrent navigator: EmbedNavigator) {
        lock.lock()
        defer { lock.unlock() }
        guard storage[embedId]?.navigator === navigator else { return }
        storage[embedId] = nil
    }
}
