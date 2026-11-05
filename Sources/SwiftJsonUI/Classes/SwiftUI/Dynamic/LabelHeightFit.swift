import SwiftUI

#if DEBUG

private struct HeightBoundKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True under a node that bounds the height (a declared height or
    /// maxHeight, or a weight along a vertical stack), with no vertical
    /// ScrollView in between. sjui codegen: JsonToSwiftUIConverter
    /// mark_height_bounds, the same rule over the layout's tree.
    var jsonuiHeightBound: Bool {
        get { self[HeightBoundKey.self] }
        set { self[HeightBoundKey.self] = newValue }
    }
}

/// What a node does to `jsonuiHeightBound` for everything built inside it.
enum HeightBoundEffect {
    case inherit
    case bound
    /// A Collection's cells and an Embed's screen: generated on their own,
    /// so the generator's walk does not see the node around them.
    case cleared

    static func of(_ component: DynamicComponent, parentOrientation: String?, data: [String: Any]) -> HeightBoundEffect {
        if component.type == "Collection" || component.type == "Embed" { return .cleared }
        let common = component.typedAttributes(CommonAttributes.self)
        // matchParent is the screen's height, not a bound: a Label under it
        // that the screen has no room for runs on, as on Android.
        let raw = component.heightRaw?.lowercased()
        let fills = raw == "matchparent" || raw == "match_parent" || raw == "-1"
        if !fills, component.declaredHeight != nil { return .bound }
        if common.maxHeight != nil { return .bound }
        if let raw, raw.hasPrefix("@{") { return .bound }
        if component.rawAttribute("heightWeight") != nil { return .bound }
        if parentOrientation == "vertical",
           let weight = DynamicHelpers.resolveWeight(from: component, data: data), weight > 0 {
            return .bound
        }
        return .inherit
    }
}

struct HeightBoundMark: ViewModifier {
    let effect: HeightBoundEffect
    @Environment(\.jsonuiHeightBound) private var inherited

    func body(content: Content) -> some View {
        switch effect {
        case .inherit: content.environment(\.jsonuiHeightBound, inherited)
        case .bound: content.environment(\.jsonuiHeightBound, true)
        case .cleared: content.environment(\.jsonuiHeightBound, false)
        }
    }
}

/// A Label of height wrapContent keeps all its lines. A stack divides a finite
/// height among its children: a child whose text needs more than its share
/// shrinks, even with room left at the end of the screen (ticket
/// sjui-label-matchparent-wrapcontent-truncates-in-scroll: a 2-line question
/// next to its buttons drew 1 line and "…"). Under a node that bounds the
/// height the text stays inside it as before, and `lines` limits it as before.
/// sjui codegen: frame_helper.rb apply_label_wrap_height.
struct LabelWrapHeight: ViewModifier {
    @Environment(\.jsonuiHeightBound) private var bound

    func body(content: Content) -> some View {
        content.fixedSize(horizontal: false, vertical: !bound)
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
