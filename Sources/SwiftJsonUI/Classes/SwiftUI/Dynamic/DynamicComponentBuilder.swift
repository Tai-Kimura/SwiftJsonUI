//
//  DynamicComponentBuilder.swift
//  SwiftJsonUI
//
//  Main component builder for dynamic views
//

import SwiftUI

// MARK: - Component Builder
public struct DynamicComponentBuilder: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    let viewId: String?
    
    public init(component: DynamicComponent, viewModel: DynamicViewModel, viewId: String? = nil) {
        self.component = component
        self.viewModel = viewModel
        self.viewId = viewId
    }
    
    public var body: some View {
        // Check if component needs visibility wrapper
        let needsVisibilityWrapper = component.visibility != nil || component.hidden == true
        
        if needsVisibilityWrapper {
            // Handle both visibility and hidden properties
            let visibility: String? = {
                if component.hidden == true {
                    return "gone"
                }
                return component.visibility
            }()
            
            let _ = print("👁️ Applying VisibilityWrapper: id=\(component.id ?? "no-id"), visibility=\(visibility ?? "none")")
            
            // Wrap with VisibilityWrapper
            VisibilityWrapper(visibility) {
                buildView(from: component)
                    .applyDynamicModifiers(component)
                    .dynamicEvents(component, viewModel: viewModel, viewId: viewId)
            }
        } else {
            // No visibility wrapper needed
            buildView(from: component)
                .applyDynamicModifiers(component)
                .dynamicEvents(component, viewModel: viewModel, viewId: viewId)
        }
    }
    
    @ViewBuilder
    func buildView(from component: DynamicComponent) -> some View {
        if let type = component.type {
            let _ = print("🔨 Building component: type=\(type), id=\(component.id ?? "no-id"), visibility=\(component.visibility ?? "visible"), hidden=\(component.hidden ?? false)")
            switch type.lowercased() {
        // Text components
        case "text", "label":
            TextConverter.convert(component: component, viewModel: viewModel)
        
        case "button":
            ButtonConverter.convert(component: component, viewModel: viewModel)
        
        case "textfield":
            TextFieldConverter.convert(component: component, viewModel: viewModel)
        
        case "textview":
            TextViewConverter.convert(component: component, viewModel: viewModel)
        
        // Image components
        case "image":
            ImageViewConverter.convert(component: component, viewModel: viewModel)
        
        case "networkimage":
            NetworkImageConverter.convert(component: component, viewModel: viewModel)
        
        // Container components
        case "view":
            DynamicViewContainer(component: component, viewModel: viewModel, viewId: viewId)
        
        case "scrollview", "scroll":
            DynamicScrollViewContainer(component: component, viewModel: viewModel, viewId: viewId)
        
        // Selection components
        case "toggle", "switch", "check":
            ToggleConverter.convert(component: component, viewModel: viewModel)
        
        case "checkbox":
            CheckboxConverter.convert(component: component, viewModel: viewModel)
        
        case "radio":
            RadioConverter.convert(component: component, viewModel: viewModel)
        
        case "picker":
            PickerConverter.convert(component: component, viewModel: viewModel)
        
        case "selectbox":
            SelectBoxConverter.convert(component: component, viewModel: viewModel)
        
        case "slider":
            SliderConverter.convert(component: component, viewModel: viewModel)
        
        case "progress", "progressbar":
            ProgressConverter.convert(component: component, viewModel: viewModel)
        
        // Complex components
        case "iconlabel":
            IconLabelConverter.convert(component: component, viewModel: viewModel, viewId: viewId)
        
        case "collection":
            CollectionConverter.convert(component: component, viewModel: viewModel, viewId: viewId)
        
        case "table", "list":
            TableConverter.convert(component: component, viewModel: viewModel, viewId: viewId)
        
        case "tabview":
            TabViewConverter.convert(component: component, viewModel: viewModel, viewId: viewId)
        
        case "web", "webview":
            WebConverter.convert(component: component, viewModel: viewModel)
        
        // Special effects
        case "gradientview", "gradient":
            GradientViewConverter.convert(component: component, viewModel: viewModel, viewId: viewId)
        
        case "blur", "blurview":
            BlurConverter.convert(component: component, viewModel: viewModel, viewId: viewId)
        
        // Default/Unknown
        default:
            // Unknown component type - show error message
            Text("Error: Unknown component type '\(type)'")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.red.opacity(0.8), lineWidth: 1)
                )
            }
        } else {
            // Skip components without type (data, include, etc.)
            EmptyView()
        }
    }
}