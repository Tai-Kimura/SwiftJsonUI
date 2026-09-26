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
    /// The component as the layout gives it; `component` is what is built.
    let source: DynamicComponent
    let data: [String: Any]
    let viewId: String?
    let isWeightedChild: Bool
    let parentOrientation: String?

    /// Observe global configuration so that published theme-mode changes
    /// (`SwiftJsonUIConfiguration.setThemeMode(_:)`) recompose Dynamic views
    /// and re-resolve colors via `themedColorProvider`.
    @ObservedObject private var config = SwiftJsonUIConfiguration.shared

    /// Inside a component whose `userInteractionEnabled` is false, or a
    /// binding resolving false (TapAccessibility).
    @Environment(\.jsonuiInteractionStopped) private var stoppedAround

    /// The component built: marked when a component around it stops
    /// interaction, so its tap, its traits and the image rule read no tap.
    var component: DynamicComponent {
        stoppedAround ? source.markedStopped() : source
    }

    /// Draws `component` as it is. A layout starts at an entry that resolves
    /// its styles, includes and responsive overrides and stamps it —
    /// `DynamicView(jsonName:)`, `DynamicView(component:)`, or
    /// `JSONLayoutLoader.decodeComponent(from:)` on a dictionary already
    /// through them; this is for a node of a tree that did (a custom
    /// adapter's children).
    public init(component: DynamicComponent, data: [String: Any], viewId: String? = nil, isWeightedChild: Bool = false, parentOrientation: String? = nil) {
        self.source = component
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

        Group {
            if needsVisibilityWrapper {
                buildWithVisibility()
            } else {
                buildComponentWithModifiers()
            }
        }
        // A component with a tap handler is the nearest tappable for every
        // image rendered inside it (ImageAccessibility.role).
        .modifier(ImageTappableMark(
            node: ImageAccessibility.isTappable(component.rawData, stopped: stoppedAround) ? component.rawData : nil
        ))
        // A component whose userInteractionEnabled is false, or a binding
        // resolving false, stops everything built inside it (TapAccessibility).
        // Always applied, so a binding that flips keeps the subtree's identity.
        .environment(\.jsonuiInteractionStopped, stoppedAround || stopsInteraction)
    }

    /// `userInteractionEnabled` is false, or a binding resolving false.
    private var stopsInteraction: Bool {
        DynamicHelpers.resolveBool(
            source.typedAttributes(CommonAttributes.self).userInteractionEnabled, legacy: nil, data: data
        ) == false
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

    /// An app-registered component. A leaf given children: the build refuses
    /// this layout, so Debug says so in the component's place rather than
    /// drawing it without them.
    @ViewBuilder
    private func appComponent(_ adapter: CustomComponentAdapter, _ component: DynamicComponent) -> some View {
        if let refusal = LeafChildren.rejection(for: adapter, component: component) {
            Text("Error: \(refusal)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red)
                .cornerRadius(6)
                .onAppear { Logger.debug("[CustomComponentAdapter] \(refusal)") }
        } else {
            adapter.buildView(
                component: component,
                data: data,
                viewId: viewId,
                parentOrientation: parentOrientation
            )
        }
    }

    @ViewBuilder
    func buildView(from component: DynamicComponent) -> some View {
        // Debug audit: warn once per (type, key) about attributes that
        // were parsed from the layout but are not declared for the
        // component (typo, or a definitions gap) — they will never be
        // applied by the converter.
        let _ = JsonUIAttributeAudit.audit(component: component)
        let _ = UnresolvedStages.nameOnce(component)
        if component.include != nil {
            IncludeConverter.convert(component: component, data: data, viewId: viewId)
        } else if let type = component.type, let adapter = CustomComponentRegistry.shared.adapter(for: type) {
            // A type the app registered as its own component is taken before
            // the built-in cases, as sjui's codegen takes the app's converter
            // before its own. It was asked only in `default:`, so an app's own
            // component named like a built-in or one of its spellings — an
            // app's ProgressBar — was drawn in Debug as the built-in Progress
            // while the release build drew the app's (measured: the adapter
            // was not called).
            appComponent(adapter, component)
        } else if component.type != nil {
            // A type-synonym spelling (HStack, ProgressBar, WebView, …) is drawn
            // as its type, from the vendored table (TypeSynonyms) — after the
            // app's registry was asked, above, with the node as written.
            declaredComponent(drawn(component))
        } else {
            EmptyView()
        }
    }

    /// Called with the type of every node drawn as an unknown type (the red
    /// box) — a type neither declared nor a synonym, or one the declaration
    /// does not draw on this face (component_metadata.json `swift_dynamic`).
    /// Tests count them; nothing in the library sets it.
    public static var unknownTypeHandler: ((String) -> Void)?

    /// The types declaredComponent draws, as spelled (the SSoT's section
    /// names; CircleImage is a type-synonym spelling drawn as Image). The
    /// switch compared `type.lowercased()`, so "switch" was drawn as Switch
    /// on this path alone (4f's ruling, 1.9.0: case-sensitive).
    static let declaredTypes = ["Label", "Button", "TextField", "TextView", "Image", "CircleImage", "NetworkImage",
                                "View", "SafeAreaView", "ScrollView", "Switch", "CheckBox", "Radio", "Segment",
                                "SelectBox", "Slider", "Progress", "Indicator", "IconLabel", "Collection", "TabView",
                                "Embed", "Web", "GradientView", "Blur"]

    /// `component` as drawn: a type-synonym spelling rewritten by
    /// TypeSynonyms (its type, and the attributes the spelling means), decoded
    /// again from its raw data. Anything else is `component` itself.
    private func drawn(_ component: DynamicComponent) -> DynamicComponent {
        var raw = TypeSynonyms.canonicalize(component.rawData)
        // A declared alias section (EditText / Input -> TextField, Check ->
        // CheckBox, Toggle -> Switch: `_alias_of`, generated as
        // JsonUIComponentAliases) is drawn as its canonical section.
        if let type = (raw ?? component.rawData)["type"] as? String,
           let canonical = JsonUIComponentAliases.canonical(for: type) {
            var aliased = raw ?? component.rawData
            aliased["type"] = canonical
            raw = aliased
        }
        guard let raw = raw else { return component }
        do {
            let json = try JSONSerialization.data(withJSONObject: raw, options: [])
            let decoder = JSONDecoder()
            JsonUINormalization.apply(to: decoder, normalized: component.isNormalized)
            let decoded = try decoder.decode(DynamicComponent.self, from: json)
            let _ = JsonUIAttributeAudit.audit(component: decoded)
            // Decoded again: the mark it carried goes with it.
            return component.interactionStoppedAround ? decoded.markedStopped() : decoded
        } catch {
            Logger.debug("[TypeSynonyms] '\(component.type ?? "")' could not be decoded as "
                + "'\(raw["type"] ?? "")': \(error)")
            return component
        }
    }

    /// The canonical declared sections. They held synonym and alias
    /// spellings of their own, which drifted from the table and from
    /// KotlinJsonUI's cases; a spelling that is neither declared nor a
    /// synonym (Spacer, Triangle, …) is unknown.
    @ViewBuilder
    private func declaredComponent(_ component: DynamicComponent) -> some View {
        if let type = component.type {
            switch type {
            // Text components
            case "Label":
                LabelConverter.convert(component: component, data: data, parentOrientation: parentOrientation)

            case "Button":
                ButtonConverter.convert(component: component, data: data, parentOrientation: parentOrientation)

            // EditText / Input are component-name aliases of TextField
            // (attribute_definitions.json `_alias_of`)
            case "TextField":
                TextFieldConverter.convert(component: component, data: data)

            case "TextView":
                TextViewConverter.convert(component: component, data: data)

            // Image components. CircleImage / CircleImageView are Image
            // synonyms drawn as CircleImage (`render_as`), which
            // ImageViewConverter clips to a circle.
            case "Image", "CircleImage":
                ImageViewConverter.convert(component: component, data: data)

            case "NetworkImage":
                NetworkImageConverter.convert(component: component, data: data)

            // Container components
            case "View":
                DynamicViewContainer(component: component, data: data, viewId: viewId)

            case "SafeAreaView":
                DynamicSafeAreaViewContainer(component: component, data: data, viewId: viewId)

            case "ScrollView":
                DynamicScrollViewContainer(component: component, data: data, viewId: viewId)

            // No case for Spacer / Space / Divider / Separator. None of them is
            // a component type (attribute_definitions.json, component_metadata
            // .json), and codegen sends all four to DefaultConverter — the
            // "Unsupported component" Text any undeclared type gets. This
            // runtime used to draw them as a SwiftUI Spacer and Divider, so
            // DEBUG showed a screen the release build does not. They fall to
            // `default:` below with every other undeclared type.

            // Selection components
            case "Switch":
                ToggleConverter.convert(component: component, data: data)

            case "CheckBox":
                CheckboxConverter.convert(component: component, data: data)

            case "Radio":
                RadioConverter.convert(component: component, data: data)

            case "Segment":
                SegmentConverter.convert(component: component, data: data)

            case "SelectBox":
                SelectBoxConverter.convert(component: component, data: data)

            case "Slider":
                SliderConverter.convert(component: component, data: data)

            case "Progress":
                ProgressConverter.convert(component: component, data: data)

            case "Indicator":
                IndicatorConverter.convert(component: component, data: data)

            // Complex components
            case "IconLabel":
                IconLabelConverter.convert(component: component, data: data, viewId: viewId)

            case "Collection":
                CollectionConverter.convert(component: component, data: data, viewId: viewId)

            case "TabView":
                TabViewConverter.convert(component: component, data: data, viewId: viewId)

            case "Embed":
                EmbedConverter.convert(component: component, data: data, viewId: viewId)

            case "Web":
                WebConverter.convert(component: component, data: data)

            // Special effects
            case "GradientView":
                GradientViewConverter.convert(component: component, data: data, viewId: viewId)

            case "Blur":
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
                // The app's registry was asked first, above. A declared type
                // written in another case is unknown, as in the codegens, and
                // named with the spelling it may mean (TypeNameSpelling).
                let _ = TypeNameSpelling.nameOnce(
                    written: type,
                    declared: Self.declaredTypes.first { $0.caseInsensitiveCompare(type) == .orderedSame })
                let _ = Self.unknownTypeHandler?(type)
                Text("Error: Unknown component type '\(type)'")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(6)
            }
        }
    }
}
/// A node drawn with a stage not run on it — a `style` not applied, a
/// `responsive` block not resolved, an `include` not expanded — named once
/// per stage in DEBUG (4f's ruling on the entries that skip stages, 1.9.0).
/// The symptom, not the entry: the entries stamp and resolve, but a node a
/// stage does not walk to arrives the same way, and so does a style whose
/// file is missing.
enum UnresolvedStages {
    /// Hook for tests / apps; defaults to Logger.debug.
    static var warningHandler: ((String) -> Void)?
    /// The stages named already, this process (tests reset it).
    static var reported = Set<String>()
    private static let lock = NSLock()

    static func sentence(key: String, type: String) -> String {
        "'\(type)' is drawn with '\(key)' unresolved — it did not come through an entry that resolves it "
            + "(DynamicView(jsonName:), DynamicView(component:)), or its style file is missing"
    }

    static func unresolved(_ component: DynamicComponent) -> [String] {
        var keys: [String] = []
        if component.rawData["style"] is String { keys.append("style") }
        if component.rawData["responsive"] != nil { keys.append("responsive") }
        if component.include != nil { keys.append("include") }
        return keys
    }

    static func nameOnce(_ component: DynamicComponent) {
        for key in unresolved(component) {
            lock.lock()
            let first = reported.insert(key).inserted
            lock.unlock()
            guard first else { continue }
            let message = sentence(key: key, type: component.type ?? "include")
            if let warningHandler { warningHandler(message) } else { Logger.debug(message) }
        }
    }
}

// MARK: - Force re-evaluation when data dictionary changes
extension DynamicComponentBuilder: Equatable {
    public static func == (lhs: DynamicComponentBuilder, rhs: DynamicComponentBuilder) -> Bool { false }
}
#endif // DEBUG
