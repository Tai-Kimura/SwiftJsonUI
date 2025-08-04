//
//  DynamicEventHandler.swift
//  SwiftJsonUI
//
//  Event handling for dynamic views
//

import SwiftUI
import Combine

// MARK: - Event Types
public enum DynamicEventType: String {
    case onClick = "onClick"
    case onLongPress = "onLongPress"
    case onAppear = "onAppear"
    case onDisappear = "onDisappear"
    case onChange = "onChange"
    case onSubmit = "onSubmit"
    case onToggle = "onToggle"
    case onSelect = "onSelect"
}

// MARK: - Event Context
public struct DynamicEventContext {
    public let componentId: String?
    public let eventType: DynamicEventType
    public let action: String
    public let value: Any?
    public let component: DynamicComponent
    public let viewModel: DynamicViewModel
    
    public init(
        componentId: String?,
        eventType: DynamicEventType,
        action: String,
        value: Any? = nil,
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) {
        self.componentId = componentId
        self.eventType = eventType
        self.action = action
        self.value = value
        self.component = component
        self.viewModel = viewModel
    }
}

// MARK: - Event Handler Protocol
public protocol DynamicEventHandlerProtocol: AnyObject {
    func handleEvent(_ context: DynamicEventContext)
}

// MARK: - Default Event Handler
public class DefaultDynamicEventHandler: DynamicEventHandlerProtocol {
    public init() {}
    
    public func handleEvent(_ context: DynamicEventContext) {
        Logger.debug("[DynamicEvent] \(context.eventType.rawValue): \(context.action)")
        
        // デフォルトのアクション処理
        switch context.action {
        case "log":
            if let value = context.value {
                print("[DynamicView] Component \(context.componentId ?? "unknown"): \(value)")
            } else {
                print("[DynamicView] Component \(context.componentId ?? "unknown") triggered")
            }
            
        case "dismiss":
            // View dismissal
            NotificationCenter.default.post(
                name: Notification.Name("DynamicViewDismiss"),
                object: nil
            )
            
        case "navigate":
            // Navigation
            if let value = context.value as? String {
                NotificationCenter.default.post(
                    name: Notification.Name("DynamicViewNavigate"),
                    object: nil,
                    userInfo: ["destination": value]
                )
            }
            
        default:
            // カスタムアクション
            NotificationCenter.default.post(
                name: Notification.Name("DynamicViewAction"),
                object: nil,
                userInfo: [
                    "action": context.action,
                    "componentId": context.componentId ?? "",
                    "value": context.value ?? "",
                    "viewModel": context.viewModel
                ]
            )
        }
    }
}

// MARK: - Event Manager
public class DynamicEventManager: ObservableObject {
    public static let shared = DynamicEventManager()
    
    private var handlers: [String: DynamicEventHandlerProtocol] = [:]
    private let defaultHandler = DefaultDynamicEventHandler()
    
    private init() {}
    
    public func registerHandler(_ handler: DynamicEventHandlerProtocol, for viewId: String? = nil) {
        let key = viewId ?? "default"
        handlers[key] = handler
    }
    
    public func unregisterHandler(for viewId: String? = nil) {
        let key = viewId ?? "default"
        handlers.removeValue(forKey: key)
    }
    
    public func handleEvent(_ context: DynamicEventContext, viewId: String? = nil) {
        let key = viewId ?? "default"
        let handler = handlers[key] ?? handlers["default"] ?? defaultHandler
        handler.handleEvent(context)
    }
}

// MARK: - View Extension for Events
extension View {
    @ViewBuilder
    public func dynamicEvents(
        _ component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String? = nil
    ) -> some View {
        self
            .applyOnClick(component, viewModel: viewModel, viewId: viewId)
            .applyOnLongPress(component, viewModel: viewModel, viewId: viewId)
            .applyOnAppear(component, viewModel: viewModel, viewId: viewId)
            .applyOnDisappear(component, viewModel: viewModel, viewId: viewId)
    }
    
    @ViewBuilder
    private func applyOnClick(
        _ component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String?
    ) -> some View {
        if let onClick = component.onClick {
            self.onTapGesture {
                let context = DynamicEventContext(
                    componentId: component.id,
                    eventType: .onClick,
                    action: onClick,
                    component: component,
                    viewModel: viewModel
                )
                DynamicEventManager.shared.handleEvent(context, viewId: viewId)
            }
        } else {
            self
        }
    }
    
    @ViewBuilder
    private func applyOnLongPress(
        _ component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String?
    ) -> some View {
        if let onLongPress = component.onLongPress {
            self.onLongPressGesture {
                let context = DynamicEventContext(
                    componentId: component.id,
                    eventType: .onLongPress,
                    action: onLongPress,
                    component: component,
                    viewModel: viewModel
                )
                DynamicEventManager.shared.handleEvent(context, viewId: viewId)
            }
        } else {
            self
        }
    }
    
    @ViewBuilder
    private func applyOnAppear(
        _ component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String?
    ) -> some View {
        if let onAppear = component.onAppear {
            self.onAppear {
                let context = DynamicEventContext(
                    componentId: component.id,
                    eventType: .onAppear,
                    action: onAppear,
                    component: component,
                    viewModel: viewModel
                )
                DynamicEventManager.shared.handleEvent(context, viewId: viewId)
            }
        } else {
            self
        }
    }
    
    @ViewBuilder
    private func applyOnDisappear(
        _ component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String?
    ) -> some View {
        if let onDisappear = component.onDisappear {
            self.onDisappear {
                let context = DynamicEventContext(
                    componentId: component.id,
                    eventType: .onDisappear,
                    action: onDisappear,
                    component: component,
                    viewModel: viewModel
                )
                DynamicEventManager.shared.handleEvent(context, viewId: viewId)
            }
        } else {
            self
        }
    }
}