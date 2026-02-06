# SwiftLint Issue Templates

This directory contains issue templates generated from SwiftLint CI run #21748287134 (2026-02-06).

## Issues to Create

These templates can be copy-pasted to create GitHub issues:

1. **issue-1-line-length.md** - Fix 4 line length violations (157, 126, 136, 142 chars)
2. **issue-2-large-tuple.md** - Refactor large tuple in PatternMatcherTests.swift
3. **issue-3-trailing-commas.md** - Remove 3 trailing commas (auto-fixable)
4. **issue-4-parameter-alignment.md** - Fix 10 parameter alignment violations

## How to Use

### Option 1: Create Issues Manually

Copy the content from each issue file and paste into a new GitHub issue at:
https://github.com/tpak/renamescreenshots/issues/new

The frontmatter contains suggested title and labels.

### Option 2: Use GitHub CLI

```bash
# Create issue from template
gh issue create --title "Fix line_length violations in source files" \
  --label "code-quality,swiftlint,good first issue" \
  --body-file .github/ISSUE_TEMPLATES_SWIFTLINT/issue-1-line-length.md

gh issue create --title "Refactor large tuple in PatternMatcherTests.swift" \
  --label "code-quality,swiftlint,testing" \
  --body-file .github/ISSUE_TEMPLATES_SWIFTLINT/issue-2-large-tuple.md

gh issue create --title "Remove trailing commas in collection literals" \
  --label "code-quality,swiftlint,testing,good first issue" \
  --body-file .github/ISSUE_TEMPLATES_SWIFTLINT/issue-3-trailing-commas.md

gh issue create --title "Fix vertical parameter alignment in function calls" \
  --label "code-quality,swiftlint,testing" \
  --body-file .github/ISSUE_TEMPLATES_SWIFTLINT/issue-4-parameter-alignment.md
```

### Option 3: Bulk Create Script

Run the provided script to create all issues at once:

```bash
cd /home/runner/work/renamescreenshots/renamescreenshots
./.github/ISSUE_TEMPLATES_SWIFTLINT/create-all-issues.sh
```

## Summary

- **Total Violations:** 18
- **Total Issues:** 4 (grouped by violation type)
- **Priority Distribution:**
  - High: 0
  - Medium: 3 (line length, large tuple, parameter alignment)
  - Low: 1 (trailing commas - auto-fixable)
- **Good First Issues:** 2 (line length, trailing commas)

## Source Information

- **CI Run:** #21748287134
- **Branch:** feature/about-dialog
- **Date:** 2026-02-06
- **SwiftLint Version:** 0.63.2

## Cleanup

After all issues are created and resolved, this directory can be deleted.
