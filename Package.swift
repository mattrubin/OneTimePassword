// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "OneTimePassword",
    platforms: [
        .iOS(.v8),
        .watchOS(.v2)
    ],
    products: [
        .library(
            name: "OneTimePassword",
            targets: ["OneTimePassword"])
    ],
    dependencies: [
        .package(url: "https://github.com/bas-d/Base32", .branch("spm"))
    ],
    targets: [
        .target(name: "OneTimePassword", dependencies: ["Base32"], path: "Sources"),
        .testTarget(name: "OneTimePasswordTests", dependencies: ["OneTimePassword"], path: "Tests")
    ]
)
