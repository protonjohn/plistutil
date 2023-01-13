// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PlistUtil",
    products: [
        .executable(name: "plistutil", targets: ["PlistUtil"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0")
    ],
    targets: [
        .executableTarget(name: "PlistUtil",
                          dependencies: [
                            .product(name: "ArgumentParser",
                                     package: "swift-argument-parser")
                          ]
        ),
        .testTarget(
            name: "PlistUtilTests",
            dependencies: [
                .target(name: "PlistUtil"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
    ]
)
