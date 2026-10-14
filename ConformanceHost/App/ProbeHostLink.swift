//
//  ProbeHostLink.swift
//  ConformanceHost
//
//  What a probe reaches of a generated view's data in the codegen host.
//
//  The host scripts/generate_codegen_host.rb emits for a probe layout keeps the
//  generated view's Data private to its store, so a probe could see what its
//  generated rows LOOK like but not what they DID. A probe whose manifest
//  (ProbeLayouts/handlers/<probe>.json) names `count` handlers, `watch` or
//  `writes` gets a linked host instead (scripts/codegen_host_emit.rb
//  linked_host), which reads this link from the environment:
//    - a `count` handler, and every change of a watched var, calls `count`;
//    - the values the probe writes (`write`) land in the named Data vars —
//      the ones at hand when the host appears (`values`), then each write.
//  The probe puts the link on the view the registry returns:
//  `CodegenFixtureRegistry.probeView(named:)?.environment(\.probeHostLink, link)`.
//
//  Compiled in both hosts: the dynamic-only build has no generated host, and
//  a link nobody reads is inert.
//

import Combine
import SwiftUI

final class ProbeHostLink {
    /// One count per call: a handler called, a watched var that changed.
    let count: (String) -> Void
    /// Every value written so far, by Data var name (the latest of each).
    private(set) var values: [String: Any] = [:]
    private let subject = PassthroughSubject<[String: Any], Never>()
    /// Each write, as it is made.
    var writes: AnyPublisher<[String: Any], Never> { subject.eraseToAnyPublisher() }
    /// For a host with no link: never publishes.
    static let noWrites = Empty<[String: Any], Never>(completeImmediately: false).eraseToAnyPublisher()

    init(values: [String: Any] = [:], count: @escaping (String) -> Void) {
        self.values = values
        self.count = count
    }

    func write(_ values: [String: Any]) {
        self.values.merge(values) { _, new in new }
        subject.send(values)
    }

    /// A written value into a Data var. The wrong type stops the app rather
    /// than leaving the var as it was: a write that does not land reads, in a
    /// probe, as a stop that held or a control that did not move.
    static func assign<T>(_ value: Any, to slot: inout T, _ name: String) {
        guard let typed = value as? T else {
            preconditionFailure("ProbeHostLink: \(name) was written a \(type(of: value)), the Data var is a \(T.self)")
        }
        slot = typed
    }
}

private struct ProbeHostLinkKey: EnvironmentKey {
    static let defaultValue: ProbeHostLink? = nil
}

extension EnvironmentValues {
    var probeHostLink: ProbeHostLink? {
        get { self[ProbeHostLinkKey.self] }
        set { self[ProbeHostLinkKey.self] = newValue }
    }
}
