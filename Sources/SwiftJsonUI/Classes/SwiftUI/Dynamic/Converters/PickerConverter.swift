//
//  PickerConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Picker with MenuPickerStyle.
//  This is a simplified picker for dropdown-style selection. For segmented
//  control, see SegmentConverter. For date/item pickers, see SelectBoxConverter.
//
//  Closest Ruby equivalent: selectbox_converter.rb (normal type) and segment_converter.rb
//  use Picker internally, but this Dynamic converter provides a lightweight
//  menu-style Picker.
//
//  Modifier order (matches base_view_converter.rb apply_modifiers):
//    1. Picker(...) with pickerStyle, font, foregroundColor
//    2. onValueChange (.onChange)
//    3. padding
//    4. frame_constraints
//    5. frame_size
//    6. insets
//    7. background
//    8. cornerRadius
//    9. border
//   10. margins
//   11. opacity
//   12. shadow
//   13. clipped
//   14. offset
//   15. hidden
//   16. disabled
//   17. hitTesting
//   18. tint
//   19. onClick + lifecycle
//   20. confirmationDialog
//   21. accessibilityIdentifier
//

import SwiftUI
#if DEBUG

public struct PickerConverter {

    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        let items = component.items ?? []
        let label = DynamicHelpers.processText(component.text, data: data)

        // Resolve selection binding from selectedIndex or selectedItem
        // Try Int binding first (selectedIndex), then String binding
        let selectionBinding: SwiftUI.Binding<Int> = {
            // Check for selectedIndex binding in rawData
            if let selectedIndexExpr = component.rawData["selectedIndex"] as? String,
               selectedIndexExpr.hasPrefix("@{") {
                return DynamicBindingHelper.int(selectedIndexExpr, data: data, fallback: component.selectedIndex ?? 0)
            }
            // Static selectedIndex
            return .constant(component.selectedIndex ?? 0)
        }()

        // --- 1. Picker base ---
        var result = AnyView(
            Picker(label, selection: selectionBinding) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    Text(item.dynamicLocalized()).tag(index)
                }
            }
            .pickerStyle(MenuPickerStyle())
        )

        // Apply font
        if let font = DynamicHelpers.fontFromComponent(component) {
            result = AnyView(result.font(font))
        }

        // Apply foregroundColor
        if let fontColor = DynamicHelpers.getColor(component.fontColor, data: data) {
            result = AnyView(result.foregroundColor(fontColor))
        }

        // --- 2. onValueChange ---
        // Note: onChange requires iOS 17+ for the (oldValue, newValue) signature.
        // For Dynamic mode, we use the event helper pattern instead.
        // The ViewModel should observe the binding directly for change callbacks.

        // --- 3-21. Standard modifiers (matches apply_modifiers order) ---
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }
}
#endif // DEBUG
