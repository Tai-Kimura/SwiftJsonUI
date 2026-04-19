//
//  DeveloperMenuContainer.swift
//  SwiftJsonUI
//
//  A container view that provides developer menu functionality:
//  - Double tap to show view selector
//  - Long press to toggle dynamic mode
//
//  In RELEASE builds, gestures are disabled and content is shown as-is.
//

import SwiftUI

/// Protocol for defining screens in the developer menu
public protocol DeveloperScreen: Hashable {
    var name: String { get }
}

/// Container view that wraps content with developer menu gestures
/// In DEBUG builds (when enabled = true): double tap shows view selector, long press toggles dynamic mode
/// In RELEASE builds or when enabled = false: just displays content without any developer features
public struct DeveloperMenuContainer<Screen: DeveloperScreen, Content: View>: View {
    @SwiftUI.Binding var currentScreen: Screen
    let screens: [Screen]
    let enabled: Bool
    let content: (Screen) -> Content

    #if DEBUG
    @ObservedObject private var viewSwitcher = ViewSwitcher.shared
    @State private var showViewSelector = false
    @State private var isSnackbarVisible = false
    @State private var snackbarMessage = ""
    #endif

    public init(
        currentScreen: SwiftUI.Binding<Screen>,
        screens: [Screen],
        enabled: Bool = true,
        @ViewBuilder content: @escaping (Screen) -> Content
    ) {
        self._currentScreen = currentScreen
        self.screens = screens
        self.enabled = enabled
        self.content = content
    }

    public var body: some View {
        #if DEBUG
        if !enabled {
            // Developer menu disabled, just show content
            content(currentScreen)
        } else {
        ZStack {
            // Main content with developer gestures
            content(currentScreen)
                .id(viewSwitcher.isDynamic)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            let newMode = !viewSwitcher.isDynamic
                            ViewSwitcher.setDynamicMode(newMode)
                            showSnackbar(message: newMode ? "Dynamic Mode: ON" : "Dynamic Mode: OFF")
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            showViewSelector = true
                        }
                )

            // Snackbar
            if isSnackbarVisible {
                VStack {
                    Spacer()
                    Text(snackbarMessage)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .sheet(isPresented: $showViewSelector) {
            DeveloperMenuSheet(
                currentScreen: $currentScreen,
                screens: screens,
                isDynamicMode: viewSwitcher.isDynamic,
                onDynamicModeToggle: {
                    let newMode = !viewSwitcher.isDynamic
                    ViewSwitcher.setDynamicMode(newMode)
                    showSnackbar(message: newMode ? "Dynamic Mode: ON" : "Dynamic Mode: OFF")
                },
                onDismiss: {
                    showViewSelector = false
                }
            )
            .presentationDetents([.medium])
        }
        } // else enabled
        #else
        // RELEASE: Just show content without any developer features
        content(currentScreen)
        #endif
    }

    #if DEBUG
    private func showSnackbar(message: String) {
        snackbarMessage = message
        withAnimation {
            isSnackbarVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isSnackbarVisible = false
            }
        }
    }
    #endif
}

#if DEBUG
/// Sheet view for developer menu (only available in DEBUG builds)
public struct DeveloperMenuSheet<Screen: DeveloperScreen>: View {
    @SwiftUI.Binding var currentScreen: Screen
    let screens: [Screen]
    let isDynamicMode: Bool
    let onDynamicModeToggle: () -> Void
    let onDismiss: () -> Void

    public init(
        currentScreen: SwiftUI.Binding<Screen>,
        screens: [Screen],
        isDynamicMode: Bool,
        onDynamicModeToggle: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self._currentScreen = currentScreen
        self.screens = screens
        self.isDynamicMode = isDynamicMode
        self.onDynamicModeToggle = onDynamicModeToggle
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationView {
            List {
                // Dynamic Mode Toggle
                Section {
                    HStack {
                        Text("Dynamic Mode")
                        Spacer()
                        Toggle("", isOn: SwiftUI.Binding(
                            get: { isDynamicMode },
                            set: { _ in onDynamicModeToggle() }
                        ))
                    }
                }

                // View Selection
                Section(header: Text("Select View")) {
                    ForEach(screens, id: \.self) { screen in
                        Button(action: {
                            currentScreen = screen
                            onDismiss()
                        }) {
                            HStack {
                                Text(screen == currentScreen ? "●" : "○")
                                    .foregroundColor(screen == currentScreen ? .blue : .gray)
                                Text(screen.name)
                                    .foregroundColor(screen == currentScreen ? .blue : .primary)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Developer Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        onDismiss()
                    }
                }
            }
        }
    }
}
#endif // DEBUG
