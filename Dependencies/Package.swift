// swift-tools-version: 5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Dependencies",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "Dependencies",
            targets: ["Dependencies"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/algolia/algoliasearch-client-swift", from: "8.0.0"),
        .package(url: "https://github.com/pointfreeco/combine-schedulers", from: "0.9.1"),
        .package(url: "https://github.com/EvanCooper9/ECKit", branch: "main"),
        .package(url: "https://github.com/hmlongco/Factory", from: "2.0.0"),
        .package(url: "https://github.com/JohnSundell/Files", from: "4.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.8.0"),
        .package(url: "https://github.com/RevenueCat/purchases-ios", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Dependencies",
            dependencies: [
                .product(name: "AlgoliaSearchClient", package: "algoliasearch-client-swift"),
                .product(name: "CombineSchedulers", package: "combine-schedulers"),
                "ECKit",
                "Factory",
                "Files",

                // Firebase
                .product(name: "FirebaseAnalyticsSwift", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuthCombine-Community", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestoreCombine-Community", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestoreSwift", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFunctionsCombine-Community", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorageCombine-Community", package: "firebase-ios-sdk"),

                .product(name: "RevenueCat", package: "purchases-ios"),
                .product(name: "Algorithms", package: "swift-algorithms")
            ]
        ),
    ]
)
