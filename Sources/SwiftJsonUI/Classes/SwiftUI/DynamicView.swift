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
                Logger.debug("[DynamicView] Rendering component: \(component.type)")
                DynamicComponentBuilder(
                    component: component,
                    viewModel: viewModel,
                    viewId: viewId
                )
            } else {
                Logger.debug("[DynamicView] No rootComponent, showing loading...")
                ProgressView("Loading...")
                    .onAppear {
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