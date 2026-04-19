import Foundation

// Test JSON
let testJSON = """
{
    "type": "View",
    "id": "parent",
    "width": "matchParent",
    "height": 120,
    "background": "#E0E0E0",
    "child": [
        {
            "type": "Label",
            "id": "child1",
            "text": "alignTop",
            "alignTop": true,
            "background": "#FFD0D0",
            "fontSize": 14,
            "padding": 8
        },
        {
            "type": "Label",
            "id": "child2",
            "text": "centerInParent",
            "centerInParent": true,
            "fontSize": 16
        }
    ]
}
"""

// Test decoding
let decoder = JSONDecoder()
if let data = testJSON.data(using: .utf8) {
    do {
        let component = try decoder.decode(DynamicComponent.self, from: data)
        print("✅ Successfully decoded component:")
        print("  Type: \(component.type)")
        print("  ID: \(component.id ?? "nil")")
        print("  Background: \(component.background ?? "nil")")
        
        if let child = component.child {
            if let array = child.value as? [DynamicComponent] {
                print("  Children count: \(array.count)")
                for (index, childComponent) in array.enumerated() {
                    print("    Child \(index):")
                    print("      Type: \(childComponent.type)")
                    print("      ID: \(childComponent.id ?? "nil")")
                    print("      Text: \(childComponent.text ?? "nil")")
                    print("      AlignTop: \(childComponent.alignTop ?? false)")
                    print("      CenterInParent: \(childComponent.centerInParent ?? false)")
                }
            }
        }
    } catch {
        print("❌ Decoding error: \(error)")
    }
}