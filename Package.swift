// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SpankKit",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(name: "SpankKit", targets: ["SpankKit"]),
        .library(name: "SpankKitAssets", targets: ["SpankKitAssets"]),
    ],
    targets: [
        // Development: local path. For release, switch to:
        // .binaryTarget(name: "Spank", url: "https://github.com/AmatsuZero/spank/releases/download/v<VERSION>/Spank.xcframework.zip", checksum: "<SHA256>")
        .binaryTarget(
            name: "Spank",
            path: "dist/Spank.xcframework"
        ),
        .target(
            name: "SpankKit",
            dependencies: ["Spank"]
        ),
        .target(
            name: "SpankKitAssets",
            dependencies: ["SpankKit"],
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "SpankKitTests",
            dependencies: ["SpankKit", "SpankKitAssets"]
        ),
    ]
)
