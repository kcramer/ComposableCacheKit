// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "ComposableCacheKit",
    platforms: [
        .macOS(.v10_12), .iOS(.v10), .watchOS(.v3), .tvOS(.v10)
    ],
    products: [
        .library(
            name: "ComposableCacheKit",
            targets: ["ComposableCacheKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/khanlou/Promise", .upToNextMajor(from: "2.0.1"))
    ],
    targets: [
        .target(
            name: "ComposableCacheKit",
            dependencies: ["Promise"],
            path: "ComposableCacheKit"
        ),
        .testTarget(
            name: "ComposableCacheKitTests",
            dependencies: ["ComposableCacheKit"],
            path: "ComposableCacheKitTests"
        )
    ]
)
