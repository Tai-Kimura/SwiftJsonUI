//
//  TableConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI List (Table).
//
//  Modifier order (matches table_converter.rb):
//    List { ForEach { ... } }
//    -> .listStyle()                // hideSeparator -> .plain, or listStyle attribute
//    -> .listRowSeparator(.hidden)  // hideSeparator == true
//    -> applyStandardModifiers()    // base_view_converter apply_modifiers
//
//  Data sources (priority order):
//    1. binding data + cell_layout -> ForEach with identified items + cell view
//    2. data array (AnyCodable)    -> ForEach with TableRow
//    3. items string array         -> ForEach with Text rows
//    4. child components           -> ForEach with DynamicComponentBuilder
//    5. fallback                   -> ForEach(0..<10) placeholder

import SwiftUI
#if DEBUG

public struct TableConverter {

    public static func convert(
        component: DynamicComponent,
        data: [String: Any],
        viewId: String? = nil
    ) -> AnyView {
        // Build List content
        var result = AnyView(
            List {
                buildListContent(component: component, data: data, viewId: viewId)
            }
        )

        // .listStyle - hideSeparator takes precedence
        if component.rawData["hideSeparator"] as? Bool == true {
            result = AnyView(result.listStyle(.plain))
            result = AnyView(result.listRowSeparator(.hidden))
        } else if let listStyle = component.rawData["listStyle"] as? String {
            result = applyListStyle(result, style: listStyle)
        }

        // applyStandardModifiers
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }

    // MARK: - Private

    @ViewBuilder
    private static func buildListContent(
        component: DynamicComponent,
        data: [String: Any],
        viewId: String?
    ) -> some View {
        let componentData = component.data ?? []
        let items = component.items ?? []

        if !componentData.isEmpty {
            // Data array -> TableRow for each item
            ForEach(0..<componentData.count, id: \.self) { index in
                TableRow(dataItem: componentData[index], component: component, data: data)
            }
        } else if !items.isEmpty {
            // String items -> Text rows
            ForEach(0..<items.count, id: \.self) { index in
                HStack {
                    {
                        var text = Text(items[index].dynamicLocalized())
                            .foregroundColor(DynamicHelpers.getColor(component.fontColor) ?? .primary)
                        if let font = DynamicHelpers.fontFromComponent(component) {
                            text = text.font(font)
                        }
                        return text
                    }()
                    Spacer()
                }
            }
        } else if let children = component.childComponents {
            // Child components -> DynamicComponentBuilder
            // Strip weighted child flags before passing to children
            let cData: [String: Any] = {
                var d = data
                d.removeValue(forKey: "__isWeightedChild")
                d.removeValue(forKey: "__weightedParentOrientation")
                return d
            }()
            ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                DynamicComponentBuilder(component: child, data: cData, viewId: viewId)
            }
        } else {
            // Fallback placeholder
            ForEach(0..<10) { index in
                Text("Row \(index)")
            }
        }
    }

    private static func applyListStyle(_ view: AnyView, style: String) -> AnyView {
        switch style {
        case "grouped":
            return AnyView(view.listStyle(.grouped))
        case "insetGrouped":
            return AnyView(view.listStyle(.insetGrouped))
        case "sidebar":
            return AnyView(view.listStyle(.sidebar))
        default:
            return AnyView(view.listStyle(.plain))
        }
    }
}

// MARK: - TableRow

struct TableRow: View {
    let dataItem: AnyCodable
    let component: DynamicComponent
    let data: [String: Any]

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let data = dataItem.value as? [String: Any] {
                    ForEach(Array(data.keys.sorted()), id: \.self) { key in
                        if let value = data[key] {
                            HStack {
                                Text(key)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(String(describing: value))
                                    .font(.body)
                            }
                        }
                    }
                } else {
                    Text(String(describing: dataItem.value))
                        .font(.body)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
#endif // DEBUG
