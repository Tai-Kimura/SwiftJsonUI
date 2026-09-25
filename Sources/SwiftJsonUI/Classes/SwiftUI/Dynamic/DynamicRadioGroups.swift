//
//  DynamicRadioGroups.swift
//  SwiftJsonUI
//
//  The selection of each group of single Radios a Dynamic screen's data does
//  not bind — no `SwiftUI.Binding<String>` under the group's name. One store
//  per DynamicView, handed down the environment, because the Radios of a group
//  are separate components that can sit anywhere in the tree: group name → the
//  chosen Radio's id, absent until the user chooses (so each Radio's `checked`
//  seeds what shows), and cleared when a plain value under the group's name
//  changes (the view model's word wins). sjui's codegen holds the same thing as
//  one `@State` per group on the view.
//
//  Before, such a group read `.constant("")` — a static group did not move on
//  a tap, and a plain value under its name was not read at all (tickets
//  static-valued-controls-do-not-change-on-a-users-tap,
//  sjui-dynamic-plain-bound-controls-do-not-follow-the-view-model).
//

import SwiftUI
#if DEBUG

final class DynamicRadioGroups: ObservableObject {
    @Published var chosen: [String: String] = [:]
}

private struct DynamicRadioGroupsKey: EnvironmentKey {
    static let defaultValue: DynamicRadioGroups? = nil
}

extension EnvironmentValues {
    var dynamicRadioGroups: DynamicRadioGroups? {
        get { self[DynamicRadioGroupsKey.self] }
        set { self[DynamicRadioGroupsKey.self] = newValue }
    }
}

/// A single Radio whose group the data does not bind. `declared` is the plain
/// value under the group's name, "" when there is none. Outside a DynamicView
/// (a DynamicComponentBuilder used directly) there is no store and the group
/// shows its declared value, as it did before.
struct DynamicGroupRadio: View {
    @Environment(\.dynamicRadioGroups) private var groups
    let group: String
    let declared: String
    let content: (SwiftUI.Binding<String>) -> AnyView

    var body: some View {
        if let groups {
            Observed(groups: groups, group: group, declared: declared, content: content)
        } else {
            content(.constant(declared))
        }
    }

    private struct Observed: View {
        @ObservedObject var groups: DynamicRadioGroups
        let group: String
        let declared: String
        let content: (SwiftUI.Binding<String>) -> AnyView

        var body: some View {
            content(SwiftUI.Binding(
                get: { groups.chosen[group] ?? declared },
                set: { groups.chosen[group] = $0 }
            ))
            .onChange(of: declared) { _, _ in
                groups.chosen[group] = nil
            }
        }
    }
}
#endif // DEBUG
