import SwiftUI

/// Container that manages relative positioning of child views
public struct RelativePositionContainer: View {
    public let children: [RelativeChildConfig]
    public let alignment: Alignment
    public let backgroundColor: Color?
    
    @State private var viewFrames: [String: CGRect] = [:]
    
    public init(
        children: [RelativeChildConfig],
        alignment: Alignment = .topLeading,
        backgroundColor: Color? = nil
    ) {
        self.children = children
        self.alignment = alignment
        self.backgroundColor = backgroundColor
        
        print("🚀 RelativePositionContainer initialized:")
        print("  - Children count: \(children.count)")
        print("  - Alignment: \(String(describing: alignment))")
        for child in children {
            print("  - Child \(child.id):")
            print("    - Constraints: \(child.constraints.count)")
            for constraint in child.constraints {
                print("      - \(constraint.type) -> \(constraint.targetId)")
            }
            print("    - Margins: \(child.margins)")
        }
    }
    
    public var body: some View {
        ZStack(alignment: alignment) {
            // Background color if specified
            if let backgroundColor = backgroundColor {
                backgroundColor.ignoresSafeArea()
            }
            
            // Render children with positioning
            ForEach(children) { child in
                child.view
                    .saveFrame(id: child.id, in: .named("container"))
                    .offset(calculateOffset(for: child))
                    .padding(child.margins)
            }
        }
        .coordinateSpace(name: "container")
        .onPreferenceChange(ViewFramePreferenceKey.self) { frames in
            print("📍 RelativePositionContainer - Frames updated:")
            for (id, frame) in frames {
                print("  - \(id): origin=(\(frame.origin.x), \(frame.origin.y)), size=(\(frame.size.width), \(frame.size.height))")
            }
            viewFrames = frames
        }
    }
    
    private func calculateOffset(for child: RelativeChildConfig) -> CGSize {
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0
        
        print("🎯 Calculating offset for child: \(child.id)")
        print("  - Constraints count: \(child.constraints.count)")
        
        for constraint in child.constraints {
            print("  - Processing constraint: \(constraint.type) -> \(constraint.targetId)")
            
            guard let targetFrame = viewFrames[constraint.targetId] else {
                print("    ⚠️ Target frame not found for: \(constraint.targetId)")
                continue
            }
            
            let childFrame = viewFrames[child.id]
            print("    - Target frame: origin=(\(targetFrame.origin.x), \(targetFrame.origin.y)), size=(\(targetFrame.size.width), \(targetFrame.size.height))")
            if let cf = childFrame {
                print("    - Child frame: origin=(\(cf.origin.x), \(cf.origin.y)), size=(\(cf.size.width), \(cf.size.height))")
            } else {
                print("    - Child frame: NOT FOUND")
            }
            
            switch constraint.type {
            case .alignTop:
                let offset = targetFrame.minY - (childFrame?.minY ?? 0)
                offsetY = offset
                print("    - alignTop: offsetY = \(offset)")
            case .alignBottom:
                let offset = targetFrame.maxY - (childFrame?.maxY ?? 0)
                offsetY = offset
                print("    - alignBottom: offsetY = \(offset)")
            case .alignLeft:
                let offset = targetFrame.minX - (childFrame?.minX ?? 0)
                offsetX = offset
                print("    - alignLeft: offsetX = \(offset)")
            case .alignRight:
                let offset = targetFrame.maxX - (childFrame?.maxX ?? 0)
                offsetX = offset
                print("    - alignRight: offsetX = \(offset)")
            case .above:
                let offset = targetFrame.minY - (childFrame?.maxY ?? 0) - constraint.spacing
                offsetY = offset
                print("    - above: offsetY = \(offset)")
            case .below:
                let offset = targetFrame.maxY - (childFrame?.minY ?? 0) + constraint.spacing
                offsetY = offset
                print("    - below: offsetY = \(offset)")
            case .leftOf:
                let offset = targetFrame.minX - (childFrame?.maxX ?? 0) - constraint.spacing
                offsetX = offset
                print("    - leftOf: offsetX = \(offset)")
            case .rightOf:
                let offset = targetFrame.maxX - (childFrame?.minX ?? 0) + constraint.spacing
                offsetX = offset
                print("    - rightOf: offsetX = \(offset)")
            }
        }
        
        print("  ✅ Final offset: (\(offsetX), \(offsetY))")
        return CGSize(width: offsetX, height: offsetY)
    }
}

/// Helper to create child configurations from JSON-like dictionaries
public extension RelativeChildConfig {
    static func from(
        dict: [String: Any],
        view: AnyView
    ) -> RelativeChildConfig? {
        guard let id = dict["id"] as? String else { return nil }
        
        var constraints: [RelativePositionConstraint] = []
        
        // Check for alignment constraints
        let constraintMappings: [(String, RelativePositionConstraint.ConstraintType)] = [
            ("alignTopOfView", .alignTop),
            ("alignBottomOfView", .alignBottom),
            ("alignLeftOfView", .alignLeft),
            ("alignRightOfView", .alignRight),
            ("alignTopView", .above),
            ("alignBottomView", .below),
            ("alignLeftView", .leftOf),
            ("alignRightView", .rightOf)
        ]
        
        for (key, type) in constraintMappings {
            if let targetId = dict[key] as? String {
                let spacing = CGFloat(dict["spacing"] as? Double ?? 0)
                constraints.append(RelativePositionConstraint(
                    type: type,
                    targetId: targetId,
                    spacing: spacing
                ))
            }
        }
        
        // Parse margins
        let topMargin = CGFloat(dict["topMargin"] as? Double ?? 0)
        let bottomMargin = CGFloat(dict["bottomMargin"] as? Double ?? 0)
        let leftMargin = CGFloat(dict["leftMargin"] as? Double ?? 0)
        let rightMargin = CGFloat(dict["rightMargin"] as? Double ?? 0)
        
        let margins = EdgeInsets(
            top: topMargin,
            leading: leftMargin,
            bottom: bottomMargin,
            trailing: rightMargin
        )
        
        // Parse size if specified
        var size: CGSize? = nil
        if let width = dict["width"] as? Double,
           let height = dict["height"] as? Double {
            size = CGSize(width: width, height: height)
        }
        
        return RelativeChildConfig(
            id: id,
            view: view,
            constraints: constraints,
            margins: margins,
            size: size
        )
    }
}