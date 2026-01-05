#!/bin/bash
set -e

# Generate changelog from git history
# Usage: ./Scripts/generate-changelog.sh [from-tag] [to-tag]
# Example: ./Scripts/generate-changelog.sh v1.0.0 v1.1.0

FROM_TAG=${1:-$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")}
TO_TAG=${2:-HEAD}

if [ -z "$FROM_TAG" ]; then
    echo "❌ ERROR: No previous tag found and no from-tag specified"
    echo "Usage: $0 [from-tag] [to-tag]"
    exit 1
fi

echo "📝 Generating changelog from $FROM_TAG to $TO_TAG..."
echo ""

# Get version from TO_TAG if it's a tag, otherwise from VERSION file
if git rev-parse "$TO_TAG" >/dev/null 2>&1; then
    if [[ "$TO_TAG" =~ ^v.* ]]; then
        VERSION=${TO_TAG#v}
    else
        VERSION=$(cat VERSION | tr -d '[:space:]')
    fi
else
    VERSION=$(cat VERSION | tr -d '[:space:]')
fi

echo "## [$VERSION] - $(date +%Y-%m-%d)"
echo ""

# Categorize commits by type
FEATURES=$(git log $FROM_TAG..$TO_TAG --pretty=format:"%s" --no-merges | grep "^feat:" | sed 's/^feat: /- /' || true)
FIXES=$(git log $FROM_TAG..$TO_TAG --pretty=format:"%s" --no-merges | grep "^fix:" | sed 's/^fix: /- /' || true)
DOCS=$(git log $FROM_TAG..$TO_TAG --pretty=format:"%s" --no-merges | grep "^docs:" | sed 's/^docs: /- /' || true)
CHORES=$(git log $FROM_TAG..$TO_TAG --pretty=format:"%s" --no-merges | grep "^chore:" | sed 's/^chore: /- /' || true)
OTHER=$(git log $FROM_TAG..$TO_TAG --pretty=format:"%s" --no-merges | grep -v "^feat:" | grep -v "^fix:" | grep -v "^docs:" | grep -v "^chore:" | sed 's/^/- /' || true)

if [ -n "$FEATURES" ]; then
    echo "### Added"
    echo "$FEATURES"
    echo ""
fi

if [ -n "$FIXES" ]; then
    echo "### Fixed"
    echo "$FIXES"
    echo ""
fi

if [ -n "$DOCS" ]; then
    echo "### Documentation"
    echo "$DOCS"
    echo ""
fi

if [ -n "$CHORES" ]; then
    echo "### Maintenance"
    echo "$CHORES"
    echo ""
fi

if [ -n "$OTHER" ]; then
    echo "### Other Changes"
    echo "$OTHER"
    echo ""
fi

# Repository URL
REPO_URL=$(git remote get-url origin | sed 's/\.git$//' | sed 's/git@github.com:/https:\/\/github.com\//')

echo "**Full Changelog**: $REPO_URL/compare/$FROM_TAG...$TO_TAG"
echo ""
echo "[$VERSION]: $REPO_URL/releases/tag/v$VERSION"
