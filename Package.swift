// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SafeConnectionSdk",
    platforms: [
        .iOS("15.5"),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SafeConnectionSdk",
            targets: ["SafeConnectionSdk"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Moya/Moya", .upToNextMajor(from: "15.0.3")),
        .package(url: "https://github.com/marmelroy/PhoneNumberKit", .upToNextMajor(from: "4.1.3")),
        .package(url: "https://github.com/realm/realm-swift", .upToNextMajor(from: "10.54.5")),
        .package(url: "https://github.com/ZipArchive/ZipArchive", .upToNextMajor(from: "2.6.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SafeConnectionSdk",
            dependencies: [
                .product(name: "Moya", package: "Moya"),
                .product(name: "PhoneNumberKit", package: "PhoneNumberKit"),
                .product(name: "RealmSwift", package: "realm-swift"),
                .product(name: "ZipArchive", package: "ZipArchive"),
            ]
        ),
        .testTarget(
            name: "SafeConnectionSdkTests",
            dependencies: ["SafeConnectionSdk"]
        ),
    ]
)
