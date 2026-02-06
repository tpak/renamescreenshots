# SwiftLint CI Failures - Issue Creation Guide

This PR documents 18 SwiftLint violations found in CI run #21748287134 (2026-02-06) on the `feature/about-dialog` branch and provides ready-to-use templates for creating GitHub issues.

## What Was Done

✅ **Analyzed** SwiftLint workflow run #21748287134  
✅ **Extracted** all 18 violations from the CI logs  
✅ **Categorized** violations into 4 logical issue groups  
✅ **Created** individual issue templates with:
  - Clear descriptions
  - File and line references  
  - Steps to fix
  - Code examples
  - SwiftLint rule documentation

## Files Created

### Summary Documents (Root Directory)
- **`SWIFTLINT_SUMMARY.md`** - Quick reference table with all violations
- **`SWIFTLINT_ISSUES.md`** - Comprehensive guide with examples and fix instructions
- **`README_SWIFTLINT.md`** - This file

### Issue Templates (`.github/ISSUE_TEMPLATES_SWIFTLINT/`)
- **`issue-1-line-length.md`** - 4 line length violations (Medium priority)
- **`issue-2-large-tuple.md`** - 1 large tuple violation (Medium priority)
- **`issue-3-trailing-commas.md`** - 3 trailing comma violations (Low priority, auto-fixable)
- **`issue-4-parameter-alignment.md`** - 10 parameter alignment violations (Medium priority)
- **`README.md`** - Usage instructions for the templates
- **`create-all-issues.sh`** - Automated script to create all issues

## How to Create the Issues

### Option 1: Automated (Recommended)

Run the provided script to create all 4 issues at once:

```bash
./.github/ISSUE_TEMPLATES_SWIFTLINT/create-all-issues.sh
```

**Requirements:** GitHub CLI (`gh`) must be installed and authenticated.

### Option 2: Manual Creation

For each issue file in `.github/ISSUE_TEMPLATES_SWIFTLINT/`:

1. Go to https://github.com/tpak/renamescreenshots/issues/new
2. Open the issue template file (e.g., `issue-1-line-length.md`)
3. Copy the title from the frontmatter (the `title:` field)
4. Copy the body content (everything after the frontmatter `---`)
5. Add the labels listed in the frontmatter
6. Click "Submit new issue"

### Option 3: GitHub CLI (Individual)

```bash
# Fix line length violations
gh issue create \
  --title "Fix line_length violations in source files" \
  --label "code-quality,swiftlint,good first issue" \
  --body-file .github/ISSUE_TEMPLATES_SWIFTLINT/issue-1-line-length.md

# Refactor large tuple
gh issue create \
  --title "Refactor large tuple in PatternMatcherTests.swift" \
  --label "code-quality,swiftlint,testing" \
  --body-file .github/ISSUE_TEMPLATES_SWIFTLINT/issue-2-large-tuple.md

# Remove trailing commas
gh issue create \
  --title "Remove trailing commas in collection literals" \
  --label "code-quality,swiftlint,testing,good first issue" \
  --body-file .github/ISSUE_TEMPLATES_SWIFTLINT/issue-3-trailing-commas.md

# Fix parameter alignment
gh issue create \
  --title "Fix vertical parameter alignment in function calls" \
  --label "code-quality,swiftlint,testing" \
  --body-file .github/ISSUE_TEMPLATES_SWIFTLINT/issue-4-parameter-alignment.md
```

## Violations Summary

| Category | Count | Auto-Fix | Priority |
|----------|-------|----------|----------|
| Line Length | 4 | ❌ | Medium |
| Large Tuple | 1 | ❌ | Medium |
| Trailing Commas | 3 | ✅ | Low |
| Parameter Alignment | 10 | ❌ | Medium |
| **Total** | **18** | **3/18** | **-** |

## After Creating Issues

Once the issues are created:

1. **Assign them** to appropriate team members or mark as "good first issue"
2. **Prioritize** them based on urgency (consider fixing trailing commas first since they're auto-fixable)
3. **Link them** to the `feature/about-dialog` branch PR if needed
4. **Track progress** as they get resolved

## Fixing the Violations

### Quick Fixes

Some violations can be auto-fixed:
```bash
swiftlint --fix
```

This will automatically fix:
- Trailing commas ✅
- Some formatting issues ✅

### Manual Fixes Required

The following require manual refactoring:
- Line length violations (need code restructuring)
- Large tuples (need refactoring to structs or separate variables)
- Parameter alignment (need manual formatting)

### Verification

After making fixes:
```bash
# Verify no SwiftLint errors
swiftlint lint --strict

# Ensure tests still pass
swift test
```

## Cleanup

After all issues are created and resolved, you can delete:
- `.github/ISSUE_TEMPLATES_SWIFTLINT/` directory
- `SWIFTLINT_SUMMARY.md`
- `SWIFTLINT_ISSUES.md`
- `README_SWIFTLINT.md` (this file)

## CI Information

- **Workflow:** SwiftLint (`.github/workflows/swiftlint.yml`)
- **Run ID:** 21748287134
- **Branch:** feature/about-dialog
- **Date:** 2026-02-06
- **SwiftLint Version:** 0.63.2
- **Status:** Failed (18 violations)

## Questions or Issues?

If you have questions about any of the violations or how to fix them:
1. Check the detailed documentation in `SWIFTLINT_ISSUES.md`
2. Review the SwiftLint rule documentation at https://realm.github.io/SwiftLint/
3. View the full CI logs at: https://github.com/tpak/renamescreenshots/actions/runs/21748287134
