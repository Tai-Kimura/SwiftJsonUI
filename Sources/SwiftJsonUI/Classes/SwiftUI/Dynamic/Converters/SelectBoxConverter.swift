//
//  SelectBoxConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI SelectBoxView
//

import SwiftUI

// MARK: - SelectBox-specific modifiers (margins and border only)
// Corresponding to Generated code: selectbox_converter.rb
struct SelectBoxModifiers: ViewModifier {
    let component: DynamicComponent
    let viewModel: DynamicViewModel
    
    func body(content: Content) -> some View {
        // Debug log
        // Check if width/height were actually specified in JSON
        let hasWidthSpec = component.widthRaw != nil || component.width != nil
        let hasHeightSpec = component.heightRaw != nil || component.height != nil
        
        let width = (hasWidthSpec && component.width != nil && component.width != .infinity) ? component.width : nil
        let height = (hasHeightSpec && component.height != nil && component.height != .infinity) ? component.height : nil
        
        print("📦 [SelectBoxModifiers] Applying:")
        print("  - id: \(component.id ?? "no-id")")
        print("  - width: \(String(describing: width)) (raw: \(component.widthRaw ?? "nil"))")
        print("  - height: \(String(describing: height)) (raw: \(component.heightRaw ?? "nil"))")
        print("  - borderWidth: \(String(describing: component.borderWidth))")
        print("  - borderColor: \(String(describing: component.borderColor))")
        print("  - cornerRadius: \(String(describing: component.cornerRadius))")
        
        // Apply modifiers based on what was actually specified
        var modifiedContent = AnyView(
            content.padding(DynamicHelpers.getPadding(from: component))
        )
        
        // Apply min/max constraints if any were specified
        let maxWidth = (component.width == .infinity) ? CGFloat.infinity : component.maxWidth
        let maxHeight = (component.height == .infinity) ? CGFloat.infinity : component.maxHeight
        
        if component.minWidth != nil || maxWidth != nil || component.minHeight != nil || maxHeight != nil {
            modifiedContent = AnyView(
                modifiedContent.frame(
                    minWidth: component.minWidth,
                    maxWidth: maxWidth,
                    minHeight: component.minHeight,
                    maxHeight: maxHeight
                )
            )
        }
        
        // Apply exact size only if specified
        if width != nil || height != nil {
            modifiedContent = AnyView(
                modifiedContent.frame(
                    width: width,
                    height: height
                )
            )
        }
        
        return modifiedContent
            // Apply border after component's internal cornerRadius
            .overlay(getBorder())
            // Apply margins as outer padding
            .padding(DynamicHelpers.getMargins(from: component))
            .opacity(DynamicHelpers.getOpacity(from: component))
            .opacity(DynamicHelpers.isHidden(component) ? 0 : 1)
    }
    
    /// Get border overlay
    @ViewBuilder
    private func getBorder() -> some View {
        if let borderWidth = component.borderWidth,
           borderWidth > 0,
           let borderColorString = component.borderColor {
            let _ = print("📦 [SelectBoxModifiers] Creating border with width: \(borderWidth), color: \(borderColorString)")
            let borderColor = DynamicHelpers.colorFromHex(borderColorString) ?? .gray
            RoundedRectangle(cornerRadius: component.cornerRadius ?? 8)
                .stroke(borderColor, lineWidth: borderWidth)
        } else {
            let _ = print("📦 [SelectBoxModifiers] No border: width=\(String(describing: component.borderWidth)), color=\(String(describing: component.borderColor))")
            EmptyView()
        }
    }
    
}

public struct SelectBoxConverter {
    
    /// Convert DynamicComponent to SwiftUI SelectBoxView
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let id = component.id ?? "selectBox"
        let prompt = component.hint ?? component.placeholder
        let items = component.items ?? []
        
        // Determine select type based on selectItemType property
        let selectItemType: SelectBoxView.SelectItemType = {
            if let itemType = component.selectItemType, itemType.lowercased() == "date" {
                return .date
            }
            return .normal
        }()
        
        // Date picker settings
        let datePickerMode: SelectBoxView.DatePickerMode = {
            if let mode = component.datePickerMode {
                switch mode.lowercased() {
                case "time":
                    return .time
                case "datetime", "dateandtime":
                    return .dateTime
                default:
                    return .date
                }
            }
            return .date
        }()
        
        let datePickerStyle: SelectBoxView.DatePickerStyle = {
            if let style = component.datePickerStyle {
                switch style.lowercased() {
                case "wheel", "wheels":
                    return .wheel
                case "compact":
                    return .compact
                case "graphical", "inline":
                    return .graphical
                default:
                    return .automatic
                }
            }
            return .automatic
        }()
        
        let dateStringFormat = component.dateStringFormat ?? "yyyy-MM-dd"
        
        // Parse minimum and maximum dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let minimumDate = component.minimumDate.flatMap { dateFormatter.date(from: $0) }
        let maximumDate = component.maximumDate.flatMap { dateFormatter.date(from: $0) }
        
        return AnyView(
            SelectBoxView(
                id: id,
                prompt: prompt,
                fontSize: component.fontSize ?? 16,
                fontColor: DynamicHelpers.colorFromHex(component.fontColor) ?? .primary,
                backgroundColor: DynamicHelpers.colorFromHex(component.background) ?? Color(UIColor.systemGray6),
                cornerRadius: component.cornerRadius ?? 8,
                selectItemType: selectItemType,
                items: items,
                datePickerMode: datePickerMode,
                datePickerStyle: datePickerStyle,
                dateStringFormat: dateStringFormat,
                minimumDate: minimumDate,
                maximumDate: maximumDate
            )
            .modifier(SelectBoxModifiers(component: component, viewModel: viewModel))  // Margins and border only
        )
    }
}