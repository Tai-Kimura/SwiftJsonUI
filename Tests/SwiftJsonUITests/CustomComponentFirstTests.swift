import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
/// A type the app registers as its own component (CustomComponentRegistry)
/// reaches its adapter before any built-in case, as sjui's codegen takes the
/// app's converter before its own — whatever the type is called: a built-in
/// name (Label), a built-in spelling (ProgressBar, which the builder switched
/// to the built-in Progress), a spelling of View in the type-synonym canon
/// (HStack).
///
/// Measured before the change (iOS 18.6): the adapter was not called for
/// ProgressBar, WebView or Scroll, and was for a type no built-in case takes.
/// An app's ProgressBar was drawn in Debug as the built-in Progress while its
/// release build drew the app's.
final class CustomComponentFirstTests: XCTestCase {
    private static var built: [String: Int] = [:]

    private struct Probe: CustomComponentAdapter {
        let componentType: String
        func buildView(component: DynamicComponent, data: [String: Any], viewId: String?, parentOrientation: String?) -> AnyView {
            CustomComponentFirstTests.built[componentType, default: 0] += 1
            return AnyView(Text("app \(componentType)"))
        }
    }

    /// Draws `json` through the builder and returns the types whose adapter
    /// built a view.
    private func draw(_ json: String) throws -> Set<String> {
        Self.built = [:]
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        let host = UIHostingController(rootView: DynamicComponentBuilder(component: component, data: [:]))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        window.isHidden = true
        return Set(Self.built.keys)
    }

    func testAnAppRegisteredTypeReachesItsAdapterFirst() throws {
        let types = ["ProgressBar", "Label", "HStack", "ProbeCustomType"]
        for t in types { CustomComponentRegistry.shared.register(Probe(componentType: t)) }
        // Registered here only: a registered Label would take every other
        // test's Label nodes. (CustomContainerAccessibilityTests registers its
        // own in its setUp.)
        defer { CustomComponentRegistry.shared.reset() }
        for t in types {
            XCTAssertEqual(try draw("{\"type\": \"\(t)\", \"text\": \"t\"}"), [t], "\(t) reaches the app's adapter")
        }
    }
}
#endif
