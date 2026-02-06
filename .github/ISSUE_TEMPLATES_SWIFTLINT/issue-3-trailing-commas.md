---
title: "Remove trailing commas in collection literals"
labels: code-quality, swiftlint, testing, good first issue
---

## Description

SwiftLint found 3 collection literals with trailing commas. While trailing commas can be useful in some languages, Swift's style guide discourages them.

## Files and Lines

1. `Tests/ScreenshotRenamerTests/PatternMatcherTests.swift:238`
2. `Tests/ScreenshotRenamerTests/ScreenshotRenamerTests.swift:218`
3. `Tests/ScreenshotRenamerTests/ScreenshotRenamerTests.swift:239`

## Steps to Fix

1. Find each array/dictionary literal at the specified lines
2. Remove the trailing comma before the closing bracket/brace
3. Run `swiftlint lint --strict` to verify fixes
4. Ensure all tests still pass with `swift test`

## Auto-Fix Available

This can be automatically fixed with:
```bash
swiftlint --fix
```

## SwiftLint Rule

- **Rule:** `trailing_comma`
- **Severity:** Warning (treated as error with --strict)

## Example Fix

```swift
// Before:
let items = [
    "item1",
    "item2",
    "item3",  // ❌ trailing comma
]

// After:
let items = [
    "item1",
    "item2",
    "item3"   // ✅ no trailing comma
]
```

## Source

- **CI Run:** #21748287134
- **Branch:** feature/about-dialog
- **Date:** 2026-02-06
