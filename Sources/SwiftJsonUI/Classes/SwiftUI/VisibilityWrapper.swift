//
//  VisibilityWrapper.swift
//  SwiftJsonUI
//
//  Wrapper view that handles visibility states for all views
//

import SwiftUI

public enum Visibility: String {
    case visible = "visible"
    case invisible = "invisible"
    case gone = "gone"
    
    public init(from string: String?) {
        guard let string = string else {
            self = .visible
            return
        }
        self = Visibility(rawValue: string) ?? .visible
    }
}

public struct VisibilityWrapper<Content: View>: View {
    let visibility: Visibility
    let content: Content
    
    public init(_ visibility: Visibility = .visible, @ViewBuilder content: () -> Content) {
        self.visibility = visibility
        self.content = content()
    }
    
    public init(_ visibilityString: String?, @ViewBuilder content: () -> Content) {
        self.visibility = Visibility(from: visibilityString)
        self.content = content()
    }
    
    public var body: some View {
        switch visibility {
        case .gone:
            // gone: completely removed from layout
            EmptyView()
        case .invisible:
            // invisible: takes space but not visible — also hide it from
            // accessibility (VoiceOver / UI tests must not see an invisible
            // view). accessibilityHidden alone does not remove *explicit*
            // accessibility containers created inside the subtree, so first
            // collapse the subtree into a single anonymous element.
            // accessibilityHidden alone also leaves that element — with the
            // identifier from inside — in the tree XCUITest reads, so a UI test
            // still found the invisible view on screen (and `visible` held).
            // Replacing its accessibility representation with nothing takes it
            // out of that tree too: as on Android, an invisible view is not
            // found by its id. Drawing and the opacity animation are unchanged.
            content
                .opacity(0)
                .accessibilityElement(children: .ignore)
                .accessibilityHidden(true)
                .accessibilityRepresentation { EmptyView() }
        case .visible:
            // visible: show normally
            content
        }
    }
}