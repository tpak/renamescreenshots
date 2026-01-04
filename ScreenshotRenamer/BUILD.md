# Building the Swift Screenshot Renamer

## Creating the Xcode Project

Since Xcode project files are binary and complex, here are instructions to create the project in Xcode:

### Step 1: Create New Xcode Project

1. Open Xcode
2. File → New → Project
3. Select **macOS** → **App**
4. Configure:
   - **Product Name**: ScreenshotRenamer
   - **Team**: Your team (or None for local development)
   - **Organization Identifier**: com.tirpak
   - **Interface**: Storyboard (we won't use it)
   - **Language**: Swift
   - **Uncheck** "Use Core Data"
   - **Uncheck** "Include Tests" (we'll add manually)
5. Save in the `ScreenshotRenamer` directory

### Step 2: Add Source Files

Drag these folders into the Xcode project navigator:

- `ScreenshotRenamer/App/` → Add all .swift files
- `ScreenshotRenamer/Core/` → Add all .swift files
- `ScreenshotRenamer/FileWatcher/` → Add all .swift files
- `ScreenshotRenamer/Models/` → Add all .swift files
- `ScreenshotRenamer/Utilities/` → Add all .swift files

Make sure to:
- ✅ Check "Copy items if needed"
- ✅ Select "Create groups"
- ✅ Add to target: ScreenshotRenamer

### Step 3: Configure Info.plist

Replace the default `Info.plist` with `Resources/Info.plist`, or manually add:

```xml
<key>LSUIElement</key>
<true/>
```

This hides the dock icon (menu bar only app).

### Step 4: Add Test Target

1. File → New → Target
2. Select **macOS** → **Unit Testing Bundle**
3. Name: ScreenshotRenamerTests
4. Add test files:
   - `ScreenshotRenamerTests/PatternMatcherTests.swift`
   - `ScreenshotRenamerTests/FileValidatorTests.swift`

### Step 5: Configure Build Settings

In project settings → Build Settings:

**Deployment**:
- **macOS Deployment Target**: 11.0 or later

**Signing & Capabilities**:
- **Signing**: Automatically manage signing
- **Team**: Your team (or select "Sign to Run Locally")

**Frameworks and Libraries**:
- **CoreServices.framework** (for FSEvents)

### Step 6: Build and Run

1. Select **ScreenshotRenamer** scheme
2. Build: `⌘B`
3. Run: `⌘R`

The menu bar icon should appear!

---

## Alternative: Command-Line Build Script

If you prefer not to use Xcode GUI, here's a Swift Package Manager approach:

### Create Package.swift

```swift
// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "ScreenshotRenamer",
    platforms: [.macOS(.v11)],
    products: [
        .executable(name: "ScreenshotRenamer", targets: ["ScreenshotRenamer"])
    ],
    targets: [
        .executableTarget(
            name: "ScreenshotRenamer",
            dependencies: [],
            path: "ScreenshotRenamer",
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "ScreenshotRenamerTests",
            dependencies: ["ScreenshotRenamer"],
            path: "ScreenshotRenamerTests"
        )
    ]
)
```

### Build with Swift Package Manager

```bash
# Build
swift build -c release

# Run
.build/release/ScreenshotRenamer
```

**Note**: Swift Package Manager produces a CLI executable, not a .app bundle. You'll need to manually create the .app structure for menu bar functionality.

---

## Creating .app Bundle Manually

If using Swift PM, create the bundle structure:

```bash
# Create bundle structure
mkdir -p ScreenshotRenamer.app/Contents/MacOS
mkdir -p ScreenshotRenamer.app/Contents/Resources

# Copy executable
cp .build/release/ScreenshotRenamer ScreenshotRenamer.app/Contents/MacOS/

# Copy Info.plist
cp ScreenshotRenamer/Resources/Info.plist ScreenshotRenamer.app/Contents/

# Make executable
chmod +x ScreenshotRenamer.app/Contents/MacOS/ScreenshotRenamer

# Code sign (ad-hoc)
codesign --force --deep --sign - ScreenshotRenamer.app
```

---

## Xcode Project Configuration Reference

For manual `.xcodeproj` editing, key settings:

**Project.pbxproj**:
```
PRODUCT_NAME = ScreenshotRenamer
PRODUCT_BUNDLE_IDENTIFIER = com.tirpak.screenshot-renamer
MACOSX_DEPLOYMENT_TARGET = 11.0
INFOPLIST_FILE = ScreenshotRenamer/Resources/Info.plist
CODE_SIGN_STYLE = Automatic
COMBINE_HIDPI_IMAGES = YES
```

**Build Phases**:
1. **Compile Sources**: All .swift files
2. **Link Binary**: CoreServices.framework
3. **Copy Resources**: Info.plist, Assets.xcassets (if any)

---

## Troubleshooting Build Issues

**"Cannot find AppDelegate in scope"**
- Make sure `@main` attribute is on `AppDelegate` class
- Check all files are added to the target

**"Module 'CoreServices' not found"**
- Add CoreServices.framework in Build Phases → Link Binary

**"Info.plist not found"**
- Update INFOPLIST_FILE build setting to point to correct path

**Signing failures**
- For local development: Select "Sign to Run Locally"
- For distribution: Requires Apple Developer account

---

## Recommended: Use Xcode

While Swift Package Manager works, **Xcode is strongly recommended** for macOS app development:

- Visual project management
- Integrated testing (⌘U)
- Debugger support
- Asset catalog management
- Code signing UI
- Easier .app bundle creation

The manual setup above is provided for completeness and understanding.
