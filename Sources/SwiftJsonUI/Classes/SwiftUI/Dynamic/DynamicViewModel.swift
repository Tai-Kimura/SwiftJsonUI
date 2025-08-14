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
    @Published public var variables: [String: Any] = [:]
    @Published public var progressValues: [String: Double] = [:]
    @Published public var sliderValues: [String: Double] = [:]
    @Published public var selectedSegments: [String: Int] = [:]
    @Published public var selectedRadios: [String: Int] = [:]
    @Published public var decodeError: String?
    @Published public var data: [String: Any] = [:]
    
    private let jsonName: String?
    private var cancellables = Set<AnyCancellable>()
    
    public init(jsonName: String, data: [String: Any] = [:]) {
        self.jsonName = jsonName
        self.data = data
        loadJSON()
    }
    
    public init(component: DynamicComponent, data: [String: Any] = [:]) {
        self.jsonName = nil
        self.rootComponent = component
        self.data = data
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
                decodeError = nil
                Logger.debug("[DynamicViewModel] Successfully decoded component: \(rootComponent?.type ?? "nil")")
            } catch {
                Logger.debug("[DynamicViewModel] Decode error: \(error)")
                decodeError = "JSON Decode Error:\n\(error)"
                if let jsonString = String(data: data, encoding: .utf8) {
                    Logger.debug("[DynamicViewModel] JSON content: \(jsonString.prefix(200))...")
                    decodeError! += "\n\nJSON Preview:\n\(jsonString.prefix(500))"
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
    
    // MARK: - Variable Processing
    
    /// Process text with @{} variable placeholders
    public func processText(_ text: String?) -> String {
        guard let text = text else { return "" }
        
        // Check if text contains @{} pattern
        guard text.contains("@{") else { return text }
        
        var result = text
        
        // Find all @{...} patterns
        let pattern = "@\\{([^}]+)\\}"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            // Process matches in reverse order to maintain string indices
            for match in matches.reversed() {
                if let range = Range(match.range, in: text),
                   let varRange = Range(match.range(at: 1), in: text) {
                    let varName = String(text[varRange])
                    
                    // Remove optional markers
                    let cleanVarName = varName
                        .replacingOccurrences(of: " ?? ''", with: "")
                        .replacingOccurrences(of: "?", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    
                    // Get variable value - check data dictionary first, then variables
                    let value: String
                    if let dataValue = data[cleanVarName] {
                        value = String(describing: dataValue)
                    } else if let varValue = variables[cleanVarName] {
                        value = String(describing: varValue)
                    } else {
                        // Default values for common variables
                        switch cleanVarName {
                        case "title":
                            value = "Dynamic Title"
                        case "message":
                            value = "Dynamic Message"
                        default:
                            value = ""
                        }
                    }
                    
                    result.replaceSubrange(range, with: value)
                }
            }
        }
        
        return result
    }
    
    /// Process any value that might contain @{} reference
    public func processValue<T>(_ value: Any?) -> T? {
        guard let value = value else { return nil }
        
        // If it's a string, check for @{} pattern
        if let stringValue = value as? String {
            if stringValue.hasPrefix("@{") && stringValue.hasSuffix("}") {
                let startIndex = stringValue.index(stringValue.startIndex, offsetBy: 2)
                let endIndex = stringValue.index(stringValue.endIndex, offsetBy: -1)
                let varName = String(stringValue[startIndex..<endIndex])
                
                // Return the value from data dictionary
                return data[varName] as? T
            }
        }
        
        // Return the value as-is if it's not a @{} reference
        return value as? T
    }
    
    /// Process boolean value that might contain @{} reference
    public func processBool(_ value: Any?) -> Bool {
        return processValue(value) ?? false
    }
    
    /// Process double value that might contain @{} reference
    public func processDouble(_ value: Any?) -> Double {
        return processValue(value) ?? 0.0
    }
    
    /// Process int value that might contain @{} reference
    public func processInt(_ value: Any?) -> Int {
        return processValue(value) ?? 0
    }
    
    /// Process string value that might contain @{} reference
    public func processString(_ value: Any?) -> String? {
        return processValue(value)
    }
}