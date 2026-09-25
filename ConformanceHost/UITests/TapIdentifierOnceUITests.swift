//
//  TapIdentifierOnceUITests.swift
//  ConformanceHostUITests
//
//  Every identifier inside a combined tap is found exactly once, and the tap
//  is one button (TapIdentifierOnceView). NOT opt-in: the host's UI tests run
//  in jsonui-cli's conformance-mobile workflow (both iOS jobs), and this runs
//  with them.
//
//  In the codegen host (CONFORMANCE_HOST_MODE=codegen, which
//  run_conformance.sh forwards) the sjui-generated shapes (`cg_`) are asked
//  the same, and must be there; in the dynamic host they must not be.
//
//  Measured before the fix (SwiftJsonUI 4b25264, iOS 26.5 and 18.6): an
//  id-less tap holding one child with an id — the Label's and the Image's id
//  counted 2 (the button took the id); two children — each counted 1, the
//  button's identifier "a-b". After: every id 1, one button per shape.
//

import XCTest

final class TapIdentifierOnceUITests: XCTestCase {
    /// Every id the probe's shapes declare.
    private let ids = [
        "tio_one_label", "tio_one_image", "tio_two_a", "tio_two_b",
        "tio_own_one", "tio_own_one_label", "tio_own_image", "tio_own_image_child",
        "tio_own_plain", "tio_own_two", "tio_own_two_a", "tio_own_two_b",
    ]

    /// Each shape's wrapper, and the identifier its one button must carry:
    /// its own id, or none — not one taken from a child ("a-b" for two).
    private let wrappers: [(String, String)] = [
        ("wrap_one_label", ""), ("wrap_one_image", ""), ("wrap_one_plain", ""), ("wrap_two", ""),
        ("wrap_own_one", "tio_own_one"), ("wrap_own_image", "tio_own_image"),
        ("wrap_own_plain", "tio_own_plain"), ("wrap_own_two", "tio_own_two"),
    ]

    /// The generated half (codegen host only): the same shapes, `cg_` ids.
    private let codegenIds = [
        "cg_one_label", "cg_one_image", "cg_two_a", "cg_two_b",
        "cg_own_one", "cg_own_one_label", "cg_own_image", "cg_own_image_child",
        "cg_own_plain", "cg_own_two", "cg_own_two_a", "cg_own_two_b",
    ]

    private let codegenWrappers: [(String, String)] = [
        ("wrap_cg_one_label", ""), ("wrap_cg_one_image", ""), ("wrap_cg_one_plain", ""), ("wrap_cg_two", ""),
        ("wrap_cg_own_one", "cg_own_one"), ("wrap_cg_own_image", "cg_own_image"),
        ("wrap_cg_own_plain", "cg_own_plain"), ("wrap_cg_own_two", "cg_own_two"),
    ]

    func testEveryIdentifierInACombinedTapIsFoundOnce() throws {
        let codegenHost = ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen"
        let app = XCUIApplication()
        app.launchArguments = ["-tapIdentifierOnce"]
        // As ConformanceUITests does: the app switches the generated views off
        // their DEBUG dynamic path only when it is told the host mode.
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["tio_ready"].waitForExistence(timeout: 15), "probe did not start")
        XCTAssertFalse(app.staticTexts["tio_decode_failed"].exists, "a shape did not decode")

        // The instrument counts duplicates: one id on two views is 2.
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "tio_dup").count, 2,
                       "the positive control: the query no longer counts a duplicate")

        let generated = app.staticTexts["tio_codegen"].exists
        print("TIO host=\(codegenHost ? "codegen" : "dynamic") generated shapes=\(generated)")
        XCTAssertEqual(generated, codegenHost,
                       "the generated shapes should be there exactly in the codegen host")
        let allIds = codegenHost ? ids + codegenIds : ids
        let allWrappers = codegenHost ? wrappers + codegenWrappers : wrappers

        for id in allIds {
            let query = app.descendants(matching: .any).matching(identifier: id)
            let types = (0..<query.count).map { String(query.element(boundBy: $0).elementType.rawValue) }
            print("TIO id \(id): count=\(query.count) types=\(types.joined(separator: "/"))")
            XCTAssertEqual(query.count, 1, "\(id): found \(query.count) times (types \(types))")
        }
        for (wrapper, own) in allWrappers {
            let container = app.descendants(matching: .any).matching(identifier: wrapper).firstMatch
            XCTAssertTrue(container.exists, "\(wrapper) missing")
            let buttons = container.descendants(matching: .button)
            let buttonIds = (0..<buttons.count).map { buttons.element(boundBy: $0).identifier }
            print("TIO \(wrapper): buttons=\(buttons.count) ids=\(buttonIds)")
            XCTAssertEqual(buttons.count, 1, "\(wrapper): the tap is not one button")
            XCTAssertEqual(buttonIds, [own], "\(wrapper): the button's identifier")
        }
    }
}
