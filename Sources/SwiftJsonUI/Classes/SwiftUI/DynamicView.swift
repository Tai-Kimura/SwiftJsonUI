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
    
    public init(jsonName: String, viewId: String? = nil) {
        _viewModel = StateObject(wrappedValue: DynamicViewModel(jsonName: jsonName))
        self.viewId = viewId ?? UUID().uuidString
    }
    
    public init(component: DynamicComponent, viewId: String? = nil) {
        _viewModel = StateObject(wrappedValue: DynamicViewModel(component: component))
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
            viewModel.reload()
        }
        #endif
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