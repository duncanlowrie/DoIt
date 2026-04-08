// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DoIt",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "DoIt",
            path: "Sources/DoIt"
        )
    ]
)
