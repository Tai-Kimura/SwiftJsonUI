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

    public init(component: DynamicComponent, data: [String: Any], viewId: String? = nil, isWeightedChild: Bool = false, parentOrientation: String? = nil) {
        self.component = component
        self.data = data
        self.viewId = viewId
        self.isWeightedChild = isWeightedChild
        self.parentOrientation = parentOrientation
    }

    public var body: some View {
        // Check if component needs visibility wrapper
        let needsVisibilityWrapper = component.visibility != nil || component.hidden == true

        if needsVisibilityWrapper {
            buildWithVisibility()
        } else {
            buildComponentWithModifiers()
        }
    }

    @ViewBuilder
    private func buildWithVisibility() -> some View {
        if component.hidden == true {
            VisibilityWrapper("gone") {
                buildComponentWithModifiers()
            }
        } else if let visibilityValue = component.visibility {
            if visibilityValue.hasPrefix("@{") && visibilityValue.hasSuffix("}") {
                let varName = String(visibilityValue.dropFirst(2).dropLast())
                // Check for SwiftUI.Binding<String> in data (reactive)
                if let binding = data[varName] as? SwiftUI.Binding<String> {
                    let _ = Logger.debug("[Visibility] id=\(component.id ?? "?") varName=\(varName) → Binding<String>=\(binding.wrappedValue)")
                    ReactiveVisibilityWrapper(visibility: binding) {
                        buildComponentWithModifiers()
                    }
                } else {
                    // Fallback: unwrap Binding or use plain value
                    let resolved: String? = {
                        if let b = data[varName] as? SwiftUI.Binding<Bool> {
                            return b.wrappedValue ? "visible" : "gone"
                        }
                        return data[varName] as? String
                    }()
                    let _ = Logger.debug("[Visibility] id=\(component.id ?? "?") varName=\(varName) → resolved=\(resolved ?? "nil") (dataType=\(data[varName].map { String(describing: type(of: $0)) } ?? "missing"))")
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

        if parentOrientation == "horizontal" {
            if component.alignTop == true {
                info.needsWrapper = true
                info.wrapperAlignment = .top
            } else if component.alignBottom == true {
                info.needsWrapper = true
                info.wrapperAlignment = .bottom
            } else if component.centerVertical == true {
                info.needsWrapper = true
                info.wrapperAlignment = .center
            }

            if component.alignRight == true {
                info.needsSpacerBefore = true
            } else if component.alignLeft == true {
                info.needsSpacerAfter = true
            } else if component.centerHorizontal == true || component.centerInParent == true {
                info.needsSpacerBefore = true
                info.needsSpacerAfter = true
            }

            if component.centerInParent == true {
                info.needsWrapper = true
                info.wrapperAlignment = .center
            }
        } else if parentOrientation == "vertical" {
            if component.alignLeft == true {
                info.needsWrapper = true
                info.wrapperAlignment = .leading
            } else if component.alignRight == true {
                info.needsWrapper = true
                info.wrapperAlignment = .trailing
            } else if component.centerHorizontal == true {
                info.needsWrapper = true
                info.wrapperAlignment = .center
            }

            if component.alignBottom == true {
                info.needsSpacerBefore = true
            } else if component.alignTop == true {
                info.needsSpacerAfter = true
            } else if component.centerVertical == true || component.centerInParent == true {
                info.needsSpacerBefore = true
                info.needsSpacerAfter = true
            }

            if component.centerInParent == true {
                info.needsWrapper = true
                info.wrapperAlignment = .center
            }
        }

        return info
    }

    // MARK: - Component Routing

    @ViewBuilder
    func buildView(from component: DynamicComponent) -> some View {
        if component.include != nil {
            IncludeConverter.convert(component: component, data: data, viewId: viewId)
        } else if let type = component.type {
            switch type.lowercased() {
            // Text components
            case "text", "label":
                LabelConverter.convert(component: component, data: data, parentOrientation: parentOrientation)

            case "button":
                ButtonConverter.convert(component: component, data: data, parentOrientation: parentOrientation)

            case "textfield":
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

            case "web", "webview":
                WebConverter.convert(component: component, data: data)

            // Special effects
            case "gradientview", "gradient":
                GradientViewConverter.convert(component: component, data: data, viewId: viewId)

            case "blur", "blurview":
                BlurConverter.convert(component: component, data: data, viewId: viewId)

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
