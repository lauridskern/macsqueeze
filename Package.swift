// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "MacSqueeze",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "MacSqueeze", targets: ["MacSqueeze"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ainame/Swift-WebP.git", exact: "0.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "MacSqueeze",
            dependencies: [
                .product(name: "WebP", package: "Swift-WebP"),
            ],
            path: "Sources/MacSqueeze"
        ),
        .testTarget(
            name: "MacSqueezeTests",
            dependencies: ["MacSqueeze"],
            path: "Tests/MacSqueezeTests"
        ),
    ]
)
