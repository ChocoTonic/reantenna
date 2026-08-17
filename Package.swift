// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ReAntenna",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "AntennaCore", targets: ["AntennaCore"]),
        .executable(name: "AntennaCoreSmoke", targets: ["AntennaCoreSmoke"]),
        .executable(name: "ReAntennaPreview", targets: ["ReAntennaPreview"]),
    ],
    targets: [
        .target(name: "AntennaCore"),
        .executableTarget(name: "AntennaCoreSmoke", dependencies: ["AntennaCore"]),
        .executableTarget(
            name: "ReAntennaPreview",
            dependencies: ["AntennaCore"],
            path: "ReAntennaApp"
        ),
        .testTarget(name: "AntennaCoreTests", dependencies: ["AntennaCore"]),
    ]
)
