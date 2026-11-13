//
//  CollectionConverter+Reorder.swift
//  SwiftJsonUI
//
//  Dynamic's half of a reorderable Collection (ticket jui-collection-drag-to-reorder): the same CollectionReorder,
//  CollectionReorderRows and collectionReorderContainer the generated code calls, read from the layout's
//  reorderable / onReorder / reorderHandle / reorderLockedProperty.
//

#if DEBUG
import SwiftUI

extension CollectionConverter {

    /// The Collection's reorder declaration, or nil when it declares none (the rows are then the plain ForEach they
    /// always were). `reorderable` may be a binding; `onReorder` names a `(Int, Int, Int) -> Void` the data holds.
    static func reorder(component: DynamicComponent, data: [String: Any]) -> CollectionReorder? {
        let attrs = component.typedAttributes(CollectionAttributes.self)
        guard attrs.reorderable != nil else { return nil }
        let enabled = DynamicHelpers.resolveBool(attrs.reorderable, legacy: false, data: data) ?? false
        let raw = attrs.onReorder?.rawRepresentation as? String
        let handler = DynamicEventHelper.handlerName(from: raw).flatMap { data[$0] as? (Int, Int, Int) -> Void }
        let handle = attrs.reorderHandle.flatMap { $0.isEmpty ? nil : $0 }
        let lockedProperty = attrs.reorderLockedProperty.flatMap { $0.isEmpty ? nil : $0 }
        return CollectionReorder(isEnabled: enabled, usesHandle: handle != nil,
                                 hasLockedRows: lockedProperty != nil) { section, from, to in
            handler?(section, from, to)
        }
    }

    /// The ids the rows are told (each cell's own key — its cellId, else its cellIdProperty value — or its index
    /// when it has none or repeats one), and the indexes of the locked rows.
    static func reorderIdentity(of items: [CollectionCellItem], component: DynamicComponent,
                                cellIdProperty: String?) -> (ids: [String], locked: Set<Int>) {
        var seen = Set<String>()
        let ids = items.map { item -> String in
            if let key = cellKey(item.data, cellIdProperty: cellIdProperty), seen.insert(key).inserted { return key }
            return "#\(item.index)"
        }
        guard let property = component.typedAttributes(CollectionAttributes.self).reorderLockedProperty,
              !property.isEmpty else { return (ids, []) }
        let locked = Set(items.enumerated().compactMap { offset, item -> Int? in
            let value = DynamicBindingResolver.unwrap(item.data[property])
            let isLocked = (value as? Bool) ?? ((value as? NSNumber)?.boolValue) ?? ((value as? String) == "true")
            return isLocked ? offset : nil
        })
        return (ids, locked)
    }

    /// One section's rows: the plain ForEach without a reorder declaration, CollectionReorderRows with one. The
    /// handle's id reaches the cell's components through the environment (CollectionReorderHandleMark).
    @ViewBuilder
    static func reorderableRows<Row: View>(
        items: [CollectionCellItem],
        section: Int,
        component: DynamicComponent,
        cellIdProperty: String?,
        reorder: CollectionReorder?,
        style: CollectionReorderStyle,
        @ViewBuilder row: @escaping (CollectionCellItem) -> Row
    ) -> some View {
        if let reorder {
            let identity = reorderIdentity(of: items, component: component, cellIdProperty: cellIdProperty)
            CollectionReorderRows(section: section, ids: identity.ids, locked: identity.locked, reorder: reorder,
                                  style: style) { index in
                row(items[index])
                    .environment(\.collectionReorderHandleId,
                                 component.typedAttributes(CollectionAttributes.self).reorderHandle)
            }
        } else {
            ForEach(items) { item in row(item) }
        }
    }
}

#endif // DEBUG
