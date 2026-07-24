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
//  - `navigationMode.delegate` (default): the embedded screen shares the
//    parent's navigation, BUT pop/dismiss/navigateBack are bounded at the
//    embed (the embed itself is never closed by its own child's back call).
//  - `navigationMode.isolated` (requires the `isolatedNavigation:` init):
//    the embed owns a private NavigationStack. push stays inside the embed,
//    pop stops at the embed stack's root. Stack lifetime == container view
//    identity (reset when the embed leaves the view tree). Deep links only
//    address the host router; edge-swipe gesture routing is delegated to
//    the OS (geometric — not part of the cross-platform contract).
//

import SwiftUI

public enum EmbedNavigationMode {
    /// Embedded screen shares the parent's NavController/Router for push;
    /// pop/dismiss/navigateBack are bounded at the embed.
    case delegate
    /// Embedded screen has its own private navigation stack. Codegen must
    /// pass `isolatedNavigation:` — this case alone does not create a stack.
    case isolated
}

// MARK: - Isolated navigation (v1.5)

/// A pushable entry on an isolated embed's private stack. Hashability is
/// derived from the screen name plus a flat fingerprint of the params —
/// good enough for NavigationPath identity (params are small snapshots).
public struct EmbedDestination: Hashable {
    public let screen: String
    public let params: [String: Any]
    private let fingerprint: String

    public init(screen: String, params: [String: Any] = [:]) {
        self.screen = screen
        self.params = params
        self.fingerprint = EmbedDestination.fingerprint(of: params)
    }

    public static func == (lhs: EmbedDestination, rhs: EmbedDestination) -> Bool {
        lhs.screen == rhs.screen && lhs.fingerprint == rhs.fingerprint
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(screen)
        hasher.combine(fingerprint)
    }

    static func fingerprint(of params: [String: Any]) -> String {
        params.keys.sorted().map { "\($0)=\(params[$0] ?? "nil")" }.joined(separator: "|")
    }
}

/// The private navigation stack of an isolated embed. Owned by the
/// `EmbedContainer` (`.automatic`) or supplied by the host (`.custom`).
/// The cross-platform contract (conformance-tested): push appends to THIS
/// stack, pop stops at the stack root (the embed itself never closes),
/// `depth` reports the number of pushed entries.
public final class EmbedNavigator: ObservableObject {
    @Published public var path = NavigationPath()

    public init() {}

    /// Number of entries pushed above the embed root.
    public var depth: Int { path.count }

    /// Push a screen by layout JSON name (snake_case) with optional params.
    /// This is the canonical, conformance-tested entry point.
    public func push(screen: String, params: [String: Any] = [:]) {
        path.append(EmbedDestination(screen: screen, params: params))
    }

    /// Push an app-defined Hashable route (resolved by a
    /// `.navigationDestination(for:)` the app attaches inside the embed).
    public func push<Route: Hashable>(_ route: Route) {
        path.append(route)
    }

    /// Pop one entry. Bounded at the embed stack's root: popping at depth 0
    /// is a no-op — the embed never closes itself.
    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// Pop everything back to the embed root.
    public func popToRoot() {
        guard !path.isEmpty else { return }
        path.removeLast(path.count)
    }
}

/// How an isolated embed obtains its private stack. This type is new in
/// SwiftJsonUI 10.5.0 — generated code for `navigationMode:"isolated"`
/// references it deliberately so that building against an older library
/// fails at compile time instead of silently degrading to delegate mode.
public enum EmbedIsolatedNavigation {
    /// The container creates and owns the navigator (codegen default).
    case automatic
    /// The host supplies a navigator (e.g. to drive the stack from outside).
    case custom(EmbedNavigator)
}

public struct EmbedContainer<Content: View>: View {
    public let embedId: String
    public let screen: String
    public let params: [String: Any]
    public let navigationMode: EmbedNavigationMode
    public let eventBridge: ((EmbeddedEvent) -> Void)?
    public let content: () -> Content

    private let isolatedNavigation: EmbedIsolatedNavigation?
    private let destinationResolver: ((EmbedDestination) -> AnyView)?
    @StateObject private var autoNavigator = EmbedNavigator()

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
        self.isolatedNavigation = nil
        self.destinationResolver = nil
    }

    /// Isolated-mode initializer (SwiftJsonUI >= 10.5.0). `destinationResolver`
    /// maps screen-name pushes (`EmbedDestination`) to views; when nil, DEBUG
    /// builds fall back to DynamicView and release builds render an explicit
    /// error box (never a silent no-op).
    public init(
        embedId: String,
        screen: String,
        params: [String: Any] = [:],
        navigationMode: EmbedNavigationMode,
        isolatedNavigation: EmbedIsolatedNavigation,
        destinationResolver: ((EmbedDestination) -> AnyView)? = nil,
        eventBridge: ((EmbeddedEvent) -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.embedId = embedId
        self.screen = screen
        self.params = params
        self.navigationMode = navigationMode
        self.eventBridge = eventBridge
        self.content = content
        self.isolatedNavigation = isolatedNavigation
        self.destinationResolver = destinationResolver
    }

    private var activeNavigator: EmbedNavigator? {
        guard navigationMode == .isolated else { return nil }
        switch isolatedNavigation {
        case .custom(let navigator): return navigator
        case .automatic: return autoNavigator
        case nil: return nil
        }
    }

    public var body: some View {
        // The `id(embedId)` modifier ensures that distinct embeds in the
        // same parent body position get distinct view identities — which is
        // what gives each one its own @StateObject lifecycle when the same
        // screen is embedded multiple times.
        if let navigator = activeNavigator {
            IsolatedEmbedBody(
                navigator: navigator,
                destinationResolver: destinationResolver,
                context: makeContext(navigator: navigator),
                embedId: embedId,
                content: content
            )
        } else {
            content()
                .id(embedId)
                .environment(\.embeddedScreenContext, makeContext(navigator: nil))
        }
    }

    private func makeContext(navigator: EmbedNavigator?) -> EmbeddedScreenContext {
        EmbeddedScreenContext(
            embedId: embedId,
            screen: screen,
            params: params,
            navigationDelegate: EmbeddedNavigationDelegate(boundedAtEmbed: navigationMode == .delegate),
            eventBridge: eventBridge,
            navigator: navigator
        )
    }
}

/// Body of an isolated embed: a private NavigationStack whose path is owned
/// by the navigator. Kept as a separate view so the @ObservedObject
/// invalidates only this subtree on push/pop.
private struct IsolatedEmbedBody<Content: View>: View {
    @ObservedObject var navigator: EmbedNavigator
    let destinationResolver: ((EmbedDestination) -> AnyView)?
    let context: EmbeddedScreenContext
    let embedId: String
    let content: () -> Content

    var body: some View {
        NavigationStack(path: $navigator.path) {
            content()
                .navigationDestination(for: EmbedDestination.self) { destination in
                    resolve(destination)
                        .environment(\.embeddedScreenContext, context)
                }
        }
        .id(embedId)
        .environment(\.embeddedScreenContext, context)
        .onAppear {
            EmbedNavigatorRegistry.shared.register(navigator, for: embedId)
        }
        .onDisappear {
            EmbedNavigatorRegistry.shared.unregister(embedId, ifCurrent: navigator)
        }
    }

    @ViewBuilder
    private func resolve(_ destination: EmbedDestination) -> some View {
        if let resolver = destinationResolver {
            resolver(destination)
        } else {
            #if DEBUG
            DynamicView(
                jsonName: destination.screen,
                viewId: "\(destination.screen)_embed_\(embedId)_pushed",
                data: destination.params
            )
            #else
            Text("Embed: no destinationResolver for pushed screen '\(destination.screen)'")
                .foregroundColor(.white)
                .padding(8)
                .background(Color.red)
            #endif
        }
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
    /// Private stack of an isolated embed; nil in delegate mode (and when
    /// the screen is shown standalone). Embedded VMs route push/pop here
    /// when present instead of the parent's navigation.
    public let navigator: EmbedNavigator?
    private let eventBridge: ((EmbeddedEvent) -> Void)?

    public init(
        embedId: String,
        screen: String,
        params: [String: Any],
        navigationDelegate: EmbeddedNavigationDelegate,
        eventBridge: ((EmbeddedEvent) -> Void)?,
        navigator: EmbedNavigator? = nil
    ) {
        self.embedId = embedId
        self.screen = screen
        self.params = params
        self.navigationDelegate = navigationDelegate
        self.eventBridge = eventBridge
        self.navigator = navigator
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
    /// False in isolated mode — pop drives the embed's private stack
    /// (`EmbeddedScreenContext.navigator`), which itself bounds at its root.
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

    /// Type-erased overload for generated wiring: codegen emits this
    /// unconditionally for every embedded screen's view, without knowing
    /// whether the VM conforms to `EmbeddedInitParamsReceiver`. The cast is
    /// dynamic — a non-conforming view model makes this a no-op.
    ///
    /// The consecutive same-params guard (`EmbedInitParamsApplyGuard`) lets
    /// this generated wiring coexist with legacy manual
    /// `.receiveEmbedInitParams(to:)` calls during migration: the second
    /// apply of identical params to the same VM instance is suppressed.
    @ViewBuilder
    func receiveEmbedInitParams(to viewModel: Any) -> some View {
        if let receiver = viewModel as? EmbeddedInitParamsReceiver {
            modifier(EmbedInitParamsModifier(viewModel: receiver))
        } else {
            self
        }
    }
}

// MARK: - Double-drive guard

/// Suppresses a consecutive apply of the SAME params to the same VM
/// instance. Needed while generated wiring (unconditional emit, 15-4) and
/// legacy manual `.receiveEmbedInitParams(to:)` calls coexist on one view —
/// both fire on appear, but `applyInitParams` must run once per distinct
/// params snapshot. The last-applied fingerprint is stored on the VM
/// instance itself (associated object) so instance identity — not a
/// reusable memory address — scopes the guard.
enum EmbedInitParamsApplyGuard {
    private static var fingerprintKey: UInt8 = 0

    /// Stable fingerprint of a params snapshot (sorted keys + value
    /// descriptions; nested dicts stringify via their description, so
    /// nested leaf changes still flip the fingerprint).
    static func fingerprint(_ params: [String: Any]) -> String {
        return params.keys.sorted().map { "\($0)=\(params[$0] ?? "nil")" }.joined(separator: "|")
    }

    /// Returns true when the apply should proceed (params differ from the
    /// previous apply on this VM instance), recording the new fingerprint.
    static func shouldApply(_ params: [String: Any], to receiver: EmbeddedInitParamsReceiver) -> Bool {
        let next = fingerprint(params)
        let last = objc_getAssociatedObject(receiver, &fingerprintKey) as? String
        if last == next { return false }
        objc_setAssociatedObject(receiver, &fingerprintKey, next, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return true
    }
}

private struct EmbedInitParamsModifier: ViewModifier {
    @Environment(\.embeddedScreenContext) private var context
    let viewModel: any EmbeddedInitParamsReceiver

    func body(content: Content) -> some View {
        content
            .onAppear {
                if let params = context?.params, !params.isEmpty {
                    apply(params)
                }
            }
            .onChange(of: paramsFingerprint) { _, _ in
                if let params = context?.params {
                    apply(params)
                }
            }
    }

    private func apply(_ params: [String: Any]) {
        guard EmbedInitParamsApplyGuard.shouldApply(params, to: viewModel) else { return }
        viewModel.applyInitParams(params)
    }

    /// `[String: Any]` is not Equatable. We synthesize a fingerprint from
    /// the description so `.onChange` fires when the dict content shifts.
    private var paramsFingerprint: String {
        guard let params = context?.params else { return "" }
        return EmbedInitParamsApplyGuard.fingerprint(params)
    }
}
