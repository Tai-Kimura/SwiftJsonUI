import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
/// Dynamic draws what the declaration says this face draws, and nothing else.
///
/// jsonui-cli's shared/core/component_metadata.json (vendored as a test
/// fixture; CI compares it with the pinned jsonui-cli ref) declares, per
/// component, the faces that draw it — `platforms.swift_dynamic` for this one.
/// A type it declares drawn here must not reach the unknown-type box; one it
/// declares not drawn here (CircleView: "For cross-platform layouts use View
/// with cornerRadius") must. The types are read from the declaration, not
/// listed: change the declaration and this follows it.
final class ComponentPlatformDeclarationTests: XCTestCase {

    /// What a type needs to draw at all. A type not listed needs nothing.
    private let extra: [String: String] = [
        "Label": #", "text": "t""#,
        "Button": #", "text": "t""#,
        "TextField": #", "text": "t""#,
        "EditText": #", "text": "t""#,
        "Input": #", "text": "t""#,
        "TextView": #", "text": "t""#,
        "Image": #", "srcName": "probe""#,
        "NetworkImage": #", "url": "https://example.invalid/x.png""#,
        "View": #", "child": [{"type": "Label", "text": "c"}]"#,
        "SafeAreaView": #", "child": [{"type": "Label", "text": "c"}]"#,
        "ScrollView": #", "child": [{"type": "Label", "text": "c"}]"#,
        "CircleView": #", "child": [{"type": "Label", "text": "c"}]"#,
        "Collection": #", "items": []"#,
        "SelectBox": #", "items": ["a", "b"]"#,
        "Segment": #", "items": ["a", "b"]"#,
        "Radio": #", "text": "r""#,
        "IconLabel": #", "text": "t""#,
        "Web": #", "url": "https://example.invalid/""#,
        "TabView": #", "tabs": [{"title": "a"}, {"title": "b"}]"#,
        "Embed": #", "screen": "probe_missing""#,
    ]

    override func tearDown() {
        DynamicComponentBuilder.unknownTypeHandler = nil
        super.tearDown()
    }

    /// The types drawn as unknown while `json` renders.
    @MainActor
    private func unknownTypes(_ json: String) throws -> [String] {
        var unknown: [String] = []
        DynamicComponentBuilder.unknownTypeHandler = { unknown.append($0) }
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        let renderer = ImageRenderer(content:
            DynamicComponentBuilder(component: component, data: [:]).frame(width: 320, height: 200))
        _ = renderer.uiImage
        return unknown
    }

    @MainActor
    func testEachTypeIsDrawnWhereTheDeclarationSaysAndUnknownWhereItDoesNot() throws {
        // control: the hook sees a type no case takes
        XCTAssertEqual(try unknownTypes(#"{"type": "ProbeUndeclaredType"}"#), ["ProbeUndeclaredType"])

        let data = try TestFixtures.loadJSON(named: "component_metadata")
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var drawnHere = 0, notDrawnHere = 0
        var mismatches: [String] = []
        for (type, value) in root.sorted(by: { $0.key < $1.key }) {
            guard let entry = value as? [String: Any],
                  let platforms = entry["platforms"] as? [String: Any],
                  let declared = platforms["swift_dynamic"] as? Bool else { continue }
            declared ? (drawnHere += 1) : (notDrawnHere += 1)
            let unknown = try unknownTypes(#"{"type": "\#(type)"\#(extra[type] ?? "")}"#).contains(type)
            if declared && unknown { mismatches.append("\(type): declared drawn here, drawn as unknown") }
            if !declared && !unknown { mismatches.append("\(type): declared not drawn here, drawn") }
        }
        XCTAssertGreaterThanOrEqual(drawnHere, 20, "the declaration's types were not read")
        XCTAssertEqual(mismatches, [], "Dynamic disagrees with component_metadata.json swift_dynamic")
        print("ComponentPlatformDeclarationTests: \(drawnHere) declared drawn, \(notDrawnHere) declared not drawn")
    }
}
#endif
