// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Snake",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Snake"
        )
    ]
)
