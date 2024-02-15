// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FCKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "FCKit", targets: ["FCKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/EvanCooper9/ECKit", branch: "main"),
        .package(url: "https://github.com/hmlongco/Factory", from: "2.0.0"),
    ],
    targets: [
        .target(name: "FCKit", dependencies: [
            "ECKit",
            "Factory"
        ]),
        .testTarget(name: "FCKitTests", dependencies: ["FCKit"]),
    ]
)
