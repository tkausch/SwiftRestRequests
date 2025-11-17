// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftRestRequests",
    platforms: [
            .iOS(.v15),
            .watchOS(.v8),
            .tvOS(.v15),
            .macOS(.v12)
    ],
    products: [
        .library(
            name: "SwiftRestRequests",
            targets: ["SwiftRestRequests"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log", from: "1.5.4"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "SwiftRestRequests",
            dependencies: [.product(name: "Logging", package: "swift-log")],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .testTarget(
            name: "SwiftRestRequestsTests",
            dependencies: ["SwiftRestRequests"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
