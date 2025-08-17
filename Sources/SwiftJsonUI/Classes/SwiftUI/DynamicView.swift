//
//  DynamicView.swift
//  SwiftJsonUI
//
//  Main dynamic view entry point
//

import SwiftUI
import Combine

// MARK: - Dynamic View
public struct DynamicView: View {
    @StateObject private var viewModel: DynamicViewModel
    private let viewId: String
    
    public init(jsonName: String, viewId: String? = nil, data: [String: Any] = [:]) {
        _viewModel = StateObject(wrappedValue: DynamicViewModel(jsonName: jsonName, data: data))
        self.viewId = viewId ?? UUID().uuidString
    }
    
    public init(component: DynamicComponent, viewId: String? = nil, data: [String: Any] = [:]) {
        _viewModel = StateObject(wrappedValue: DynamicViewModel(component: component, data: data))
        self.viewId = viewId ?? UUID().uuidString
    }
    
    public var body: some View {
        Group {
            if let component = viewModel.rootComponent {
                DynamicComponentBuilder(
                    component: component,
                    viewModel: viewModel,
                    viewId: viewId
                )
                .id(createViewId())  // Add ID to force view recreation when data changes
                .onAppear {
                    Logger.debug("[DynamicView] Rendering component: \(component.type ?? "unknown")")
                }
            } else if let error = viewModel.decodeError {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("JSON Decode Error")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding(.bottom, 5)
                        
                        Text(error)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(UIColor.systemBackground))
            } else {
                ProgressView("Loading...")
                    .onAppear {
                        Logger.debug("[DynamicView] No rootComponent, showing loading...")
                        Logger.debug("[DynamicView] ProgressView appeared, attempting to load...")
                        viewModel.loadJSON()
                    }
            }
        }
        #if DEBUG
        .onReceive(HotLoader.instance.$lastUpdate) { date in
            Logger.debug("[DynamicView] HotLoader update received: \(date)")
            // Clear style cache to reload updated styles
            StyleProcessor.clearCache()
            viewModel.reload()
        }
        #endif
    }
    
    // Generate a unique ID based on viewModel data to force view recreation when data changes
    private func createViewId() -> String {
        // Create ID from all data values in the viewModel
        let dataValues = viewModel.data
            .sorted { $0.key < $1.key }  // Sort for consistent ordering
            .map { "\($0.key):\($0.value)" }
            .joined(separator: "_")
        
        // Include variables as well since they can also affect view rendering
        let variableValues = viewModel.variables
            .sorted { $0.key < $1.key }
            .map { "\($0.key):\($0.value)" }
            .joined(separator: "_")
        
        // Combine both to create a unique ID
        let combinedId = "\(dataValues)_\(variableValues)"
        
        // If empty, use viewId as fallback
        return combinedId.isEmpty ? viewId : combinedId
    }
}

// MARK: - Preview Helper
public struct DynamicViewPreview: View {
    let jsonName: String
    
    public init(jsonName: String) {
        self.jsonName = jsonName
    }
    
    public var body: some View {
        DynamicView(jsonName: jsonName)
            .onAppear {
                #if DEBUG
                HotLoader.instance.isHotLoadEnabled = true
                #endif
            }
    }
}