// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FCKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "FCKit", targets: ["FCKit"]),
        .library(name: "FCKitMocks", targets: ["FCKitMocks"])
    ],
    dependencies: [
        .package(url: "https://github.com/CombineCommunity/CombineExt", from: "1.0.0"),
        .package(url: "https://github.com/EvanCooper9/ECKit", branch: "main"),
        .package(url: "https://github.com/hmlongco/Factory", from: "2.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0"),
    ],
    targets: [
        .target(name: "FCKit", dependencies: [
            "CombineExt",
            "ECKit",
            "Factory",
            .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
            .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
            .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
            .product(name: "FirebaseFirestoreCombine-Community", package: "firebase-ios-sdk"),
            .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
        ]),
        .target(name: "FCKitMocks", dependencies: [
            "FCKit",
            .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
            .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
        ]),
        .testTarget(name: "FCKitTests", dependencies: [
            "FCKit",
            "FCKitMocks"
        ]),
    ]
)
