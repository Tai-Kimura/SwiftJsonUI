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

    public static func applyPadding(_ view: AnyView, component: DynamicComponent, data: [String: Any] = [:]) -> AnyView {
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
        //    Tool: .padding(.leading, N) added separately after base padding.
        //    Each override is number|binding — a `@{binding}` spelling left the
        //    legacy typed slot nil during decode, so resolve it from the typed
        //    CommonAttributes against `data` (falling back to the legacy value).
        let common = component.typedAttributes(CommonAttributes.self)
        let startPad = DynamicHelpers.resolveNumber(common.paddingStart, legacy: component.paddingStart, data: data)
        let endPad = DynamicHelpers.resolveNumber(common.paddingEnd, legacy: component.paddingEnd, data: data)
        let leftPad = DynamicHelpers.resolveNumber(common.paddingLeft ?? common.leftPadding, legacy: component.paddingLeft, data: data)
        let rightPad = DynamicHelpers.resolveNumber(common.paddingRight ?? common.rightPadding, legacy: component.paddingRight, data: data)
        let topPad = DynamicHelpers.resolveNumber(common.paddingTop ?? common.topPadding, legacy: component.paddingTop, data: data)
        let bottomPad = DynamicHelpers.resolveNumber(common.paddingBottom ?? common.bottomPadding, legacy: component.paddingBottom, data: data)

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
            // When both dimensions are fixed, apply gravity-based alignment so a
            // frame larger than its content honors gravity (matches frame_helper.rb:
            // .frame(width:, height:, alignment: gravity_to_frame_alignment)).
            let typeStr = component.type?.lowercased() ?? ""
            let isTextComponent = ["label", "text"].contains(typeStr)
            let hasDeclaredTextFrameAlign = isTextComponent &&
                (component.textAlign != nil || component.gravity != nil)
            if fixedWidth != nil && fixedHeight != nil,
               let alignment = frameAlignment(for: component, bothAxes: true) {
                result = AnyView(result.frame(width: fixedWidth, height: fixedHeight, alignment: alignment))
            } else if fixedWidth != nil, fixedHeight == nil, hasDeclaredTextFrameAlign,
                      let alignment = frameAlignment(for: component, bothAxes: false) {
                // Fixed width + wrapContent height on a text component honors
                // declared textAlign / gravity — frame_helper.rb's width-only
                // branch emits the alignment only when one of them is
                // declared, so a bare width stays at SwiftUI's implicit
                // center.
                result = AnyView(result.frame(width: fixedWidth, alignment: alignment))
            } else {
                result = AnyView(result.frame(width: fixedWidth, height: fixedHeight))
            }
        }

        // matchParent (-1 or .infinity) → maxWidth/maxHeight: .infinity
        // For Label/Text, align based on textAlign (matches frame_helper.rb)
        // For other components, align based on gravity
        let isMatchParentWidth = (width == .infinity || width == -1)
        let isMatchParentHeight = (height == .infinity || height == -1)

        if component.type?.lowercased() == "collection" {
            let _ = Logger.debug("[applyFrameSize] id=\(component.id ?? "?") width=\(String(describing: width)) height=\(String(describing: height)) isMatchW=\(isMatchParentWidth) isMatchH=\(isMatchParentHeight)")
        }

        // matchParent clamps to a declared max bound (canonical
        // size.maxBoundsClampFill, shared/core/attribute_semantics.json):
        // the fill frame carries the bound itself — .frame(maxWidth: 120)
        // IS min(parent, 120) — so no modifier-order game can lose it.
        // (applyFrameConstraints deliberately skips max bounds on
        // matchParent axes for the same reason.)
        let fillMaxWidth = component.maxWidth ?? .infinity
        let fillMaxHeight = component.maxHeight ?? .infinity

        if isMatchParentWidth && isMatchParentHeight {
            if let alignment = frameAlignment(for: component, bothAxes: true) {
                result = AnyView(result.frame(maxWidth: fillMaxWidth, maxHeight: fillMaxHeight, alignment: alignment))
            } else {
                result = AnyView(result.frame(maxWidth: fillMaxWidth, maxHeight: fillMaxHeight))
            }
        } else if isMatchParentWidth {
            if let alignment = frameAlignment(for: component, bothAxes: false) {
                result = AnyView(result.frame(maxWidth: fillMaxWidth, alignment: alignment))
            } else {
                result = AnyView(result.frame(maxWidth: fillMaxWidth))
            }
        } else if isMatchParentHeight {
            result = AnyView(result.frame(maxHeight: fillMaxHeight))
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
        // `disabledBackground` is string|binding: the raw String cast read a
        // bound spelling as a literal colour name, which resolves to nothing.
        if component.enabled?.value as? Bool == false,
           let disabledBg = component.typedAttributes(CommonAttributes.self)
               .disabledBackground?.rawRepresentation as? String,
           let color = DynamicHelpers.getColor(disabledBg, data: data) {
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

    public static func applyCornerRadius(_ view: AnyView, component: DynamicComponent, data: [String: Any] = [:]) -> AnyView {
        // cornerRadius is number|binding — resolve a `@{binding}` from data
        // (the legacy typed slot is nil for the binding spelling).
        let common = component.typedAttributes(CommonAttributes.self)
        guard let cornerRadius = DynamicHelpers.resolveNumber(common.cornerRadius, legacy: component.cornerRadius, data: data),
              cornerRadius > 0 else { return view }
        return AnyView(view.cornerRadius(cornerRadius))
    }

    // MARK: - 7. Border

    public static func applyBorder(_ view: AnyView, component: DynamicComponent, data: [String: Any] = [:]) -> AnyView {
        // borderWidth and cornerRadius are both number|binding — resolve any
        // `@{binding}` spelling from data before drawing the stroke overlay.
        let common = component.typedAttributes(CommonAttributes.self)
        guard let borderWidth = DynamicHelpers.resolveNumber(common.borderWidth, legacy: component.borderWidth, data: data),
              borderWidth > 0 else { return view }
        // Both attributes are required to draw: borderWidth alone means no
        // border (the canonical cross-platform semantics — android draws
        // nothing either). A declared-but-unresolvable color still falls
        // back to gray rather than silently dropping a declared border.
        guard component.borderColor != nil else { return view }
        let borderColor = DynamicHelpers.getColor(component.borderColor, data: data) ?? .gray
        let radius = DynamicHelpers.resolveNumber(common.cornerRadius, legacy: component.cornerRadius, data: data) ?? 0
        return AnyView(view.overlay(
            RoundedRectangle(cornerRadius: radius)
                .stroke(borderColor, lineWidth: borderWidth)
        ))
    }

    // MARK: - 8. Margins (external spacing)

    public static func applyMargins(_ view: AnyView, component: DynamicComponent, data: [String: Any] = [:]) -> AnyView {
        var result = view
        // ZStack children get their individual margins as a full-margin
        // offset from the parent container (DynamicViewContainer
        // zStackContent, the codegen contract) — padding here on top of
        // that double-applied them. The `margins` array is not part of the
        // offset computation and keeps its padding on every path.
        let offsetOwnsIndividuals = data["__zstackMarginChild"] as? Bool == true
            && component.margins == nil
        if !offsetOwnsIndividuals {
            let margins = DynamicHelpers.getMargins(from: component, data: data)
            if margins.top != 0 || margins.leading != 0 || margins.bottom != 0 || margins.trailing != 0 {
                result = AnyView(result.padding(margins))
            }
        } else {
            let insets = offsetOwnedMarginInsets(component: component, data: data)
            if insets.top != 0 || insets.leading != 0 || insets.bottom != 0 || insets.trailing != 0 {
                result = AnyView(result.padding(insets))
            }
        }
        return applyFlexibleMargins(result, component: component)
    }

    /// What a ZStack child still pads for itself once the parent's `.offset`
    /// has taken the individual margins.
    ///
    /// The offset carries the DIFFERENCE of the two opposing margins and
    /// nothing more, so that is all it can own: what the pair shares is a
    /// plain inset and still belongs here. Suppressing this padding outright
    /// annihilated symmetric margins — 10/10 offsets by zero, so the
    /// declaration rendered as no margin at all.
    ///
    /// An axis the child centres is disabled by the same contract entry
    /// (semantics.margins) and `zstackMarginOffset` zeroes it, so nothing is
    /// lifted there. start/endMargin are not consumed by the offset on any
    /// axis and keep their padding, re-derived alone — without the left/right
    /// fallback `getMargins` would apply.
    ///
    /// Internal rather than private so the split has a unit test: the AnyView
    /// it ends up on cannot be inspected.
    static func offsetOwnedMarginInsets(component: DynamicComponent, data: [String: Any]) -> EdgeInsets {
        let centersHorizontally = component.centerInParent == true || component.centerHorizontal == true
        let centersVertically = component.centerInParent == true || component.centerVertical == true
        let sharedHorizontal = centersHorizontally
            ? 0 : sharedMargin(component.leftMargin, component.rightMargin, data: data)
        let sharedVertical = centersVertically
            ? 0 : sharedMargin(component.topMargin, component.bottomMargin, data: data)
        let start = DynamicDecodingHelper.marginValueToCGFloat(component.startMargin, data: data)
        let end = DynamicDecodingHelper.marginValueToCGFloat(component.endMargin, data: data)
        return EdgeInsets(
            top: sharedVertical,
            leading: start != 0 ? start : sharedHorizontal,
            bottom: sharedVertical,
            trailing: end != 0 ? end : sharedHorizontal
        )
    }

    /// The inset two opposing margins have in common — the part a
    /// difference-carrying offset cannot express, and so the part that stays
    /// with padding (`SpacingHelper#margin_padding` splits it the same way).
    /// An undeclared opposite edge has nothing in common with anything, and
    /// mixed signs share no inset: both keep the offset-owns-everything
    /// behaviour by returning zero.
    private static func sharedMargin(_ value: AnyCodable?, _ opposite: AnyCodable?, data: [String: Any]) -> CGFloat {
        guard value != nil, opposite != nil else { return 0 }
        let a = DynamicDecodingHelper.marginValueToCGFloat(value, data: data)
        let b = DynamicDecodingHelper.marginValueToCGFloat(opposite, data: data)
        return max(0, min(a, b))
    }

    /// min/max{Start,End}Margin — a bounded margin rather than a fixed inset.
    /// A fixed margin on the same side wins, matching both UIKit and the
    /// generated-code path (`SpacingHelper#apply_flexible_margins`); `margins`
    /// covers every side, so it suppresses both.
    private static func applyFlexibleMargins(_ view: AnyView, component: DynamicComponent) -> AnyView {
        guard component.margins == nil else { return view }
        let common = component.typedAttributes(CommonAttributes.self)

        let leadingFixed = component.startMargin != nil || component.leftMargin != nil
        let trailingFixed = component.endMargin != nil || component.rightMargin != nil

        let minStart = leadingFixed ? nil : common.minStartMargin
        let maxStart = leadingFixed ? nil : common.maxStartMargin
        let minEnd = trailingFixed ? nil : common.minEndMargin
        let maxEnd = trailingFixed ? nil : common.maxEndMargin
        guard minStart != nil || maxStart != nil || minEnd != nil || maxEnd != nil else { return view }

        return AnyView(view.flexibleHorizontalMargin(
            minStart: minStart.map { CGFloat($0) },
            maxStart: maxStart.map { CGFloat($0) },
            minEnd: minEnd.map { CGFloat($0) },
            maxEnd: maxEnd.map { CGFloat($0) }
        ))
    }

    // MARK: - 9. Opacity

    public static func applyOpacity(_ view: AnyView, component: DynamicComponent, data: [String: Any] = [:]) -> AnyView {
        // Only the bound spelling is a String; a literal opacity decodes as a
        // number and falls through to the legacy path below. `alpha` needs no
        // special case any more — 49-E made it a declared alias, so the
        // generated lookup resolves it into `opacity` itself.
        let opacityStr = component.typedAttributes(CommonAttributes.self)
            .opacity?.rawRepresentation as? String
        if let opacityStr = opacityStr,
           let inner = DynamicBindingResolver.inner(of: opacityStr) {
            let expression = DynamicBindingResolver.parse(inner)
            let rawValue = expression.negated
                ? nil
                : DynamicBindingResolver.lookupRaw(path: expression.path, in: data)
            // Reactive Binding<Double> keeps its wrapper
            if let binding = rawValue as? SwiftUI.Binding<Double> {
                return AnyView(ReactiveOpacityWrapper(opacity: binding, content: view))
            }
            // Canonical number value context (dot-path / default / coercion)
            if let value = DynamicBindingResolver.resolveDouble(expression: inner, data: data) {
                return AnyView(view.opacity(value))
            }
        }
        if let opacity = component.opacity {
            return AnyView(view.opacity(Double(opacity)))
        }
        if let alpha = component.alpha, !component.isNormalized {
            return AnyView(view.opacity(Double(alpha)))
        }
        if component.visibility == "invisible" {
            // Full invisible mechanism, mirroring VisibilityWrapper /
            // applyHidden: a bare .opacity(0) keeps the view findable by
            // VoiceOver and UI tests. Normally the builder wraps first and
            // this branch never fires — it must still agree on the
            // semantics for builder-bypassing callers.
            return AnyView(
                view
                    .opacity(0)
                    .accessibilityElement(children: .ignore)
                    .accessibilityHidden(true)
            )
        }
        return view
    }

    // MARK: - 10. Shadow

    public static func applyShadow(_ view: AnyView, component: DynamicComponent) -> AnyView {
        guard let shadow = component.shadow else { return view }
        // The declared STRING form is the UIKit pipe contract
        // 'color|offsetX|offsetY|opacity|radius' — exactly five fields;
        // anything else draws nothing (SJUIViewCreator's count == 5 guard,
        // the canonical semantics all four render paths share).
        guard let shadowDict = shadow.value as? [String: Any] else {
            if let pipe = shadow.value as? String {
                let parts = pipe.components(separatedBy: "|")
                if parts.count == 5,
                   let color = DynamicHelpers.getColor(parts[0]),
                   let x = Double(parts[1]), let y = Double(parts[2]),
                   let opacity = Double(parts[3]), let radius = Double(parts[4]) {
                    return AnyView(view.shadow(
                        color: color.opacity(opacity),
                        radius: CGFloat(radius), x: CGFloat(x), y: CGFloat(y)
                    ))
                }
            }
            return view
        }

        // Object form mirrors sjui codegen (build_shadow_modifier): no
        // declared opacity leaves the colour at full strength, and no
        // declared colour falls through to SwiftUI's default shadow colour.
        let colorHex = shadowDict["color"] as? String ?? shadowDict["shadowColor"] as? String
        let radius = CGFloat(shadowDict["radius"] as? Double ?? shadowDict["shadowRadius"] as? Double ?? 5.0)
        let offsetX = CGFloat(shadowDict["offsetX"] as? Double ?? shadowDict["shadowOffsetX"] as? Double ?? 0.0)
        let offsetY = CGFloat(shadowDict["offsetY"] as? Double ?? shadowDict["shadowOffsetY"] as? Double ?? 0.0)
        let opacity = shadowDict["opacity"] as? Double ?? shadowDict["shadowOpacity"] as? Double

        if let hex = colorHex, let color = DynamicHelpers.getColor(hex) {
            let resolved = opacity.map { color.opacity($0) } ?? color
            return AnyView(view.shadow(color: resolved, radius: radius, x: offsetX, y: offsetY))
        }
        return AnyView(view.shadow(radius: radius, x: offsetX, y: offsetY))
    }

    // MARK: - 11. Clipped

    /// `clipToBounds` — literal or bound.
    ///
    /// The hand-decoded `component.clipToBounds` is nil for `@{expr}`, so a
    /// bound declaration never clipped. The generated extraction carries
    /// both forms, and `View.clipToBounds(_:)` is the same public seam the
    /// generated code calls — one rule, both paths.
    public static func applyClipped(
        _ view: AnyView,
        component: DynamicComponent,
        data: [String: Any] = [:]
    ) -> AnyView {
        let enabled = DynamicHelpers.resolveBool(
            component.typedAttributes(CommonAttributes.self).clipToBounds,
            legacy: component.clipToBounds,
            data: data
        ) ?? false
        return AnyView(view.clipToBounds(enabled))
    }

    // MARK: - 11a. safeAreaInsetPositions

    /// The edges that RESERVE the safe area.
    ///
    /// The name is the trap: `.ignoresSafeArea(edges:)` reads like the right
    /// modifier and does the opposite — it lets content spill INTO the safe
    /// area. `.safeAreaPadding` is the one that reserves it, which is what
    /// the SSoT, the web converter's `env(safe-area-inset-*)` padding and
    /// Compose's `windowInsetsPadding` all mean. 49-B moved
    /// `base_view_converter.rb#apply_safe_area_insets_to_bag` onto
    /// `.safeAreaPadding` for the same reason; this is the dynamic half,
    /// landing together so the two paths never disagree.
    ///
    /// It sits in the shared chain, not in the SafeAreaView container, because
    /// codegen applies it to EVERY component — the SSoT says so explicitly
    /// ("every platform honours the attribute on a PLAIN view too").
    public static func applySafeAreaInsets(_ view: AnyView, component: DynamicComponent) -> AnyView {
        guard let positions = component.typedAttributes(ViewAttributes.self).safeAreaInsetPositions
                ?? component.typedAttributes(SafeAreaViewAttributes.self).safeAreaInsetPositions,
              let edges = safeAreaEdgeSet(positions) else { return view }
        return AnyView(view.safeAreaPadding(edges))
    }

    /// The `Edge.Set` a declared position list selects, or nil when it selects
    /// none. Vocabulary matches `base_view_converter.rb` SAFE_AREA_EDGES,
    /// including the `left`/`right` spellings it accepts beyond the enum.
    static func safeAreaEdgeSet(_ positions: [Any]) -> Edge.Set? {
        let list = positions.compactMap { $0 as? String }.map { $0.lowercased() }
        if list.contains("all") { return .all }
        if list == ["none"] { return nil }

        var edges: Edge.Set = []
        for position in list {
            switch position {
            case "top": edges.insert(.top)
            case "bottom": edges.insert(.bottom)
            case "leading", "left": edges.insert(.leading)
            case "trailing", "right": edges.insert(.trailing)
            case "vertical": edges.insert(.vertical)
            case "horizontal": edges.insert(.horizontal)
            default: break
            }
        }
        return edges.isEmpty ? nil : edges
    }

    // MARK: - 11b. highlighted / highlightBackground

    /// The pressed-or-selected appearance, driven by the `highlighted` flag.
    ///
    /// UIKit swaps to `highlightBackgroundColor` when the flag is set
    /// (`SJUIView:187`). SwiftUI has no such state, so codegen emits the same
    /// swap conditionally (`base_view_converter.rb#apply_highlighted_to_bag`)
    /// — but nothing on the dynamic side read either half of the pair, even
    /// though `DynamicComponent` decodes both.
    ///
    /// Both halves are required: a `highlightBackground` with no `highlighted`
    /// describes a state that is never entered, which is why codegen returns
    /// early on either being absent.
    public static func applyHighlighted(
        _ view: AnyView,
        component: DynamicComponent,
        data: [String: Any] = [:]
    ) -> AnyView {
        let common = component.typedAttributes(CommonAttributes.self)
        guard let background = common.highlightBackground?.rawRepresentation as? String,
              let color = DynamicHelpers.getColor(background, data: data) else { return view }
        // `highlighted` is undeclared in the SSoT — codegen reads it anyway
        // (`@component['highlighted']`), so it comes through the raw
        // passthrough here. Flagged to 49-E; the declaration is the thing
        // that is wrong, not the read.
        guard DynamicBindingHelper.resolveBool(
            component.rawAttribute("highlighted"), data: data, fallback: false
        ) else { return view }
        return AnyView(view.background(color))
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

    // MARK: - 12b. zIndex (indexBelow / indexAbove)

    public static func applyZIndex(_ view: AnyView, component: DynamicComponent) -> AnyView {
        // Mirrors base_view_converter.rb: a numeric value becomes ∓N, a
        // view-ID reference degrades to ∓1 (SwiftUI has no relative z-order
        // between named siblings, only zIndex).
        func magnitude(_ raw: Any) -> Double {
            if let n = raw as? NSNumber { return n.doubleValue }
            if let s = raw as? String, let n = Double(s), s.range(of: #"^\d+$"#, options: .regularExpression) != nil {
                return n
            }
            return 1
        }
        if let below = component.rawData["indexBelow"] {
            return AnyView(view.zIndex(-magnitude(below)))
        }
        if let above = component.rawData["indexAbove"] {
            return AnyView(view.zIndex(magnitude(above)))
        }
        return view
    }

    // MARK: - 13. Hidden

    public static func applyHidden(_ view: AnyView, component: DynamicComponent, data: [String: Any] = [:]) -> AnyView {
        if component.visibility == "gone" {
            return AnyView(view.hidden())
        }
        // hidden == visibility:"invisible" (canonical spec): keep the layout
        // space, draw nothing, leave the accessibility tree. Collapsing is
        // "gone" only. This fallback is only reached off the builder path
        // (DynamicComponentBuilder wraps hidden in VisibilityWrapper).
        if component.hidden == true {
            return invisible(view)
        }

        // Binding hidden: @{propertyName} or @{!propertyName}
        if let expr = component.typedAttributes(CommonAttributes.self).hidden?.bindingExpression {
            let hiddenValue = "@{\(expr)}"
            // Try reactive SwiftUI.Binding<Bool> first
            if let binding = DynamicBindingHelper.extractBoolBinding(from: hiddenValue, data: data) {
                return AnyView(ReactiveHiddenWrapper(isHidden: binding, content: view))
            }
            // Plain value re-resolves on every data-driven rebuild.
            let isHidden = DynamicBindingHelper.resolveBool(hiddenValue, data: data, fallback: false)
            if isHidden {
                return invisible(view)
            }
            return view
        }

        return view
    }

    /// visibility:"invisible" mechanics — mirrors VisibilityWrapper's
    /// `.invisible` branch (space kept, not drawn, accessibility-hidden).
    private static func invisible(_ view: AnyView) -> AnyView {
        AnyView(
            view
                .opacity(0)
                .accessibilityElement(children: .ignore)
                .accessibilityHidden(true)
        )
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
        if let expr = component.typedAttributes(CommonAttributes.self).enabled?.bindingExpression {
            let enabledValue = "@{\(expr)}"
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

    public static func applyHitTesting(
        _ view: AnyView,
        component: DynamicComponent,
        data: [String: Any] = [:]
    ) -> AnyView {
        // boolean|binding — the hand-decoded slot is nil for `@{expr}`, so a
        // bound `userInteractionEnabled: false` never disabled hit testing.
        if DynamicHelpers.resolveBool(
            component.typedAttributes(CommonAttributes.self).userInteractionEnabled,
            legacy: component.userInteractionEnabled,
            data: data
        ) == false {
            return AnyView(view.allowsHitTesting(false))
        }
        if component.typedAttributes(CommonAttributes.self).touchDisabledState != nil {
            return AnyView(view.allowsHitTesting(false))
        }
        return view
    }

    // MARK: - 17. Accessibility Identifier

    /// Component types whose SwiftUI representation is a plain layout container
    /// (HStack/VStack/ZStack/ScrollView wrapper) that does not become an
    /// accessibility element on its own.
    /// `embed` is included because EmbedContainer is a plain wrapper view: a
    /// bare .accessibilityIdentifier on it is pushed down into the embedded
    /// screen and clobbers the identifier of that screen's root container
    /// (its nearest descendant element) — the embedded root id then never
    /// resolves in XCUITest while pane leaves still do. An id-bearing Embed
    /// always gets the merge-hazard anchor (subtree unknown, contribution 0).
    /// Keep in sync with sjui_tools BaseViewConverter::
    /// ACCESSIBILITY_CONTAINER_TYPES.
    private static let accessibilityContainerTypes: Set<String> = [
        "view", "safeareaview", "scrollview", "scroll",
        "blur", "blurview", "gradientview", "gradient",
        "embed"
    ]

    /// Component types guaranteed to surface at least one accessibility
    /// element of their own when visible (text, controls, images). Types not
    /// listed (Collection, Table, Web, TabView, includes, bare decorative
    /// views…) may yield zero elements at runtime and are conservatively not
    /// counted by `accessibilityMergeHazard`.
    /// Keep in sync with sjui_tools BaseViewConverter::
    /// CERTAIN_ACCESSIBILITY_ELEMENT_TYPES.
    private static let certainAccessibilityElementTypes: Set<String> = [
        "label", "text", "iconlabel", "button",
        "textfield", "edittext", "input", "textview",
        "image", "circleimage", "networkimage",
        "switch", "toggle", "checkbox", "check", "radio",
        "segment", "progress", "slider", "indicator", "selectbox"
    ]

    /// DEPTH BUDGET: the invisible anchor overlay is a secondary-child
    /// layout node; its evaluation recurses through the container content
    /// inline, so each anchored ancestor on a nesting path stays on the
    /// stack while descending (~2.4 KB per site measured at -Onone; AnyView
    /// erasure does NOT break this chain — plain modifiers stay at a
    /// constant stack cost, the overlay grows linearly). Emitted for every
    /// id-bearing container this exhausted the device main-thread stack on
    /// large screens (EXC_BAD_ACCESS code=2). The merge hazard the anchor
    /// guards against only exists when the container can end up with fewer
    /// than two accessibility children, so the anchor is only applied for
    /// those containers.
    ///
    /// Conservative approximation, kept in sync with sjui_tools
    /// BaseViewConverter#accessibility_merge_hazard?: a child contributes
    /// only when it is guaranteed present (no visibility binding /
    /// invisible / gone) and guaranteed to surface accessibility elements —
    /// a certain element type contributes 1, an id-bearing container
    /// contributes 1 (it becomes an explicit accessibility container
    /// itself), an id-less plain container contributes its own guaranteed
    /// children (promoted to the grandparent). Uncertainty errs toward
    /// emitting the anchor, never toward dropping a needed one.
    static func accessibilityMergeHazard(_ component: DynamicComponent) -> Bool {
        return guaranteedAccessibleChildCount(component) < 2
    }

    private static func guaranteedAccessibleChildCount(_ component: DynamicComponent) -> Int {
        return (component.childComponents ?? []).reduce(0) { count, child in
            count + guaranteedAccessibilityContribution(child)
        }
    }

    private static func guaranteedAccessibilityContribution(_ child: DynamicComponent) -> Int {
        if child.include != nil { return 0 } // unknown subtree
        if let visibility = child.visibility, visibility != "visible" { return 0 }
        let typeName = child.type?.lowercased() ?? ""
        if accessibilityContainerTypes.contains(typeName) {
            // id-bearing container: becomes an explicit accessibility
            // container (a single element) under applyAccessibilityId
            if child.id != nil { return 1 }
            // plain container: guaranteed descendants are promoted (2 is
            // enough — the caller only compares against 2)
            return min(guaranteedAccessibleChildCount(child), 2)
        }
        return certainAccessibilityElementTypes.contains(typeName) ? 1 : 0
    }

    public static func applyAccessibilityId(_ view: AnyView, component: DynamicComponent) -> AnyView {
        guard let id = component.id else { return view }
        let typeName = component.type?.lowercased() ?? ""
        // Statically invisible components must not become accessibility
        // elements at all — explicit accessibility containers ignore an
        // ancestor's .accessibilityHidden(true), so creating one here would
        // leave an invisible view findable by VoiceOver / UI tests.
        // (VisibilityWrapper hides the rest of the subtree.)
        if component.visibility == "invisible" {
            return view
        }
        if accessibilityContainerTypes.contains(typeName) {
            // Plain SwiftUI containers are not accessibility elements, so a bare
            // .accessibilityIdentifier is pushed down onto the nearest descendant
            // element — it never surfaces for the container itself and can
            // clobber a child's own identifier (e.g. a screen root "root" View
            // overwriting the id of the single control inside it).
            // Make the container an explicit accessibility container first; this
            // matches the UIKit path, where every UIView with an id is queryable
            // by XCUITest, and keeps all descendant elements accessible.
            //
            // The invisible zero-ish anchor overlay prevents SwiftUI from
            // merging two nested containers when the outer one has exactly one
            // accessibility child (the merge drops the inner container's
            // identifier): with the anchor the container has at least two
            // children, so it is never collapsed into its single child.
            // Only applied where that hazard exists — see
            // accessibilityMergeHazard (device stack-depth budget).
            if accessibilityMergeHazard(component) {
                return AnyView(
                    view
                        .overlay(alignment: .topLeading) {
                            SwiftUI.Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier(id)
                )
            }
            return AnyView(
                view
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(id)
            )
        }
        return AnyView(view.accessibilityIdentifier(id))
    }

    // MARK: - 18. ConfirmationDialog

    @available(iOS 15.0, *)
    public static func applyConfirmationDialog(_ view: AnyView, component: DynamicComponent, data: [String: Any]) -> AnyView {
        guard let dialogConfig = component.typedAttributes(CommonAttributes.self).confirmationDialog,
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

    public static func applyStandardModifiers(_ view: AnyView, component: DynamicComponent, data: [String: Any], skipPadding: Bool = false, skipInsets: Bool = false, skipBackground: Bool = false) -> AnyView {
        var result = view

        // 1. padding (skipped for relative positioning containers)
        if !skipPadding {
            result = applyPadding(result, component: component, data: data)
        }
        // 2. frame constraints
        result = applyFrameConstraints(result, component: component)
        // 3. frame size
        result = applyFrameSize(result, component: component, data: data)
        // 4. insets (skipped for Collection which handles insets with spacers)
        if !skipInsets {
            result = applyInsets(result, component: component)
        }
        // 5. background (skipped when the caller already painted it —
        // an empty View renders Rectangle().fill, the codegen leaf contract)
        if !skipBackground {
            result = applyBackground(result, component: component, data: data)
            // 5b. highlighted → highlightBackground, painted over the base
            // background exactly as UIKit swaps SJUIView's backgroundColor.
            result = applyHighlighted(result, component: component, data: data)
            // 5c. safeAreaInsetPositions — reserves the named edges.
            result = applySafeAreaInsets(result, component: component)
        }
        // 6. cornerRadius
        result = applyCornerRadius(result, component: component, data: data)
        // 7. border
        result = applyBorder(result, component: component, data: data)
        // 8. margins
        result = applyMargins(result, component: component, data: data)
        // 9. opacity
        result = applyOpacity(result, component: component, data: data)
        // 10. shadow
        result = applyShadow(result, component: component)
        // 11. clipped
        result = applyClipped(result, component: component, data: data)
        // 12. offset
        result = applyOffset(result, component: component)
        // 12b. zIndex (indexBelow / indexAbove)
        result = applyZIndex(result, component: component)
        // 13. hidden
        result = applyHidden(result, component: component, data: data)
        // 14. disabled
        result = applyDisabled(result, component: component, data: data)
        // 15. hitTesting
        result = applyHitTesting(result, component: component, data: data)
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
        // 20. disabled again, OUTSIDE the accessibility element. Step 14 put
        // .disabled inside the chain, but applyAccessibilityId creates the
        // container's a11y element on top of it — an element outside the
        // disabled environment never gets the notEnabled trait, so
        // XCUITest read the target as enabled (measured: the View-hosted
        // enabled__false conformance fixture). Re-applying outermost puts
        // the element inside the disabled environment. Double-application
        // is harmless.
        result = applyDisabled(result, component: component, data: data)

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
            switch component.textAlign?.lowercased() {
            case "center":
                return bothAxes ? .center : .center
            case "right", "trailing":
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
