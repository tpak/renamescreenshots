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
            path: "ScreenshotRenamer",
            exclude: ["Resources/Info.plist"]
        ),
        .testTarget(
            name: "ScreenshotRenamerTests",
            dependencies: ["ScreenshotRenamer"],
            path: "ScreenshotRenamerTests"
        )
    ]
)
