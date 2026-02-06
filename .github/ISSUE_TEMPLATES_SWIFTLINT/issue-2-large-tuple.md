---
title: "Refactor large tuple in PatternMatcherTests.swift"
labels: code-quality, swiftlint, testing
---

## Description

SwiftLint found a tuple with more than 2 members in the test file, which reduces code readability.

## File and Line

- `Tests/ScreenshotRenamerTests/PatternMatcherTests.swift:228`

## Steps to Fix

1. Locate the tuple at line 228 in `PatternMatcherTests.swift`
2. Replace the tuple with either:
   - A struct with named properties for better clarity, OR
   - Break into multiple separate variables, OR
   - Use an array if elements are homogeneous
3. Run `swiftlint lint --strict` to verify the fix
4. Ensure all tests still pass with `swift test`

## SwiftLint Rule

- **Rule:** `large_tuple`  
- **Maximum allowed:** 2 tuple members
- **Severity:** Error

## Example Fix

```swift
// Before:
let data = (value1, value2, value3, value4)

// After - using a struct:
struct TestData {
    let value1: Type1
    let value2: Type2
    let value3: Type3
    let value4: Type4
}
let data = TestData(value1: ..., value2: ..., value3: ..., value4: ...)
```

## Source

- **CI Run:** #21748287134
- **Branch:** feature/about-dialog
- **Date:** 2026-02-06
