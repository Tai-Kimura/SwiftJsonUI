//
//  JsonUIBindingPathTests.swift
//  SwiftJsonUITests
//
//  `JsonUIBindingPath` is the canonical path resolution and value coercion,
//  and unlike the rest of the Dynamic subsystem it is NOT `#if DEBUG`.
//
//  That is the whole point of it, and the reason it needs its own tests. The
//  static (codegen) face emits references to this type for any binding path
//  that traverses into an untyped JSON container, and generated code is
//  distributed and built for release. When the same logic lived inside
//  `DynamicBindingResolver` (which is `#if DEBUG`), the generated code
//  compiled in DEBUG and failed in the consumer's release build — the worst
//  available failure, because every gate goes green first. Measured: the
//  conformance host, which compiles SwiftJsonUI with DEBUG undefined, failed
//  five views with "Type 'SwiftJsonUI' has no member 'DynamicBindingResolver'".
//
//  `DynamicBindingResolver` now delegates here, so these examples pin the
//  behaviour BOTH faces get. The cases below are the ones where a plausible
//  reimplementation differs from the canonical rules — which is what the
//  static face would have had to write if this type did not exist.
//

import XCTest
@testable import SwiftJsonUI

final class JsonUIBindingPathTests: XCTestCase {

    private let data: [String: Any] = [
        "profile": ["name": "Grace", "meta": ["age": 36]],
        "items": [["title": "First"], ["title": "Second"]],
        "scalars": ["alpha", "beta"],
        "flat.key": "shadowed",
        "empty": [Any]()
    ]

    // MARK: - Traversal

    func testResolvesADottedPath() {
        XCTAssertEqual(JsonUIBindingPath.resolve(path: "profile.name", in: data) as? String, "Grace")
    }

    func testResolvesANestedPath() {
        XCTAssertEqual(JsonUIBindingPath.resolve(path: "profile.meta.age", in: data) as? Int, 36)
    }

    func testResolvesABracketIndex() {
        XCTAssertEqual(JsonUIBindingPath.resolve(path: "items[0].title", in: data) as? String, "First")
        XCTAssertEqual(JsonUIBindingPath.resolve(path: "scalars[1]", in: data) as? String, "beta")
    }

    func testAFlatKeyShadowsTheNestedPath() {
        // Canonical: a data map that literally contains "a.b" wins over
        // traversal. A reimplementation that splits on "." first would miss
        // this and return nil.
        XCTAssertEqual(JsonUIBindingPath.resolve(path: "flat.key", in: data) as? String, "shadowed")
    }

    // MARK: - Unresolved rather than trapped

    func testAnOutOfRangeIndexIsUnresolvedNotACrash() {
        // The reason the static face must not emit `data.items[9]`: a Swift
        // subscript traps. Canonical semantics say unresolved.
        XCTAssertNil(JsonUIBindingPath.resolve(path: "items[9].title", in: data))
        XCTAssertNil(JsonUIBindingPath.resolve(path: "empty[0]", in: data))
    }

    func testAnIndexOnANonArrayIsUnresolved() {
        XCTAssertNil(JsonUIBindingPath.resolve(path: "profile[0]", in: data))
    }

    func testAMissingOrNonObjectIntermediateIsUnresolved() {
        XCTAssertNil(JsonUIBindingPath.resolve(path: "profile.absent.deeper", in: data))
        XCTAssertNil(JsonUIBindingPath.resolve(path: "profile.name.deeper", in: data))
        XCTAssertNil(JsonUIBindingPath.resolve(path: "absent.name", in: data))
    }

    func testAMalformedSegmentIsUnresolved() {
        XCTAssertNil(JsonUIBindingPath.resolve(path: "items[-1]", in: data))
        XCTAssertNil(JsonUIBindingPath.resolve(path: "items[x]", in: data))
        XCTAssertNil(JsonUIBindingPath.resolve(path: "[0]", in: data))
        XCTAssertNil(JsonUIBindingPath.resolve(path: "", in: data))
    }

    func testABareNameThatIsNotPresentIsUnresolved() {
        // No dot and no bracket: the flat lookup is the only chance.
        XCTAssertNil(JsonUIBindingPath.resolve(path: "absent", in: data))
    }

    // MARK: - Canonical text form

    func testAnIntegralNumberHasNoFractionalPart() {
        // The rule string interpolation gets wrong: "\(1.0)" is "1.0".
        XCTAssertEqual(JsonUIBindingPath.stringify(1.0), "1")
        XCTAssertEqual(JsonUIBindingPath.stringify(36), "36")
        XCTAssertEqual(JsonUIBindingPath.text(forNumber: 42), "42")
    }

    func testANonIntegralNumberKeepsItsFraction() {
        XCTAssertEqual(JsonUIBindingPath.stringify(2.5), "2.5")
    }

    func testTheIntegralShortcutStopsAtItsMagnitudeBound() {
        // Guarded by |x| < 1e15 so the Int64 conversion cannot overflow.
        // Above the bound the NSNumber form is used instead — the point is
        // that it does not trap.
        XCTAssertEqual(JsonUIBindingPath.stringify(1e14), "100000000000000")
        XCTAssertNotNil(JsonUIBindingPath.stringify(1e15))
        XCTAssertNotNil(JsonUIBindingPath.stringify(1e300))
    }

    func testBoolsAreTrueAndFalseNotOneAndZero() {
        // NSNumber bridging would let `true` stringify as "1" without the
        // CFBoolean check.
        XCTAssertEqual(JsonUIBindingPath.stringify(true), "true")
        XCTAssertEqual(JsonUIBindingPath.stringify(false), "false")
    }

    func testAContainerHasNoTextForm() {
        // Unresolved, NOT a debug dump: interpolating a dictionary would
        // render '["name": "Grace"]' into the UI.
        XCTAssertNil(JsonUIBindingPath.stringify(["name": "Grace"]))
        XCTAssertNil(JsonUIBindingPath.stringify(["a", "b"]))
        XCTAssertNil(JsonUIBindingPath.stringify(nil))
        XCTAssertNil(JsonUIBindingPath.stringify(NSNull()))
    }

    func testTheResolvedNestedNumberRendersCanonically() {
        // End to end: the shape that reached the conformance host.
        let raw = JsonUIBindingPath.resolve(path: "profile.meta.age", in: data)
        XCTAssertEqual(JsonUIBindingPath.stringify(raw), "36")
    }

    // MARK: - Bool coercion

    func testBoolTable() {
        XCTAssertEqual(JsonUIBindingPath.bool(true), true)
        XCTAssertEqual(JsonUIBindingPath.bool(0), false)
        XCTAssertEqual(JsonUIBindingPath.bool(2), true)
        XCTAssertEqual(JsonUIBindingPath.bool("TRUE"), true)
        XCTAssertEqual(JsonUIBindingPath.bool("0"), false)
        XCTAssertNil(JsonUIBindingPath.bool("yes"))
        XCTAssertNil(JsonUIBindingPath.bool(["a"]))
        XCTAssertNil(JsonUIBindingPath.bool(nil))
    }

    // MARK: - Number coercion

    func testNumberTable() {
        XCTAssertEqual(JsonUIBindingPath.double(2), 2)
        XCTAssertEqual(JsonUIBindingPath.double("2.5"), 2.5)
        XCTAssertNil(JsonUIBindingPath.double("x"))
        XCTAssertNil(JsonUIBindingPath.double(nil))
    }

    func testABoolIsNotANumber() {
        // Without the CFBoolean check, `true` coerces to 1.0 here.
        XCTAssertNil(JsonUIBindingPath.double(true))
        XCTAssertNil(JsonUIBindingPath.double(false))
    }

    // MARK: - The unwrap hook

    func testTheUnwrapHookIsAppliedToEveryContainerNotJustTheRoot() {
        // The dynamic face passes its AnyCodable unwrap through this hook.
        // A hook applied only at the root would resolve one hop and fail on
        // the second, which is exactly the nested case that failed before.
        struct Box { let value: Any }
        let boxed: [String: Any] = [
            "profile": Box(value: ["meta": Box(value: ["age": 7])])
        ]
        let unwrap: (Any?) -> Any? = { v in (v as? Box)?.value ?? v }

        XCTAssertEqual(
            JsonUIBindingPath.resolve(path: "profile.meta.age", in: boxed, unwrap: unwrap) as? Int,
            7
        )
        // Control: without the hook the same path is unresolved, so the
        // example above is actually exercising it.
        XCTAssertNil(JsonUIBindingPath.resolve(path: "profile.meta.age", in: boxed))
    }
}
