//
//  DynamicComponentBuilder.swift
//  SwiftJsonUI
//
//  Main component builder for dynamic views.
//  Each converter is responsible for its own modifiers and events.
//  Builder only handles visibility/alignment wrapping.
//

import SwiftUI
#if DEBUG


// MARK: - Component Builder
public struct DynamicComponentBuilder: View {
    let component: DynamicComponent
    let data: [String: Any]
    let viewId: String?
    let isWeightedChild: Bool
    let parentOrientation: String?

    /// Observe global configuration so that published theme-mode changes
    /// (`SwiftJsonUIConfiguration.setThemeMode(_:)`) recompose Dynamic views
    /// and re-resolve colors via `themedColorProvider`.
    @ObservedObject private var config = SwiftJsonUIConfiguration.shared

    public init(component: DynamicComponent, data: [String: Any], viewId: String? = nil, isWeightedChild: Bool = false, parentOrientation: String? = nil) {
        self.component = component
        self.data = data
        self.viewId = viewId
        self.isWeightedChild = isWeightedChild
        self.parentOrientation = parentOrientation
    }

    public var body: some View {
        // Check if component needs visibility wrapper. `hidden` — literal or
        // binding-typed ("@{flag}" / "@{!flag}") — is the boolean shorthand
        // for visibility:"invisible" (canonical spec on every platform): the
        // view KEEPS its layout space, is not drawn, and is removed from the
        // accessibility tree. It must NOT collapse — collapsing is
        // visibility:"gone" only.
        let needsVisibilityWrapper = component.visibilitySpelling() != nil || component.commonBool(\.hidden) == true
            || bindingHiddenExpression != nil

        if needsVisibilityWrapper {
            buildWithVisibility()
        } else {
            buildComponentWithModifiers()
        }
    }

    /// The `hidden` value when it is a binding expression (a literal bool is
    /// carried by the `.value` case and never lands here).
    ///
    /// The generated extraction already separates the two forms, so this no
    /// longer has to re-detect a binding by looking at the raw string.
    private var bindingHiddenExpression: String? {
        guard let expression = component
            .typedAttributes(CommonAttributes.self).hidden?.bindingExpression
        else { return nil }
        return "@{\(expression)}"
    }

    @ViewBuilder
    private func buildWithVisibility() -> some View {
        if component.commonBool(\.hidden) == true {
            // hidden: true == visibility:"invisible" (space kept, not drawn,
            // accessibility-hidden) — NOT "gone".
            VisibilityWrapper("invisible") {
                buildComponentWithModifiers()
            }
        } else if let hiddenValue = bindingHiddenExpression {
            if let binding = DynamicBindingHelper.extractBoolBinding(from: hiddenValue, data: data) {
                ReactiveVisibilityWrapper(visibility: SwiftUI.Binding(
                    get: { binding.wrappedValue ? "invisible" : "visible" },
                    set: { _ in }
                )) {
                    buildComponentWithModifiers()
                }
            } else {
                // Plain value: re-resolves on every data-driven rebuild.
                VisibilityWrapper(
                    DynamicBindingHelper.resolveBool(hiddenValue, data: data, fallback: false)
                        ? "invisible" : "visible"
                ) {
                    buildComponentWithModifiers()
                }
            }
        } else if let visibilityValue = component.visibilitySpelling() {
            if let inner = DynamicBindingResolver.inner(of: visibilityValue) {
                let expression = DynamicBindingResolver.parse(inner)
                let rawValue = expression.negated
                    ? nil
                    : DynamicBindingResolver.lookupRaw(path: expression.path, in: data)
                // Check for SwiftUI.Binding<String> in data (reactive)
                if let binding = rawValue as? SwiftUI.Binding<String> {
                    let _ = Logger.debug("[Visibility] id=\(component.id ?? "?") varName=\(expression.path) → Binding<String>=\(binding.wrappedValue)")
                    ReactiveVisibilityWrapper(visibility: binding) {
                        buildComponentWithModifiers()
                    }
                } else {
                    // Fallback: unwrap Binding / plain value via the
                    // canonical lookup (dot paths and `??` defaults resolve)
                    let resolved: String? = {
                        if let b = rawValue as? SwiftUI.Binding<Bool> {
                            return b.wrappedValue ? "visible" : "gone"
                        }
                        if let b = DynamicBindingResolver.strictBool(rawValue) {
                            return b ? "visible" : "gone"
                        }
                        if let s = DynamicBindingResolver.stringify(rawValue) {
                            return s
                        }
                        if case .string(let fallback)? = expression.defaultLiteral {
                            return fallback
                        }
                        return nil
                    }()
                    let _ = Logger.debug("[Visibility] id=\(component.id ?? "?") varName=\(expression.path) → resolved=\(resolved ?? "nil")")
                    VisibilityWrapper(resolved) {
                        buildComponentWithModifiers()
                    }
                }
            } else {
                VisibilityWrapper(visibilityValue) {
                    buildComponentWithModifiers()
                }
            }
        } else {
            buildComponentWithModifiers()
        }
    }

    @ViewBuilder
    private func buildComponentWithModifiers() -> some View {
        let alignmentInfo = getComponentAlignmentInfo()
        let needsSpacerHandling = alignmentInfo.needsSpacerBefore || alignmentInfo.needsSpacerAfter

        if alignmentInfo.needsWrapper || needsSpacerHandling {
            buildAlignmentWrappedComponent(alignmentInfo: alignmentInfo)
        } else {
            // Each converter returns a fully-modified view (modifiers + events applied)
            buildView(from: component)
        }
    }

    @ViewBuilder
    private func buildAlignmentWrappedComponent(alignmentInfo: AlignmentInfo) -> some View {
        // Each converter returns a fully-modified view
        let modifiedView = buildView(from: component)

        if alignmentInfo.needsWrapper {
            if parentOrientation == "horizontal" {
                if alignmentInfo.needsSpacerBefore { Spacer() }
                VStack { modifiedView }
                    .frame(maxHeight: .infinity, alignment: alignmentInfo.wrapperAlignment)
                if alignmentInfo.needsSpacerAfter { Spacer() }
            } else if parentOrientation == "vertical" {
                if alignmentInfo.needsSpacerBefore { Spacer() }
                HStack { modifiedView }
                    .frame(maxWidth: .infinity, alignment: alignmentInfo.wrapperAlignment)
                if alignmentInfo.needsSpacerAfter { Spacer() }
            } else {
                modifiedView
            }
        } else {
            if alignmentInfo.needsSpacerBefore { Spacer() }
            modifiedView
            if alignmentInfo.needsSpacerAfter { Spacer() }
        }
    }

    // MARK: - Alignment Info

    private struct AlignmentInfo {
        var needsWrapper: Bool = false
        var wrapperAlignment: Alignment = .center
        var needsSpacerBefore: Bool = false
        var needsSpacerAfter: Bool = false
    }

    private func getComponentAlignmentInfo() -> AlignmentInfo {
        guard let parentOrientation = parentOrientation else {
            return AlignmentInfo()
        }

        var info = AlignmentInfo()
        // Read through the generated table, not the hand-written decode slot:
        // the slot is `Bool?` and a `@{expr}` decodes to nil there, so a bound
        // alignment placed nothing and the child stayed at the container's
        // default corner. Same `flag` shape RelativePositionConverter already
        // uses for the same eight attributes (plan 50 §4, group C).
        let common = component.typedAttributes(CommonAttributes.self)
        func flag(_ attr: AttrValue<Bool>?) -> Bool {
            DynamicHelpers.resolveBool(attr, legacy: nil, data: data) == true
        }

        if parentOrientation == "horizontal" {
            if flag(common.alignTop) {
                info.needsWrapper = true
                info.wrapperAlignment = .top
            } else if flag(common.alignBottom) {
                info.needsWrapper = true
                info.wrapperAlignment = .bottom
            } else if flag(common.centerVertical) {
                info.needsWrapper = true
                info.wrapperAlignment = .center
            }

            if flag(common.alignRight) {
                info.needsSpacerBefore = true
            } else if flag(common.alignLeft) {
                info.needsSpacerAfter = true
            } else if flag(common.centerHorizontal) || flag(common.centerInParent) {
                info.needsSpacerBefore = true
                info.needsSpacerAfter = true
            }

            if flag(common.centerInParent) {
                info.needsWrapper = true
                info.wrapperAlignment = .center
            }
        } else if parentOrientation == "vertical" {
            if flag(common.alignLeft) {
                info.needsWrapper = true
                info.wrapperAlignment = .leading
            } else if flag(common.alignRight) {
                info.needsWrapper = true
                info.wrapperAlignment = .trailing
            } else if flag(common.centerHorizontal) {
                info.needsWrapper = true
                info.wrapperAlignment = .center
            }

            if flag(common.alignBottom) {
                info.needsSpacerBefore = true
            } else if flag(common.alignTop) {
                info.needsSpacerAfter = true
            } else if flag(common.centerVertical) || flag(common.centerInParent) {
                info.needsSpacerBefore = true
                info.needsSpacerAfter = true
            }

            if flag(common.centerInParent) {
                info.needsWrapper = true
                info.wrapperAlignment = .center
            }
        }

        return info
    }

    // MARK: - Component Routing

    @ViewBuilder
    func buildView(from component: DynamicComponent) -> some View {
        // Debug audit: warn once per (type, key) about attributes that
        // were parsed from the layout but are not declared for the
        // component (typo, or a definitions gap) — they will never be
        // applied by the converter.
        let _ = JsonUIAttributeAudit.audit(component: component)
        if component.include != nil {
            IncludeConverter.convert(component: component, data: data, viewId: viewId)
        } else if let type = component.type {
            switch type.lowercased() {
            // Text components
            case "text", "label":
                LabelConverter.convert(component: component, data: data, parentOrientation: parentOrientation)

            case "button":
                ButtonConverter.convert(component: component, data: data, parentOrientation: parentOrientation)

            // EditText / Input are component-name aliases of TextField
            // (attribute_definitions.json `_alias_of`)
            case "textfield", "edittext", "input":
                TextFieldConverter.convert(component: component, data: data)

            case "textview":
                TextViewConverter.convert(component: component, data: data)

            // Image components
            case "image":
                ImageViewConverter.convert(component: component, data: data)

            case "networkimage":
                NetworkImageConverter.convert(component: component, data: data)

            // Container components
            case "view":
                DynamicViewContainer(component: component, data: data, viewId: viewId)

            case "safeareaview":
                DynamicSafeAreaViewContainer(component: component, data: data, viewId: viewId)

            case "scrollview", "scroll":
                DynamicScrollViewContainer(component: component, data: data, viewId: viewId)

            // Spacer and Divider
            case "spacer", "space":
                SpacerConverter.convert(component: component, data: data)

            case "divider", "separator":
                DividerConverter.convert(component: component, data: data)

            // Selection components
            case "toggle", "switch":
                ToggleConverter.convert(component: component, data: data)

            case "checkbox", "check":
                CheckboxConverter.convert(component: component, data: data)

            case "radio":
                RadioConverter.convert(component: component, data: data)

            case "segment", "segmentedcontrol":
                SegmentConverter.convert(component: component, data: data)

            case "picker":
                PickerConverter.convert(component: component, data: data)

            case "selectbox":
                SelectBoxConverter.convert(component: component, data: data)

            case "slider":
                SliderConverter.convert(component: component, data: data)

            case "progress", "progressbar":
                ProgressConverter.convert(component: component, data: data)

            case "indicator", "activityindicator":
                IndicatorConverter.convert(component: component, data: data)

            // Complex components
            case "iconlabel":
                IconLabelConverter.convert(component: component, data: data, viewId: viewId)

            case "collection":
                CollectionConverter.convert(component: component, data: data, viewId: viewId)

            case "table", "list":
                TableConverter.convert(component: component, data: data, viewId: viewId)

            case "tabview":
                TabViewConverter.convert(component: component, data: data, viewId: viewId)

            case "embed":
                EmbedConverter.convert(component: component, data: data, viewId: viewId)

            case "web", "webview":
                WebConverter.convert(component: component, data: data)

            // Special effects
            case "gradientview", "gradient":
                GradientViewConverter.convert(component: component, data: data, viewId: viewId)

            case "blur", "blurview":
                BlurConverter.convert(component: component, data: data, viewId: viewId)

            // Synthetic node for a child whose decode threw (see
            // DynamicDecodingHelper.decodeChildren) — render a visible
            // error box instead of letting the node vanish and the
            // sibling layout collapse.
            case DynamicDecodingHelper.decodeErrorType:
                let originalType = component.rawData["_originalType"] as? String
                let detail = [
                    originalType.map { "type '\($0)'" },
                    component.id.map { "id '\($0)'" }
                ].compactMap { $0 }.joined(separator: ", ")
                Text("Error: Failed to decode component"
                     + (detail.isEmpty ? "" : " (\(detail))"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(6)

            // Default/Unknown
            default:
                if let adapter = CustomComponentRegistry.shared.adapter(for: type) {
                    adapter.buildView(
                        component: component,
                        data: data,
                        viewId: viewId,
                        parentOrientation: parentOrientation
                    )
                } else {
                    Text("Error: Unknown component type '\(type)'")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(6)
                }
            }
        } else {
            EmptyView()
        }
    }
}
// MARK: - Force re-evaluation when data dictionary changes
extension DynamicComponentBuilder: Equatable {
    public static func == (lhs: DynamicComponentBuilder, rhs: DynamicComponentBuilder) -> Bool { false }
}
#endif // DEBUG
