// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "DotaPing",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "DotaPing", targets: ["DotaPing"])],
    targets: [
        .target(name: "PingCore"),
        .executableTarget(name: "DotaPing", dependencies: ["PingCore"], resources: [.copy("Resources/Pings"), .copy("Resources/Wheel"), .copy("Resources/Particles"), .copy("Resources/Sounds"), .copy("Resources/Branding")]),
        .executableTarget(name: "PingCoreChecks", dependencies: ["PingCore"], path: "Tests/PingCoreTests")
    ]
)
