//
//  DynamicModifierHelper.swift
//  SwiftJsonUI
//
//  Individual modifier methods that converters call in their own order.
//  Replaces CommonModifiers (unified application) with per-converter control.
//

import SwiftUI
#if DEBUG

public struct DynamicModifierHelper {

    // MARK: - 1. Padding (internal spacing)

    public static func applyPadding(_ view: AnyView, component: DynamicComponent) -> AnyView {
        var result = view

        // 1. Base padding (paddings array or scalar "padding"/"paddings")
        //    Tool: .padding(N) or .padding(.top, T).padding(.trailing, R)...
        if let paddingInsets = DynamicDecodingHelper.edgeInsetsFromAnyCodable(component.paddings) {
            if let scalar = component.paddings?.value as? Int {
                result = AnyView(result.padding(CGFloat(scalar)))
            } else if let scalar = component.paddings?.value as? Double {
                result = AnyView(result.padding(CGFloat(scalar)))
            } else if let arr = component.paddings?.value as? [Any] {
                switch arr.count {
                case 1:
                    let v = CGFloat(truncating: (arr[0] as? NSNumber) ?? 0)
                    result = AnyView(result.padding(v))
                case 2:
                    let vertical = CGFloat(truncating: (arr[0] as? NSNumber) ?? 0)
                    let horizontal = CGFloat(truncating: (arr[1] as? NSNumber) ?? 0)
                    result = AnyView(result.padding(.horizontal, horizontal).padding(.vertical, vertical))
                case 4:
                    // top, right, bottom, left
                    result = AnyView(result.padding(paddingInsets))
                default:
                    result = AnyView(result.padding(paddingInsets))
                }
            } else {
                result = AnyView(result.padding(paddingInsets))
            }
        }

        // 2. Individual padding overrides (STACKING, not replacing)
        //    Tool: .padding(.leading, N) added separately after base padding
        let startPad = component.paddingStart
        let endPad = component.paddingEnd
        let leftPad = component.paddingLeft
        let rightPad = component.paddingRight
        let topPad = component.paddingTop
        let bottomPad = component.paddingBottom

        if let v = startPad ?? leftPad, v != 0 {
            result = AnyView(result.padding(.leading, v))
        }
        if let v = endPad ?? rightPad, v != 0 {
            result = AnyView(result.padding(.trailing, v))
        }
        if let v = topPad, v != 0 {
            result = AnyView(result.padding(.top, v))
        }
        if let v = bottomPad, v != 0 {
            result = AnyView(result.padding(.bottom, v))
        }

        return result
    }

    // MARK: - 2. Frame Size (width/height)

    public static func applyFrameSize(_ view: AnyView, component: DynamicComponent, data: [String: Any] = [:]) -> AnyView {
        var result = view

        var width = component.width
        var height = component.height

        // WeightedStack: tool sets child's main-axis to matchParent before conversion.
        // Replicate by forcing matchParent here (inside the modifier chain, before background).
        let isWeightedChild = data["__isWeightedChild"] as? Bool ?? false
        let weightedParentOrientation = data["__weightedParentOrientation"] as? String
        if isWeightedChild {
            if weightedParentOrientation == "horizontal" {
                if width != .infinity && width != -1 {
                    width = .infinity
                }
            } else if weightedParentOrientation == "vertical" {
                if height != .infinity && height != -1 {
                    height = .infinity
                }
            }
        }

        // Apply fixed frame (finite positive values only)
        let fixedWidth = (width != nil && width != .infinity && width! > 0 && width!.isFinite) ? width : nil
        let fixedHeight = (height != nil && height != .infinity && height! > 0 && height!.isFinite) ? height : nil

        if fixedWidth != nil || fixedHeight != nil {
            result = AnyView(result.frame(width: fixedWidth, height: fixedHeight))
        }

        // matchParent (-1 or .infinity) → maxWidth/maxHeight: .infinity
        // For Label/Text, align based on textAlign (matches frame_helper.rb)
        // For other components, align based on gravity
        let isMatchParentWidth = (width == .infinity || width == -1)
        let isMatchParentHeight = (height == .infinity || height == -1)

        if component.type?.lowercased() == "collection" {
            let _ = Logger.debug("[applyFrameSize] id=\(component.id ?? "?") width=\(String(describing: width)) height=\(String(describing: height)) isMatchW=\(isMatchParentWidth) isMatchH=\(isMatchParentHeight)")
        }

        if isMatchParentWidth && isMatchParentHeight {
            if let alignment = frameAlignment(for: component, bothAxes: true) {
                result = AnyView(result.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment))
            } else {
                result = AnyView(result.frame(maxWidth: .infinity, maxHeight: .infinity))
            }
        } else if isMatchParentWidth {
            if let alignment = frameAlignment(for: component, bothAxes: false) {
                result = AnyView(result.frame(maxWidth: .infinity, alignment: alignment))
            } else {
                result = AnyView(result.frame(maxWidth: .infinity))
            }
        } else if isMatchParentHeight {
            result = AnyView(result.frame(maxHeight: .infinity))
        }

        return result
    }

    // MARK: - 3. Frame Constraints (min/max/ideal)

    public static func applyFrameConstraints(_ view: AnyView, component: DynamicComponent) -> AnyView {
        var result = view

        if let mw = component.minWidth {
            result = AnyView(result.frame(minWidth: mw))
        }
        if let mh = component.minHeight {
            result = AnyView(result.frame(minHeight: mh))
        }
        if let iw = component.idealWidth {
            result = AnyView(result.frame(idealWidth: iw))
        }
        if let ih = component.idealHeight {
            result = AnyView(result.frame(idealHeight: ih))
        }

        // maxWidth/maxHeight (only if not already handled by applyFrameSize for matchParent)
        let width = component.width
        let height = component.height
        let isMatchParentWidth = (width == .infinity || width == -1)
        let isMatchParentHeight = (height == .infinity || height == -1)

        if let mw = component.maxWidth, !isMatchParentWidth {
            result = AnyView(result.frame(maxWidth: mw))
        }
        if let mh = component.maxHeight, !isMatchParentHeight {
            result = AnyView(result.frame(maxHeight: mh))
        }

        // fixedSize for wrapContent + maxWidth/maxHeight
        let needsHFixed = (width == nil && component.maxWidth != nil && component.maxWidth != .infinity)
        let needsVFixed = (height == nil && component.maxHeight != nil && component.maxHeight != .infinity)
        if needsHFixed || needsVFixed {
            result = AnyView(result.fixedSize(
                horizontal: needsHFixed || (needsVFixed && width == nil),
                vertical: needsVFixed || (needsHFixed && height == nil)
            ))
        }

        return result
    }

    // MARK: - 4. Insets (insets, insetHorizontal, insetVertical)

    public static func applyInsets(_ view: AnyView, component: DynamicComponent) -> AnyView {
        var top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0

        if let insetInsets = DynamicDecodingHelper.edgeInsetsFromAnyCodable(component.insets) {
            top += insetInsets.top
            leading += insetInsets.leading
            bottom += insetInsets.bottom
            trailing += insetInsets.trailing
        }

        if let h = component.insetHorizontal {
            leading += h
            trailing += h
        }
        if let v = component.insetVertical {
            top += v
            bottom += v
        }

        if top != 0 || leading != 0 || bottom != 0 || trailing != 0 {
            return AnyView(view.padding(EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)))
        }
        return view
    }

    // MARK: - 5. Background

    public static func applyBackground(_ view: AnyView, component: DynamicComponent, data: [String: Any] = [:]) -> AnyView {
        // enabled=false + disabledBackground
        if component.enabled?.value as? Bool == false, let disabledBg = component.rawData["disabledBackground"] as? String,
           let color = DynamicHelpers.getColor(disabledBg) {
            return AnyView(view.background(color))
        }

        guard let background = component.background else { return view }

        // Check binding — getColor already handles SwiftUI.Binding unwrapping
        if let color = DynamicHelpers.getColor(background, data: data) {
            return AnyView(view.background(color))
        }

        // Try direct color name
        if let color = DynamicHelpers.getColor(background) {
            return AnyView(view.background(color))
        }

        return view
    }

    // MARK: - 6. Corner Radius

    public static func applyCornerRadius(_ view: AnyView, component: DynamicComponent) -> AnyView {
        guard let cornerRadius = component.cornerRadius, cornerRadius > 0 else { return view }
        return AnyView(view.cornerRadius(cornerRadius))
    }

    // MARK: - 7. Border

    public static func applyBorder(_ view: AnyView, component: DynamicComponent, data: [String: Any] = [:]) -> AnyView {
        guard let borderWidth = component.borderWidth, borderWidth > 0 else { return view }
        let borderColor = DynamicHelpers.getColor(component.borderColor, data: data) ?? .gray
        let radius = component.cornerRadius ?? 0
        return AnyView(view.overlay(
            RoundedRectangle(cornerRadius: radius)
                .stroke(borderColor, lineWidth: borderWidth)
        ))
    }

    // MARK: - 8. Margins (external spacing)

    public static func applyMargins(_ view: AnyView, component: DynamicComponent, data: [String: Any] = [:]) -> AnyView {
        let margins = DynamicHelpers.getMargins(from: component, data: data)
        if margins.top != 0 || margins.leading != 0 || margins.bottom != 0 || margins.trailing != 0 {
            return AnyView(view.padding(margins))
        }
        return view
    }

    // MARK: - 9. Opacity

    public static func applyOpacity(_ view: AnyView, component: DynamicComponent, data: [String: Any] = [:]) -> AnyView {
        // Check for binding expression in opacity or alpha
        let opacityStr = component.rawData["opacity"] as? String ?? component.rawData["alpha"] as? String
        if let opacityStr = opacityStr,
           opacityStr.hasPrefix("@{") && opacityStr.hasSuffix("}") {
            let propName = String(opacityStr.dropFirst(2).dropLast(1))
            if let binding = data[propName] as? SwiftUI.Binding<Double> {
                return AnyView(ReactiveOpacityWrapper(opacity: binding, content: view))
            }
            // Try plain numeric value from data
            if let value = data[propName] as? Double {
                return AnyView(view.opacity(value))
            }
            if let value = data[propName] as? CGFloat {
                return AnyView(view.opacity(Double(value)))
            }
            if let value = data[propName] as? Float {
                return AnyView(view.opacity(Double(value)))
            }
            if let value = data[propName] as? NSNumber {
                return AnyView(view.opacity(value.doubleValue))
            }
        }
        if let opacity = component.opacity {
            return AnyView(view.opacity(Double(opacity)))
        }
        if let alpha = component.alpha {
            return AnyView(view.opacity(Double(alpha)))
        }
        if component.visibility == "invisible" {
            return AnyView(view.opacity(0))
        }
        return view
    }

    // MARK: - 10. Shadow

    public static func applyShadow(_ view: AnyView, component: DynamicComponent) -> AnyView {
        guard let shadow = component.shadow, let shadowDict = shadow.value as? [String: Any] else { return view }

        let colorHex = shadowDict["color"] as? String ?? shadowDict["shadowColor"] as? String
        let radius = CGFloat(shadowDict["radius"] as? Double ?? shadowDict["shadowRadius"] as? Double ?? 5.0)
        let offsetX = CGFloat(shadowDict["offsetX"] as? Double ?? shadowDict["shadowOffsetX"] as? Double ?? 0.0)
        let offsetY = CGFloat(shadowDict["offsetY"] as? Double ?? shadowDict["shadowOffsetY"] as? Double ?? 0.0)
        let opacity = shadowDict["opacity"] as? Double ?? shadowDict["shadowOpacity"] as? Double ?? 0.3

        if let hex = colorHex, let color = DynamicHelpers.getColor(hex) {
            return AnyView(view.shadow(color: color.opacity(opacity), radius: radius, x: offsetX, y: offsetY))
        }
        return AnyView(view.shadow(color: Color.black.opacity(opacity), radius: radius, x: offsetX, y: offsetY))
    }

    // MARK: - 11. Clipped

    public static func applyClipped(_ view: AnyView, component: DynamicComponent) -> AnyView {
        guard component.clipToBounds == true else { return view }
        return AnyView(view.clipped())
    }

    // MARK: - 12. Offset

    public static func applyOffset(_ view: AnyView, component: DynamicComponent) -> AnyView {
        let x = component.rawData["offsetX"] as? CGFloat ?? 0
        let y = component.rawData["offsetY"] as? CGFloat ?? 0
        if x != 0 || y != 0 {
            return AnyView(view.offset(x: x, y: y))
        }
        return view
    }

    // MARK: - 13. Hidden

    public static func applyHidden(_ view: AnyView, component: DynamicComponent, data: [String: Any] = [:]) -> AnyView {
        if component.hidden == true || component.visibility == "gone" {
            return AnyView(view.hidden())
        }

        // Binding hidden: @{propertyName} or @{!propertyName}
        if let hiddenValue = component.rawData["hidden"] as? String,
           hiddenValue.hasPrefix("@{") && hiddenValue.hasSuffix("}") {
            // Try reactive SwiftUI.Binding<Bool> first
            if let binding = DynamicBindingHelper.extractBoolBinding(from: hiddenValue, data: data) {
                return AnyView(ReactiveHiddenWrapper(isHidden: binding, content: view))
            }
            // Fallback to plain value
            let isHidden = DynamicBindingHelper.resolveBool(hiddenValue, data: data, fallback: false)
            return AnyView(view.opacity(isHidden ? 0 : 1))
        }

        return view
    }

    // MARK: - 14. Tint

    public static func applyTint(_ view: AnyView, component: DynamicComponent, data: [String: Any] = [:]) -> AnyView {
        guard let tintColor = component.tintColor ?? component.tint,
              let color = DynamicHelpers.getColor(tintColor) else { return view }
        return AnyView(view.tint(color))
    }

    // MARK: - 15. Disabled

    public static func applyDisabled(_ view: AnyView, component: DynamicComponent, data: [String: Any] = [:]) -> AnyView {
        if component.enabled?.value as? Bool == false {
            return AnyView(view.disabled(true))
        }
        // Binding: @{!isEnabled} or @{isEnabled}
        if let enabledValue = component.rawData["enabled"] as? String,
           enabledValue.hasPrefix("@{") && enabledValue.hasSuffix("}") {
            // Try reactive SwiftUI.Binding<Bool> — negate for disabled
            if let enabledBinding = DynamicBindingHelper.extractBoolBinding(from: enabledValue, data: data) {
                let disabledBinding = SwiftUI.Binding<Bool>(
                    get: { !enabledBinding.wrappedValue },
                    set: { enabledBinding.wrappedValue = !$0 }
                )
                return AnyView(ReactiveDisabledWrapper(isDisabled: disabledBinding, content: view))
            }
            // Fallback to plain value
            let isEnabled = DynamicBindingHelper.resolveBool(enabledValue, data: data, fallback: true)
            if !isEnabled {
                return AnyView(view.disabled(true))
            }
        }
        return view
    }

    // MARK: - 16. Hit Testing

    public static func applyHitTesting(_ view: AnyView, component: DynamicComponent) -> AnyView {
        if component.userInteractionEnabled == false {
            return AnyView(view.allowsHitTesting(false))
        }
        if component.rawData["touchDisabledState"] != nil {
            return AnyView(view.allowsHitTesting(false))
        }
        return view
    }

    // MARK: - 17. Accessibility Identifier

    public static func applyAccessibilityId(_ view: AnyView, component: DynamicComponent) -> AnyView {
        guard let id = component.id else { return view }
        return AnyView(view.accessibilityIdentifier(id))
    }

    // MARK: - 18. ConfirmationDialog

    @available(iOS 15.0, *)
    public static func applyConfirmationDialog(_ view: AnyView, component: DynamicComponent, data: [String: Any]) -> AnyView {
        guard let dialogConfig = component.rawData["confirmationDialog"] as? [String: Any],
              let isPresentedBinding = dialogConfig["isPresented"] as? String,
              let propName = DynamicEventHelper.extractPropertyName(from: isPresentedBinding),
              let binding = data[propName] as? SwiftUI.Binding<Bool> else {
            return view
        }

        let title: String = {
            if let titleValue = dialogConfig["title"] as? String {
                if let resolved: String = DynamicBindingHelper.resolveValue(titleValue, data: data) {
                    return resolved
                }
                return titleValue
            }
            return ""
        }()

        let titleVisibility: SwiftUI.Visibility = {
            switch dialogConfig["titleVisibility"] as? String {
            case "visible": return .visible
            case "hidden": return .hidden
            default: return .automatic
            }
        }()

        let message: String? = {
            if let msgValue = dialogConfig["message"] as? String {
                if let resolved: String = DynamicBindingHelper.resolveValue(msgValue, data: data) {
                    return resolved
                }
                return msgValue
            }
            return nil
        }()

        // Build actions content
        let actionsContent: AnyView? = {
            if let layout = dialogConfig["layout"] as? [String: Any],
               let layoutName = layout["name"] as? String,
               let layoutDataBinding = layout["data"] as? String,
               let layoutDataVar = DynamicEventHelper.extractPropertyName(from: layoutDataBinding),
               let layoutData = data[layoutDataVar] as? [String: Any] {
                let jsonName = layoutName.hasSuffix(".json") ? String(layoutName.dropLast(5)) : layoutName
                return AnyView(DynamicView(jsonName: jsonName, data: layoutData))
            }
            if let actionsBindingStr = dialogConfig["actions"] as? String,
               let actionsVar = DynamicEventHelper.extractPropertyName(from: actionsBindingStr),
               let actionsClosure = data[actionsVar] as? (() -> AnyView) {
                return actionsClosure()
            }
            return nil
        }()

        guard let actions = actionsContent else { return view }

        if let msg = message {
            return AnyView(
                view.confirmationDialog(Text(title), isPresented: binding, titleVisibility: titleVisibility) {
                    actions
                } message: {
                    Text(msg)
                }
            )
        } else {
            return AnyView(
                view.confirmationDialog(Text(title), isPresented: binding, titleVisibility: titleVisibility) {
                    actions
                }
            )
        }
    }

    // MARK: - Standard Modifier Combination
    // Matches tool's base_view_converter.rb apply_modifiers order:
    // padding → frame_constraints → frame_size → insets → background → cornerRadius → border
    // → margins → opacity → shadow → clipped → offset → hidden
    // → safeAreaInsets → disabled → tag → hitTesting → tintColor
    // → onClick → lifecycle → confirmationDialog → accessibilityId

    public static func applyStandardModifiers(_ view: AnyView, component: DynamicComponent, data: [String: Any], skipPadding: Bool = false, skipInsets: Bool = false) -> AnyView {
        var result = view

        // 1. padding (skipped for relative positioning containers)
        if !skipPadding {
            result = applyPadding(result, component: component)
        }
        // 2. frame constraints
        result = applyFrameConstraints(result, component: component)
        // 3. frame size
        result = applyFrameSize(result, component: component, data: data)
        // 4. insets (skipped for Collection which handles insets with spacers)
        if !skipInsets {
            result = applyInsets(result, component: component)
        }
        // 5. background
        result = applyBackground(result, component: component, data: data)
        // 6. cornerRadius
        result = applyCornerRadius(result, component: component)
        // 7. border
        result = applyBorder(result, component: component, data: data)
        // 8. margins
        result = applyMargins(result, component: component, data: data)
        // 9. opacity
        result = applyOpacity(result, component: component, data: data)
        // 10. shadow
        result = applyShadow(result, component: component)
        // 11. clipped
        result = applyClipped(result, component: component)
        // 12. offset
        result = applyOffset(result, component: component)
        // 13. hidden
        result = applyHidden(result, component: component, data: data)
        // 14. disabled
        result = applyDisabled(result, component: component, data: data)
        // 15. hitTesting
        result = applyHitTesting(result, component: component)
        // 16. tint
        result = applyTint(result, component: component, data: data)
        // 17. onClick + lifecycle events
        result = DynamicEventHelper.applyEvents(result, component: component, data: data)
        // 18. confirmationDialog
        if #available(iOS 15.0, *) {
            result = applyConfirmationDialog(result, component: component, data: data)
        }
        // 19. accessibilityId
        result = applyAccessibilityId(result, component: component)

        return result
    }

    // MARK: - Frame Alignment Helper (matches frame_helper.rb)

    /// Determine frame alignment for matchParent dimensions.
    /// For Label/Text: based on textAlign (leading/center/trailing)
    /// For other components: based on gravity
    private static func frameAlignment(for component: DynamicComponent, bothAxes: Bool) -> Alignment? {
        let typeStr = component.type?.lowercased() ?? ""
        let isTextComponent = ["label", "text"].contains(typeStr)

        if isTextComponent {
            // Match frame_helper.rb: Label/Text use textAlign for frame alignment
            switch component.textAlign {
            case "center":
                return bothAxes ? .center : .center
            case "right":
                return bothAxes ? .topTrailing : .trailing
            default:
                return bothAxes ? .topLeading : .leading
            }
        }

        // Non-text components: use gravity (nil gravity = nil = SwiftUI default .center)
        return gravityToFrameAlignment(component.gravity, bothAxes: bothAxes)
    }

    /// Convert gravity array to SwiftUI Alignment (matches frame_helper.rb gravity_to_frame_alignment)
    /// Returns nil when gravity is not set, matching tool behavior (no alignment arg = SwiftUI default .center)
    private static func gravityToFrameAlignment(_ gravity: [String]?, bothAxes: Bool) -> Alignment? {
        guard let parts = gravity, !parts.isEmpty else { return nil }

        var h: String? = nil
        var v: String? = nil
        for g in parts {
            let gl = g.lowercased()
            switch gl {
            case "right", "end": h = "trailing"
            case "left", "start": h = "leading"
            case "centerhorizontal", "center_horizontal": h = "center"
            case "top": v = "top"
            case "bottom": v = "bottom"
            case "centervertical", "center_vertical": v = "center"
            case "center":
                h = "center"
                v = "center"
            default: break
            }
        }

        if bothAxes {
            let ha: HorizontalAlignment = {
                switch h {
                case "trailing": return .trailing
                case "center": return .center
                default: return .leading
                }
            }()
            let va: VerticalAlignment = {
                switch v {
                case "bottom": return .bottom
                case "center": return .center
                default: return .top
                }
            }()
            return Alignment(horizontal: ha, vertical: va)
        } else {
            switch h {
            case "trailing": return .trailing
            case "center": return .center
            default: return .leading
            }
        }
    }
}
#endif // DEBUG
