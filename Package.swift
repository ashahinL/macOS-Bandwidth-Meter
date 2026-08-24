// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BandwidthMeter",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "BandwidthMeter", targets: ["BandwidthMeter"]),
        .executable(name: "bandwidth-meter", targets: ["BandwidthMeterCLI"]),
        .executable(name: "MeterSelfTest", targets: ["MeterSelfTest"]),
        .library(name: "MeterCore", targets: ["MeterCore"]),
    ],
    targets: [
        .target(
            name: "InterfaceCounters",
            path: "Sources/InterfaceCounters",
            publicHeadersPath: "include"
        ),
        .target(
            name: "MeterCore",
            dependencies: [],
            path: "Sources/MeterCore"
        ),
        .executableTarget(
            name: "BandwidthMeter",
            dependencies: ["MeterCore", "InterfaceCounters"],
            path: "Sources/BandwidthMeter",
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit"),
                .linkedFramework("Charts"),
                .linkedFramework("ServiceManagement"),
            ]
        ),
        .executableTarget(
            name: "BandwidthMeterCLI",
            dependencies: ["MeterCore"],
            path: "Sources/BandwidthMeterCLI"
        ),
        .executableTarget(
            name: "MeterSelfTest",
            dependencies: ["MeterCore"],
            path: "Sources/MeterSelfTest"
        ),
    ]
)
