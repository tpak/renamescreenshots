import Foundation

// Load the ScreenshotRenamer module
@testable import ScreenshotRenamer

// Create a test screenshot file
let testDir = FileManager.default.temporaryDirectory.appendingPathComponent("screenshot-test-\(UUID().uuidString)")
try! FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)

print("Test directory: \(testDir.path)")

// Create a test screenshot file with 12-hour format
let testFile = testDir.appendingPathComponent("Screenshot 2024-01-03 at 1.23.45 PM.png")
try! "test".write(to: testFile, atomically: true, encoding: .utf8)

print("Created test file: \(testFile.lastPathComponent)")

// Run the renamer
let settings = ScreenshotSettings(location: testDir, prefix: "Screenshot")
let renamer = ScreenshotRenamer(settings: settings, whitelist: [testDir])

let result = try! renamer.renameScreenshots()

print("\nResults:")
print("  Total files: \(result.totalFiles)")
print("  Renamed: \(result.renamedFiles)")
print("  Errors: \(result.errors)")

// Check what files exist now
let contents = try! FileManager.default.contentsOfDirectory(at: testDir, includingPropertiesForKeys: nil)
print("\nFinal files:")
for file in contents {
    print("  - \(file.lastPathComponent)")
}

// Cleanup
try! FileManager.default.removeItem(at: testDir)

if result.renamedFiles > 0 {
    print("\n✅ SUCCESS: Renaming works!")
} else {
    print("\n❌ FAILED: No files renamed")
}
