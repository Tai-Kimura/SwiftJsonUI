import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
/// A type-synonym spelling draws exactly as the type the table says it is
/// drawn as (TypeSynonyms, jsonui-cli's type_synonyms.json vendored), with
/// the attributes its spelling means.
///
/// Measured before the change (iOS simulator): the builder's own cases took
/// some spellings and not others — HStack / VStack / Row / Column / Box /
/// Div / Iframe / DatePicker / … drew the red "Unknown component type" box,
/// Table / List and Picker drew with converters of their own — and
/// KotlinJsonUI's cases took a different set.
final class TypeSynonymsDrawTests: XCTestCase {

    /// What each drawn-as type needs to draw.
    private let extra: [String: String] = [
        "Label": #", "text": "t""#,
        "TextView": #", "text": "t""#,
        "Image": #", "srcName": "probe_missing""#,
        "CircleImage": ##", "srcName": "probe_missing", "background": "#3366CC""##,
        "NetworkImage": #", "url": "https://example.invalid/x.png""#,
        "SelectBox": #", "items": ["a", "b"]"#,
        "CheckBox": "",
        "Radio": #", "text": "r""#,
        "Segment": #", "items": ["a", "b"]"#,
        "Slider": "",
        "Progress": "",
        "Indicator": "",
        "View": #", "child": [{"type": "Label", "text": "c"}]"#,
        "ScrollView": #", "child": [{"type": "Label", "text": "c"}]"#,
        "Collection": #", "items": []"#,
        "GradientView": ##", "gradient": ["#FF0000", "#0000FF"]"##,
        "Blur": "",
        "Web": #", "url": "data:text/html,probe""#,
    ]

    /// The node drawn by the builder on white, 320 x 200 at scale 1. The
    /// test bundle has no host app, so a hosting controller in a window
    /// draws nothing (measured: every picture was the same blank one);
    /// ImageRenderer needs no window.
    @MainActor
    private func render(_ json: String) throws -> UIImage {
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        let renderer = ImageRenderer(content:
            DynamicComponentBuilder(component: component, data: ["t": ""])
                .frame(width: 320, height: 200)
                .background(Color.white)
        )
        renderer.scale = 1
        return try XCTUnwrap(renderer.uiImage, "nothing was rendered for \(json)")
    }

    /// Pixels of `image` within 0.1 of the colour (0...255 components),
    /// read after drawing it into an sRGB RGBA8 context — the renderer's own
    /// format may be wide-colour (more bytes per pixel, other order).
    private func count(_ image: UIImage, r: CGFloat, g: CGFloat, b: CGFloat) -> [CGPoint] {
        guard let cg = image.cgImage, let space = CGColorSpace(name: CGColorSpace.sRGB) else { return [] }
        let w = cg.width, h = cg.height
        var bytes = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(data: &bytes, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return [] }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        var points: [CGPoint] = []
        for y in 0..<h {
            for x in 0..<w {
                let o = (y * w + x) * 4
                let (rr, gg, bb) = (CGFloat(bytes[o]), CGFloat(bytes[o + 1]), CGFloat(bytes[o + 2]))
                if abs(rr - r) < 26, abs(gg - g) < 26, abs(bb - b) < 26 { points.append(CGPoint(x: x, y: y)) }
            }
        }
        return points
    }

    /// The unknown-type box is drawn on SwiftUI's red — the system red, not
    /// #FF0000 (a GradientView's pure red is not the box).
    private func isUnknownBox(_ image: UIImage) -> Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor.systemRed.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            .getRed(&r, green: &g, blue: &b, alpha: &a)
        return count(image, r: r * 255, g: g * 255, b: b * 255).count > 200
    }

    @MainActor
    func testEverySynonymDrawsAsItsType() throws {
        let url = try XCTUnwrap(TypeSynonyms.resourceURL)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let synonyms = try XCTUnwrap(root["synonyms"] as? [String: Any])
        // controls: a declared type draws something, and differs from the
        // unknown-type box a spelling that reaches no case draws
        let label = try render(#"{"type": "Label", "text": "t"}"#)
        XCTAssertFalse(count(label, r: 0, g: 0, b: 0).isEmpty && count(label, r: 255, g: 255, b: 255).count == 320 * 200,
                       "a Label drew nothing: the pictures compared below would all be the same")
        let unknown = try render(#"{"type": "ProbeUndeclaredType"}"#)
        XCTAssertTrue(isUnknownBox(unknown), "the unknown-type box was not recognised")
        var differ: [String] = []
        var unsteady: Set<String> = []
        for spelling in synonyms.keys.sorted() {
            let entry = try XCTUnwrap(TypeSynonyms.entries[spelling.lowercased()])
            let target = entry.drawnAs
            let x = try XCTUnwrap(extra[target], "no drawing extra for \(target)")
            let implied = entry.implied.map { #", "\#($0.key)": "\#($0.value)""# }.joined()
            let asSynonym = try render(#"{"type": "\#(spelling)"\#(x)}"#)
            let asTarget = try render(#"{"type": "\#(target)"\#(x)\#(implied)}"#)
            let again = try render(#"{"type": "\#(target)"\#(x)\#(implied)}"#)
            if asTarget.pngData() == again.pngData() {
                // The target draws the same picture each time: the spelling
                // must draw that picture. (ImageRenderer draws a UIKit-backed
                // view as a placeholder, which still differs from the
                // unknown-type box.)
                if asSynonym.pngData() != asTarget.pngData() { differ.append("\(spelling) differs from \(target)") }
            } else {
                unsteady.insert(target)
                if isUnknownBox(asSynonym) && !isUnknownBox(asTarget) {
                    differ.append("\(spelling) drew the unknown-type box")
                }
            }
        }
        // Printed so a run shows which targets were compared by picture.
        print("TypeSynonymsDrawTests: compared by 'not the unknown box' only: \(unsteady.sorted())")
        XCTAssertEqual(differ, [], "synonyms drawn otherwise than their type")
    }

    private func twoLabels(_ type: String, _ extra: String = "") -> String {
        #"{"type": "\#(type)"\#(extra), "child": ["#
            + ##"{"type": "Label", "text": "MMMM", "fontColor": "#FF0000", "fontSize": 20}, "##
            + ##"{"type": "Label", "text": "MMMM", "fontColor": "#0000FF", "fontSize": 20}]}"##
    }

    /// Where the red label and the blue label were drawn.
    @MainActor
    private func boxes(_ json: String) throws -> (red: CGRect, blue: CGRect) {
        let image = try render(json)
        func box(_ pts: [CGPoint]) -> CGRect {
            guard let f = pts.first else { return .null }
            return pts.reduce(CGRect(origin: f, size: .zero)) { $0.union(CGRect(origin: $1, size: .zero)) }
        }
        return (box(count(image, r: 255, g: 0, b: 0)), box(count(image, r: 0, g: 0, b: 255)))
    }

    @MainActor
    func testTheSpellingsThatMeanADirectionLayTheirChildrenOutInIt() throws {
        for t in ["HStack", "Row"] {
            let (red, blue) = try boxes(twoLabels(t))
            XCTAssertFalse(red.isNull || blue.isNull, "\(t): a label was not drawn")
            XCTAssertTrue(blue.minX > red.maxX && blue.minY < red.maxY, "\(t): children not side by side (\(red), \(blue))")
        }
        for t in ["VStack", "Column"] {
            let (red, blue) = try boxes(twoLabels(t))
            XCTAssertFalse(red.isNull || blue.isNull, "\(t): a label was not drawn")
            XCTAssertTrue(blue.minY > red.maxY && blue.minX < red.maxX, "\(t): children not one under the other (\(red), \(blue))")
        }
        // The node's own orientation is drawn, not the spelling's.
        let (red, blue) = try boxes(twoLabels("HStack", #", "orientation": "vertical""#))
        XCTAssertTrue(blue.minY > red.maxY, "HStack with orientation vertical: not drawn vertical (\(red), \(blue))")
    }

    @MainActor
    func testATypeNeitherDeclaredNorASynonymIsUnknown() throws {
        XCTAssertTrue(isUnknownBox(try render(#"{"type": "Triangle"}"#)), "Triangle was not the unknown-type box")
        // control: a declared type is not
        XCTAssertFalse(isUnknownBox(try render(#"{"type": "Label", "text": "t"}"#)))
    }
}
#endif
