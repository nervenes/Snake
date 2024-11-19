//
//  Package.swift
//  Snake
//
//  Created by Evren Sen on 2024-11-19.
//
//  swift-tools-version: 6.0
//

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
