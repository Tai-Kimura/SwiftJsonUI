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
//  the order Compose's LaunchedEffect has. sjui codegen emits the same
//  (UserEditBindingHelper).
//
//  A deferred call that is no longer current is dropped: it reads the
//  binding again when it runs, and if the value is not the one its edit
//  wrote, a later edit (or a programmatic change) came first. 10.30.1 handed
//  every deferred call its own edit's value, so a burst of edits ("strin" ...
//  "" from six deletes) queued six calls, and a handler that writes the
//  value back (`data.x = v`) put an intermediate value back into the field
//  after the burst, losing the edits after it (ticket
//  sjui-ontextchange-deferred-handler-replays-stale-value). A burst is now
//  one call with the latest value — intermediate values coalesce, as under
//  `.onChange` and LaunchedEffect.
//

import SwiftUI
#if DEBUG

extension SwiftUI.Binding where Value: Equatable {
    /// The same binding, calling `onEdit` with the new value — on the main
    /// queue's next turn — whenever it is SET to something different, if
    /// the value is still that one by then. Reads and programmatic changes
    /// of the underlying storage do not call it.
    func callingOnEdit(_ onEdit: @escaping (Value) -> Void) -> SwiftUI.Binding<Value> {
        SwiftUI.Binding(
            get: { self.wrappedValue },
            set: { newValue, transaction in
                let changed = self.wrappedValue != newValue
                self.transaction(transaction).wrappedValue = newValue
                guard changed else { return }
                DispatchQueue.main.async {
                    // Overtaken by a later edit or a programmatic change: stale.
                    guard self.wrappedValue == newValue else { return }
                    onEdit(newValue)
                }
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
