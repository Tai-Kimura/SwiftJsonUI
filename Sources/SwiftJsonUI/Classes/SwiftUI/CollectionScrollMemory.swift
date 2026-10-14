//
//  CollectionScrollMemory.swift
//  SwiftJsonUI
//
//  The scrollTo value each Collection of a screen was last seen with, by the
//  Collection's id (jsonui-cli Collection.scrollTo; kjui-collection-scrollto-
//  ignored-after-visibility-gone, 2026-10-14).
//
//  A scroll is a CHANGE of the value: the value a Collection is drawn with
//  scrolls nowhere (`.onChange(of:)` does not fire for it). visibility gone
//  removes a Collection (VisibilityWrapper draws EmptyView), so the one that
//  comes back is a new view, and a value written in the same update that
//  brought it back was its first value — the request never ran. The memory
//  lives above the gone boundary, at the screen: a Collection appearing with
//  a value other than the one it was last seen with on this screen is
//  appearing with a request, and runs it. A screen built afresh has an empty
//  memory, so the value it opens with still scrolls nowhere. A Collection
//  with no id is not remembered (nothing names it), and keeps the first-draw
//  rule.
//
//  Outside `#if DEBUG`: sjui's generated code uses it in every configuration.
//

import SwiftUI

public final class CollectionScrollMemory {
    private var seen: [String: AnyHashable?] = [:]

    public init() {}

    /// Whether `value` is a request for the Collection `id` appearing now.
    public func isRequestOnEntry(_ id: String?, _ value: AnyHashable?) -> Bool {
        guard let id, let last = seen[id] else { return false }
        return last != value
    }

    /// The value the Collection `id` is now drawn with.
    public func record(_ id: String?, _ value: AnyHashable?) {
        guard let id else { return }
        seen[id] = .some(value)
    }
}

private struct CollectionScrollMemoryKey: EnvironmentKey {
    static let defaultValue: CollectionScrollMemory? = nil
}

public extension EnvironmentValues {
    /// The screen's memory; nil where no screen provided one (the first-draw rule only).
    var collectionScrollMemory: CollectionScrollMemory? {
        get { self[CollectionScrollMemoryKey.self] }
        set { self[CollectionScrollMemoryKey.self] = newValue }
    }
}

/// Provides a memory to the content unless one is already provided above:
/// the outermost provider is the screen, and an included layout shares it.
public struct ProvideCollectionScrollMemory: ViewModifier {
    @Environment(\.collectionScrollMemory) private var inherited
    @State private var own = CollectionScrollMemory()

    public init() {}

    public func body(content: Content) -> some View {
        content.environment(\.collectionScrollMemory, inherited ?? own)
    }
}

/// The entry half of a Collection's scrollTo: on appearing, a value the
/// screen saw this Collection with differently is a request — `perform` runs
/// on the next turn of the main queue, once the scroll container exists, with
/// the value as the Collection holds it (an optional stays optional, so the
/// same body as `.onChange(of:)`'s runs) — and every value the Collection is
/// drawn with is recorded.
public struct CollectionScrollEntry<Value: Hashable>: ViewModifier {
    let id: String?
    let value: Value
    let perform: (Value) -> Void
    @Environment(\.collectionScrollMemory) private var memory

    public init(id: String?, value: Value, perform: @escaping (Value) -> Void) {
        self.id = id
        self.value = value
        self.perform = perform
    }

    public func body(content: Content) -> some View {
        content
            .onAppear {
                let request = memory?.isRequestOnEntry(id, AnyHashable(value)) == true
                memory?.record(id, AnyHashable(value))
                if request {
                    let value = value
                    DispatchQueue.main.async { perform(value) }
                }
            }
            .onChange(of: value) { _, newValue in
                memory?.record(id, AnyHashable(newValue))
            }
    }
}

public extension View {
    /// ProvideCollectionScrollMemory.
    func providesCollectionScrollMemory() -> some View {
        modifier(ProvideCollectionScrollMemory())
    }

    /// CollectionScrollEntry.
    func collectionScrollEntry<Value: Hashable>(_ id: String?, value: Value, perform: @escaping (Value) -> Void) -> some View {
        modifier(CollectionScrollEntry(id: id, value: value, perform: perform))
    }
}
