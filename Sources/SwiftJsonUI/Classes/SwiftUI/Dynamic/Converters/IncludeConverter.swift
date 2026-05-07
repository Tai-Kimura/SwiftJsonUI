//
//  IncludeConverter.swift
//  SwiftJsonUI
//
//  Converts include components to load and display included views
//

import SwiftUI
#if DEBUG

public struct IncludeConverter {

    /// Convert include component to load another JSON view
    public static func convert(
        component: DynamicComponent,
        data: [String: Any],
        viewId: String? = nil
    ) -> AnyView {
        guard let includePath = component.include else {
            return AnyView(EmptyView())
        }

        // Merge shared_data and data
        var mergedData: [String: Any] = [:]

        // First add shared_data (if exists)
        if let sharedData = component.sharedData {
            for (key, value) in sharedData {
                mergedData[key] = value.value
            }
        }

        // Then override with includeData (if exists)
        if let includeData = component.includeData {
            for (key, value) in includeData {
                mergedData[key] = value.value
            }
        }

        // Process @{} bindings in merged data
        var processedData: [String: Any] = [:]
        for (key, value) in mergedData {
            if let stringValue = value as? String {
                if stringValue.hasPrefix("@{") && stringValue.hasSuffix("}") {
                    let startIndex = stringValue.index(stringValue.startIndex, offsetBy: 2)
                    let endIndex = stringValue.index(stringValue.endIndex, offsetBy: -1)
                    let propertyName = String(stringValue[startIndex..<endIndex])

                    if let parentValue = data[propertyName] {
                        processedData[key] = parentValue
                    } else {
                        processedData[key] = stringValue
                    }
                } else {
                    processedData[key] = value
                }
            } else {
                processedData[key] = value
            }
        }

        return AnyView(
            DynamicView(
                jsonName: includePath,
                viewId: "\(includePath)_view",
                data: processedData
            )
        )
    }
}
#endif // DEBUG
