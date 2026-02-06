# SwiftLint Violations - Issues to Create

This document contains GitHub issues that need to be created for SwiftLint violations found in CI run #21748287134 (2026-02-06) on the `feature/about-dialog` branch.

**Total Violations:** 18 (18 serious)

## Quick Start - Creating the Issues

**Recommended: Use the automated script**
```bash
./.github/ISSUE_TEMPLATES_SWIFTLINT/create-all-issues.sh
```

This will create all 4 issues automatically using the GitHub CLI. See [.github/ISSUE_TEMPLATES_SWIFTLINT/README.md](.github/ISSUE_TEMPLATES_SWIFTLINT/README.md) for alternative methods.

---

## Issue 1: Fix Line Length Violations (4 files)

**Title:** Fix line_length violations in source files

**Labels:** `code-quality`, `swiftlint`, `good first issue`

**Priority:** Medium

**Description:**

SwiftLint found 4 lines that exceed the 120 character limit. These should be broken into multiple lines for better readability.

**Files and Lines:**
1. `Sources/ScreenshotRenamer/Core/PatternMatcher.swift:103` - 157 characters
2. `Sources/ScreenshotRenamer/Core/ScreenshotRenamer.swift:108` - 126 characters  
3. `Sources/ScreenshotRenamer/App/AppDelegate.swift:17` - 136 characters
4. `Sources/ScreenshotRenamer/App/MenuBarController.swift:779` - 142 characters

**Steps to Fix:**
1. Review each line in the files above
2. Break long lines into multiple lines using appropriate line breaks
3. Ensure code remains readable and maintains Swift style conventions
4. Run `swiftlint lint --strict` to verify fixes
5. Ensure all tests still pass with `swift test`

**SwiftLint Rule:** `line_length`  
**Maximum allowed:** 120 characters

---

## Issue 2: Fix Large Tuple Violation in PatternMatcherTests

**Title:** Refactor large tuple in PatternMatcherTests.swift

**Labels:** `code-quality`, `swiftlint`, `testing`

**Priority:** Medium

**Description:**

SwiftLint found a tuple with more than 2 members in the test file, which reduces code readability.

**File and Line:**
- `Tests/ScreenshotRenamerTests/PatternMatcherTests.swift:228`

**Steps to Fix:**
1. Locate the tuple at line 228 in `PatternMatcherTests.swift`
2. Replace the tuple with either:
   - A struct with named properties for better clarity, OR
   - Break into multiple separate variables, OR
   - Use an array if elements are homogeneous
3. Run `swiftlint lint --strict` to verify the fix
4. Ensure all tests still pass with `swift test`

**SwiftLint Rule:** `large_tuple`  
**Maximum allowed:** 2 tuple members

**Example Fix:**
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

---

## Issue 3: Remove Trailing Commas from Test Files

**Title:** Remove trailing commas in collection literals (3 test files)

**Labels:** `code-quality`, `swiftlint`, `testing`, `good first issue`

**Priority:** Low

**Description:**

SwiftLint found 3 collection literals with trailing commas. While trailing commas can be useful in some languages, Swift's style guide discourages them.

**Files and Lines:**
1. `Tests/ScreenshotRenamerTests/PatternMatcherTests.swift:238`
2. `Tests/ScreenshotRenamerTests/ScreenshotRenamerTests.swift:218`
3. `Tests/ScreenshotRenamerTests/ScreenshotRenamerTests.swift:239`

**Steps to Fix:**
1. Find each array/dictionary literal at the specified lines
2. Remove the trailing comma before the closing bracket/brace
3. Run `swiftlint lint --strict` to verify fixes
4. Ensure all tests still pass with `swift test`

**SwiftLint Rule:** `trailing_comma`

**Example Fix:**
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

---

## Issue 4: Fix Vertical Parameter Alignment in Test Files

**Title:** Fix vertical parameter alignment in function calls (10 violations)

**Labels:** `code-quality`, `swiftlint`, `testing`

**Priority:** Medium

**Description:**

SwiftLint found 10 multi-line function calls where parameters are not vertically aligned. Proper alignment improves code readability.

**Files and Lines:**

**DebugLoggerTests.swift (5 violations):**
- Line 53
- Line 62
- Line 88
- Line 103
- Line 109

**ScreenshotRenamerTests.swift (5 violations):**
- Line 171
- Line 173
- Line 189
- Line 207
- Line 245

**Steps to Fix:**
1. For each violation, align function parameters vertically
2. Ensure opening and closing parentheses are properly positioned
3. Run `swiftlint lint --strict` to verify fixes
4. Ensure all tests still pass with `swift test`

**SwiftLint Rule:** `vertical_parameter_alignment_on_call`

**Example Fix:**
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

---

## CI Workflow Information

**Run ID:** 21748287134  
**Branch:** feature/about-dialog  
**Date:** 2026-02-06  
**SwiftLint Version:** 0.63.2  
**Workflow:** `.github/workflows/swiftlint.yml`

**View Full Logs:**
```bash
gh run view 21748287134 --log
```

---

## Fixing All Issues

To fix all issues at once:

1. Clone the repository and checkout the branch:
   ```bash
   git checkout feature/about-dialog
   ```

2. Install SwiftLint:
   ```bash
   brew install swiftlint
   ```

3. Run SwiftLint to see all violations:
   ```bash
   swiftlint lint --strict
   ```

4. Fix violations following the guidance above

5. Verify fixes:
   ```bash
   swiftlint lint --strict
   swift test
   ```

6. Commit and push:
   ```bash
   git add .
   git commit -m "fix: resolve SwiftLint violations"
   git push
   ```

---

## Automation Option

SwiftLint can auto-fix some violations:

```bash
swiftlint --fix
```

This will automatically fix:
- Trailing commas
- Some formatting issues

Manual fixes still needed for:
- Line length violations (requires code restructuring)
- Large tuples (requires refactoring)
- Parameter alignment (requires manual formatting)

---

**Created:** 2026-02-06  
**Source:** SwiftLint CI Run #21748287134
