// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftJsonUI",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftJsonUI",
            targets: ["SwiftJsonUI"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftJsonUI",
            path: "Sources",
            resources: [
                // jsonui-cli's shared/core/type_synonyms.json, vendored byte
                // for byte (CI compares it with the pinned jsonui-cli ref).
                // Dynamic draws a type-synonym spelling as this table says.
                .copy("SwiftJsonUI/Resources/type_synonyms.json")
            ]),
        .testTarget(
            name: "SwiftJsonUITests",
            dependencies: ["SwiftJsonUI"],
            path: "Tests/SwiftJsonUITests",
            resources: [
                .copy("Fixtures")
            ]),
    ]
)
