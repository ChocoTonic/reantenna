// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Threadline",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "AntennaCore", targets: ["AntennaCore"]),
        .executable(name: "AntennaCoreSmoke", targets: ["AntennaCoreSmoke"]),
        .executable(name: "ThreadlinePreview", targets: ["ThreadlinePreview"]),
    ],
    targets: [
        .target(name: "AntennaCore"),
        .executableTarget(name: "AntennaCoreSmoke", dependencies: ["AntennaCore"]),
        .executableTarget(
            name: "ThreadlinePreview",
            dependencies: ["AntennaCore"],
            path: "AntennaApp"
        ),
        .testTarget(name: "AntennaCoreTests", dependencies: ["AntennaCore"]),
    ]
)
