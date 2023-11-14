// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PlistUtil",
    platforms: [.macOS(.v11), .iOS(.v15)],
    products: [
        .executable(name: "plistutil", targets: ["PlistUtil"]),
        .library(name: "CodingCollection", targets: ["CodingCollection"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.3"),
        .package(url: "https://github.com/jpsim/Yams", exact: "5.0.6"),
    ],
    targets: [
        .executableTarget(name: "PlistUtil",
                          dependencies: [
                            "CodingCollection",
                            "Yams",
                            .product(name: "ArgumentParser",
                                     package: "swift-argument-parser")
                          ]
        ),
        .target(name: "CodingCollection"),
        .testTarget(
            name: "CodingCollectionTests",
            dependencies: [
                "CodingCollection"
            ]
        ),
        .testTarget(
            name: "PlistUtilTests",
            dependencies: [
                "CodingCollection",
                .target(name: "PlistUtil"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
    ]
)
