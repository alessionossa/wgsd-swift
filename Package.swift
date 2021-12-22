// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "wgsd-swift",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "wgsd-swift",
            targets: ["wgsd-swift"]),
    ],
    dependencies: [
        .package(name: "Resolver", url: "https://github.com/alessionossa/swift-resolver.git", from: "0.4.0"),
        .package(url: "https://github.com/swift-extras/swift-extras-base64.git", from: "0.7.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "wgsd-swift",
            dependencies: [.product(name: "Resolver", package: "Resolver"),
                           .product(name: "ExtrasBase64", package: "swift-extras-base64"),
                          ]
        ),
        .testTarget(
            name: "wgsd-swiftTests",
            dependencies: ["wgsd-swift"]),
    ]
)
