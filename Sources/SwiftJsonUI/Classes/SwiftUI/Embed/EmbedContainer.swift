//
//  EmbedContainer.swift
//  SwiftJsonUI
//
//  SwiftUI container for the `Embed` view type. Hosts another screen as a
//  region of the parent layout. The embedded screen owns its own ViewModel
//  (independent from the parent VM) via SwiftUI's @StateObject identity
//  scoping — this container provides the params / events / navigation
//  boundary scaffold around it.
//
//  v1 contracts (per jsonui-cli/docs/plans/2026-05-11-embed-feature.md §16):
//  - `screen` value is the layout JSON filename (snake_case).
//  - `params` is a flat [String: Any]. VMs that conform to
//    `EmbeddedInitParamsReceiver` receive them on first appear and on every
//    change; other VMs silently ignore.
//  - `events` are emitted by the embedded VM via
//    `EnvironmentValues.embeddedScreenContext.emit(name:payload:)`. When the
//    screen is shown standalone (not embedded), the context is nil and emit
//    is a no-op.
//  - `navigationMode.delegate` (v1 only): the embedded screen shares the
//    parent's navigation, BUT pop/dismiss/navigateBack are bounded at the
//    embed (the embed itself is never closed by its own child's back call).
//

import SwiftUI

public enum EmbedNavigationMode {
    /// Embedded screen shares the parent's NavController/Router for push;
    /// pop/dismiss/navigateBack are bounded at the embed.
    case delegate
    /// (v1.5) Embedded screen has its own private navigation stack.
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
        // The `id(embedId)` modifier ensures that distinct embeds in the
        // same parent body position get distinct view identities — which is
        // what gives each one its own @StateObject lifecycle when the same
        // screen is embedded multiple times.
        content()
            .id(embedId)
            .environment(\.embeddedScreenContext, EmbeddedScreenContext(
                embedId: embedId,
                screen: screen,
                params: params,
                navigationDelegate: EmbeddedNavigationDelegate(boundedAtEmbed: navigationMode == .delegate),
                eventBridge: eventBridge
            ))
    }
}

// MARK: - EmbeddedEvent

/// Event emitted by an embedded screen, surfaced to the parent via `eventBridge`.
/// The `.named(name:payload:)` case is the generic envelope; named events
/// follow the `on[A-Z]...` convention.
public enum EmbeddedEvent {
    case named(name: String, payload: [String: Any])
}

// MARK: - EmbeddedScreenContext (environment-propagated)

/// Context propagated to the embedded screen via the SwiftUI environment.
/// VMs read this to access init params, emit events back to the parent, and
/// route navigation calls through the embed-aware delegate.
public struct EmbeddedScreenContext {
    public let embedId: String
    public let screen: String
    public let params: [String: Any]
    public let navigationDelegate: EmbeddedNavigationDelegate
    private let eventBridge: ((EmbeddedEvent) -> Void)?

    public init(
        embedId: String,
        screen: String,
        params: [String: Any],
        navigationDelegate: EmbeddedNavigationDelegate,
        eventBridge: ((EmbeddedEvent) -> Void)?
    ) {
        self.embedId = embedId
        self.screen = screen
        self.params = params
        self.navigationDelegate = navigationDelegate
        self.eventBridge = eventBridge
    }

    /// Emit an event to the parent. Called by the embedded VM (e.g. on
    /// `viewModel.userTapped() { context.emit("onOrderUpdated", payload: [:]) }`).
    /// No-op when the screen is shown standalone (context is nil).
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

// MARK: - InitParams contract (optional VM conformance)

/// Optional protocol: VMs that want to react to embed init params conform
/// to this and implement `applyInitParams(_:)`. Called once on first appear,
/// and again whenever the bound params change.
public protocol EmbeddedInitParamsReceiver: AnyObject {
    func applyInitParams(_ params: [String: Any])
}

// MARK: - Navigation boundary

/// Bounds pop/dismiss/navigateBack at the embed when navigationMode is
/// `.delegate`. The embedded VM should route nav calls through this rather
/// than directly invoking the parent's NavController, so that "back" inside
/// the embed never closes the embed itself.
public struct EmbeddedNavigationDelegate {
    /// True when in delegate mode — pop is bounded at the embed.
    /// False in isolated mode (v1.5) — pop drives the embed's private stack.
    public let boundedAtEmbed: Bool

    public init(boundedAtEmbed: Bool) {
        self.boundedAtEmbed = boundedAtEmbed
    }

    /// Returns true if the caller should silently swallow this pop.
    /// In delegate mode + the embed is currently at its root level (no
    /// internal push history), pop is bounded.
    /// VMs/navigators consult this before invoking the parent's
    /// `NavigationPath.removeLast()` or similar.
    public func shouldBoundPop(internalPushDepth: Int) -> Bool {
        return boundedAtEmbed && internalPushDepth == 0
    }
}

// MARK: - Helper modifier for VMs that conform to EmbeddedInitParamsReceiver

public extension View {
    /// Drives `applyInitParams` on the given VM whenever the
    /// `embeddedScreenContext.params` changes. Call this inside the
    /// embedded screen's body so init params reach the VM reactively.
    ///
    /// Usage in a generated screen view:
    /// ```swift
    /// var body: some View {
    ///     OrderDetailGeneratedView(data: $viewModel.data)
    ///         .receiveEmbedInitParams(to: viewModel)
    /// }
    /// ```
    func receiveEmbedInitParams<VM: EmbeddedInitParamsReceiver>(to viewModel: VM) -> some View {
        modifier(EmbedInitParamsModifier(viewModel: viewModel))
    }
}

private struct EmbedInitParamsModifier<VM: EmbeddedInitParamsReceiver>: ViewModifier {
    @Environment(\.embeddedScreenContext) private var context
    let viewModel: VM

    func body(content: Content) -> some View {
        content
            .onAppear {
                if let params = context?.params, !params.isEmpty {
                    viewModel.applyInitParams(params)
                }
            }
            .onChange(of: paramsFingerprint) { _, _ in
                if let params = context?.params {
                    viewModel.applyInitParams(params)
                }
            }
    }

    /// `[String: Any]` is not Equatable. We synthesize a fingerprint from
    /// the description so `.onChange` fires when the dict content shifts.
    /// Good enough for params (which are flat, small, and snapshot-able).
    private var paramsFingerprint: String {
        guard let params = context?.params else { return "" }
        return params.keys.sorted().map { "\($0)=\(params[$0] ?? "nil")" }.joined(separator: "|")
    }
}
