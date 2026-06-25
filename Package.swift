// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpsRoom",
    platforms: [
        .iOS(.v16),
        .macOS(.v13), // Enables `swift test` on Mac CI; primary target remains iOS.
    ],
    products: [
        .library(
            name: "OpsRoom",
            targets: ["OpsRoom"]
        ),
    ],
    targets: [
        .target(
            name: "OpsRoom",
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        ),
        .testTarget(
            name: "OpsRoomTests",
            dependencies: ["OpsRoom"]
        ),
    ]
)
