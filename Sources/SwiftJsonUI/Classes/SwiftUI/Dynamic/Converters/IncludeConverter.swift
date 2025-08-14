//
//  IncludeConverter.swift
//  SwiftJsonUI
//
//  Converts include components to load and display included views
//

import SwiftUI

// MARK: - Wrapper view for included content
struct IncludedContentView: View {
    let jsonName: String
    let data: [String: Any]
    @ObservedObject var parentViewModel: DynamicViewModel
    
    // Create a local ViewModel for the included view
    @StateObject private var includedViewModel = DynamicViewModel(jsonName: "")
    
    var body: some View {
        DynamicView(
            jsonName: jsonName,
            viewId: "\(jsonName)_view",
            data: data
        )
        .environmentObject(includedViewModel)
        .onAppear {
            // Initialize the included view model with the json name
            includedViewModel.loadJSON(named: jsonName)
            // Set the initial data
            includedViewModel.data = data
        }
    }
}

public struct IncludeConverter {
    
    /// Convert include component to load another JSON view
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String? = nil
    ) -> AnyView {
        guard let includePath = component.include else {
            print("⚠️ Include component missing 'include' property")
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
                    // Extract property name
                    let startIndex = stringValue.index(stringValue.startIndex, offsetBy: 2)
                    let endIndex = stringValue.index(stringValue.endIndex, offsetBy: -1)
                    let propertyName = String(stringValue[startIndex..<endIndex])
                    
                    // Get value from parent viewModel
                    if let parentValue = viewModel.data[propertyName] {
                        processedData[key] = parentValue
                    } else {
                        // If not found, keep the binding expression for debugging
                        processedData[key] = stringValue
                    }
                } else {
                    // Static value
                    processedData[key] = value
                }
            } else {
                // Non-string value
                processedData[key] = value
            }
        }
        
        print("📦 Include: path=\(includePath), data=\(processedData)")
        
        // Create the included view
        return AnyView(
            IncludedContentView(
                jsonName: includePath,
                data: processedData,
                parentViewModel: viewModel
            )
        )
    }
}