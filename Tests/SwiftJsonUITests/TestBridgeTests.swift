//
//  TestBridgeTests.swift
//  SwiftJsonUITests
//
//  The initialState check (shared coercion vector), the payload store
//  (read once, consumed once per launchId x screenId) and the bridge JSON.
//

import XCTest
import CoreGraphics
@testable import SwiftJsonUI

final class InitialStateCoercionVectorTests: XCTestCase {
    private func loadCases() throws -> [[String: Any]] {
        let data = try TestFixtures.loadJSON(named: "initial_state_coercion_vectors")
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual((root["version"] as? NSNumber)?.intValue, 1)
        return try XCTUnwrap(root["cases"] as? [[String: Any]])
    }

    /// Every case: the declared data and the input give exactly the applied
    /// and rejected keys the vector lists (as sets).
    func testEveryVectorCase() throws {
        let cases = try loadCases()
        XCTAssertGreaterThan(cases.count, 50, "the vector lost its cases")
        for vectorCase in cases {
            let name = vectorCase["name"] as? String ?? "?"
            let declared = (vectorCase["data"] as? [[String: Any]] ?? []).reduce(into: [String: String]()) {
                $0[$1["name"] as! String] = ($1["class"] as! String)
            }
            let input = vectorCase["input"] as? [String: Any] ?? [:]
            var applied: Set<String> = []
            var rejected: Set<String> = []
            for (key, value) in input {
                guard let declaredClass = declared[key] else {
                    rejected.insert("\(key)|not a data field")
                    continue
                }
                switch JsonUITestValue.check(value, declaredClass: declaredClass) {
                case .accept: applied.insert(key)
                case .reject(let reason): rejected.insert("\(key)|\(reason)")
                }
            }
            let expect = vectorCase["expect"] as! [String: Any]
            let expectedApplied = Set(expect["applied"] as! [String])
            let expectedRejected = Set((expect["rejected"] as! [[String: String]]).map { "\($0["key"]!)|\($0["reason"]!)" })
            XCTAssertEqual(applied, expectedApplied, "applied: \(name)")
            XCTAssertEqual(rejected, expectedRejected, "rejected: \(name)")
        }
    }

    // MARK: what an accepted value becomes (the vector says only accept/reject)

    private func accepted(_ json: String, _ declaredClass: String) throws -> Any? {
        let value = try JSONSerialization.jsonObject(with: Data("[\(json)]".utf8)) as! [Any]
        guard case .accept(let converted) = JsonUITestValue.check(value[0], declaredClass: declaredClass) else {
            XCTFail("\(json) as \(declaredClass) was rejected"); return nil
        }
        return converted
    }

    func testAcceptedValuesHaveTheSwiftTypeOfTheirClass() throws {
        XCTAssertEqual(try accepted("2.0", "Int") as? Int, 2)
        XCTAssertEqual(try accepted("3", "Double") as? Double, 3.0)
        XCTAssertEqual(try accepted("1.5", "Float") as? Float, 1.5)
        XCTAssertEqual(try accepted("1.5", "CGFloat") as? CGFloat, 1.5)
        XCTAssertEqual(try accepted("true", "Boolean") as? Bool, true)
        XCTAssertEqual(try accepted("\"#FF0000\"", "Color") as? String, "#FF0000")
        XCTAssertEqual(try accepted("[\"a\",\"b\"]", "Array(String)") as? [String], ["a", "b"])
        XCTAssertEqual(try accepted("[1,2]", "[Int]") as? [Int], [1, 2])
        XCTAssertNil(try accepted("null", "String?"))
    }

    func testASwiftBoolIsABooleanAndASwiftIntIsNot() {
        // Values that never went through JSON: true is still a boolean, 1 is not.
        guard case .accept = JsonUITestValue.check(true, declaredClass: "Bool") else { return XCTFail() }
        guard case .reject = JsonUITestValue.check(1, declaredClass: "Bool") else { return XCTFail() }
        guard case .reject = JsonUITestValue.check(true, declaredClass: "Int") else { return XCTFail() }
    }
}

final class TestInitialStateStoreTests: XCTestCase {
    private func payload(_ screens: String, version: Int = 1, launchId: String = "L1") -> String {
        #"{"version":\#(version),"launchId":"\#(launchId)","screens":\#(screens)}"#
    }

    func testTheScreensValuesAreHandedOutOnceAndOtherScreensGetNothing() {
        let store = TestInitialStateStore.parse(payload(#"{"login":{"email":"a"}}"#))
        XCTAssertEqual(store.launchId, "L1")
        XCTAssertEqual(store.take("login")?["email"] as? String, "a")
        XCTAssertNil(store.take("login"), "a screen built again in the same launch applied twice")
        XCTAssertNil(store.take("home"))
    }

    func testNoPayloadAnotherVersionOrNoLaunchIdIsNoPayload() {
        for raw in [nil, "", "not json", payload(#"{"login":{}}"#, version: 2),
                    #"{"version":1,"screens":{"login":{"email":"a"}}}"#] {
            let store = TestInitialStateStore.parse(raw)
            XCTAssertNil(store.launchId, "\(String(describing: raw))")
            XCTAssertNil(store.take("login"))
        }
    }

    func testApplyRecordsAppliedAsThePayloadKeysMinusTheRejected() {
        let store = TestInitialStateStore.parse(payload(#"{"login":{"email":"a","nickname":"x"}}"#))
        let values = store.take("login")!
        let receipt = store.apply(values, for: "login") { _ in [.notADataField("nickname")] }
        XCTAssertEqual(receipt.applied, ["email"])
        XCTAssertEqual(receipt.rejected, [JsonUIRejectedKey(key: "nickname", reason: "not a data field")])
        XCTAssertEqual(store.receipt(for: "login"), receipt, "a recreated screen must still report it")
    }
}

final class StateBridgeJSONTests: XCTestCase {
    private func decode(_ text: String) throws -> [String: Any] {
        try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any])
    }

    func testABridgeWithAReceipt() throws {
        let receipt = JsonUITestReceipt(applied: ["email"], rejected: [JsonUIRejectedKey(key: "x", reason: "not a data field")])
        let json = try decode(StateBridgeJSON.encode(launchId: "L1", receipt: receipt,
                                                     data: ["email": "a", "count": 2, "nickname": NSNull()]))
        XCTAssertEqual(json["launchId"] as? String, "L1")
        let initialState = try XCTUnwrap(json["initialState"] as? [String: Any])
        XCTAssertEqual(initialState["applied"] as? [String], ["email"])
        XCTAssertEqual((initialState["rejected"] as? [[String: String]])?.first?["reason"], "not a data field")
        let data = try XCTUnwrap(json["data"] as? [String: Any])
        XCTAssertEqual(data["count"] as? Int, 2)
        XCTAssertTrue(data["nickname"] is NSNull, "a nil optional is null, not absent")
    }

    func testNoLaunchAndNoReceiptAreNull() throws {
        let json = try decode(StateBridgeJSON.encode(launchId: nil, receipt: nil, data: [:]))
        XCTAssertTrue(json["launchId"] is NSNull)
        XCTAssertTrue(json["initialState"] is NSNull)
    }

    func testOverTheLimitIsTruncatedWithItsSize() throws {
        let big = String(repeating: "x", count: StateBridgeJSON.byteLimit)
        let json = try decode(StateBridgeJSON.encode(launchId: "L1", receipt: nil, data: ["text": big]))
        let size = try XCTUnwrap(json["truncated"] as? Int)
        XCTAssertGreaterThan(size, StateBridgeJSON.byteLimit)
        XCTAssertEqual(json.count, 1)
    }

    func testJustUnderTheLimitIsNotTruncated() throws {
        // Boundary: the same shape one byte short of the limit stays whole.
        let overhead = StateBridgeJSON.encode(launchId: "L1", receipt: nil, data: ["text": ""]).utf8.count
        let text = String(repeating: "x", count: StateBridgeJSON.byteLimit - overhead)
        let encoded = StateBridgeJSON.encode(launchId: "L1", receipt: nil, data: ["text": text])
        XCTAssertEqual(encoded.utf8.count, StateBridgeJSON.byteLimit)
        XCTAssertNil(try decode(encoded)["truncated"])
        let over = StateBridgeJSON.encode(launchId: "L1", receipt: nil, data: ["text": text + "x"])
        XCTAssertNotNil(try decode(over)["truncated"])
    }

    func testAValueJSONCannotHoldIsDroppedNotFatal() throws {
        let json = try decode(StateBridgeJSON.encode(launchId: nil, receipt: nil,
                                                     data: ["ok": "a", "bad": Date()]))
        let data = try XCTUnwrap(json["data"] as? [String: Any])
        XCTAssertEqual(data["ok"] as? String, "a")
        XCTAssertNil(data["bad"])
    }

    func testTheBridgeIdentifier() {
        XCTAssertEqual(stateBridgeIdentifier("login"), "__state_login")
    }
}
