// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "ScreenshotRenamer",
    platforms: [.macOS(.v11)],
    products: [
        .executable(
            name: "ScreenshotRenamer",
            targets: ["ScreenshotRenamer"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ScreenshotRenamer",
            dependencies: [],
            exclude: ["Resources/Info.plist", "Resources/AppIcon.icns"]
        ),
        .testTarget(
            name: "ScreenshotRenamerTests",
            dependencies: ["ScreenshotRenamer"]
        )
    ]
)
