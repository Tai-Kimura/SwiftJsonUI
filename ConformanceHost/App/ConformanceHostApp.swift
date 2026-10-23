//
//  ConformanceHostApp.swift
//  ConformanceHost
//
//  Renders a single conformance fixture layout through the SwiftJsonUI
//  SwiftUI dynamic component system (Dynamic mode, DEBUG only).
//
//  Fixture selection (checked in this order):
//    1. Launch argument  -fixtureId <id>          — single fixture
//    2. Launch env       CONFORMANCE_FIXTURE_IDS  — comma-separated batch;
//       the UITest runner advances through the batch by posting the Darwin
//       notification "jsonui.conformance.advance" (relaunch-free batching).
//
//  Fixture ids look like "Label/text__static" and map to the bundled
//  resource "fixtures/<id>.layout.json" (synced by scripts/sync_fixtures.sh).
//
//  Test hooks exposed to XCUITest (all invisible, zero screenshot impact):
//    - accessibilityIdentifier "conformance_current_<id>" on the fixture
//      wrapper — signals which fixture is currently displayed
//    - accessibilityIdentifier "conformance_load_error" — layout failed to
//      load or decode
//    - accessibilityIdentifier "conformance_done" — batch exhausted
//

import SwiftUI
import SwiftJsonUI

/// Which rendering pipeline this host exercises for the current launch.
///
/// - `dynamic` (default): DynamicView interprets the fixture layout JSON at
///   runtime — the pipeline the conformance baselines were built on.
/// - `codegen`: the fixture is rendered by the **generated SwiftUI view**
///   (sjui build output, compiled in by scripts/generate_codegen_host.rb) —
///   the pipeline production apps actually ship. Selected with the launch
///   env `CONFORMANCE_HOST_MODE=codegen`; parity between the two pipelines
///   is judged by `jui conformance parity` against the dynamic baselines.
enum ConformanceHostMode {
    static let isCodegen: Bool =
        ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen"
}

/// `pending.invalid` never completes and never fails
/// (INTERACTIVE_HOST_CONTRACT.md §5): the request is held open forever so the
/// LOADING face becomes the resting state of the run instead of racing the
/// shutter. Every other `.invalid` name fails synchronously — RFC 2606 says
/// it can never resolve, and waiting on a real resolver's NXDOMAIN makes the
/// error face timing-dependent. Registered for the shared session in the App
/// init, matched before any catch-all (§5.2).
final class ConformanceInvalidHostProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        guard let host = request.url?.host else { return false }
        return host == "pending.invalid" || host.hasSuffix(".invalid")
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if request.url?.host == "pending.invalid" {
            // Hold forever: no callback, no failure. stopLoading() is the
            // only exit, and it arrives when the fixture is torn down.
            return
        }
        // Deliver the failure ASYNCHRONOUSLY: completing the client from
        // inside startLoading races the loading system's state machine and
        // the task can hang instead of failing — measured as the errorImage
        // fixture stuck on a blank loading face (NetworkImage/
        // errorImage__static ios inert, local-env after 0a03e6c; the
        // contract expects uniformly-active).
        let client = self.client
        DispatchQueue.global().async {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotFindHost))
        }
    }

    override func stopLoading() {}
}

@main
struct ConformanceHostApp: App {
    init() {
        URLProtocol.registerClass(ConformanceInvalidHostProtocol.self)
        // Test-only, and only when the run declares a delay (WebPaintDelaySpecimen).
        WebPaintDelaySpecimen.startIfDeclared()
        if ConformanceHostMode.isCodegen {
            // Generated views check ViewSwitcher.isDynamicMode inside their
            // body (DEBUG builds render DynamicView while it is true). Flip
            // it synchronously before the first render — setDynamicMode()
            // dispatches async and would let the first fixture slip through
            // the dynamic path.
            ViewSwitcher.shared.isDynamic = false
            // Resource providers the generated code resolves through (named
            // colors via SwiftJsonUIConfiguration.getColor — 31 F6: without
            // the registration every named color is nil, fills go black,
            // backgrounds vanish; 93 parity entries were that single miss).
            // Indirected through the registry because the generated
            // ColorManager only exists in codegen builds — the committed
            // default stub is a no-op so dynamic-only builds keep compiling.
            CodegenFixtureRegistry.activate()
        }
    }

    var body: some Scene {
        WindowGroup {
            ConformanceRootView()
        }
    }
}

/// Batch state driven by the "jsonui.conformance.advance" Darwin notification.
final class FixtureBatchModel: ObservableObject {
    static let advanceNotification = "jsonui.conformance.advance" as CFString
    /// INTERACTIVE_HOST_CONTRACT.md §6 job 4: rebuild the current fixture view
    /// and its stores, so a new instance of the same screen appears in the
    /// same launch.
    static let remountNotification = "jsonui.conformance.remount" as CFString

    let fixtureIds: [String]
    @Published var currentIndex: Int = 0
    @Published var remountCount: Int = 0

    var currentFixtureId: String? {
        guard currentIndex < fixtureIds.count else { return nil }
        return fixtureIds[currentIndex]
    }

    init() {
        var ids: [String] = []
        let arguments = ProcessInfo.processInfo.arguments
        if let flagIndex = arguments.firstIndex(of: "-fixtureId"), flagIndex + 1 < arguments.count {
            ids = [arguments[flagIndex + 1]]
        } else if let batch = ProcessInfo.processInfo.environment["CONFORMANCE_FIXTURE_IDS"] {
            ids = batch.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        }
        self.fixtureIds = ids
        registerAdvanceObserver()
        registerRemountObserver()
    }

    private func registerRemountObserver() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observer, _, _, _ in
                guard let observer = observer else { return }
                let model = Unmanaged<FixtureBatchModel>.fromOpaque(observer).takeUnretainedValue()
                DispatchQueue.main.async {
                    model.remountCount += 1
                }
            },
            FixtureBatchModel.remountNotification,
            nil,
            .deliverImmediately
        )
    }

    private func registerAdvanceObserver() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observer, _, _, _ in
                guard let observer = observer else { return }
                let model = Unmanaged<FixtureBatchModel>.fromOpaque(observer).takeUnretainedValue()
                DispatchQueue.main.async {
                    model.currentIndex += 1
                }
            },
            FixtureBatchModel.advanceNotification,
            nil,
            .deliverImmediately
        )
    }
}

struct ConformanceRootView: View {
    @StateObject private var batch = FixtureBatchModel()

    /// The probe a launch argument asks for, or nil. DEBUG only: the probes
    /// render through Dynamic mode, which SwiftJsonUI compiles in DEBUG only,
    /// so a Release build of this host hosts the codegen face and nothing else
    /// (Release is how the testBridge gate-closed arm runs).
    private var probeView: AnyView? {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-hiddenToggleProbe") { return AnyView(HiddenToggleProbeView()) }
        if arguments.contains("-gestureProbe") { return AnyView(GestureProbeView()) }
        if arguments.contains("-screenMarkerProbe") { return AnyView(ScreenMarkerProbeView()) }
        if arguments.contains("-screenMarkerSplitProbe") { return AnyView(ScreenMarkerSplitProbeView()) }
        if arguments.contains("-screenMarkerFullScreenProbe") { return AnyView(ScreenMarkerFullScreenProbeView()) }
        if arguments.contains("-screenMarkerOverlayProbe") { return AnyView(ScreenMarkerOverlayProbeView()) }
        if arguments.contains("-screenMarkerShrinkProbe") { return AnyView(ScreenMarkerShrinkProbeView()) }
        if arguments.contains("-offsetProbe") { return AnyView(OffsetHitTargetProbeView()) }
        if arguments.contains("-confirmationDialogProbe") { return AnyView(ConfirmationDialogProbeView()) }
        if arguments.contains("-duplicateIdentifierProbe") { return AnyView(DuplicateIdentifierProbeView()) }
        if arguments.contains("-decorativeImageProbe") { return AnyView(DecorativeImageProbeView()) }
        if arguments.contains("-imageEventsProbe") { return AnyView(ImageEventsProbeView()) }
        if arguments.contains("-canTapGateProbe") { return AnyView(CanTapGateProbeView()) }
        if arguments.contains("-interactionGateProbe") { return AnyView(InteractionGateProbeView()) }
        if arguments.contains("-a11yActivationProbe") { return AnyView(A11yActivationProbeView()) }
        if arguments.contains("-interactionInputsProbe") { return AnyView(InteractionInputsProbeView()) }
        if arguments.contains("-canTapCodegenProbe") { return AnyView(CanTapCodegenProbeView()) }
        if let i = arguments.firstIndex(of: "-autoFocusProbe"), i + 1 < arguments.count {
            return AnyView(AutoFocusCodegenProbeView(variant: arguments[i + 1]))
        }
        if arguments.contains("-responsiveDisabledProbe") { return AnyView(ResponsiveDisabledProbeView()) }
        if arguments.contains("-sameTypeDuplicateProbe") { return AnyView(SameTypeDuplicateProbeView()) }
        if arguments.contains("-clippedViewportProbe") { return AnyView(ClippedViewportProbeView()) }
        if arguments.contains("-coveredTapProbe") { return AnyView(CoveredTapProbeView()) }
        if arguments.contains("-keyboardClearanceProbe") { return AnyView(KeyboardClearanceProbeView()) }
        if arguments.contains("-tapIdentifierOnce") { return AnyView(TapIdentifierOnceView()) }
        if arguments.contains("-leafChildren") { return AnyView(LeafChildrenProbeView()) }
        if arguments.contains("-customContainerId") { return AnyView(CustomContainerIdView()) }
        if arguments.contains("-compositeLeafId") { return AnyView(CompositeLeafIdView()) }
        if arguments.contains("-onClickProbe") { return AnyView(OnClickProbeView()) }
        if arguments.contains("-tabEnabledProbe") { return AnyView(TabEnabledProbeView()) }
        if arguments.contains("-stateNamesProbe") { return AnyView(StateNamesProbeView()) }
        if arguments.contains("-tapArityProbe") { return AnyView(TapArityProbeView()) }
        if arguments.contains("-pickArityProbe") { return AnyView(PickArityProbeView()) }
        if arguments.contains("-linkTapProbe") { return AnyView(LinkTapProbeView()) }
        if arguments.contains("-dynamicStateProbe") { return AnyView(DynamicStateProbeView()) }
        if arguments.contains("-pressedBackgroundProbe") { return AnyView(PressedBackgroundProbeView()) }
        if arguments.contains("-bindFoldProbe") { return AnyView(BindFoldProbeView()) }
        if arguments.contains("-pagingAddressProbe") { return AnyView(PagingAddressProbeView()) }
        if arguments.contains("-sectionScrollProbe") { return AnyView(SectionScrollProbeView()) }
        if arguments.contains("-scrollRuleProbe") { return AnyView(ScrollRuleProbeView(grid: false)) }
        if arguments.contains("-sectionGridProbe") { return AnyView(ScrollRuleProbeView(grid: true)) }
        if arguments.contains("-scrollNoKeyProbe") { return AnyView(ScrollRuleProbeView(grid: false, noKey: true)) }
        if arguments.contains("-scrollRouteProbe") { return AnyView(ScrollRouteProbeView(codegen: false)) }
        if arguments.contains("-scrollRouteProbeCodegen") { return AnyView(ScrollRouteProbeView(codegen: true)) }
        if arguments.contains("-scrollRouteProbe2") { return AnyView(ScrollRouteProbeView(codegen: false, second: true)) }
        if arguments.contains("-scrollRouteProbe2Codegen") { return AnyView(ScrollRouteProbeView(codegen: true, second: true)) }
        if arguments.contains("-scrollRouteProbe3") { return AnyView(ScrollRouteProbeView(codegen: false, third: true)) }
        if arguments.contains("-scrollRouteProbe3Codegen") { return AnyView(ScrollRouteProbeView(codegen: true, third: true)) }
        if arguments.contains("-scrollRouteProbe4") { return AnyView(ScrollRouteProbeView(codegen: false, fourth: true)) }
        if arguments.contains("-scrollRouteProbe4Codegen") { return AnyView(ScrollRouteProbeView(codegen: true, fourth: true)) }
        if arguments.contains("-scrollRouteProbe5") { return AnyView(ScrollRouteProbeView(codegen: false, fifth: true)) }
        if arguments.contains("-scrollRouteProbe5Codegen") { return AnyView(ScrollRouteProbeView(codegen: true, fifth: true)) }
        if arguments.contains("-scrollRouteProbe6") { return AnyView(ScrollRouteProbeView(codegen: false, sixth: true)) }
        if arguments.contains("-scrollRouteProbe6Codegen") { return AnyView(ScrollRouteProbeView(codegen: true, sixth: true)) }
        if arguments.contains("-scrollRouteProbe7") { return AnyView(ScrollRouteProbeView(codegen: false, seventh: true)) }
        if arguments.contains("-scrollRouteProbe7Codegen") { return AnyView(ScrollRouteProbeView(codegen: true, seventh: true)) }
        if arguments.contains("-leafGravityProbe") { return AnyView(LeafGravityProbeView(codegen: false)) }
        if arguments.contains("-leafGravityProbeCodegen") { return AnyView(LeafGravityProbeView(codegen: true)) }
        if arguments.contains("-eagerRowFillProbe") { return AnyView(EagerRowFillProbeView(codegen: false)) }
        if arguments.contains("-eagerRowFillProbeCodegen") { return AnyView(EagerRowFillProbeView(codegen: true)) }
        if arguments.contains("-emptyBackgroundProbe") { return AnyView(EmptyBackgroundProbeView(codegen: false)) }
        if arguments.contains("-emptyBackgroundProbeCodegen") { return AnyView(EmptyBackgroundProbeView(codegen: true)) }
        if arguments.contains("-disabledColoursProbeCodegen") { return AnyView(DisabledColoursProbeView()) }
        if arguments.contains("-offsetPlacementProbe") { return AnyView(OffsetProbeView(codegen: false)) }
        if arguments.contains("-offsetPlacementProbeCodegen") { return AnyView(OffsetProbeView(codegen: true)) }
        if arguments.contains("-anchorTapProbe") { return AnyView(AnchorTapProbeView(variant: UserDefaults.standard.string(forKey: "atVariant") ?? "dyn")) }
        if arguments.contains("-idBoxProbe") { return AnyView(IdBoxProbeView(codegen: false)) }
        if arguments.contains("-idBoxProbeCodegen") { return AnyView(IdBoxProbeView(codegen: true)) }
        if arguments.contains("-cellIdBoxProbe") { return AnyView(CellIdBoxProbeView(codegen: false)) }
        if arguments.contains("-cellIdBoxProbeCodegen") { return AnyView(CellIdBoxProbeView(codegen: true)) }
        if arguments.contains("-textViewInsetProbe") { return AnyView(TextViewInsetProbeView(codegen: false)) }
        if arguments.contains("-textViewInsetProbeCodegen") { return AnyView(TextViewInsetProbeView(codegen: true)) }
        if arguments.contains("-boundsAlignmentProbe") { return AnyView(BoundsAlignmentProbeView(codegen: false)) }
        if arguments.contains("-boundsAlignmentProbeCodegen") { return AnyView(BoundsAlignmentProbeView(codegen: true)) }
        if arguments.contains("-labelVerticalProbe") { return AnyView(LabelVerticalProbeView(codegen: false)) }
        if arguments.contains("-labelVerticalProbeCodegen") { return AnyView(LabelVerticalProbeView(codegen: true)) }
        if arguments.contains("-insetsRoutesProbe") { return AnyView(InsetsOrderProbeView(codegen: false, routes: true)) }
        if arguments.contains("-insetsRoutesProbeCodegen") { return AnyView(InsetsOrderProbeView(codegen: true, routes: true)) }
        if arguments.contains("-insetsOrderProbe") { return AnyView(InsetsOrderProbeView(codegen: false)) }
        if arguments.contains("-insetsOrderProbeCodegen") { return AnyView(InsetsOrderProbeView(codegen: true)) }
        if arguments.contains("-buttonTextAlignProbe") { return AnyView(ButtonTextAlignProbeView(codegen: false)) }
        if arguments.contains("-buttonTextAlignProbeCodegen") { return AnyView(ButtonTextAlignProbeView(codegen: true)) }
        if arguments.contains("-rowCrossFitProbe") { return AnyView(RowCrossFitProbeView(codegen: false)) }
        if arguments.contains("-rowCrossFitProbeCodegen") { return AnyView(RowCrossFitProbeView(codegen: true)) }
        if arguments.contains("-labelHorizontalProbe") { return AnyView(LabelHorizontalProbeView(codegen: false)) }
        if arguments.contains("-labelHorizontalProbeCodegen") { return AnyView(LabelHorizontalProbeView(codegen: true)) }
        if arguments.contains("-wrapMaxProbe") { return AnyView(WrapMaxProbeView(codegen: false)) }
        if arguments.contains("-wrapMaxProbeCodegen") { return AnyView(WrapMaxProbeView(codegen: true)) }
        if arguments.contains("-aspectFillHitProbe") { return AnyView(AspectFillHitProbeView(codegen: false)) }
        if arguments.contains("-aspectFillHitProbeCodegen") { return AnyView(AspectFillHitProbeView(codegen: true)) }
        if arguments.contains("-paddingsOrderProbe") { return AnyView(PaddingsOrderProbeView(codegen: false)) }
        if arguments.contains("-paddingsOrderProbeCodegen") { return AnyView(PaddingsOrderProbeView(codegen: true)) }
        if arguments.contains("-buttonPaddingProbe") { return AnyView(ButtonPaddingProbeView(codegen: false)) }
        if arguments.contains("-buttonPaddingProbeCodegen") { return AnyView(ButtonPaddingProbeView(codegen: true)) }
        if arguments.contains("-cellDataRefreshProbe") { return AnyView(CellDataRefreshProbeView(codegen: false)) }
        if arguments.contains("-cellDataRefreshProbeCodegen") { return AnyView(CellDataRefreshProbeView(codegen: true)) }
        if arguments.contains("-pagerIdentityProbe") { return AnyView(PagerIdentityProbeView(codegen: false)) }
        if arguments.contains("-pagerIdentityProbeCodegen") { return AnyView(PagerIdentityProbeView(codegen: true)) }
        if arguments.contains("-pagerHeightProbe") { return AnyView(PagerHeightProbeView(codegen: false)) }
        if arguments.contains("-pagerHeightProbeCodegen") { return AnyView(PagerHeightProbeView(codegen: true)) }
        if arguments.contains("-scrollHeightProbe") { return AnyView(ScrollHeightProbeView(codegen: false)) }
        if arguments.contains("-scrollHeightProbeCodegen") { return AnyView(ScrollHeightProbeView(codegen: true)) }
        if arguments.contains("-aspectFillProbe") { return AnyView(AspectFillProbeView(codegen: false)) }
        if arguments.contains("-aspectFillProbeCodegen") { return AnyView(AspectFillProbeView(codegen: true)) }
        if arguments.contains("-frameAlignmentProbe") { return AnyView(FrameAlignmentProbeView(codegen: false)) }
        if arguments.contains("-frameAlignmentProbeCodegen") { return AnyView(FrameAlignmentProbeView(codegen: true)) }
        if arguments.contains("-collectionFitProbe") { return AnyView(CollectionFitProbeView(codegen: false)) }
        if arguments.contains("-collectionFitProbeCodegen") { return AnyView(CollectionFitProbeView(codegen: true)) }
        if arguments.contains("-scrollRouteProbe8") { return AnyView(ScrollRouteProbeView(codegen: false, eighth: true)) }
        if arguments.contains("-scrollRouteProbe8Codegen") { return AnyView(ScrollRouteProbeView(codegen: true, eighth: true)) }
        #endif
        return nil
    }

    var body: some View {
        Group {
            if let probe = probeView {
                probe
            } else if batch.fixtureIds.isEmpty {
                Text("ConformanceHost: pass -fixtureId <id> or CONFORMANCE_FIXTURE_IDS")
                    .padding()
                    .accessibilityIdentifier("conformance_idle")
            } else if let fixtureId = batch.currentFixtureId {
                FixtureScreen(fixtureId: fixtureId)
                    // Force full teardown/rebuild between fixtures so no state leaks.
                    // A remount (testBridge) rebuilds the same fixture the same way.
                    .id("\(fixtureId)#\(batch.remountCount)")
            } else {
                Text("Conformance batch complete")
                    .padding()
                    .accessibilityIdentifier("conformance_done")
            }
        }
    }
}

/// Loads one fixture layout from the bundle and renders it via Dynamic mode.
struct FixtureScreen: View {
    /// The Dynamic face: a fixture rendered through DynamicView. DEBUG only —
    /// SwiftJsonUI compiles Dynamic mode in DEBUG only; a Release build hosts
    /// the codegen face and says so here if asked for the Dynamic one.
    @ViewBuilder
    private var dynamicFixture: some View {
        #if DEBUG
        if let component = FixtureLoader.loadComponent(fixtureId: fixtureId) {
            if let bridgeDecl = TestBridgeIndex.decl(for: fixtureId) {
                // INTERACTIVE_HOST_CONTRACT.md §6: the bridge, over a typed store.
                TestBridgeDynamicFixture(component: component, fixtureId: fixtureId,
                                         state: state, decl: bridgeDecl)
            } else {
                DynamicView(component: component, viewId: "conformance", data: state.externalData)
                    // afterFirstDraw (AfterFirstDraw.swift): the one change the
                    // manifest asks for after the first draw, through the store.
                    .conformanceAfterFirstDraw(
                        fixtureId,
                        declared: state.afterFirstDraw != nil,
                        applied: state.afterFirstDrawApplied,
                        fire: state.fireAfterFirstDraw
                    )
            }
        } else {
            Text("Failed to load fixture: \(fixtureId)")
                .foregroundColor(.red)
                .padding()
                .accessibilityIdentifier("conformance_load_error")
        }
        #else
        Text("Dynamic mode is DEBUG-only: run the codegen face in a Release build")
            .foregroundColor(.red)
            .padding()
            .accessibilityIdentifier("conformance_load_error")
        #endif
    }

    let fixtureId: String

    /// Generic interactive-fixture state (INTERACTIVE_HOST_CONTRACT.md):
    /// bindings + declared handler closures for `class: interactive`
    /// fixtures, empty for everything else. Identity is per-fixture via
    /// `.id(fixtureId)` on this view, so the store resets between fixtures.
    @StateObject private var state: ConformanceStateStore

    init(fixtureId: String) {
        self.fixtureId = fixtureId
        _state = StateObject(wrappedValue: ConformanceStateStore(fixtureId: fixtureId))
        // UISegmentedControl.appearance() is process-wide: a fixture that
        // declares segment colours restyles every later fixture's segments
        // (both render paths reach through .appearance(), see
        // segment_converter.rb), which made the Segment measurements
        // order-dependent — the normalColor screenshot carried a selected
        // pill tint leaked from a colour fixture rendered earlier in the
        // batch. Reset before each fixture so declared colours are the only
        // ones on screen.
        let appearance = UISegmentedControl.appearance()
        appearance.selectedSegmentTintColor = nil
        appearance.setTitleTextAttributes(nil, for: .normal)
        appearance.setTitleTextAttributes(nil, for: .selected)
        // UISwitch.appearance() leaks the same way: thumbTintColor set by a
        // Switch colour fixture restyled every later switch's knob.
        UISwitch.appearance().thumbTintColor = nil
        // UITabBar.appearance() too: tabBarBackground goes through the proxy
        // (TabViewConverter), so a background fixture painted every later
        // tab bar — showLabels measured against a leaked red bar (32 parity).
        UITabBar.appearance().backgroundColor = nil
        UITabBar.appearance().unselectedItemTintColor = nil
    }

    var body: some View {
        ZStack {
            if ConformanceHostMode.isCodegen {
                if let generated = CodegenFixtureRegistry.view(for: fixtureId) {
                    generated
                } else {
                    // Same marker the dynamic path uses for an unloadable
                    // fixture, so the UITest reports it as an error rather
                    // than timing out — a fixture the codegen registry does
                    // not carry (generation failed / deliberately skipped)
                    // must not look like a hang.
                    Text("No generated view for fixture: \(fixtureId)")
                        .foregroundColor(.red)
                        .padding()
                        .accessibilityIdentifier("conformance_load_error")
                }
            } else {
                dynamicFixture
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // The frames gate's measuring elements: every id hands its layout
        // box up, and a clear `frame:<id>` element is drawn at it here,
        // behind the fixture so the fixture's own elements stay hittable
        // (SwiftJsonUI jsonUIConformanceFrame / jsonUIConformanceFrames),
        // which the reader prefers to the id's own element.
        // `-noConformanceFrameProbe` launches without them, as an app runs
        // (ConformanceFrameProbeUITests).
        .jsonUIConformanceFrames()
        .environment(\.jsonuiConformanceFrameProbe,
                     !ProcessInfo.processInfo.arguments.contains("-noConformanceFrameProbe"))
        // Marker for the UITest runner: which fixture is on screen right now.
        // The marker is its own (invisible, 1x1) accessibility element — an
        // identifier on the wrapper itself would not surface as an element and
        // would be pushed down onto the fixture content, clobbering its ids.
        .overlay(alignment: .bottomTrailing) {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("conformance_current_\(FixtureLoader.markerSafe(fixtureId))")
        }
        // The canvas's top-left corner, the other end of the fixture's frame:
        // a matchParent root fills the canvas, so the two markers are the
        // root's frame. The element that carries the layout's `root` id
        // cannot say it — SwiftUI reports it as the box around its children
        // (ConformanceUITests.recordFrames). Invisible, 1x1, its own element.
        .overlay(alignment: .topLeading) {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("conformance_origin")
        }
        .overlay(alignment: .bottomLeading) {
            AfterFirstDrawMarker(fixtureId: fixtureId)
        }
    }
}

/// `conformance_after_first_draw`: the afterFirstDraw stamp for the UITest
/// (`fired=<ms> applied=<ms>`), present only once the current fixture has
/// fired. A 1x1 clear element, like the other markers: nothing it carries is
/// drawn. Its own view, so a stamp re-renders the marker and not the fixture.
struct AfterFirstDrawMarker: View {
    let fixtureId: String
    @ObservedObject private var stamp = AfterFirstDrawStamp.shared

    var body: some View {
        if stamp.fixtureId == fixtureId, !stamp.markerValue.isEmpty {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("conformance_after_first_draw")
                .accessibilityValue(stamp.markerValue)
        }
    }
}

enum FixtureLoader {
    /// "Label/text__static" -> marker-safe "Label_text__static"
    /// (XCUITest identifier matching is exact-string, slashes are fine, but a
    /// flat token keeps logs/queries unambiguous and matches artifact naming.)
    static func markerSafe(_ fixtureId: String) -> String {
        fixtureId.replacingOccurrences(of: "/", with: "_")
    }

    /// Locate the fixture's layout inside the app bundle (the fixtures
    /// directory is bundled as a folder reference, preserving subdirectories).
    /// The path comes from the manifest `layout` field — it is NOT always
    /// "fixtures/<id>.layout.json": the generator appends `_N` to filenames
    /// when two ids collide case-insensitively (onclick vs onClick).
    static func layoutURL(fixtureId: String) -> URL? {
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        let relativePath = ConformanceStateIndex.layoutPath(for: fixtureId)
            ?? "fixtures/\(fixtureId).layout.json"
        let direct = resourceURL.appendingPathComponent(relativePath)
        if FileManager.default.fileExists(atPath: direct.path) {
            return direct
        }
        // Fallback: flattened bundling (group reference)
        let basename = relativePath.split(separator: "/").map(String.init).last?
            .replacingOccurrences(of: ".layout.json", with: "") ?? fixtureId
        return Bundle.main.url(forResource: "\(basename).layout", withExtension: "json")
    }

    #if DEBUG
    static func loadComponent(fixtureId: String) -> DynamicComponent? {
        guard let url = layoutURL(fixtureId: fixtureId),
              let data = try? Data(contentsOf: url),
              let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        // Same pre-processing pipeline as JSONLayoutLoader.loadComponent
        // (styles applied; conformance fixtures contain no includes).
        let processed = StyleProcessor.processStyles(jsonObject)
        return JSONLayoutLoader.decodeComponent(from: processed)
    }
    #endif
}

#if DEBUG
/// A testBridge fixture on the Dynamic face (INTERACTIVE_HOST_CONTRACT.md §6):
/// DynamicView over the host's String vars plus the fixture's typed store,
/// with the library's bridge attached under this face's screen id.
struct TestBridgeDynamicFixture: View {
    let component: DynamicComponent
    let fixtureId: String
    @ObservedObject var state: ConformanceStateStore
    @StateObject private var store: TestBridgeFixtureStore

    init(component: DynamicComponent, fixtureId: String, state: ConformanceStateStore, decl: TestBridgeDecl) {
        self.component = component
        self.fixtureId = fixtureId
        self.state = state
        _store = StateObject(wrappedValue: TestBridgeFixtureStore(decl: decl))
    }

    var body: some View {
        // The host's declared String vars win a name collision, as in
        // ConformanceStateStore.externalData: an afterFirstDraw var is one.
        let data = store.externalData().merging(state.externalData) { _, declared in declared }
        DynamicView(component: component, viewId: "conformance", data: data)
            .conformanceAfterFirstDraw(
                fixtureId,
                declared: state.afterFirstDraw != nil,
                applied: state.afterFirstDrawApplied,
                fire: state.fireAfterFirstDraw
            )
            .jsonUITestBridge(
                TestBridgeDecl.screenId(for: fixtureId),
                snapshot: { store.snapshot(overriding: state.stringValues) },
                apply: { store.apply($0) }
            )
    }
}
#endif
