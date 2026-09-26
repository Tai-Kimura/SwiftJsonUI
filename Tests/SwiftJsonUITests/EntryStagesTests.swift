//
//  EntryStagesTests.swift
//  SwiftJsonUITests
//
//  Every entry runs the stages the loader runs (4f's ruling on the entries
//  that skip stages, 1.9.0). A component the app decoded itself, handed to
//  DynamicView(component:), was only stamped: its styles, includes and
//  responsive overrides were skipped. It now goes through
//  JSONLayoutLoader.prepared — the same tree the loader's path draws, and
//  prepared twice is prepared once. A node that reaches the builder with a
//  stage not run on it is named once (UnresolvedStages): both sides of the
//  line are armed here.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class EntryStagesTests: XCTestCase {

    private var written: [URL] = []
    private var said: [String] = []

    override func setUp() {
        super.setUp()
        StyleProcessor.clearCache()
        UnresolvedStages.reported = []
        UnresolvedStages.warningHandler = { [unowned self] in self.said.append($0) }
    }

    override func tearDown() {
        written.forEach { try? FileManager.default.removeItem(at: $0) }
        StyleProcessor.clearCache()
        UnresolvedStages.warningHandler = nil
        UnresolvedStages.reported = []
        super.tearDown()
    }

    private func style(_ name: String, _ body: [String: Any]) throws {
        let dir = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0])
            .appendingPathComponent("Styles", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(name).json")
        try JSONSerialization.data(withJSONObject: body).write(to: url)
        written.append(url)
    }

    private func appDecoded(_ tree: [String: Any]) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: JSONSerialization.data(withJSONObject: tree))
    }

    private func same(_ a: DynamicComponent, _ b: DynamicComponent) -> Bool {
        NSDictionary(dictionary: a.rawData).isEqual(to: b.rawData)
    }

    private func tree(_ tag: String) -> [String: Any] {
        ["type": "View", "child": [
            ["type": "Label", "text": "a", "style": "\(tag)_red"],
            ["type": "Label", "text": "b", "fontSize": 12, "responsive": ["regular": ["fontSize": 30]]],
        ]]
    }

    /// The tree the loader's path draws from the same dictionary: styles,
    /// stamped, the responsive overrides resolved.
    private func loaderPath(_ json: [String: Any]) throws -> DynamicComponent {
        let styled = LayoutPath.stamp(StyleProcessor.processStyles(json))
        let resolved = ResponsiveResolver(horizontalSizeClass: .regular, verticalSizeClass: .regular).resolveTree(styled)
        return try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: resolved))
    }

    private func prepared(_ c: DynamicComponent) -> DynamicComponent {
        JSONLayoutLoader.prepared(c, horizontalSizeClass: .regular, verticalSizeClass: .regular)
    }

    func testAnAppDecodedComponentGoesThroughTheLoadersStages() throws {
        let tag = "entry_\(UUID().uuidString.prefix(8))"
        try style("\(tag)_red", ["fontColor": "#FF0000"])
        let got = prepared(try appDecoded(tree(tag)))
        XCTAssertTrue(same(got, try loaderPath(tree(tag))), "\(got.rawData)")
        let labels = try XCTUnwrap(got.childComponents)
        XCTAssertEqual(labels[0].rawData["fontColor"] as? String, "#FF0000")
        XCTAssertEqual(labels[1].rawData["fontSize"] as? Int, 30)
        XCTAssertEqual(labels.map(LayoutPath.path(of:)), ["0_0", "0_1"])
    }

    func testPreparedTwiceIsPreparedOnce() throws {
        let tag = "entry_\(UUID().uuidString.prefix(8))"
        try style("\(tag)_red", ["fontColor": "#FF0000"])
        let once = prepared(try appDecoded(tree(tag)))
        XCTAssertTrue(same(prepared(once), once))
    }

    func testATreeWithNothingToResolveIsOnlyStamped() throws {
        let plain = try appDecoded(["type": "View", "child": [["type": "Label", "text": "a"]]])
        XCTAssertFalse(JSONLayoutLoader.hasUnresolvedStages(plain.rawData))
        XCTAssertTrue(same(prepared(plain), JSONLayoutLoader.stamped(plain)))
    }

    // MARK: - The builder names a node a stage did not run on

    private func draw(_ component: DynamicComponent) {
        let host = UIHostingController(rootView: DynamicComponentBuilder(component: component, data: [:]))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        window.isHidden = true
    }

    func testAResolvedNodeIsNotNamed() throws {
        let tag = "entry_\(UUID().uuidString.prefix(8))"
        try style("\(tag)_red", ["fontColor": "#FF0000"])
        draw(prepared(try appDecoded(tree(tag))))
        XCTAssertEqual(said, [])
    }

    func testAnUnresolvedStyleAndResponsiveAreNamedOnce() throws {
        let tag = "entry_\(UUID().uuidString.prefix(8))"
        try style("\(tag)_red", ["fontColor": "#FF0000"])
        let skipped = try appDecoded(tree(tag))
        draw(skipped)
        draw(skipped)
        XCTAssertEqual(said.sorted(), [
            UnresolvedStages.sentence(key: "responsive", type: "Label"),
            UnresolvedStages.sentence(key: "style", type: "Label"),
        ])
    }
}
#endif
