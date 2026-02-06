---
title: "Fix vertical parameter alignment in function calls"
labels: code-quality, swiftlint, testing
---

## Description

SwiftLint found 10 multi-line function calls where parameters are not vertically aligned. Proper alignment improves code readability.

## Files and Lines

### DebugLoggerTests.swift (5 violations)
- Line 53
- Line 62
- Line 88
- Line 103
- Line 109

### ScreenshotRenamerTests.swift (5 violations)
- Line 171
- Line 173
- Line 189
- Line 207
- Line 245

## Steps to Fix

1. For each violation, align function parameters vertically
2. Ensure opening and closing parentheses are properly positioned
3. Run `swiftlint lint --strict` to verify fixes
4. Ensure all tests still pass with `swift test`

## SwiftLint Rule

- **Rule:** `vertical_parameter_alignment_on_call`
- **Severity:** Warning (treated as error with --strict)

## Example Fix

```swift
// Before - misaligned:
someFunction(parameter1: value1,
    parameter2: value2,
             parameter3: value3)

// After - properly aligned:
someFunction(parameter1: value1,
             parameter2: value2,
             parameter3: value3)

// Alternative - all on one line if under 120 chars:
someFunction(parameter1: value1, parameter2: value2, parameter3: value3)
```

## Source

- **CI Run:** #21748287134
- **Branch:** feature/about-dialog
- **Date:** 2026-02-06
