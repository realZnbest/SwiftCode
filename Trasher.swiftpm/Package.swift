// swift-tools-version: 5.10

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Trasher",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "Trasher",
            targets: ["AppModule"],
            bundleIdentifier: "dev.trasher.game",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .leaf),
            accentColor: .presetColor(.green),
            supportedDeviceFamilies: [
                .pad
            ],
            supportedInterfaceOrientations: [
                .landscapeRight,
                .landscapeLeft
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "Sources/AppModule"
        )
    ]
)
