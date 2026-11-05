// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "DotaPingCoreChecks",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "PingCore"),
        .executableTarget(name: "PingCoreChecks", dependencies: ["PingCore"])
    ]
)
