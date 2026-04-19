//
//  TabViewConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI TabView.
//  Rewritten to match tab_view_converter.rb modifier order.
//
//  Modifier order (matching Ruby converter):
//  1. TabView(selection:) { children.tabItem().badge().tag() }
//  2. .toolbarBackground() (tabBarBackground)
//  3. .toolbarBackground(.visible)
//  4. .onChange(onTabChange)
//  5. applyStandardModifiers()
//

import SwiftUI
#if DEBUG

public struct TabViewConverter {

    public static func convert(
        component: DynamicComponent,
        data: [String: Any],
        viewId: String? = nil
    ) -> AnyView {
        let tabs = component.tabs ?? []

        // Resolve selectedIndex binding
        let selectedIndexRaw = component.rawData["selectedIndex"] as? String
        let hasSelectionBinding = selectedIndexRaw != nil
            && selectedIndexRaw!.hasPrefix("@{") && selectedIndexRaw!.hasSuffix("}")
        let selectionBinding: SwiftUI.Binding<Int> = {
            if hasSelectionBinding {
                return DynamicBindingHelper.int(selectedIndexRaw, data: data)
            }
            return .constant(component.selectedIndex ?? 0)
        }()

        // Build tab item models
        var tabItems: [TabItemModel] = []
        for (index, tabDict) in tabs.enumerated() {
            tabItems.append(TabItemModel(
                id: index,
                title: tabDict["title"] as? String ?? "Tab \(index + 1)",
                icon: tabDict["icon"] as? String ?? "circle",
                selectedIcon: tabDict["selectedIcon"] as? String,
                iconType: tabDict["iconType"] as? String ?? "system",
                badge: tabDict["badge"],
                view: tabDict["view"] as? String
            ))
        }

        // Resolve tabBarBackground color
        let tabBarBackground: Color? = DynamicHelpers.getColor(component.tabBarBackground, data: data)

        // Resolve onTabChange callback
        var onTabChangeCallback: ((Int) -> Void)? = nil
        if let onTabChangeRaw = component.onTabChange,
           let propName = DynamicEventHelper.extractPropertyName(from: onTabChangeRaw) {
            onTabChangeCallback = data[propName] as? ((Int) -> Void)
        }

        var result = AnyView(
            TabViewWrapperView(
                tabItems: tabItems,
                selectionBinding: selectionBinding,
                tabBarBackground: tabBarBackground,
                onTabChangeCallback: onTabChangeCallback,
                component: component,
                data: data,
                viewId: viewId
            )
        )

        // 5. applyStandardModifiers (tintColor is handled inside applyStandardModifiers)
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }
}

// MARK: - Tab Item Model

private struct TabItemModel: Identifiable {
    let id: Int
    let title: String
    let icon: String
    let selectedIcon: String?
    let iconType: String
    let badge: Any?
    let view: String?
}

// MARK: - TabView Wrapper (manages @State internally for selection)

private struct TabViewWrapperView: View {
    let tabItems: [TabItemModel]
    @SwiftUI.Binding var selectedTab: Int
    let tabBarBackground: Color?
    let onTabChangeCallback: ((Int) -> Void)?
    let component: DynamicComponent
    let data: [String: Any]
    let viewId: String?

    init(
        tabItems: [TabItemModel],
        selectionBinding: SwiftUI.Binding<Int>,
        tabBarBackground: Color?,
        onTabChangeCallback: ((Int) -> Void)?,
        component: DynamicComponent,
        data: [String: Any],
        viewId: String?
    ) {
        self.tabItems = tabItems
        self._selectedTab = selectionBinding
        self.tabBarBackground = tabBarBackground
        self.onTabChangeCallback = onTabChangeCallback
        self.component = component
        self.data = data
        self.viewId = viewId
    }

    var body: some View {
        // 1. TabView(selection:) { children.tabItem().badge().tag() }
        TabView(selection: $selectedTab) {
            ForEach(tabItems) { item in
                tabContent(for: item)
                    .tabItem { tabItemLabel(for: item) }
                    .applyBadge(item.badge, data: data)
                    .tag(item.id)
            }
        }
        // 2. .toolbarBackground() (tabBarBackground)
        // 3. .toolbarBackground(.visible)
        .applyTabBarBackground(tabBarBackground)
        // 4. .onChange(onTabChange)
        .onChange(of: selectedTab) { _, newValue in
            onTabChangeCallback?(newValue)
        }
    }

    // MARK: - Tab Item Label

    @ViewBuilder
    private func tabItemLabel(for item: TabItemModel) -> some View {
        let isSelected = selectedTab == item.id
        let currentIcon = isSelected ? (item.selectedIcon ?? item.icon) : item.icon
        let hasDifferentIcons = item.selectedIcon != nil && item.selectedIcon != item.icon

        if item.iconType == "resource" {
            // Resource image from asset catalog
            if hasDifferentIcons {
                Label {
                    Text(item.title.dynamicLocalized())
                } icon: {
                    Image(currentIcon)
                        .renderingMode(.template)
                }
            } else {
                Label {
                    Text(item.title.dynamicLocalized())
                } icon: {
                    Image(item.icon)
                        .renderingMode(.template)
                }
            }
        } else {
            // SF Symbols (system)
            if hasDifferentIcons {
                Label {
                    Text(item.title.dynamicLocalized())
                } icon: {
                    Image(systemName: currentIcon)
                }
            } else {
                Label(item.title.dynamicLocalized(), systemImage: item.icon)
            }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private func tabContent(for item: TabItemModel) -> some View {
        if let viewName = item.view {
            if let adapter = CustomComponentRegistry.shared.adapter(for: viewName) {
                adapter.buildView(
                    component: component,
                    data: data,
                    viewId: "\(viewName)_tab_\(item.id)",
                    parentOrientation: "vertical"
                )
            } else {
                DynamicView(
                    jsonName: viewName,
                    viewId: "\(viewName)_tab_\(item.id)",
                    data: data
                )
            }
        } else {
            Text(item.title.dynamicLocalized())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - View Extensions for TabView modifiers

private extension View {

    @ViewBuilder
    func applyBadge(_ badge: Any?, data: [String: Any]) -> some View {
        if let badge = badge {
            if let intBadge = badge as? Int {
                self.badge(intBadge)
            } else if let stringBadge = badge as? String {
                if stringBadge.hasPrefix("@{") && stringBadge.hasSuffix("}") {
                    let bindingProp = String(stringBadge.dropFirst(2).dropLast())
                    if let boundValue = data[bindingProp] as? Int {
                        self.badge(boundValue)
                    } else if let boundValue = data[bindingProp] as? String {
                        self.badge(boundValue)
                    } else {
                        self
                    }
                } else {
                    self.badge(stringBadge)
                }
            } else {
                self
            }
        } else {
            self
        }
    }

    @ViewBuilder
    func applyTabBarBackground(_ bgColor: Color?) -> some View {
        if let color = bgColor {
            if #available(iOS 16.0, *) {
                self
                    .toolbarBackground(color, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar)
            } else {
                self
            }
        } else {
            self
        }
    }
}

#endif // DEBUG
