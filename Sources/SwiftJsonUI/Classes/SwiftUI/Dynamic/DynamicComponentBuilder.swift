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
    let viewModel: DynamicViewModel  // @ObservedObjectを削除してビュー更新を防ぐ
    let viewId: String?
    let isWeightedChild: Bool
    let parentOrientation: String?
    
    public init(component: DynamicComponent, viewModel: DynamicViewModel, viewId: String? = nil, isWeightedChild: Bool = false, parentOrientation: String? = nil) {
        self.component = component
        self.viewModel = viewModel
        self.viewId = viewId
        self.isWeightedChild = isWeightedChild
        self.parentOrientation = parentOrientation
    }
    
    public var body: some View {
        let _ = print("🏗️ DynamicComponentBuilder.body: type=\(component.type ?? "nil"), id=\(component.id ?? "nil")")
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
                buildComponentWithModifiers()
            }
        } else {
            // No visibility wrapper needed
            buildComponentWithModifiers()
        }
    }
    
    @ViewBuilder
    private func buildComponentWithModifiers() -> some View {
        // Check if component needs alignment wrapper based on parent orientation
        let alignmentInfo = getComponentAlignmentInfo()
        
        if alignmentInfo.needsWrapper {
            // Build component wrapped for alignment
            buildAlignmentWrappedComponent(alignmentInfo: alignmentInfo)
        } else {
            // Build component without alignment wrapper
            let view = buildView(from: component)
            
            // These components handle their own modifiers (padding/margins/background/cornerRadius)
            // Applying applyDynamicModifiers would cause double application
            let typeString = component.type?.lowercased() ?? ""
            let selfManagedTypes = ["button", "text", "label", "image", "networkimage", "textfield", "textview", "selectbox", "scrollview", "scroll"]
            
            // Check if this is a View container that uses relative positioning
            let skipPadding = shouldSkipPadding()
            
            if selfManagedTypes.contains(typeString) {
                view
                    .dynamicEvents(component, viewModel: viewModel, viewId: viewId)
            } else {
                view
                    .applyDynamicModifiers(component, isWeightedChild: isWeightedChild, skipPadding: skipPadding)
                    .dynamicEvents(component, viewModel: viewModel, viewId: viewId)
            }
        }
    }
    
    @ViewBuilder
    private func buildAlignmentWrappedComponent(alignmentInfo: (needsWrapper: Bool, wrapperAlignment: Alignment)) -> some View {
        let view = buildView(from: component)
        
        // These components handle their own modifiers
        let typeString = component.type?.lowercased() ?? ""
        let selfManagedTypes = ["button", "text", "label", "image", "networkimage", "textfield", "textview", "selectbox", "scrollview", "scroll"]
        
        // Check if this is a View container that uses relative positioning
        let skipPadding = shouldSkipPadding()
        
        let modifiedView = Group {
            if selfManagedTypes.contains(typeString) {
                view
                    .dynamicEvents(component, viewModel: viewModel, viewId: viewId)
            } else {
                view
                    .applyDynamicModifiers(component, isWeightedChild: isWeightedChild, skipPadding: skipPadding)
                    .dynamicEvents(component, viewModel: viewModel, viewId: viewId)
            }
        }
        
        // Apply alignment wrapper based on parent orientation
        if parentOrientation == "horizontal" {
            // Wrap in VStack for vertical alignment in HStack
            VStack {
                modifiedView
            }
            .frame(maxHeight: .infinity, alignment: alignmentInfo.wrapperAlignment)
        } else if parentOrientation == "vertical" {
            // Wrap in HStack for horizontal alignment in VStack
            HStack {
                modifiedView
            }
            .frame(maxWidth: .infinity, alignment: alignmentInfo.wrapperAlignment)
        } else {
            // No parent orientation, just return the view
            modifiedView
        }
    }
    
    private func getComponentAlignmentInfo() -> (needsWrapper: Bool, wrapperAlignment: Alignment) {
        guard let parentOrientation = parentOrientation else {
            return (false, .center)
        }
        
        var needsWrapper = false
        var wrapperAlignment: Alignment = .center
        
        if parentOrientation == "horizontal" {
            // In HStack: alignTop/Bottom/centerVertical need VStack wrapper for individual vertical alignment
            if component.alignTop == true {
                needsWrapper = true
                wrapperAlignment = .top
            } else if component.alignBottom == true {
                needsWrapper = true
                wrapperAlignment = .bottom
            } else if component.centerVertical == true {
                needsWrapper = true
                wrapperAlignment = .center
            } else if component.centerInParent == true {
                // centerInParent also needs vertical centering
                needsWrapper = true
                wrapperAlignment = .center
            }
        } else if parentOrientation == "vertical" {
            // In VStack: alignLeft/Right/centerHorizontal need HStack wrapper for individual horizontal alignment
            if component.alignLeft == true {
                needsWrapper = true
                wrapperAlignment = .leading
            } else if component.alignRight == true {
                needsWrapper = true
                wrapperAlignment = .trailing
            } else if component.centerHorizontal == true {
                needsWrapper = true
                wrapperAlignment = .center
            } else if component.centerInParent == true {
                // centerInParent also needs horizontal centering
                needsWrapper = true
                wrapperAlignment = .center
            }
        }
        
        return (needsWrapper, wrapperAlignment)
    }
    
    private func shouldSkipPadding() -> Bool {
        // Skip padding if this is a View container with relative positioning
        if component.type?.lowercased() == "view" {
            if let children = component.childComponents {
                let needsRelativePositioning = RelativePositionConverter.childrenNeedRelativePositioning(children)
                let hasConflictingAlignments = RelativePositionConverter.childrenHaveConflictingAlignments(
                    children, 
                    parentOrientation: component.orientation
                )
                
                // Skip padding if relative positioning will be used
                return needsRelativePositioning && 
                       (component.orientation == nil || hasConflictingAlignments)
            }
        }
        return false
    }
    
    @ViewBuilder
    func buildView(from component: DynamicComponent) -> some View {
        // Check for include first (has no type)
        if let includePath = component.include {
            let _ = print("🔨 Building include: path=\(includePath), id=\(component.id ?? "no-id")")
            IncludeConverter.convert(component: component, viewModel: viewModel, viewId: viewId)
        } else if let type = component.type {
            let _ = print("🔨 Building component: type=\(type), id=\(component.id ?? "no-id"), include=\(component.include ?? "nil"), visibility=\(component.visibility ?? "visible"), hidden=\(component.hidden ?? false)")
            switch type.lowercased() {
        // Text components
        case "text", "label":
            LabelConverter.convert(component: component, viewModel: viewModel, parentOrientation: parentOrientation)
        
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
        
        case "safeareaview":
            // SafeAreaView respects safe area bounds
            DynamicSafeAreaViewContainer(component: component, viewModel: viewModel, viewId: viewId)
        
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