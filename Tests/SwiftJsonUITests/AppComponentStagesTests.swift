import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
/// An app component's adapter applies the common stages its node declares
/// (DynamicModifierHelper.applyStandardModifiers), as a generated adapter
/// does; DynamicComponentBuilder does not. An adapter that does not is named
/// once per type, and one that does is not.
///
/// Measured before (iOS 26.5): a ProgressBar drawn by an adapter that applies
/// nothing got no onAppear, and nothing said so; drawn by one that applies
/// the standard modifiers, its onAppear was called with `progressBar_0_1`.
final class AppComponentStagesTests: XCTestCase {
    private struct Bare: CustomComponentAdapter {
        let componentType: String
        func buildView(component: DynamicComponent, data: [String: Any], viewId: String?, parentOrientation: String?) -> AnyView {
            AnyView(Text("app \(componentType)"))
        }
    }

    private struct Standard: CustomComponentAdapter {
        let componentType: String
        func buildView(component: DynamicComponent, data: [String: Any], viewId: String?, parentOrientation: String?) -> AnyView {
            DynamicModifierHelper.applyStandardModifiers(AnyView(Text("app \(componentType)")), component: component, data: data)
        }
    }

    private var said: [String] = []

    override func setUp() {
        super.setUp()
        said = []
        AppComponentStages.resetReported()
        AppComponentStages.warningHandler = { [weak self] in self?.said.append($0) }
    }

    override func tearDown() {
        AppComponentStages.warningHandler = nil
        AppComponentStages.resetReported()
        CustomComponentRegistry.shared.reset()
        super.tearDown()
    }

    /// Draws `json` twice, returning the handlers called.
    private func draw(_ json: String, _ adapter: CustomComponentAdapter) -> [String] {
        CustomComponentRegistry.shared.register(adapter)
        var calls: [String] = []
        let data: [String: Any] = ["pbS": { (id: String) -> Void in calls.append("pbS(\(id))") }]
        let component = JSONLayoutLoader.stamped(try! JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8)))
        for _ in 0..<2 {
            let host = UIHostingController(rootView: DynamicComponentBuilder(component: component, data: data))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.3))
            window.isHidden = true
        }
        return calls
    }

    private let withStage = #"{"type":"View","child":[{"type":"ProgressBar","height":8,"onAppear":"pbS"}]}"#

    func testAnAdapterThatDoesNotApplyTheStagesIsNamedOncePerType() {
        let calls = draw(withStage, Bare(componentType: "ProgressBar"))
        XCTAssertEqual(calls, [], "control: nothing called the onAppear")
        XCTAssertEqual(said.count, 1, said.joined(separator: "\n"))
        XCTAssertTrue(said.first?.contains("'ProgressBar' declares onAppear, height") == true, said.first ?? "")
        XCTAssertTrue(said.first?.contains("DynamicModifierHelper.applyStandardModifiers") == true, said.first ?? "")
    }

    func testAnAdapterThatAppliesThemIsNotNamed() {
        let calls = draw(withStage, Standard(componentType: "ProgressBar"))
        XCTAssertTrue(calls.contains("pbS(progressBar_0_0)"), "control: its onAppear was called: \(calls)")
        XCTAssertEqual(said, [])
    }

    func testANodeThatDeclaresNoStageIsNotNamed() {
        _ = draw(#"{"type":"View","child":[{"type":"ProgressBar"}]}"#, Bare(componentType: "ProgressBar"))
        XCTAssertEqual(said, [])
    }
}
#endif
