//
//  ChildView.swift
//  SwiftJsonUI
//
//  Child view wrapper that applies visibility using VisibilityWrapper
//

import SwiftUI
#if DEBUG


// MARK: - Child View with Visibility
public struct ChildView: View {
    let component: DynamicComponent
    let data: [String: Any]
    let viewId: String?

    public init(component: DynamicComponent, data: [String: Any], viewId: String? = nil) {
        self.component = component
        self.data = data
        self.viewId = viewId
    }

    /// Data with weighted child flags stripped (for building children only)
    private var childData: [String: Any] {
        var d = data
        d.removeValue(forKey: "__isWeightedChild")
        d.removeValue(forKey: "__weightedParentOrientation")
        return d
    }

    public var body: some View {
        let visibility: String? = {
            if component.hidden == true {
                return "gone"
            }
            return component.visibility
        }()

        VisibilityWrapper(visibility) {
            DynamicComponentBuilder(component: component, data: childData, viewId: viewId)
        }
    }
}
// MARK: - Force re-evaluation when data dictionary changes
extension ChildView: Equatable {
    public static func == (lhs: ChildView, rhs: ChildView) -> Bool { false }
}
#endif // DEBUG
