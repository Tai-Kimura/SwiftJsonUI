//
//  DynamicViewModel.swift
//  SwiftJsonUI
//
//  View model for dynamic views
//

import SwiftUI
import Combine

// MARK: - View Model
public class DynamicViewModel: ObservableObject {
    @Published public var rootComponent: DynamicComponent?
    @Published public var textFieldValues: [String: String] = [:]
    @Published public var toggleValues: [String: Bool] = [:]
    
    private let jsonName: String?
    private var cancellables = Set<AnyCancellable>()
    
    public init(jsonName: String) {
        self.jsonName = jsonName
        loadJSON()
    }
    
    public init(component: DynamicComponent) {
        self.jsonName = nil
        self.rootComponent = component
    }
    
    public func loadJSON() {
        guard let jsonName = jsonName else { 
            Logger.debug("[DynamicViewModel] No jsonName provided")
            return 
        }
        
        Logger.debug("[DynamicViewModel] Loading JSON: \(jsonName)")
        
        if let data = JSONLayoutLoader.loadJSON(named: jsonName) {
            Logger.debug("[DynamicViewModel] JSON data loaded, size: \(data.count) bytes")
            do {
                let decoder = JSONDecoder()
                rootComponent = try decoder.decode(DynamicComponent.self, from: data)
                Logger.debug("[DynamicViewModel] Successfully decoded component: \(rootComponent?.type ?? "nil")")
            } catch {
                Logger.debug("[DynamicViewModel] Decode error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    Logger.debug("[DynamicViewModel] JSON content: \(jsonString.prefix(200))...")
                }
            }
        } else {
            Logger.debug("[DynamicViewModel] Failed to load JSON data for: \(jsonName)")
        }
    }
    
    public func reload() {
        loadJSON()
    }
    
    public func handleAction(_ action: String?) {
        guard let action = action else { return }
        // アクション処理を実装
        Logger.debug("[DynamicView] Action: \(action)")
        
        // カスタムアクションハンドラーに通知
        NotificationCenter.default.post(
            name: Notification.Name("DynamicViewAction"),
            object: nil,
            userInfo: ["action": action, "viewModel": self]
        )
    }
}