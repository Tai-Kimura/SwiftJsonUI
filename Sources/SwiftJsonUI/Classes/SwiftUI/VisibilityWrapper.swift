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
            // invisible: takes space but not visible
            content
                .opacity(0)
        case .visible:
            // visible: show normally
            content
        }
    }
}