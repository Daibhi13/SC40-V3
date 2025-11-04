// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SC40Models",
    platforms: [
        .iOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "SC40Models",
            targets: ["SC40Models"]
        ),
    ],
    targets: [
        .target(
            name: "SC40Models",
            dependencies: []
        ),
        .testTarget(
            name: "SC40ModelsTests",
            dependencies: ["SC40Models"]
        ),
    ]
)
