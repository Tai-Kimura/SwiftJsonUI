//
//  DynamicHelpers.swift
//  SwiftJsonUI
//
//  Helper functions for dynamic views
//

import SwiftUI

// MARK: - Helper Functions
public struct DynamicHelpers {
    
    public static func fontFromComponent(_ component: DynamicComponent) -> Font {
        let size = component.fontSize ?? 16
        let fontName = component.font
        
        if fontName == "bold" {
            return .system(size: size, weight: .bold)
        } else if let fontName = fontName {
            return .custom(fontName, size: size)
        } else {
            return .system(size: size)
        }
    }
    
    public static func colorFromHex(_ hex: String?) -> Color? {
        guard let hex = hex else { return nil }
        let cleanHex = hex.replacingOccurrences(of: "#", with: "")
        
        guard cleanHex.count == 6,
              let intValue = Int(cleanHex, radix: 16) else {
            return nil
        }
        
        let r = Double((intValue >> 16) & 0xFF) / 255.0
        let g = Double((intValue >> 8) & 0xFF) / 255.0
        let b = Double(intValue & 0xFF) / 255.0
        
        return Color(red: r, green: g, blue: b)
    }
    
    public static func paddingFromArray(_ padding: [CGFloat]?) -> EdgeInsets {
        guard let padding = padding else {
            return EdgeInsets()
        }
        
        switch padding.count {
        case 1:
            return EdgeInsets(top: padding[0], leading: padding[0], 
                            bottom: padding[0], trailing: padding[0])
        case 2:
            return EdgeInsets(top: padding[0], leading: padding[1], 
                            bottom: padding[0], trailing: padding[1])
        case 4:
            return EdgeInsets(top: padding[0], leading: padding[1], 
                            bottom: padding[2], trailing: padding[3])
        default:
            return EdgeInsets()
        }
    }
    
    public static func contentModeFromString(_ mode: String?) -> ContentMode {
        switch mode {
        case "AspectFill", "aspectFill":
            return .fill
        case "AspectFit", "aspectFit":
            return .fit
        default:
            return .fit
        }
    }
    
    public static func networkImageContentMode(_ mode: String?) -> NetworkImage.ContentMode {
        switch mode {
        case "AspectFill", "aspectFill":
            return .fill
        case "AspectFit", "aspectFit":
            return .fit
        case "center", "Center":
            return .center
        default:
            return .fit
        }
    }
    
    public static func renderingModeFromString(_ mode: String?) -> Image.TemplateRenderingMode? {
        switch mode {
        case "template", "Template":
            return .template
        case "original", "Original":
            return .original
        default:
            return nil
        }
    }
    
    public static func iconPositionFromString(_ position: String?) -> IconLabelView.IconPosition {
        switch position {
        case "top", "Top":
            return .top
        case "left", "Left":
            return .left
        case "right", "Right":
            return .right
        case "bottom", "Bottom":
            return .bottom
        default:
            return .left
        }
    }
    
    public static func textAlignmentFromString(_ alignment: String?) -> TextAlignment {
        switch alignment {
        case "Center", "center":
            return .center
        case "Left", "left":
            return .leading
        case "Right", "right":
            return .trailing
        default:
            return .leading
        }
    }
    
    public static func frameValue(_ value: String?) -> CGFloat? {
        switch value {
        case "matchParent":
            // SwiftUIでは.infinityを直接使わず、nilを返してmaxWidthで処理
            return nil
        case "wrapContent", nil:
            return nil
        default:
            if let doubleValue = Double(value ?? "") {
                return CGFloat(doubleValue)
            }
            return nil
        }
    }
    
    public static func isMatchParent(_ value: String?) -> Bool {
        return value == "matchParent"
    }
}

// MARK: - View Modifier Extension
extension View {
    @ViewBuilder
    public func applyDynamicModifiers(_ component: DynamicComponent) -> some View {
        let widthValue: String? = {
            switch component.width {
            case .single(let value):
                return value
            case .array(let values):
                return values.first
            case nil:
                return nil
            }
        }()
        let heightValue: String? = {
            switch component.height {
            case .single(let value):
                return value
            case .array(let values):
                return values.first
            case nil:
                return nil
            }
        }()
        
        self
            .frame(
                width: DynamicHelpers.frameValue(widthValue),
                height: DynamicHelpers.frameValue(heightValue)
            )
            .frame(
                minWidth: component.minWidth,
                maxWidth: DynamicHelpers.isMatchParent(widthValue) ? .infinity : 
                         (component.maxWidth == nil ? nil : DynamicHelpers.frameValue(component.maxWidth.map { "\($0)" })),
                minHeight: component.minHeight,
                maxHeight: DynamicHelpers.isMatchParent(heightValue) ? .infinity :
                         (component.maxHeight == nil ? nil : DynamicHelpers.frameValue(component.maxHeight.map { "\($0)" }))
            )
            .background(DynamicHelpers.colorFromHex(component.background) ?? Color.clear)
            .cornerRadius(component.cornerRadius ?? 0)
            .opacity(component.alpha ?? (component.visibility == "invisible" ? 0 : 1))
            .dynamicHidden(component.hidden == true || component.visibility == "gone")
            .disabled(component.userInteractionEnabled == false)
            .dynamicClipped(component.clipToBounds == true)
            .applyPadding(component)
            .applyMargin(component)
            .applyBorder(component)
            .applyShadow(component)
            .applyAspectRatio(component)
            .applyCenterInParent(component)
    }
    
    @ViewBuilder
    func dynamicHidden(_ hidden: Bool) -> some View {
        if hidden {
            self.hidden()
        } else {
            self
        }
    }
    
    @ViewBuilder
    func dynamicClipped(_ clipped: Bool) -> some View {
        if clipped {
            self.clipped()
        } else {
            self
        }
    }
    
    @ViewBuilder
    func applyBorder(_ component: DynamicComponent) -> some View {
        if let borderWidth = component.borderWidth,
           let borderColor = component.borderColor {
            let color = DynamicHelpers.colorFromHex(borderColor) ?? .clear
            let radius = component.cornerRadius ?? 0
            self.overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(color, lineWidth: borderWidth)
            )
        } else {
            self
        }
    }
    
    @ViewBuilder
    func applyShadow(_ component: DynamicComponent) -> some View {
        if let shadow = component.shadow,
           let shadowDict = shadow.value as? [String: Any] {
            let color = shadowDict["shadowColor"] as? String ?? "#000000"
            let radius = CGFloat(shadowDict["shadowRadius"] as? Double ?? 5.0)
            let offsetX = CGFloat(shadowDict["shadowOffsetX"] as? Double ?? 0.0)
            let offsetY = CGFloat(shadowDict["shadowOffsetY"] as? Double ?? 0.0)
            let opacity = shadowDict["shadowOpacity"] as? Double ?? 0.3
            
            self.shadow(
                color: (DynamicHelpers.colorFromHex(color) ?? Color.black).opacity(opacity),
                radius: radius,
                x: offsetX,
                y: offsetY
            )
        } else {
            self
        }
    }
    
    @ViewBuilder
    func applyAspectRatio(_ component: DynamicComponent) -> some View {
        if let aspectWidth = component.aspectWidth,
           let aspectHeight = component.aspectHeight,
           aspectHeight > 0 {
            let ratio = aspectWidth / aspectHeight
            self.aspectRatio(ratio, contentMode: .fit)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func applyCenterInParent(_ component: DynamicComponent) -> some View {
        if component.centerInParent == true {
            self.frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func applyPadding(_ component: DynamicComponent) -> some View {
        var view = self
        
        // padding または paddings プロパティ
        if let padding = component.padding ?? component.paddings {
            if let array = padding.value as? [Any] {
                let values = array.compactMap { $0 as? CGFloat ?? (($0 as? Double).map { CGFloat($0) }) ?? (($0 as? Int).map { CGFloat($0) }) }
                switch values.count {
                case 1:
                    view = AnyView(view.padding(values[0]))
                case 2:
                    view = AnyView(view.padding(.horizontal, values[1]).padding(.vertical, values[0]))
                case 4:
                    view = AnyView(view.padding(.top, values[0])
                        .padding(.trailing, values[1])
                        .padding(.bottom, values[2])
                        .padding(.leading, values[3]))
                default:
                    break
                }
            } else if let value = padding.value as? CGFloat {
                view = AnyView(view.padding(value))
            } else if let value = padding.value as? Double {
                view = AnyView(view.padding(CGFloat(value)))
            } else if let value = padding.value as? Int {
                view = AnyView(view.padding(CGFloat(value)))
            }
        }
        
        // 個別のpadding設定
        if let value = component.leftPadding ?? component.paddingLeft {
            view = AnyView(view.padding(.leading, value))
        }
        if let value = component.rightPadding ?? component.paddingRight {
            view = AnyView(view.padding(.trailing, value))
        }
        if let value = component.topPadding ?? component.paddingTop {
            view = AnyView(view.padding(.top, value))
        }
        if let value = component.bottomPadding ?? component.paddingBottom {
            view = AnyView(view.padding(.bottom, value))
        }
        
        // insets プロパティ
        if let insets = component.insets {
            if let array = insets.value as? [Any] {
                let values = array.compactMap { $0 as? CGFloat ?? (($0 as? Double).map { CGFloat($0) }) ?? (($0 as? Int).map { CGFloat($0) }) }
                switch values.count {
                case 1:
                    view = AnyView(view.padding(values[0]))
                case 2:
                    view = AnyView(view.padding(.vertical, values[0]).padding(.horizontal, values[1]))
                case 4:
                    view = AnyView(view.padding(.top, values[0])
                        .padding(.trailing, values[1])
                        .padding(.bottom, values[2])
                        .padding(.leading, values[3]))
                default:
                    break
                }
            }
        }
        
        // insetHorizontal
        if let value = component.insetHorizontal {
            view = AnyView(view.padding(.horizontal, value))
        }
        
        return view
    }
    
    @ViewBuilder
    func applyMargin(_ component: DynamicComponent) -> some View {
        var view = self
        
        // margin または margins プロパティ
        if let margin = component.margin ?? component.margins {
            if let array = margin.value as? [Any] {
                let values = array.compactMap { $0 as? CGFloat ?? (($0 as? Double).map { CGFloat($0) }) ?? (($0 as? Int).map { CGFloat($0) }) }
                switch values.count {
                case 1:
                    view = AnyView(view.padding(values[0]))
                case 2:
                    view = AnyView(view.padding(.vertical, values[0]).padding(.horizontal, values[1]))
                case 4:
                    view = AnyView(view.padding(.top, values[0])
                        .padding(.trailing, values[1])
                        .padding(.bottom, values[2])
                        .padding(.leading, values[3]))
                default:
                    break
                }
            } else if let value = margin.value as? CGFloat {
                view = AnyView(view.padding(value))
            } else if let value = margin.value as? Double {
                view = AnyView(view.padding(CGFloat(value)))
            } else if let value = margin.value as? Int {
                view = AnyView(view.padding(CGFloat(value)))
            }
        }
        
        // 個別のmargin設定
        if let value = component.topMargin {
            view = AnyView(view.padding(.top, value))
        }
        if let value = component.bottomMargin {
            view = AnyView(view.padding(.bottom, value))
        }
        if let value = component.leftMargin {
            view = AnyView(view.padding(.leading, value))
        }
        if let value = component.rightMargin {
            view = AnyView(view.padding(.trailing, value))
        }
        
        return view
    }
}