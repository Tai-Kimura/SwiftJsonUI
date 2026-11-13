//
//  CollectionReorder.swift
//  SwiftJsonUI
//
//  A Collection whose rows the user reorders by a long press and a drag (ticket jui-collection-drag-to-reorder,
//  plan B). Generated code and Dynamic call the same two pieces and never test the OS version themselves (the glass
//  ruling, 2026-09-14):
//
//    CollectionStackView(..., reorder: CollectionReorder(...)) {      // the stack; carries iOS 27's container
//        CollectionReorderRows(section: 0, ids: ids, locked: locked, reorder: reorder) { index in cell(index) }
//    }
//    List { CollectionReorderRows(..., style: .list) { index in cell(index) } }
//
//  The path, decided here and only here:
//    - a List                                  -> ForEach.onMove (every iOS), locked rows moveDisabled
//    - a stack, iOS 27 or later, no handle     -> ForEach.reorderable + the stack's reorderContainer
//    - a stack below iOS 27, or with a handle  -> the library's own drag (iOS 27's container cannot be held to a
//                                                 handle: measured, a row is picked up anywhere)
//  Every path reports the same thing: onReorder(section, from, to), `to` the index after the move, only for a real
//  move inside one section and never across a locked row. The VM reorders its data; a move it does not apply snaps
//  back. Each row also carries the "move up" / "move down" accessibility actions the rule allows.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Declaration

/// What a reorderable Collection declares: whether reordering is on now (`reorderable`, a binding may switch it),
/// whether rows are grabbed by a handle (`reorderHandle`), and where a move is reported (`onReorder`).
public struct CollectionReorder {
    public let isEnabled: Bool
    public let usesHandle: Bool
    public let onReorder: (_ section: Int, _ from: Int, _ to: Int) -> Void

    public init(isEnabled: Bool, usesHandle: Bool = false, onReorder: @escaping (_ section: Int, _ from: Int, _ to: Int) -> Void) {
        self.isEnabled = isEnabled
        self.usesHandle = usesHandle
        self.onReorder = onReorder
    }

    /// Whether this stack uses SwiftUI's own reorder container (iOS 27, no handle) rather than the library's drag.
    var usesSystemContainer: Bool {
        guard !usesHandle else { return false }
        if #available(iOS 27.0, *) { return true }
        return false
    }

    /// Report a move, as every path does: within one section, short of a locked row, and only a real one.
    func report(section: Int, from: Int, to: Int, locked: Set<Int>) {
        guard isEnabled,
              let to = CollectionReorderRule.clampedTo(from: from, to: to, locked: locked),
              CollectionReorderRule.shouldReport(from: from, to: to) else { return }
        onReorder(section, from, to)
    }
}

/// One row as iOS 27's reorder container sees it: the section and the row's own id (its cellId), never its index,
/// so a row keeps its identity while the rows move.
public struct CollectionReorderItem: Identifiable, Hashable, Sendable, Transferable {
    public let id: String
    public let section: Int
    public let key: String

    public init(section: Int, key: String) {
        self.section = section
        self.key = key
        self.id = "\(section)\u{1F}\(key)"
    }

    public static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.id)
    }
}

// MARK: - The registry the container reads

/// The current order of every section's rows, written by the rows and read by iOS 27's container to turn a
/// ReorderDifference (ids) into indexes. Not observed: nothing redraws when it changes.
@MainActor
final class CollectionReorderRegistry {
    var order: [Int: [String]] = [:]
    var locked: [Int: Set<Int>] = [:]
    /// The container's frame in window coordinates: a release outside it cancels (the library's drag).
    var containerFrame: CGRect?

    func index(of id: String, in section: Int) -> Int? {
        order[section]?.firstIndex(of: id)
    }
}

private struct CollectionReorderRegistryKey: EnvironmentKey {
    static let defaultValue: CollectionReorderRegistry? = nil
}

extension EnvironmentValues {
    var collectionReorderRegistry: CollectionReorderRegistry? {
        get { self[CollectionReorderRegistryKey.self] }
        set { self[CollectionReorderRegistryKey.self] = newValue }
    }
}

// MARK: - The stack's container

public extension View {
    /// Put on the stack that holds a reorderable Collection's rows (CollectionStackView does it for its own stack;
    /// a `lazy: "none"` Collection's VStack carries it directly). It is iOS 27's reorder container when this
    /// collection uses it, and for every path the registry the rows write their order to. Nil: nothing.
    func collectionReorderContainer(_ reorder: CollectionReorder?) -> some View {
        modifier(CollectionReorderContainerModifier(reorder: reorder))
    }
}

private struct CollectionReorderContainerModifier: ViewModifier {
    let reorder: CollectionReorder?
    @State private var registry = CollectionReorderRegistry()

    func body(content: Content) -> some View {
        if let reorder, reorder.usesSystemContainer, #available(iOS 27.0, *) {
            content
                .reorderContainer(for: CollectionReorderItem.self, in: Int.self, isEnabled: reorder.isEnabled) { difference in
                    Self.apply(difference, reorder: reorder, registry: registry)
                }
                .dragContainer(for: CollectionReorderItem.self) { id in
                    Self.draggable(id, registry: registry)
                }
                .environment(\.collectionReorderRegistry, registry)
        } else if reorder != nil {
            content
                .background(GeometryReader { proxy in
                    Color.clear
                        .onAppear { registry.containerFrame = proxy.frame(in: .global) }
                        .onChange(of: proxy.frame(in: .global)) { _, frame in registry.containerFrame = frame }
                })
                .environment(\.collectionReorderRegistry, registry)
        } else {
            content
        }
    }

    @available(iOS 27.0, *)
    @MainActor
    private static func apply(_ difference: ReorderDifference<String, Int>, reorder: CollectionReorder,
                              registry: CollectionReorderRegistry) {
        // One row at a time, inside its own section (v1: a move across sections is not reported).
        guard difference.sources.count == 1, let source = difference.sources.first,
              let section = registry.order.first(where: { $0.value.contains(source) })?.key,
              section == difference.destination.collectionID,
              let from = registry.index(of: source, in: section),
              let count = registry.order[section]?.count else { return }
        let before: Int?
        switch difference.destination.position {
        case .before(let id):
            guard let i = registry.index(of: id, in: section) else { return }
            before = i
        case .end:
            before = nil
        }
        let to = CollectionReorderRule.toIndex(from: from, beforeIndex: before, count: count)
        reorder.report(section: section, from: from, to: to, locked: registry.locked[section] ?? [])
    }

    @MainActor
    private static func draggable(_ id: String, registry: CollectionReorderRegistry) -> [CollectionReorderItem] {
        for (section, ids) in registry.order {
            guard let index = ids.firstIndex(of: id) else { continue }
            if registry.locked[section]?.contains(index) == true { return [] }
            let key = String(id.split(separator: "\u{1F}", maxSplits: 1).last ?? "")
            return [CollectionReorderItem(section: section, key: key)]
        }
        return []
    }
}

// MARK: - The rows

public enum CollectionReorderStyle {
    case stack
    case list
}

/// One section's rows. `ids` are the rows' own ids (cellIdProperty) in the order drawn; `locked` the indexes that do
/// not move (reorderLockedProperty). Without a `reorder` (or with it off) the rows are a plain ForEach.
public struct CollectionReorderRows<Content: View>: View {
    let section: Int
    let ids: [String]
    let locked: Set<Int>
    let reorder: CollectionReorder?
    let style: CollectionReorderStyle
    let content: (Int) -> Content

    @Environment(\.collectionReorderRegistry) private var registry
    @StateObject private var drag = CollectionReorderDrag()

    public init(section: Int, ids: [String], locked: Set<Int> = [], reorder: CollectionReorder?,
                style: CollectionReorderStyle = .stack, @ViewBuilder content: @escaping (Int) -> Content) {
        self.section = section
        self.ids = ids
        self.locked = locked
        self.reorder = reorder
        self.style = style
        self.content = content
    }

    private var items: [CollectionReorderItem] {
        ids.map { CollectionReorderItem(section: section, key: $0) }
    }

    public var body: some View {
        if let reorder, reorder.isEnabled {
            switch style {
            case .list: listRows(reorder)
            case .stack: stackRows(reorder)
            }
        } else {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, _ in content(index) }
        }
    }

    // List: onMove on every iOS.
    @ViewBuilder
    private func listRows(_ reorder: CollectionReorder) -> some View {
        ForEach(Array(items.enumerated()), id: \.element.id) { index, _ in
            content(index)
                .moveDisabled(locked.contains(index))
                .collectionReorderAccessibility(section: section, index: index, count: ids.count, locked: locked, reorder: reorder)
        }
        .onMove { source, destination in
            guard source.count == 1, let from = source.first else { return }
            let to = CollectionReorderRule.toIndex(fromOnMove: from, destination: destination)
            reorder.report(section: section, from: from, to: to, locked: locked)
        }
    }

    // A stack: iOS 27's reorderable, or the library's drag.
    @ViewBuilder
    private func stackRows(_ reorder: CollectionReorder) -> some View {
        let _ = register()
        if reorder.usesSystemContainer, #available(iOS 27.0, *) {
            ForEach(items) { item in
                let index = ids.firstIndex(of: item.key) ?? 0
                content(index)
                    .collectionReorderAccessibility(section: section, index: index, count: ids.count, locked: locked, reorder: reorder)
            }
            .reorderable(collectionID: section)
        } else {
            let _ = drag.configure(section: section, count: ids.count, locked: locked, reorder: reorder, registry: registry)
            ForEach(Array(items.enumerated()), id: \.element.id) { index, _ in
                content(index)
                    .modifier(CollectionReorderDraggedRow(drag: drag, index: index))
                    .collectionReorderAccessibility(section: section, index: index, count: ids.count, locked: locked, reorder: reorder)
            }
        }
    }

    private func register() {
        guard let registry else { return }
        let order = items.map(\.id)
        let lockedNow = locked
        let section = section
        MainActor.assumeIsolated {
            registry.order[section] = order
            registry.locked[section] = lockedNow
        }
    }
}

// MARK: - Accessibility

private extension View {
    /// "Move up" / "Move down" on a row, as the rule allows them (not past an edge, a locked row, or for a locked row).
    func collectionReorderAccessibility(section: Int, index: Int, count: Int, locked: Set<Int>,
                                        reorder: CollectionReorder) -> some View {
        let moves = CollectionReorderRule.accessibilityMoves(index: index, count: count, locked: locked)
        return self
            .accessibilityAction(named: Text(CollectionReorderText.moveUp)) {
                if moves.up { reorder.report(section: section, from: index, to: index - 1, locked: locked) }
            }
            .accessibilityAction(named: Text(CollectionReorderText.moveDown)) {
                if moves.down { reorder.report(section: section, from: index, to: index + 1, locked: locked) }
            }
    }
}

/// The library's words for the two actions, in the app's language (ja, else en).
enum CollectionReorderText {
    static var isJapanese: Bool {
        (Bundle.main.preferredLocalizations.first ?? Locale.current.identifier).hasPrefix("ja")
    }
    static var moveUp: String { isJapanese ? "上へ移動" : "Move up" }
    static var moveDown: String { isJapanese ? "下へ移動" : "Move down" }
}

// MARK: - The library's drag

/// The drag in one section: which row, how far (content coordinates — the auto-scroll included), and the rows' and
/// handles' frames it reads. Frames are window coordinates, recorded by the rows as they lay out.
@MainActor
final class CollectionReorderDrag: ObservableObject {
    @Published var dragging: Int?
    @Published var dy: CGFloat = 0
    var spans: [CollectionReorderRule.RowSpan] = []
    var frames: [Int: CGRect] = [:]
    var handleFrames: [Int: CGRect] = [:]
    var startY: CGFloat = 0
    var scrolled: CGFloat = 0
    var fingerY: CGFloat = 0
    weak var scrollView: UIScrollView?
    private var link: CADisplayLink?
    private var lastTick: CFTimeInterval = 0
    private var translation: CGFloat = 0

    /// What the recognizer asks before it begins: the row (index) under the point, if it may be picked up there.
    var pickable: (CGPoint) -> Int? = { _ in nil }
    var commit: (_ from: Int, _ to: Int, _ released: CGFloat) -> Void = { _, _, _ in }

    func begin(index: Int, at y: CGFloat, count: Int) {
        spans = (0..<count).map { i in
            let f = frames[i] ?? .zero
            return CollectionReorderRule.RowSpan(top: f.minY, bottom: f.maxY)
        }
        startY = y
        fingerY = y
        translation = 0
        scrolled = 0
        dy = 0
        dragging = index
        // The scroll view's own pan must not move the content under the finger (nor cancel the press) while a row
        // is carried; the auto-scroll moves it instead. Back on at the end.
        scrollView?.panGestureRecognizer.isEnabled = false
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        startAutoScroll()
    }

    func move(to y: CGFloat) {
        fingerY = y
        translation = y - startY
        dy = translation + scrolled
    }

    func end(cancelled: Bool) {
        stopAutoScroll()
        scrollView?.panGestureRecognizer.isEnabled = true
        let from = dragging
        let released = fingerY
        let to = target(locked: lockedNow)   // before the drag is cleared: target() reads it
        dragging = nil
        dy = 0
        guard !cancelled, let from else { return }
        commit(from, to, released)
    }

    var lockedNow: Set<Int> = []
    var count = 0
    lazy var recognizer = CollectionReorderRecognizer(drag: self)

    func target(locked: Set<Int>) -> Int {
        guard let from = dragging else { return 0 }
        return CollectionReorderRule.target(from: from, dy: dy, rows: spans, locked: locked)
    }

    private func startAutoScroll() {
        stopAutoScroll()
        let link = CADisplayLink(target: CollectionReorderDisplayLinkTarget(self),
                                 selector: #selector(CollectionReorderDisplayLinkTarget.tick(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
        lastTick = CACurrentMediaTime()
    }

    private func stopAutoScroll() {
        link?.invalidate()
        link = nil
    }

    /// The auto-scroll: the finger in the scroll view's edge band moves its content, and the drag with it.
    func tick() {
        let now = CACurrentMediaTime()
        let dt = now - lastTick
        lastTick = now
        guard let scrollView, let window = scrollView.window else { return }
        let visible = scrollView.convert(scrollView.bounds, to: window)
        let velocity = CollectionReorderRule.autoScrollVelocity(
            fingerY: fingerY, viewportTop: visible.minY, viewportBottom: visible.maxY)
        guard velocity != 0 else { return }
        let inset = scrollView.adjustedContentInset
        let minY = -inset.top
        let maxY = max(minY, scrollView.contentSize.height + inset.bottom - scrollView.bounds.height)
        let old = scrollView.contentOffset.y
        let new = min(maxY, max(minY, old + velocity * CGFloat(dt)))
        guard new != old else { return }
        scrollView.contentOffset.y = new
        scrolled += new - old
        dy = translation + scrolled
    }
}

/// CADisplayLink holds its target strongly; this breaks the cycle.
private final class CollectionReorderDisplayLinkTarget: NSObject {
    weak var drag: CollectionReorderDrag?
    init(_ drag: CollectionReorderDrag) { self.drag = drag }
    @objc func tick(_ link: CADisplayLink) {
        MainActor.assumeIsolated {
            guard let drag else { link.invalidate(); return }
            drag.tick()
        }
    }
}

/// The handle a cell declares (reorderHandle): the element the drag starts from. Generated cell code and Dynamic put
/// `.collectionReorderHandle()` on it; outside a reorderable row it does nothing.
public extension View {
    func collectionReorderHandle() -> some View {
        modifier(CollectionReorderHandleModifier())
    }
}

private struct CollectionReorderHandleKey: EnvironmentKey {
    static let defaultValue: ((CGRect) -> Void)? = nil
}

extension EnvironmentValues {
    /// Where a row's handle reports its frame.
    var collectionReorderHandleFrame: ((CGRect) -> Void)? {
        get { self[CollectionReorderHandleKey.self] }
        set { self[CollectionReorderHandleKey.self] = newValue }
    }
}

private struct CollectionReorderHandleModifier: ViewModifier {
    @Environment(\.collectionReorderHandleFrame) private var report
    func body(content: Content) -> some View {
        if let report {
            content.background(GeometryReader { proxy in
                Color.clear
                    .onAppear { report(proxy.frame(in: .global)) }
                    .onChange(of: proxy.frame(in: .global)) { _, frame in report(frame) }
            })
        } else {
            content
        }
    }
}

/// One row of the library's drag: its frame (and its handle's) for the recognizer and the rule, and its place while
/// a row is dragged — the dragged row follows the finger, the rows it passes step aside.
private struct CollectionReorderDraggedRow: ViewModifier {
    @ObservedObject var drag: CollectionReorderDrag
    let index: Int

    private var shift: CGFloat {
        guard let from = drag.dragging, from != index, drag.spans.indices.contains(from) else { return 0 }
        let to = drag.target(locked: drag.lockedNow)
        let span = drag.spans[from]
        let gap: CGFloat = {
            if from + 1 < drag.spans.count { return drag.spans[from + 1].top - span.bottom }
            if from > 0 { return span.top - drag.spans[from - 1].bottom }
            return 0
        }()
        let step = span.bottom - span.top + gap
        if from < to, index > from, index <= to { return -step }
        if to < from, index >= to, index < from { return step }
        return 0
    }

    func body(content: Content) -> some View {
        let isDragged = drag.dragging == index
        content
            .environment(\.collectionReorderHandleFrame) { frame in drag.handleFrames[index] = frame }
            .background(GeometryReader { proxy in
                Color.clear
                    .onAppear { drag.frames[index] = proxy.frame(in: .global) }
                    .onChange(of: proxy.frame(in: .global)) { _, frame in
                        if drag.dragging == nil { drag.frames[index] = frame }
                    }
            })
            .background(CollectionReorderTouchHost(recognizer: drag.recognizer).frame(width: 0, height: 0))
            .offset(y: isDragged ? drag.dy : shift)
            .zIndex(isDragged ? 1 : 0)
            .scaleEffect(isDragged ? 1.02 : 1)
            .shadow(color: .black.opacity(isDragged ? 0.2 : 0), radius: isDragged ? 8 : 0, y: isDragged ? 4 : 0)
            .animation(.easeInOut(duration: 0.15), value: shift)
    }
}

/// The section's one long-press recognizer, added to the UIScrollView the rows scroll in (or the window when they do
/// not scroll) and owned by the section's drag, so a lazy stack that lets a row go keeps it. A recognizer on the scroll
/// view, not a SwiftUI gesture on each row: on iOS 18.6 a long-press-then-drag gesture on the rows kept the ScrollView
/// from scrolling under a finger that started on a row (measured). UIKit arbitrates the two: a pan that moves before
/// the half second scrolls, a press held still picks the row up.
final class CollectionReorderRecognizer: NSObject, UIGestureRecognizerDelegate {
    weak var drag: CollectionReorderDrag?
    private var recognizer: UILongPressGestureRecognizer?
    private weak var attachedTo: UIView?

    init(drag: CollectionReorderDrag) { self.drag = drag }

    /// Attach to the scroll view (or window) a row sits in; again to the same view does nothing.
    func attach(from row: UIView) {
        guard let window = row.window else { return }
        var view = row.superview
        var scroll: UIScrollView?
        while let current = view {
            if let s = current as? UIScrollView { scroll = s; break }
            view = current.superview
        }
        let target: UIView = scroll ?? window
        MainActor.assumeIsolated { drag?.scrollView = scroll }
        guard attachedTo !== target else { return }
        if let recognizer { attachedTo?.removeGestureRecognizer(recognizer) }
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(handle(_:)))
        recognizer.minimumPressDuration = 0.5
        recognizer.allowableMovement = 10
        recognizer.delegate = self
        target.addGestureRecognizer(recognizer)
        self.recognizer = recognizer
        attachedTo = target
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let drag else {
            // The section is gone: take the recognizer off its view.
            gestureRecognizer.view?.removeGestureRecognizer(gestureRecognizer)
            return false
        }
        guard let window = gestureRecognizer.view?.window else { return false }
        let point = gestureRecognizer.location(in: window)
        return MainActor.assumeIsolated { drag.pickable(point) != nil }
    }

    @objc private func handle(_ recognizer: UILongPressGestureRecognizer) {
        guard let window = recognizer.view?.window else { return }
        let point = recognizer.location(in: window)
        MainActor.assumeIsolated {
            guard let drag else { return }
            switch recognizer.state {
            case .began:
                if let index = drag.pickable(point) { drag.begin(index: index, at: point.y, count: drag.count) }
            case .changed:
                drag.move(to: point.y)
            case .ended:
                drag.move(to: point.y)
                drag.end(cancelled: false)
            default:
                drag.end(cancelled: true)
            }
        }
    }
}

/// A zero-size view each row carries so the section's recognizer finds the scroll view the rows are in.
private struct CollectionReorderTouchHost: UIViewRepresentable {
    let recognizer: CollectionReorderRecognizer

    func makeUIView(context: Context) -> HostView {
        let view = HostView()
        view.isUserInteractionEnabled = false
        view.recognizer = recognizer
        return view
    }

    func updateUIView(_ uiView: HostView, context: Context) {
        uiView.recognizer = recognizer
    }

    final class HostView: UIView {
        var recognizer: CollectionReorderRecognizer?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            recognizer?.attach(from: self)
        }
    }
}

extension CollectionReorderDrag {
    /// The pick-up test (a row, its handle when the Collection declares one, never a locked row) and the release
    /// (inside the container, else cancelled) for the rows as they are drawn now.
    func configure(section: Int, count: Int, locked: Set<Int>, reorder: CollectionReorder,
                   registry: CollectionReorderRegistry?) {
        self.count = count
        lockedNow = locked
        pickable = { [weak self] point in
            guard let self, reorder.isEnabled, self.dragging == nil else { return nil }
            for i in 0..<count where !locked.contains(i) {
                let area = reorder.usesHandle ? self.handleFrames[i] : self.frames[i]
                if let area, area.contains(point) { return i }
            }
            return nil
        }
        commit = { [weak self] from, to, released in
            guard let self else { return }
            let spans = self.spans
            let container = registry?.containerFrame
                ?? CGRect(x: 0, y: spans.first?.top ?? 0, width: 1,
                          height: (spans.last?.bottom ?? 0) - (spans.first?.top ?? 0))
            guard CollectionReorderRule.releaseCommits(fingerY: released, containerTop: container.minY,
                                                       containerBottom: container.maxY) else { return }
            reorder.report(section: section, from: from, to: to, locked: locked)
        }
    }
}
