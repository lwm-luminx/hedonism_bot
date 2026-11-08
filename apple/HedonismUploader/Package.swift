// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HedonismUploader",
    platforms: [.macOS(.v14), .iOS(.v16)],
    products: [
        .library(name: "UploaderCore", targets: ["UploaderCore"]),
        .library(name: "CogsworthIPC", targets: ["CogsworthIPC"]),
        .executable(name: "HedonismUploader", targets: ["HedonismUploader"]),
    ],
    targets: [
        // Scanning cards, the upload ledger and the hedonism_bot API client (no UI).
        .target(name: "UploaderCore"),
        .target(name: "CogsworthIPC"),
        // The menu bar app: watches for SD cards and drives UploaderCore.
        .executableTarget(name: "HedonismUploader", dependencies: ["UploaderCore", "CogsworthIPC"], resources: [.process("Resources")]),
        // Disk images attached as stand-in SD cards for the tests (macOS only; needs hdiutil).
        .target(name: "CardTestSupport", path: "Tests/CardTestSupport"),
        .testTarget(name: "UploaderCoreTests", dependencies: ["UploaderCore", "CardTestSupport"]),
        .testTarget(name: "DesktopServicesTests", dependencies: ["HedonismUploader", "CardTestSupport"]),
    ]
)
