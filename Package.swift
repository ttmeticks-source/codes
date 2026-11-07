// swift-tools-version: 5.3
import PackageDescription
let package = Package(name: "OceanForge", platforms: [.macOS(.v11)], products: [.executable(name: "OceanForge", targets: ["OceanForge"])], targets: [.executableTarget(name: "OceanForge", path: "Sources/OceanForge")])
