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
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "ScreenshotRenamer",
            dependencies: ["Sparkle"],
            exclude: ["Resources/Info.plist", "Resources/AppIcon.icns"]
        ),
        .testTarget(
            name: "ScreenshotRenamerTests",
            dependencies: ["ScreenshotRenamer"]
        )
    ]
)
