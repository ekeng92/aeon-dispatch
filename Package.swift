// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AEONDispatch",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "AEONDispatch",
            path: "Sources/AEONDispatch"
        ),
        .testTarget(
            name: "AEONDispatchTests",
            dependencies: ["AEONDispatch"],
            path: "Tests/AEONDispatchTests"
        )
    ]
)
