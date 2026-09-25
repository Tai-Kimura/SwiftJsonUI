//
//  ImageStandardChainTests.swift
//  SwiftJsonUITests
//
//  Image, CircleImage and NetworkImage run applyStandardModifiers, the chain
//  every other Dynamic component runs, after their own image steps. Their
//  chains used to be hand-picked, and a stage left out was simply not drawn:
//  measured 2026-09-25 (`dump`, iOS 18.6) — shadow, offset, zIndex, min / max
//  frame, tint and safeAreaInsetPositions reached a View and neither image
//  type, while codegen emitted all of them for images too.
//
//  The authority is the chain itself, not a list written here: for each
//  stage, the lines its attribute adds to a View's `dump` through
//  applyStandardModifiers must be added to each image type's `dump` as well.
//  No SwiftUI type is named, so the arm follows a stage when the way it draws
//  changes. The lines compared are the fields (`modifier: …`, `value: …`);
//  the one-line summaries of each AnyView spell out the whole nested type,
//  which differs between a View and an image by construction.
//
//  A stage whose attribute adds nothing to the View's dump cannot be checked
//  here; those are printed, and only the ones in `notVisibleInDump` may be.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class ImageStandardChainTests: XCTestCase {

    /// Stage name (DynamicModifierHelper.standardOrder) → the attributes that
    /// make it act.
    private static let stages: [(String, String)] = [
        ("padding", ##""padding": 4"##),
        ("frameConstraints", ##""minWidth": 10, "maxWidth": 100"##),
        ("insets", ##""insets": [1, 2, 3, 4]"##),
        ("background", ##""background": "#FF0000""##),
        ("safeAreaInsets", ##""safeAreaInsetPositions": ["top"]"##),
        ("glass", ##""glass": true"##),
        ("cornerRadius", ##""cornerRadius": 6"##),
        ("border", ##""borderWidth": 1, "borderColor": "#000000""##),
        ("margins", ##""margins": [5, 6, 7, 8]"##),
        ("opacity", ##""alpha": 0.5"##),
        ("shadow", ##""shadow": "#000000|1|1|1|2""##),
        ("clipped", ##""clipToBounds": true"##),
        ("offset", ##""offsetX": 3, "offsetY": 4"##),
        ("zIndex", ##""indexAbove": "x""##),
        ("hidden", ##""hidden": true"##),
        ("disabled", ##""enabled": false"##),
        ("hitTesting", ##""userInteractionEnabled": false"##),
        ("tint", ##""tintColor": "#00FF00""##),
        ("events", ##""onClick": "@{tap}""##),
        ("confirmationDialog", ##""confirmationDialog": {"isPresented": "@{showDialog}", "title": "t"}"##),
        ("alert", ##""alert": {"isPresented": "@{showAlert}", "title": "t"}"##),
    ]

    /// Stages whose attribute adds no line to a View's dump: the two dialogs
    /// (the same skip class the conformance generator gives them).
    private static let notVisibleInDump: Set<String> = ["confirmationDialog", "alert"]

    private static let types = ["Image", "CircleImage", "NetworkImage"]

    private static let data: [String: Any] = [
        "tap": { () -> Void in },
        "showDialog": SwiftUI.Binding<Bool>.constant(false),
        "showAlert": SwiftUI.Binding<Bool>.constant(false),
    ]

    private func built(_ type: String, _ extra: String) throws -> AnyView {
        let text = ##"{"type": "\##(type)", "id": "probe", "width": 40, "height": 40, "srcName": "probe_asset", "url": "data:,"\##(extra)}"##
        let c = try JSONDecoder().decode(DynamicComponent.self, from: Data(text.utf8))
        switch type {
        case "View":
            return DynamicModifierHelper.applyStandardModifiers(AnyView(Color.clear), component: c, data: Self.data)
        case "NetworkImage":
            return NetworkImageConverter.convert(component: c, data: Self.data)
        default:
            return ImageViewConverter.convert(component: c, data: Self.data)
        }
    }

    /// The field lines of `dump`, in order, with the tree glyphs, the
    /// indentation, object numbers and addresses taken off.
    private func fields(_ view: AnyView) -> [String] {
        var out = ""
        dump(view, to: &out)
        return out.split(separator: "\n").compactMap { raw -> String? in
            var line = raw.trimmingCharacters(in: .whitespaces)
            for glyph in ["▿ ", "- ", "▹ "] where line.hasPrefix(glyph) { line.removeFirst(glyph.count) }
            if line.contains("ModifiedContent<") || line.hasPrefix("AnyView(") { return nil }
            line = line.replacingOccurrences(of: #"#\d+"#, with: "#", options: .regularExpression)
            return line.replacingOccurrences(of: #"0x[0-9a-f]+"#, with: "0x", options: .regularExpression)
        }
    }

    private func counted(_ lines: [String]) -> [String: Int] {
        lines.reduce(into: [:]) { $0[$1, default: 0] += 1 }
    }

    /// What `a` has beyond `b`, counting repeats.
    private func beyond(_ a: [String: Int], _ b: [String: Int]) -> [String: Int] {
        a.reduce(into: [:]) { out, entry in
            let extra = entry.value - (b[entry.key] ?? 0)
            if extra > 0 { out[entry.key] = extra }
        }
    }

    func testEveryStageAViewShowsReachesEachImageType() throws {
        let viewBase = counted(fields(try built("View", "")))
        var bases: [String: [String: Int]] = [:]
        for type in Self.types { bases[type] = counted(fields(try built(type, ""))) }

        var notVisible: Set<String> = []
        for (stage, attributes) in Self.stages {
            let added = beyond(counted(fields(try built("View", ", " + attributes))), viewBase)
            guard !added.isEmpty else {
                notVisible.insert(stage)
                continue
            }
            for type in Self.types {
                let got = beyond(counted(fields(try built(type, ", " + attributes))), bases[type]!)
                let missing = beyond(added, got)
                XCTAssertTrue(missing.isEmpty,
                              "\(type): the \(stage) stage did not reach it — \(missing.count) of the View's lines missing, e.g. \(missing.keys.sorted().prefix(2))")
            }
        }
        print("[ImageStandardChainTests] stages not visible in a View's dump here: \(notVisible.sorted())")
        XCTAssertTrue(notVisible.isSubset(of: Self.notVisibleInDump),
                      "a stage stopped showing in the control's dump, so nothing checks it: \(notVisible.subtracting(Self.notVisibleInDump).sorted())")
    }

    /// Padding sits inside the frame, as in the chain and in codegen
    /// (`.padding(4).frame(width: 40, height: 40)`). The hand-picked chains
    /// framed first and padded outside, drawing a box larger than declared.
    func testPaddingIsInsideTheFrameAsInTheChain() throws {
        func paddingBeforeFrame(_ view: AnyView) -> Bool? {
            let lines = fields(view)
            guard let padding = lines.firstIndex(where: { $0.contains("_PaddingLayout") }),
                  let frame = lines.firstIndex(where: { $0.contains("_FrameLayout") }) else { return nil }
            return padding < frame
        }
        let control = try XCTUnwrap(paddingBeforeFrame(try built("View", #", "padding": 4"#)),
                                    "control: a View's dump shows no padding or no frame")
        for type in Self.types {
            XCTAssertEqual(paddingBeforeFrame(try built(type, #", "padding": 4"#)), control,
                           "\(type): padding and frame are nested the other way round from the chain")
        }
    }
}
#endif
