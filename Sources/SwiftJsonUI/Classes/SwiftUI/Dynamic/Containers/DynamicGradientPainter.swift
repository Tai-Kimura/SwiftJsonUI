//
//  DynamicGradientPainter.swift
//  SwiftJsonUI
//
//  One gradient fill implementation for every dynamic container that
//  declares `gradient`. It lived as private helpers inside
//  DynamicViewContainer, so SafeAreaView — which declares the same
//  attribute — drew nothing at all (SafeAreaView_gradient__static parity
//  d=207, run 31202080745). The fill-precedence contract travels with it:
//  callers must skip their colour background exactly when a gradient is
//  drawable (canon: attribute_semantics.json backgroundFill — one fill per
//  face, the more specific declaration wins).
//

import SwiftUI
#if DEBUG

enum DynamicGradientPainter {

    /// The gradient's colours, or nil when this component has no drawable
    /// gradient. `colorsRaw` is the caller's TYPED read of its own attribute
    /// table (the canonical array face); the legacy dictionary face is read
    /// here so both containers accept it identically.
    static func gradientColors(_ component: DynamicComponent, colorsRaw: [Any]?) -> [Color]? {
        let gradientDict = component.rawData["gradient"] as? [String: Any]
        let raw = colorsRaw?.compactMap { $0 as? String }
            ?? (gradientDict?["colors"] as? [String])
        guard let raw, !raw.isEmpty else { return nil }
        let colors = raw.compactMap { DynamicHelpers.getColor($0) }
        return colors.isEmpty ? nil : colors
    }

    /// Paint the gradient as the view's fill. `direction` is the caller's
    /// typed read of `gradientDirection` where its component declares one
    /// (View does, SafeAreaView does not — nil falls to the declared
    /// Vertical default).
    static func apply(
        _ view: AnyView,
        component: DynamicComponent,
        colorsRaw: [Any]?,
        direction: String?
    ) -> AnyView {
        let gradientDict = component.rawData["gradient"] as? [String: Any]
        guard let colors = gradientColors(component, colorsRaw: colorsRaw) else { return view }

        // An explicit start/end pair in the dictionary form outranks the
        // direction enum — it is the more specific statement about the same
        // axis.
        if let sp = gradientDict?["startPoint"] as? String,
           let ep = gradientDict?["endPoint"] as? String {
            return AnyView(view.background(LinearGradient(
                colors: colors,
                startPoint: unitPointFromString(sp),
                endPoint: unitPointFromString(ep)
            )))
        }

        let (start, end) = gradientEndpoints(direction)
        return AnyView(view.background(
            LinearGradient(colors: colors, startPoint: start, endPoint: end)
        ))
    }

    /// The declared `gradientDirection` vocabulary, in full. `RightToLeft`
    /// and `BottomToTop` are canonical values, NOT aliases — reversed
    /// directions, matched by the codegen face (modifier_helper.rb).
    static func gradientEndpoints(_ declared: String?) -> (UnitPoint, UnitPoint) {
        switch declared?.lowercased() {
        case "horizontal", "lefttoright": return (.leading, .trailing)
        case "oblique", "diagonal": return (.topLeading, .bottomTrailing)
        case "righttoleft": return (.trailing, .leading)
        case "bottomtotop": return (.bottom, .top)
        default: return (.top, .bottom)  // Vertical / TopToBottom, the default
        }
    }

    static func unitPointFromString(_ str: String) -> UnitPoint {
        switch str.lowercased() {
        case "top": return .top
        case "bottom": return .bottom
        case "leading", "left": return .leading
        case "trailing", "right": return .trailing
        case "topleft", "topleading": return .topLeading
        case "topright", "toptrailing": return .topTrailing
        case "bottomleft", "bottomleading": return .bottomLeading
        case "bottomright", "bottomtrailing": return .bottomTrailing
        case "center": return .center
        default: return .top
        }
    }
}
#endif // DEBUG
