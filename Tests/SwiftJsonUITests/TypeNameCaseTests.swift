import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
/// A component type is its SSoT spelling, case and all (4f's ruling, 1.9.0):
/// "switch" is not Switch, an app's "progressbar" is not its "ProgressBar".
/// The builder switched on `type.lowercased()` and the registry keyed both
/// sides lowercased, so Dynamic drew what no codegen draws. A spelling that
/// differs from a declared or registered type in case only is drawn as an
/// unknown type and named once (TypeNameSpelling), with the type it may mean.
final class TypeNameCaseTests: XCTestCase {
    private static var built: [String] = []
    private var said: [String] = []
    private var unknown: [String] = []

    private struct Probe: CustomComponentAdapter {
        let componentType: String
        func buildView(component: DynamicComponent, data: [String: Any], viewId: String?, parentOrientation: String?) -> AnyView {
            TypeNameCaseTests.built.append(componentType)
            return AnyView(Text("app \(componentType)"))
        }
    }

    override func setUp() {
        super.setUp()
        Self.built = []
        TypeNameSpelling.warningHandler = { [unowned self] in self.said.append($0) }
        DynamicComponentBuilder.unknownTypeHandler = { [unowned self] in self.unknown.append($0) }
    }

    override func tearDown() {
        TypeNameSpelling.warningHandler = nil
        DynamicComponentBuilder.unknownTypeHandler = nil
        CustomComponentRegistry.shared.reset()
        super.tearDown()
    }

    private func draw(_ json: String) throws {
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        let host = UIHostingController(rootView: DynamicComponentBuilder(component: component, data: [:]))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        window.isHidden = true
    }

    func testTheRegistryTakesATypeAsSpelled() {
        let written = "probeCaseType\(UUID().uuidString.prefix(6))"
        let declared = written.prefix(1).uppercased() + written.dropFirst()
        CustomComponentRegistry.shared.register(Probe(componentType: declared))
        XCTAssertNotNil(CustomComponentRegistry.shared.adapter(for: declared))
        XCTAssertNil(CustomComponentRegistry.shared.adapter(for: written))
        XCTAssertNil(CustomComponentRegistry.shared.adapter(for: written))
        XCTAssertEqual(said, ["Unknown component type '\(written)' — did you mean '\(declared)'? Type names are case-sensitive."])
    }

    func testADeclaredTypeInAnotherCaseIsUnknownAndNamed() throws {
        // A spelling no other test writes: named once per spelling.
        let declared = ["Switch", "Label", "SelectBox", "TextField"].randomElement()!
        var written = declared
        while written == declared || written == declared.lowercased() {
            written = declared.map { Bool.random() ? $0.uppercased() : $0.lowercased() }.joined()
        }
        try draw("{\"type\": \"\(written)\", \"text\": \"t\"}")
        XCTAssertEqual(unknown, [written])
        XCTAssertTrue(said.contains("Unknown component type '\(written)' — did you mean '\(declared)'? Type names are case-sensitive."), "\(said)")
    }

    func testTheDeclaredSpellingIsDrawn() throws {
        try draw(#"{"type": "View", "child": [{"type": "Label", "text": "a"}, {"type": "Switch", "isOn": false}]}"#)
        XCTAssertEqual(unknown, [])
        XCTAssertEqual(said, [])
    }

    func testAnAppTypeInAnotherCaseIsNotTheAppsAndIsNamed() throws {
        CustomComponentRegistry.shared.register(Probe(componentType: "ProbeShelfCase"))
        try draw(#"{"type": "probeshelfcase"}"#)
        XCTAssertEqual(Self.built, [])
        XCTAssertEqual(unknown, ["probeshelfcase"])
        XCTAssertEqual(said, ["Unknown component type 'probeshelfcase' — did you mean 'ProbeShelfCase'? Type names are case-sensitive."])
    }

    func testATypeDeclaredNowhereIsNamedWithoutASuggestion() throws {
        let written = "NoSuchType\(UUID().uuidString.prefix(6))"
        try draw("{\"type\": \"\(written)\"}")
        XCTAssertEqual(unknown, [written])
        XCTAssertEqual(said, ["Unknown component type '\(written)'"])
    }
}
#endif
