import SwiftUI

/// PreferenceKey for collecting view frames in a coordinate space
public struct ViewFramePreferenceKey: PreferenceKey {
    public static var defaultValue: [String: CGRect] = [:]
    
    public static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

/// Extension to make it easier to save view positions
public extension View {
    func saveFrame(id: String, in coordinateSpace: CoordinateSpace) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ViewFramePreferenceKey.self,
                    value: [id: geometry.frame(in: coordinateSpace)]
                )
            }
        )
    }
}