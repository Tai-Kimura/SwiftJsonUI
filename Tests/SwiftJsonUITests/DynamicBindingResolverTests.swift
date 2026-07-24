//
//  DynamicBindingResolverTests.swift
//  SwiftJsonUITests
//
//  Unit tests for the central `@{...}` binding-expression resolver
//  (canonical semantics: jsonui-cli shared/core/binding_semantics.json v1).
//  The full cross-platform contract is exercised by BindingVectorTests;
//  these tests cover the resolver surface directly, including the
//  value-layer wrapper handling the vectors cannot express.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class DynamicBindingResolverTests: XCTestCase {

    // MARK: - Syntax helpers

    func testIsBindingExpression() {
        XCTAssertTrue(DynamicBindingResolver.isBindingExpression("@{name}"))
        XCTAssertFalse(DynamicBindingResolver.isBindingExpression("name"))
        XCTAssertFalse(DynamicBindingResolver.isBindingExpression("@{}"))
        XCTAssertFalse(DynamicBindingResolver.isBindingExpression("@{name"))
        XCTAssertFalse(DynamicBindingResolver.isBindingExpression(nil))
    }

    func testInnerExtraction() {
        XCTAssertEqual(DynamicBindingResolver.inner(of: "@{name}"), "name")
        XCTAssertEqual(DynamicBindingResolver.inner(of: "@{ a ?? 'x' }"), " a ?? 'x' ")
        XCTAssertNil(DynamicBindingResolver.inner(of: "literal"))
    }

    // MARK: - Expression parsing

    func testParsePlainPath() {
        let expr = DynamicBindingResolver.parse("  profile.name  ")
        XCTAssertEqual(expr.path, "profile.name")
        XCTAssertFalse(expr.negated)
        XCTAssertFalse(expr.hasDefault)
        XCTAssertNil(expr.defaultLiteral)
    }

    func testParseNegation() {
        let expr = DynamicBindingResolver.parse("!flag")
        XCTAssertEqual(expr.path, "flag")
        XCTAssertTrue(expr.negated)
    }

    func testParseDefaultSplitsOnFirstOperator() {
        let expr = DynamicBindingResolver.parse("a ?? 'x' ?? 'y'")
        XCTAssertEqual(expr.path, "a")
        XCTAssertTrue(expr.hasDefault)
        // Double default fails closed to .null (= unresolved)
        XCTAssertEqual(expr.defaultLiteral, .null)
    }

    func testParseDefaultLiterals() {
        XCTAssertEqual(DynamicBindingResolver.parse("a ?? \"x\"").defaultLiteral, .string("x"))
        XCTAssertEqual(DynamicBindingResolver.parse("a ?? 'x'").defaultLiteral, .string("x"))
        XCTAssertEqual(DynamicBindingResolver.parse("a??''").defaultLiteral, .string(""))
        XCTAssertEqual(DynamicBindingResolver.parse("a ?? true").defaultLiteral, .bool(true))
        XCTAssertEqual(DynamicBindingResolver.parse("a ?? false").defaultLiteral, .bool(false))
        XCTAssertEqual(DynamicBindingResolver.parse("a ?? 42").defaultLiteral, .number(42))
        XCTAssertEqual(DynamicBindingResolver.parse("a ?? 0.5").defaultLiteral, .number(0.5))
        XCTAssertEqual(DynamicBindingResolver.parse("a ?? null").defaultLiteral, .null)
        // Unquoted word fails closed
        XCTAssertEqual(DynamicBindingResolver.parse("a ?? guest").defaultLiteral, .null)
    }

    // MARK: - Path lookup

    func testLookupFlatKeyShadowsDotPath() {
        let data: [String: Any] = ["a.b": "flat", "a": ["b": "nested"]]
        XCTAssertEqual(DynamicBindingResolver.lookupRaw(path: "a.b", in: data) as? String, "flat")
    }

    func testLookupBracketIndex() {
        let data: [String: Any] = ["items": [["title": "First"], ["title": "Second"]]]
        XCTAssertEqual(
            DynamicBindingResolver.lookupRaw(path: "items[1].title", in: data) as? String,
            "Second"
        )
    }

    func testLookupBracketOutOfRangeIsNil() {
        let data: [String: Any] = ["items": ["a"]]
        XCTAssertNil(DynamicBindingResolver.lookupRaw(path: "items[5]", in: data))
        XCTAssertNil(DynamicBindingResolver.lookupRaw(path: "items[-1]", in: data))
        XCTAssertNil(DynamicBindingResolver.lookupRaw(path: "items[x]", in: data))
    }

    func testLookupBracketOnNonArrayIsNil() {
        XCTAssertNil(DynamicBindingResolver.lookupRaw(path: "items[0]", in: ["items": "scalar"]))
    }

    func testLookupIntermediateMissIsNil() {
        XCTAssertNil(DynamicBindingResolver.lookupRaw(path: "missing.name", in: ["name": "Ada"]))
        XCTAssertNil(DynamicBindingResolver.lookupRaw(path: "name.length", in: ["name": "Ada"]))
    }

    func testLookupTraversesAnyCodableContainers() {
        let data: [String: Any] = ["profile": AnyCodable(["name": "Grace"])]
        let raw = DynamicBindingResolver.lookupRaw(path: "profile.name", in: data)
        XCTAssertEqual(raw as? String, "Grace")
    }

    // MARK: - Value-layer unwrap

    func testUnwrapBindingWrappers() {
        var stringStore = "Ada"
        let stringBinding = SwiftUI.Binding<String>(
            get: { stringStore }, set: { stringStore = $0 })
        XCTAssertEqual(DynamicBindingResolver.unwrap(stringBinding) as? String, "Ada")

        var intStore = 7
        let intBinding = SwiftUI.Binding<Int>(get: { intStore }, set: { intStore = $0 })
        XCTAssertEqual(DynamicBindingResolver.unwrap(intBinding) as? Int, 7)

        XCTAssertNil(DynamicBindingResolver.unwrap(NSNull()))
        XCTAssertEqual(DynamicBindingResolver.unwrap(AnyCodable("x")) as? String, "x")
    }

    func testResolveStringUnwrapsBindingInData() {
        var store = "bound"
        let binding = SwiftUI.Binding<String>(get: { store }, set: { store = $0 })
        let data: [String: Any] = ["title": binding]
        XCTAssertEqual(
            DynamicBindingResolver.resolveString(expression: "@{title}", data: data),
            "bound"
        )
    }

    // MARK: - Coercion tables

    func testCoerceBoolTable() {
        XCTAssertEqual(DynamicBindingResolver.coerceBool(true), true)
        XCTAssertEqual(DynamicBindingResolver.coerceBool(false), false)
        XCTAssertEqual(DynamicBindingResolver.coerceBool(1), true)
        XCTAssertEqual(DynamicBindingResolver.coerceBool(0), false)
        XCTAssertEqual(DynamicBindingResolver.coerceBool(5), true)
        XCTAssertEqual(DynamicBindingResolver.coerceBool("true"), true)
        XCTAssertEqual(DynamicBindingResolver.coerceBool("TRUE"), true)
        XCTAssertEqual(DynamicBindingResolver.coerceBool("1"), true)
        XCTAssertEqual(DynamicBindingResolver.coerceBool("false"), false)
        XCTAssertEqual(DynamicBindingResolver.coerceBool("0"), false)
        XCTAssertNil(DynamicBindingResolver.coerceBool("yes"))
        XCTAssertNil(DynamicBindingResolver.coerceBool(nil))
        XCTAssertNil(DynamicBindingResolver.coerceBool(["nested": true]))
    }

    func testCoerceDoubleTable() {
        XCTAssertEqual(DynamicBindingResolver.coerceDouble(42), 42)
        XCTAssertEqual(DynamicBindingResolver.coerceDouble(0.5), 0.5)
        XCTAssertEqual(DynamicBindingResolver.coerceDouble("42"), 42)
        XCTAssertNil(DynamicBindingResolver.coerceDouble("abc"))
        // Booleans are NOT numbers (NSNumber bridging must not leak them in)
        XCTAssertNil(DynamicBindingResolver.coerceDouble(true))
        XCTAssertNil(DynamicBindingResolver.coerceDouble(nil))
    }

    func testStrictBool() {
        XCTAssertEqual(DynamicBindingResolver.strictBool(true), true)
        XCTAssertNil(DynamicBindingResolver.strictBool(1))
        XCTAssertNil(DynamicBindingResolver.strictBool("true"))
    }

    // MARK: - Canonical stringification

    func testStringifyCanonicalForms() {
        XCTAssertEqual(DynamicBindingResolver.stringify("x"), "x")
        XCTAssertEqual(DynamicBindingResolver.stringify(5), "5")
        XCTAssertEqual(DynamicBindingResolver.stringify(5.0), "5")
        XCTAssertEqual(DynamicBindingResolver.stringify(5.5), "5.5")
        XCTAssertEqual(DynamicBindingResolver.stringify(true), "true")
        XCTAssertEqual(DynamicBindingResolver.stringify(false), "false")
        XCTAssertNil(DynamicBindingResolver.stringify(nil))
        XCTAssertNil(DynamicBindingResolver.stringify(NSNull()))
        XCTAssertNil(DynamicBindingResolver.stringify(["k": "v"]))
        XCTAssertNil(DynamicBindingResolver.stringify(["a", "b"]))
    }

    // MARK: - processText routing (the `??` root-cause fix)

    func testProcessTextDefaultLiteralSurvives() {
        // The legacy implementation stripped every '?' from the inner
        // expression, destroying "@{x ?? 'abc'}" into a lookup of
        // "x  'abc'" — the canonical resolver must yield the default.
        XCTAssertEqual(
            DynamicHelpers.processText("@{x ?? 'abc'}", data: [:]),
            "abc"
        )
        XCTAssertEqual(
            DynamicHelpers.processText("@{x ?? \"abc\"}", data: ["x": "hit"]),
            "hit"
        )
    }

    func testProcessTextObjectValueRendersEmptyNotDebugDump() {
        let data: [String: Any] = ["profile": ["name": "Grace"]]
        XCTAssertEqual(DynamicHelpers.processText("@{profile}", data: data), "")
    }

    func testProcessTextIntegralDoubleRendersWithoutDecimalPoint() {
        XCTAssertEqual(DynamicHelpers.processText("@{count}", data: ["count": 5.0]), "5")
    }

    // MARK: - Typed process helpers routing

    func testProcessBoolCoercesAndNegates() {
        XCTAssertTrue(DynamicHelpers.processBool("@{flag}", data: ["flag": "true"]))
        XCTAssertFalse(DynamicHelpers.processBool("@{!flag}", data: ["flag": true]))
        XCTAssertTrue(DynamicHelpers.processBool("@{settings.enabled}", data: ["settings": ["enabled": true]]))
        XCTAssertTrue(DynamicHelpers.processBool("@{missing ?? true}", data: [:]))
        XCTAssertFalse(DynamicHelpers.processBool("@{missing}", data: [:]))
        XCTAssertTrue(DynamicHelpers.processBool(true, data: [:]))
    }

    func testProcessDoubleResolvesDotPathAndDefault() {
        let data: [String: Any] = ["profile": ["meta": ["age": 36]]]
        XCTAssertEqual(DynamicHelpers.processDouble("@{profile.meta.age}", data: data), 36)
        XCTAssertEqual(DynamicHelpers.processDouble("@{missing ?? 42}", data: [:]), 42)
        XCTAssertEqual(DynamicHelpers.processDouble("@{missing}", data: [:]), 0)
    }

    func testProcessStringResolvesValueContext() {
        XCTAssertEqual(DynamicHelpers.processString("@{title}", data: ["title": "Hello"]), "Hello")
        XCTAssertEqual(DynamicHelpers.processString("@{count}", data: ["count": 5]), "5")
        XCTAssertNil(DynamicHelpers.processString("@{missing}", data: [:]))
        XCTAssertEqual(DynamicHelpers.processString("literal", data: [:]), "literal")
    }

    // MARK: - DynamicBindingHelper routing

    func testResolveValueDotPathAndBinding() {
        let data: [String: Any] = ["profile": ["name": "Grace"]]
        let resolved: String? = DynamicBindingHelper.resolveValue("@{profile.name}", data: data)
        XCTAssertEqual(resolved, "Grace")
    }

    func testResolveBoolUnifiedTable() {
        // Coerced string value through the one canonical table
        XCTAssertTrue(DynamicBindingHelper.resolveBool("@{flag}", data: ["flag": "1"]))
        // Negation of a coerced value
        XCTAssertFalse(DynamicBindingHelper.resolveBool("@{!flag}", data: ["flag": "true"]))
        // Unresolved → fallback
        XCTAssertTrue(DynamicBindingHelper.resolveBool("@{missing}", data: [:], fallback: true))
        // Literal (non-binding) coercion
        XCTAssertTrue(DynamicBindingHelper.resolveBool("true", data: [:]))
        XCTAssertFalse(DynamicBindingHelper.resolveBool("false", data: [:], fallback: true))
    }

    func testResolveBoolOrBindingUnifiedTable() {
        XCTAssertTrue(DynamicDecodingHelper.resolveBoolOrBinding(
            AnyCodable("@{settings.enabled}"),
            data: ["settings": ["enabled": true]]
        ))
        XCTAssertFalse(DynamicDecodingHelper.resolveBoolOrBinding(
            AnyCodable("@{missing}"), data: [:], default: false
        ))
        XCTAssertTrue(DynamicDecodingHelper.resolveBoolOrBinding(AnyCodable("TRUE")))
    }

    // MARK: - AttrValue routing (resolveNumber / resolveBool)

    func testResolveNumberAttrBindingDotPath() {
        let data: [String: Any] = ["layout": ["width": 120]]
        let resolved = DynamicHelpers.resolveNumber(
            .binding("layout.width"), legacy: nil, data: data)
        XCTAssertEqual(resolved, 120)
    }

    func testResolveBoolAttrBindingCoercion() {
        let resolved = DynamicHelpers.resolveBool(
            .binding("flag"), legacy: nil, data: ["flag": 1])
        XCTAssertEqual(resolved, true)
    }

    // MARK: - Embed params / include data raw resolution

    func testResolveParamValuePreservesRawWrapper() {
        var store = "reactive"
        let binding = SwiftUI.Binding<String>(get: { store }, set: { store = $0 })
        let parentData: [String: Any] = ["title": binding]
        let resolved = DynamicBindingResolver.resolveParamValue(
            expression: "title", parentData: parentData)
        XCTAssertNotNil(resolved as? SwiftUI.Binding<String>,
                        "params must pass reactive wrappers through unmodified")
    }

    func testResolveParamValueRejectsDefaultAndNegation() {
        let parentData: [String: Any] = ["name": "Ada", "flag": true]
        XCTAssertNil(DynamicBindingResolver.resolveParamValue(
            expression: "name ?? 'x'", parentData: parentData))
        XCTAssertNil(DynamicBindingResolver.resolveParamValue(
            expression: "!flag", parentData: parentData))
    }

    func testResolveDataValueResolvesDefaults() {
        XCTAssertEqual(DynamicBindingResolver.resolveDataValue(
            expression: "missing ?? 'fallback'", parentData: [:]) as? String, "fallback")
        XCTAssertEqual(DynamicBindingResolver.resolveDataValue(
            expression: "profile.name", parentData: ["profile": ["name": "Grace"]]) as? String,
            "Grace")
        XCTAssertNil(DynamicBindingResolver.resolveDataValue(
            expression: "missing", parentData: [:]))
    }
}
#endif
