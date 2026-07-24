//
//  DynamicLocalState.swift
//  SwiftJsonUI
//
//  Local state host for Dynamic mode controls whose value is NOT bound to a
//  data-dict variable. Native controls on the other JsonUI runtimes (UIKit
//  UITextField/UISwitch, Android Views/Compose, web DOM inputs) are
//  inherently stateful even without a binding — a SwiftUI control built from
//  a `.constant(...)` binding is not. Wrapping the unbound control in this
//  host restores that behavior (editable field, flippable toggle) and gives
//  value-change callbacks (onTextChange / onValueChange) a real value stream
//  to fire from.
//

import SwiftUI
#if DEBUG

/// Owns a `@State` value and renders `content` with a two-way binding to it.
/// `onChange` (if provided) fires whenever the user changes the value.
struct DynamicLocalState<Value: Equatable>: View {
    @State private var value: Value
    private let onChange: ((Value) -> Void)?
    private let content: (SwiftUI.Binding<Value>) -> AnyView

    init(
        initial: Value,
        onChange: ((Value) -> Void)? = nil,
        content: @escaping (SwiftUI.Binding<Value>) -> AnyView
    ) {
        _value = State(initialValue: initial)
        self.onChange = onChange
        self.content = content
    }

    var body: some View {
        content(binding)
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
