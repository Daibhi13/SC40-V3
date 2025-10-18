import PackageDescription

let package = Package(
    name: "SC40ConnectivityTest",
    platforms: [.iOS(.v14)],
    products: [
        .executable(name: "SC40ConnectivityTest", targets: ["SC40ConnectivityTest"])
    ],
    targets: [
        .target(
            name: "SC40ConnectivityTest",
            dependencies: []
        )
    ]
)
