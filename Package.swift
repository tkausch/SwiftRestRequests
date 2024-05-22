// swift-tools-version: 5.7
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
    ],
    targets: [
        .target(
            name: "SwiftRestRequests",
            dependencies: [.product(name: "Logging", package: "swift-log")]),
        .testTarget(
            name: "SwiftRestRequestsTests",
            dependencies: ["SwiftRestRequests"]),
    ]
)
