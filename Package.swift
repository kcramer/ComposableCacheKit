// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "ComposableCacheKit",
    platforms: [
        // TODO: Switch to constants again when added in future release.
        .macOS(.v10_15), .iOS(.v13), .watchOS(.v6), .tvOS(.v13), .macCatalyst(.v15)
    ],
    products: [
        .library(
            name: "ComposableCacheKit",
            targets: ["ComposableCacheKit"]
        )
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "ComposableCacheKit"
        ),
        .testTarget(
            name: "ComposableCacheKitTests",
            dependencies: ["ComposableCacheKit"]
        )
    ]
)
