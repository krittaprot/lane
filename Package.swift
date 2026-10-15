// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Lane",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Lane", path: "Sources/Lane")
    ],
    swiftLanguageModes: [.v5]
)
