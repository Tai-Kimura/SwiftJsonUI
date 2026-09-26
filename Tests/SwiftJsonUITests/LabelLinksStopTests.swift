//
//  LabelLinksStopTests.swift
//  SwiftJsonUITests
//
//  `userInteractionEnabled: false` on a Label, or on a view around it, stops
//  its links — a range with an onClick and a URL / phone number `linkable`
//  detects — and a binding gates them (the tap rule, jsonui-cli
//  shared/core/tap_accessibility.rb; 4f ruling, jsonui-cli 1.9.0).
//  `.allowsHitTesting` stops a touch; a link is also an accessibility element
//  VoiceOver can activate, so a stopped link is no link: PartialAttributedText
//  sets no `.link` while `linksEnabled` is false (sjui build passes it) or a
//  stop is handed down (`jsonuiInteractionStopped`, which the Dynamic builder
//  sets on a stopping component and everything it builds).
//
//  Whether VoiceOver activates a `.link` under `.allowsHitTesting(false)` was
//  not measured here; these tests hold what is drawn and what is a link.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class LabelLinksStopTests: XCTestCase {

    private let urlText = "See https://example.com now"

    private func links(_ view: PartialAttributedText) -> Int {
        view.createAttributedStringWithMapping().attributedString.runs.filter { $0.link != nil }.count
    }

    func testLinksEnabledFalseLeavesNoLink() {
        let range = [PartialAttribute(textPattern: "Terms", onClick: {})]
        XCTAssertEqual(links(PartialAttributedText(urlText, linkable: true)), 1, "control: the URL is a link")
        XCTAssertEqual(links(PartialAttributedText("Terms and Privacy", partialAttributes: range)), 1,
                       "control: the range is a link")
        XCTAssertEqual(links(PartialAttributedText(urlText, linkable: true, linksEnabled: false)), 0)
        XCTAssertEqual(links(PartialAttributedText("Terms and Privacy", partialAttributes: range, linksEnabled: false)), 0)
        XCTAssertTrue(PartialAttributedText("Terms and Privacy", partialAttributes: range, linksEnabled: false)
            .createAttributedStringWithMapping().urlMapping.isEmpty)
    }

    // MARK: - What is drawn

    @MainActor
    private func pixels<V: View>(_ view: V) throws -> [UInt8] {
        let renderer = ImageRenderer(content: view.frame(width: 320, height: 40, alignment: .topLeading))
        renderer.scale = 1
        guard let cg = renderer.cgImage else { throw XCTSkip("render produced no image") }
        var buf = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
        let ctx = CGContext(data: &buf, width: cg.width, height: cg.height, bitsPerComponent: 8,
                            bytesPerRow: cg.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
        return buf
    }

    private func differ(_ a: [UInt8], _ b: [UInt8]) -> Int {
        guard a.count == b.count else { return -1 }
        var n = 0
        var i = 0
        while i < a.count {
            if a[i] != b[i] || a[i + 1] != b[i + 1] || a[i + 2] != b[i + 2] { n += 1 }
            i += 4
        }
        return n
    }

    /// A stop handed down draws the Label as `linksEnabled: false` draws it,
    /// and that is not what an operable link draws (the control: the
    /// comparison can tell a link from none).
    @MainActor
    func testAHandedDownStopStopsTheLinks() throws {
        let operable = try pixels(PartialAttributedText(urlText, linkable: true))
        let off = try pixels(PartialAttributedText(urlText, linkable: true, linksEnabled: false))
        let handedDown = try pixels(PartialAttributedText(urlText, linkable: true)
            .environment(\.jsonuiInteractionStopped, true))
        XCTAssertGreaterThan(differ(operable, off), 0, "control: a link draws otherwise than no link")
        XCTAssertEqual(differ(off, handedDown), 0)
    }

    @MainActor
    private func dynamic(_ json: String) throws -> [UInt8] {
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        return try pixels(DynamicComponentBuilder(component: component, data: ["open": true, "shut": false]))
    }

    /// The Dynamic Label: its own flag and a View's reach its links, a
    /// binding by its value.
    @MainActor
    func testTheDynamicLabelsLinksStopWithTheFlag() throws {
        let label = #"{"type": "Label", "id": "l", "text": "\#(urlText)", "linkable": true"#
        let operable = try dynamic("\(label)}")
        let off = try pixels(PartialAttributedText(urlText, linkable: true, linksEnabled: false))
        XCTAssertGreaterThan(differ(operable, off), 0, "control: the Dynamic Label draws a link")
        let cases: [(String, String, Bool)] = [
            ("own false", "\(label), \"userInteractionEnabled\": false}", true),
            ("own binding false", "\(label), \"userInteractionEnabled\": \"@{shut}\"}", true),
            ("own binding true", "\(label), \"userInteractionEnabled\": \"@{open}\"}", false),
            ("in a View with false",
             #"{"type": "View", "id": "p", "userInteractionEnabled": false, "child": [\#(label)}]}"#, true),
        ]
        for (name, json, stops) in cases {
            let drawn = try dynamic(json)
            if stops {
                XCTAssertGreaterThan(differ(drawn, operable), 0, "\(name): the link still draws as one")
            } else {
                XCTAssertEqual(differ(drawn, operable), 0, "\(name): the link stopped")
            }
        }
    }

    // MARK: - The tap rule

    /// A tappable holding a Label whose links are stopped is one button, as
    /// over plain text; links that are not stopped still count (none). The
    /// same row is in jsonui-cli's tap_accessibility_vectors.json from
    /// jsonui-cli 1.9.0; the vendored copy is pinned to an earlier ref.
    func testStoppedLinksDoNotMakeTheTappableHoldAControl() throws {
        let linked = #"{"type": "Label", "id": "k", "text": "see https://example.com", "linkable": true"#
        func shape(_ child: String) throws -> String? {
            let json = #"{"type": "View", "id": "t", "onClick": "@{onOpen}", "child": [{"type": "Label", "id": "l", "text": "x"}, \#(child)]}"#
            let c = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
            return TapAccessibility.shape(of: c)?.rawValue
        }
        XCTAssertEqual(try shape("\(linked)}"), "none", "control: links that operate count")
        XCTAssertEqual(try shape(#"{"type": "View", "userInteractionEnabled": false, "child": [\#(linked)}]}"#), "combine")
        XCTAssertEqual(try shape("\(linked), \"userInteractionEnabled\": false}"), "combine")
    }
}
#endif
