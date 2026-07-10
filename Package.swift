// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FutureEchoCore",
    platforms: [
        .iOS(.v14),
        .macOS(.v12)
    ],
    products: [
        .library(name: "FutureEchoCore", targets: ["FutureEchoCore"])
    ],
    targets: [
        .target(name: "FutureEchoCore"),
        .testTarget(name: "FutureEchoCoreTests", dependencies: ["FutureEchoCore"])
    ],
    swiftLanguageVersions: [.v5]
)

