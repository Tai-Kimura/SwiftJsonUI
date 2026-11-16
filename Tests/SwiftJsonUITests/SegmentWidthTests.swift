import SwiftUI
import UIKit
import XCTest
@testable import SwiftJsonUI

/// The width a Segment takes, offered 402 pt (jsonui-cli 2.5.47, the same on
/// every platform): wrapContent — or no width and no weight — is as wide as
/// its labels, equal segments, no label cut, capped at the offered width (past
/// it the control takes the width and the longer labels are cut, as a
/// matchParent one is). matchParent and a number keep their width. Drawn with
/// the code sjui build writes (static) and through Dynamic. With SEG_OUT set,
/// each picture is written there too.
@MainActor
final class SegmentWidthTests: XCTestCase {
    struct Drawn {
        let width: CGFloat
        let segmentWidths: [CGFloat]  // label centres, left to right
        let cut: [String]
    }

    static let uneven = ["あ", "あいうえお", "かき"]
    static let long = ["あいうえおかきくけこさしすせそ", "たちつてとなにぬねのはひふへほ", "まみむめもやゆよらりるれろわを"]

    private func find(_ v: UIView) -> UISegmentedControl? {
        if let s = v as? UISegmentedControl { return s }
        for c in v.subviews { if let s = find(c) { return s } }
        return nil
    }

    private func labels(_ v: UIView) -> [UILabel] {
        (v as? UILabel).map { [$0] } ?? [] + v.subviews.flatMap(labels)
    }

    private func draw<V: View>(_ name: String, _ view: V) throws -> Drawn {
        let root = VStack(alignment: .leading, spacing: 0) { view.padding(.vertical, 6); Spacer(minLength: 0) }
            .frame(width: 402, height: 60, alignment: .topLeading)
        let host = UIHostingController(rootView: root)
        host.safeAreaRegions = []
        host.view.backgroundColor = .clear
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 60))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        let control = try XCTUnwrap(find(host.view), "\(name): no segmented control")
        control.layoutIfNeeded()
        // Equal segments: the n-th label (left to right) centred at (n + 0.5) × width / count.
        let shown = labels(control).filter { $0.bounds.width > 0 && $0.window != nil }
            .sorted { $0.convert($0.bounds, to: control).midX < $1.convert($1.bounds, to: control).midX }
        let segments = shown.map { $0.convert($0.bounds, to: control).midX }
        let cut = labels(control).compactMap { l -> String? in
            l.bounds.width + 0.5 < l.intrinsicContentSize.width ? (l.text ?? "?") : nil
        }
        if let dir = ProcessInfo.processInfo.environment["SEG_OUT"] {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 2
            let image = UIGraphicsImageRenderer(bounds: CGRect(x: 0, y: 0, width: 402, height: 44), format: format).image { c in
                UIColor(white: 0.85, alpha: 1).setFill()
                c.fill(CGRect(x: 0, y: 0, width: 402, height: 44))
                host.view.layer.render(in: c.cgContext)
            }
            try image.pngData()!.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
        let drawn = Drawn(width: control.bounds.width, segmentWidths: segments, cut: cut)
        print("SEGWIDTH \(name): width=\(drawn.width) labelCentres=\(drawn.segmentWidths) cut=\(drawn.cut)")
        return drawn
    }

    /// What sjui build writes for a Segment of these items and width.
    private func generated(_ items: [String], _ width: Any?) -> some View {
        let picker = Picker("", selection: .constant(0)) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, t in Text(t).tag(i) }
        }.pickerStyle(.segmented)
        return Group {
            switch width {
            case let n as Int: picker.frame(width: CGFloat(n))
            case "matchParent" as String: picker.frame(maxWidth: .infinity)
            default: picker.segmentFitsItsLabels()
            }
        }
    }

    private func dynamic(_ items: [String], _ width: Any?) throws -> AnyView {
        var json: [String: Any] = ["type": "Segment", "items": items]
        if let width { json["width"] = width }
        let data = try JSONSerialization.data(withJSONObject: json)
        return SegmentConverter.convert(component: try JSONDecoder().decode(DynamicComponent.self, from: data), data: [:])
    }

    private func both(_ name: String, _ items: [String], _ width: Any?) throws -> [Drawn] {
        [try draw("static_\(name)", generated(items, width)), try draw("dynamic_\(name)", dynamic(items, width))]
    }

    private func assertFitsItsLabels(_ drawn: Drawn, _ face: String) {
        XCTAssertLessThan(drawn.width, 402, "\(face): took the offered width")
        XCTAssertEqual(drawn.cut, [], "\(face): a label is cut")
        let n = drawn.segmentWidths.count
        XCTAssertGreaterThan(n, 1, "\(face): the measure found no labels")
        for (i, mid) in drawn.segmentWidths.enumerated() {
            XCTAssertEqual(mid, (CGFloat(i) + 0.5) * drawn.width / CGFloat(n), accuracy: 1.5,
                           "\(face): segments not equal, label centres \(drawn.segmentWidths)")
        }
    }

    func testWrapContentFitsItsLabels() throws {
        for (face, d) in zip(["static", "dynamic"], try both("wrap_uneven", Self.uneven, "wrapContent")) { assertFitsItsLabels(d, face) }
        for (face, d) in zip(["static", "dynamic"], try both("control_wrap", ["One", "Two"], "wrapContent")) { assertFitsItsLabels(d, face) }
    }

    func testNoWidthIsWrapContent() throws {
        assertFitsItsLabels(try draw("dynamic_no_width", dynamic(Self.uneven, nil)), "dynamic")
    }

    func testTooLongTakesTheOfferedWidth() throws {
        for d in try both("wrap_long", Self.long, "wrapContent") {
            XCTAssertEqual(d.width, 402, accuracy: 0.5)
            XCTAssertFalse(d.cut.isEmpty, "the measure: these labels do not fit 402")
        }
    }

    func testMatchParentAndANumberKeepTheirWidth() throws {
        for d in try both("match_parent", Self.uneven, "matchParent") { XCTAssertEqual(d.width, 402, accuracy: 0.5) }
        for d in try both("width_200", Self.uneven, 200) { XCTAssertEqual(d.width, 200, accuracy: 0.5) }
    }
}
