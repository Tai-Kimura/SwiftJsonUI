//
//  AdvancedKeyboardAvoidingScrollView.swift
//  SwiftJsonUI
//
//  Created by SwiftJsonUI on 2025/01/11.
//

import SwiftUI

/// Advanced ScrollView with automatic scrolling to focused fields and SelectBox support
public struct AdvancedKeyboardAvoidingScrollView<Content: View>: View {
    @StateObject private var keyboardResponder = KeyboardResponder.shared
    @StateObject private var sheetResponder = SelectBoxSheetResponder.shared
    @StateObject private var focusTracker = FocusedFieldTracker.shared
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollProxy: ScrollViewProxy?
    @Namespace private var scrollSpace
    
    private let axes: Axis.Set
    private let showsIndicators: Bool
    private let configuration: KeyboardAvoidanceConfiguration
    private let content: Content
    
    public init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        configuration: KeyboardAvoidanceConfiguration = .default,
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.configuration = configuration
        self.content = content()
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(axes, showsIndicators: showsIndicators) {
                    VStack(alignment: .leading, spacing: 0) {
                        content
                            .environment(\.selectBoxScrollProxy, proxy)
                            .background(
                                GeometryReader { contentGeometry in
                                    Color.clear
                                        .preference(
                                            key: ContentFramePreferenceKey.self,
                                            value: contentGeometry.frame(in: .global)
                                        )
                                }
                            )
                        
                        // Dynamic spacer that adjusts to keyboard height
                        if configuration.isEnabled {
                            Spacer()
                                .frame(height: calculateSpacerHeight(in: geometry))
                                .id("keyboard_spacer")
                        }
                    }
                    .frame(minHeight: geometry.size.height)
                }
                .coordinateSpace(name: scrollSpace)
                .onAppear {
                    self.scrollProxy = proxy
                }
                .onPreferenceChange(ContentFramePreferenceKey.self) { _ in
                    // Content frame changed
                }
                .onChange(of: keyboardResponder.isKeyboardVisible) { isVisible in
                    handleKeyboardVisibilityChange(isVisible: isVisible, proxy: proxy, geometry: geometry)
                }
                .onChange(of: focusTracker.focusedFieldId) { fieldId in
                    if fieldId != nil && keyboardResponder.isKeyboardVisible {
                        scrollToFocusedField(proxy: proxy, geometry: geometry)
                    }
                }
                .onChange(of: sheetResponder.presentingSelectBoxId) { selectBoxId in
                    if let id = selectBoxId {
                        // Scroll to SelectBox when sheet is about to present
                        scrollToSelectBox(id: id, proxy: proxy)
                    }
                }
            }
        }
    }
    
    private func calculateSpacerHeight(in geometry: GeometryProxy) -> CGFloat {
        guard keyboardResponder.isKeyboardVisible else { return 0 }
        
        // Calculate the overlap between keyboard and scroll view
        let scrollViewBottom = geometry.frame(in: .global).maxY
        let keyboardTop = keyboardResponder.keyboardFrame.minY
        
        guard keyboardTop < scrollViewBottom else { return 0 }
        
        let overlap = scrollViewBottom - keyboardTop
        return overlap + configuration.additionalPadding
    }
    
    private func handleKeyboardVisibilityChange(isVisible: Bool, proxy: ScrollViewProxy, geometry: GeometryProxy) {
        guard configuration.autoScrollToFocused else { return }
        
        if isVisible {
            // Delay slightly to ensure keyboard frame is updated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrollToFocusedField(proxy: proxy, geometry: geometry)
            }
        }
    }
    
    private func scrollToFocusedField(proxy: ScrollViewProxy, geometry: GeometryProxy) {
        guard let focusedFieldId = focusTracker.focusedFieldId,
              configuration.autoScrollToFocused else { return }
        
        let focusedFrame = focusTracker.focusedFieldFrame
        let keyboardTop = keyboardResponder.keyboardFrame.minY
        let fieldBottom = focusedFrame.maxY + configuration.additionalPadding
        
        // Check if field is hidden by keyboard
        if fieldBottom > keyboardTop {
            withAnimation(.easeOut(duration: keyboardResponder.animationDuration)) {
                // Try to scroll to the field ID if it exists, otherwise scroll to spacer
                proxy.scrollTo(focusedFieldId, anchor: .bottom)
            }
        }
    }
    
    private func scrollToSelectBox(id: String, proxy: ScrollViewProxy) {
        withAnimation(.easeInOut(duration: 0.3)) {
            // Scroll to center the SelectBox in view
            proxy.scrollTo(id, anchor: .center)
        }
    }
}

/// Environment key for SelectBox scroll proxy
private struct SelectBoxScrollProxyKey: EnvironmentKey {
    static let defaultValue: ScrollViewProxy? = nil
}

public extension EnvironmentValues {
    var selectBoxScrollProxy: ScrollViewProxy? {
        get { self[SelectBoxScrollProxyKey.self] }
        set { self[SelectBoxScrollProxyKey.self] = newValue }
    }
}

/// PreferenceKey for tracking content frame
private struct ContentFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}