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
        content
            // SelectBoxView handles padding/background/cornerRadius internally
            // Only apply border and margins here
            .overlay(getBorder())  // Border after component's internal cornerRadius
            .padding(getMargins())  // Apply margins as outer padding
            .opacity(getOpacity())
            .opacity(isHidden() ? 0 : 1)
    }
    
    /// Get border overlay
    @ViewBuilder
    private func getBorder() -> some View {
        if let borderWidth = component.borderWidth,
           borderWidth > 0 {
            let borderColor = DynamicHelpers.colorFromHex(component.borderColor) ?? .gray
            RoundedRectangle(cornerRadius: component.cornerRadius ?? 8)
                .stroke(borderColor, lineWidth: borderWidth)
        }
    }
    
    private func getMargins() -> EdgeInsets {
        // Use margin properties for outer spacing
        let top = component.topMargin ?? 0
        let leading = component.leftMargin ?? 0
        let bottom = component.bottomMargin ?? 0
        let trailing = component.rightMargin ?? 0
        
        return EdgeInsets(
            top: top,
            leading: leading,
            bottom: bottom,
            trailing: trailing
        )
    }
    
    private func getOpacity() -> Double {
        if let opacity = component.opacity {
            return Double(opacity)
        }
        if let alpha = component.alpha {
            return Double(alpha)
        }
        return 1.0
    }
    
    private func isHidden() -> Bool {
        return component.hidden == true || component.visibility == "gone"
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