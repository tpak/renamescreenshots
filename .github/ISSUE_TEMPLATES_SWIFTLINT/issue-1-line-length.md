---
title: "Fix line_length violations in source files"
labels: code-quality, swiftlint, good first issue
---

## Description

SwiftLint found 4 lines that exceed the 120 character limit. These should be broken into multiple lines for better readability.

## Files and Lines

1. `Sources/ScreenshotRenamer/Core/PatternMatcher.swift:103` - 157 characters
2. `Sources/ScreenshotRenamer/Core/ScreenshotRenamer.swift:108` - 126 characters  
3. `Sources/ScreenshotRenamer/App/AppDelegate.swift:17` - 136 characters
4. `Sources/ScreenshotRenamer/App/MenuBarController.swift:779` - 142 characters

## Steps to Fix

1. Review each line in the files above
2. Break long lines into multiple lines using appropriate line breaks
3. Ensure code remains readable and maintains Swift style conventions
4. Run `swiftlint lint --strict` to verify fixes
5. Ensure all tests still pass with `swift test`

## SwiftLint Rule

- **Rule:** `line_length`  
- **Maximum allowed:** 120 characters
- **Severity:** Error

## Source

- **CI Run:** #21748287134
- **Branch:** feature/about-dialog
- **Date:** 2026-02-06
