// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HedonismUploader",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "HedonismUploader", targets: ["HedonismUploader"]),
    ],
    targets: [
        // Scanning cards, the upload ledger and the hedonism_bot API client (no UI).
        .target(name: "UploaderCore"),
        // The menu bar app: watches for SD cards and drives UploaderCore.
        .executableTarget(name: "HedonismUploader", dependencies: ["UploaderCore"]),
        .testTarget(name: "UploaderCoreTests", dependencies: ["UploaderCore"]),
    ]
)
