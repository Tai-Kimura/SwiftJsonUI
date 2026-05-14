//
//  EmbedContainer.swift
//  SwiftJsonUI
//
//  SwiftUI container for the `Embed` view type. Hosts another screen as a
//  region of the parent layout. The embedded screen owns its own ViewModel
//  (independent from the parent VM) — this container only provides the
//  navigation/event bridging and lifecycle scaffold.
//
//  See jsonui-cli/docs/plans/2026-05-11-embed-feature.md for the full design.
//

import SwiftUI

public enum EmbedNavigationMode {
    /// Embedded screen shares the parent's NavController/Router.
    case delegate
    /// Embedded screen has its own internal navigation stack.
    case isolated
}

public struct EmbedContainer<Content: View>: View {
    public let embedId: String
    public let screen: String
    public let params: [String: Any]
    public let navigationMode: EmbedNavigationMode
    public let eventBridge: ((EmbeddedEvent) -> Void)?
    public let content: () -> Content

    public init(
        embedId: String,
        screen: String,
        params: [String: Any] = [:],
        navigationMode: EmbedNavigationMode = .delegate,
        eventBridge: ((EmbeddedEvent) -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.embedId = embedId
        self.screen = screen
        self.params = params
        self.navigationMode = navigationMode
        self.eventBridge = eventBridge
        self.content = content
    }

    public var body: some View {
        // v1: navigationMode.isolated wrapping (NavigationStack) is implemented in P3.
        // For delegate mode (default), the embedded content uses ambient navigation
        // and SwiftUI's @StateObject identity is preserved by the parent's body
        // position, giving each embed slot its own ViewModel.
        content()
            .environment(\.embeddedScreenContext, EmbeddedScreenContext(
                embedId: embedId,
                screen: screen,
                eventBridge: eventBridge
            ))
    }
}

/// Event emitted by an embedded screen, surfaced to the parent via `eventBridge`.
/// Concrete events use the `.named(name:payload:)` case; typed events can be
/// modelled by extending this enum in P2.
public enum EmbeddedEvent {
    case named(name: String, payload: [String: Any])
}

/// Internal context propagated to the embedded screen via the environment.
/// Allows the embedded VM to call `emit(...)` and have it routed to the
/// parent's eventBridge. P2 will wire the actual emit path.
public struct EmbeddedScreenContext {
    public let embedId: String
    public let screen: String
    public let eventBridge: ((EmbeddedEvent) -> Void)?

    public func emit(_ name: String, payload: [String: Any] = [:]) {
        eventBridge?(.named(name: name, payload: payload))
    }
}

private struct EmbeddedScreenContextKey: EnvironmentKey {
    static let defaultValue: EmbeddedScreenContext? = nil
}

public extension EnvironmentValues {
    var embeddedScreenContext: EmbeddedScreenContext? {
        get { self[EmbeddedScreenContextKey.self] }
        set { self[EmbeddedScreenContextKey.self] = newValue }
    }
}
