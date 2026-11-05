import SwiftUI

#if DEBUG

private struct InOpenScrollKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True inside a vertical ScrollView, with no node between it and here that
    /// bounds the height. sjui codegen: JsonToSwiftUIConverter mark_open_scroll,
    /// the same rule over the layout's tree.
    var jsonuiInOpenScroll: Bool {
        get { self[InOpenScrollKey.self] }
        set { self[InOpenScrollKey.self] = newValue }
    }
}

/// Ends `jsonuiInOpenScroll` for what a node builds inside it. A vertical
/// ScrollView starts it again (DynamicScrollViewContainer).
struct OpenScrollEnd: ViewModifier {
    let ends: Bool
    @Environment(\.jsonuiInOpenScroll) private var inherited

    func body(content: Content) -> some View {
        content.environment(\.jsonuiInOpenScroll, ends ? false : inherited)
    }

    static func ends(_ component: DynamicComponent, parentOrientation: String?, data: [String: Any]) -> Bool {
        // A Collection's cells and an Embed's screen are generated on their
        // own, so the generator's walk does not see the node around them.
        if component.type == "Collection" || component.type == "Embed" { return true }
        let common = component.typedAttributes(CommonAttributes.self)
        // matchParent inside a ScrollView takes the height the content has.
        let raw = component.heightRaw?.lowercased()
        let fills = raw == "matchparent" || raw == "match_parent" || raw == "-1"
        if !fills, component.declaredHeight != nil { return true }
        if common.maxHeight != nil { return true }
        if let raw, raw.hasPrefix("@{") { return true }
        if component.rawAttribute("heightWeight") != nil { return true }
        if parentOrientation == "vertical",
           let weight = DynamicHelpers.resolveWeight(from: component, data: data), weight > 0 {
            return true
        }
        return false
    }
}

/// A Label of height wrapContent inside a vertical ScrollView keeps all its
/// lines. A stack divides a finite height among its children: a child whose
/// text needs more than its share shrinks, even with room left at the end of
/// the screen (ticket sjui-label-matchparent-wrapcontent-truncates-in-scroll: a
/// 2-line question next to its buttons drew 1 line and "..."). There the content
/// can grow. Outside a ScrollView it cannot: the text would push what is below
/// it off a screen that does not scroll, so it stays as it was, as it does under
/// a node that bounds the height, and `lines` limits it as before.
/// sjui codegen: frame_helper.rb apply_label_wrap_height.
struct LabelWrapHeight: ViewModifier {
    @Environment(\.jsonuiInOpenScroll) private var inOpenScroll

    func body(content: Content) -> some View {
        content.fixedSize(horizontal: false, vertical: inOpenScroll)
    }

    /// height wrapContent; a node with a min or max goes through
    /// applyFrameConstraints' own fixedSize, a vertical weight gets its
    /// height from the stack.
    static func applies(to component: DynamicComponent, parentOrientation: String?, data: [String: Any]) -> Bool {
        guard component.declaredHeight == nil else { return false }
        if let raw = component.heightRaw, raw.lowercased() != "wrapcontent", raw.lowercased() != "wrap_content" { return false }
        let common = component.typedAttributes(CommonAttributes.self)
        if common.minWidth != nil || common.maxWidth != nil || common.minHeight != nil || common.maxHeight != nil { return false }
        if component.rawAttribute("heightWeight") != nil { return false }
        if parentOrientation == "vertical",
           let weight = DynamicHelpers.resolveWeight(from: component, data: data), weight > 0 {
            return false
        }
        return true
    }
}

#endif // DEBUG
