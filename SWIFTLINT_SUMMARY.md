# SwiftLint Violations Summary

**CI Run:** #21748287134 | **Date:** 2026-02-06 | **Branch:** feature/about-dialog  
**Total:** 18 violations (18 serious) grouped into 4 issues

## Issues Overview

| # | Issue Title | Rule | Count | Priority | Auto-Fix | Files Affected |
|---|-------------|------|-------|----------|----------|----------------|
| 1 | Fix line_length violations | `line_length` | 4 | Medium | ❌ | 4 source files |
| 2 | Refactor large tuple | `large_tuple` | 1 | Medium | ❌ | 1 test file |
| 3 | Remove trailing commas | `trailing_comma` | 3 | Low | ✅ | 2 test files |
| 4 | Fix parameter alignment | `vertical_parameter_alignment_on_call` | 10 | Medium | ❌ | 2 test files |

## Detailed Breakdown

### Issue 1: Line Length Violations (4)
- `PatternMatcher.swift:103` - 157 chars (37 over limit)
- `ScreenshotRenamer.swift:108` - 126 chars (6 over limit)
- `AppDelegate.swift:17` - 136 chars (16 over limit)
- `MenuBarController.swift:779` - 142 chars (22 over limit)

### Issue 2: Large Tuple (1)
- `PatternMatcherTests.swift:228` - Tuple has >2 members

### Issue 3: Trailing Commas (3)
- `PatternMatcherTests.swift:238`
- `ScreenshotRenamerTests.swift:218`
- `ScreenshotRenamerTests.swift:239`

### Issue 4: Parameter Alignment (10)
**DebugLoggerTests.swift (5):** Lines 53, 62, 88, 103, 109  
**ScreenshotRenamerTests.swift (5):** Lines 171, 173, 189, 207, 245

## Quick Actions

**Create all issues:**
```bash
./.github/ISSUE_TEMPLATES_SWIFTLINT/create-all-issues.sh
```

**Auto-fix trailing commas:**
```bash
swiftlint --fix
```

**Verify fixes:**
```bash
swiftlint lint --strict
swift test
```

## Files

- **[SWIFTLINT_ISSUES.md](SWIFTLINT_ISSUES.md)** - Full documentation with examples
- **[.github/ISSUE_TEMPLATES_SWIFTLINT/](.github/ISSUE_TEMPLATES_SWIFTLINT/)** - Individual issue templates
- **[create-all-issues.sh](.github/ISSUE_TEMPLATES_SWIFTLINT/create-all-issues.sh)** - Automated issue creation script
