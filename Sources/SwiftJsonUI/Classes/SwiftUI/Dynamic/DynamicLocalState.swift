//
//  DynamicLocalState.swift
//  SwiftJsonUI
//
//  Local state host for Dynamic mode controls whose value is NOT a two-way
//  binding in the data dict — a literal, no value, or a plain value. Native
//  controls on the other JsonUI runtimes (UIKit UITextField/UISwitch, Android
//  Views/Compose, web DOM inputs) are inherently stateful even without a
//  binding — a SwiftUI control built from a `.constant(...)` binding is not.
//  Wrapping the control in this host restores that behavior (editable field,
//  flippable toggle, a Segment / Slider / TabView / Radio / CheckBox that
//  moves) and gives value-change callbacks (onTextChange / onValueChange) a
//  real value stream to fire from.
//
//  The declared value is the SEED: the user's change is kept for as long as
//  the declared value stays what it was, and a new declared value replaces it
//  — the view model's word wins (the same rule KotlinJsonUI's Dynamic keys its
//  state on). `State(initialValue:)` alone took the first value and never
//  another, so a control over a plain value never followed its view model
//  (ticket sjui-dynamic-plain-bound-controls-do-not-follow-the-view-model).
//

import SwiftUI
#if DEBUG

/// Owns a `@State` value and renders `content` with a two-way binding to it.
/// `onChange` (if provided) fires whenever the user changes the value.
struct DynamicLocalState<Value: Equatable>: View {
    @State private var value: Value
    private let declared: Value
    private let onChange: ((Value) -> Void)?
    private let content: (SwiftUI.Binding<Value>) -> AnyView

    init(
        initial: Value,
        onChange: ((Value) -> Void)? = nil,
        content: @escaping (SwiftUI.Binding<Value>) -> AnyView
    ) {
        _value = State(initialValue: initial)
        declared = initial
        self.onChange = onChange
        self.content = content
    }

    var body: some View {
        content(binding)
            // A new declared value replaces the user's; `onChange` is the
            // user's stream, so it does not fire for it.
            .onChange(of: declared) { _, newValue in
                value = newValue
            }
    }

    private var binding: SwiftUI.Binding<Value> {
        SwiftUI.Binding(
            get: { value },
            set: { newValue in
                let changed = newValue != value
                value = newValue
                if changed { onChange?(newValue) }
            }
        )
    }
}
#endif // DEBUG
