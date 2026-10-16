//
//  UserEditBinding.swift
//  SwiftJsonUI
//
//  onTextChange is the USER'S stream: it fires when the person edits the
//  field (typing, paste, the clear button), never when the value is changed
//  from somewhere else — a view model's updateData, the test runner's
//  initialState, a seed from the layout. That is what KotlinJsonUI (codegen
//  compares the field's text with the data before calling; Dynamic calls it
//  from onValueChange) and web (the input's onChange) do.
//
//  `.onChange(of: binding.wrappedValue)` cannot tell the two apart — it sees
//  every change of the value, from any source — so through 10.30.0 a VM that
//  wrote the field's text, or a test that set it through initialState, ran
//  the screen's "the input changed" handler on iOS only (ticket
//  sjui-ontextchange-fires-on-programmatic-data-change). The control writes
//  through its binding's SETTER and nothing else does, so the handler is
//  called from there — DynamicLocalState's rule for the same reason.
//
//  The handler runs on the main queue's NEXT turn, not inside the setter. A
//  handler that narrows the value and writes it back (digits only, a length
//  cap) is the reason: written inside the setter, the stored value ends the
//  edit where it began ("12" -> "12a" -> "12"), SwiftUI sees no change and a
//  TextField keeps showing "12a" while the data holds "12" (measured on a
//  consumer's TextField, iOS 27.0). Deferred, the write-back is a change of
//  its own and the field follows it — the order `.onChange(of:)` had, and
//  the order Compose's LaunchedEffect has. The value handed over is the one
//  the edit wrote. sjui codegen emits the same (UserEditBindingHelper).
//

import SwiftUI
#if DEBUG

extension SwiftUI.Binding where Value: Equatable {
    /// The same binding, calling `onEdit` with the new value — on the main
    /// queue's next turn — whenever it is SET to something different. Reads
    /// and programmatic changes of the underlying storage do not call it.
    func callingOnEdit(_ onEdit: @escaping (Value) -> Void) -> SwiftUI.Binding<Value> {
        SwiftUI.Binding(
            get: { self.wrappedValue },
            set: { newValue, transaction in
                let changed = self.wrappedValue != newValue
                self.transaction(transaction).wrappedValue = newValue
                if changed { DispatchQueue.main.async { onEdit(newValue) } }
            }
        )
    }
}

enum UserEditBinding {
    /// The text binding a TextField / TextView hands its control: the
    /// layout's onTextChange called from the setter, or `binding` unchanged
    /// when the layout names no handler.
    static func text(
        _ binding: SwiftUI.Binding<String>,
        component: DynamicComponent,
        id: String,
        data: [String: Any]
    ) -> SwiftUI.Binding<String> {
        guard let onTextChange = component.onTextChange,
              DynamicEventHelper.handlerName(from: onTextChange) != nil else {
            return binding
        }
        return binding.callingOnEdit { newValue in
            DynamicEventHelper.callWithValue(onTextChange, id: id, value: newValue, data: data)
        }
    }
}
#endif // DEBUG
