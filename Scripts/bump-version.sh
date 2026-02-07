#!/bin/bash
# Bump version following semantic versioning (semver.org)
# Usage: ./Scripts/bump-version.sh [major|minor|patch]
# Default: patch

set -e

BUMP_TYPE=${1:-patch}

if [ ! -f "VERSION" ]; then
    echo "1.0.0" > VERSION
fi

CURRENT=$(cat VERSION | tr -d '[:space:]')

# Parse version components
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

# Validate we got numbers
if ! [[ "$MAJOR" =~ ^[0-9]+$ ]] || ! [[ "$MINOR" =~ ^[0-9]+$ ]] || ! [[ "$PATCH" =~ ^[0-9]+$ ]]; then
    echo "❌ ERROR: Invalid version format in VERSION file: $CURRENT"
    exit 1
fi

case $BUMP_TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo "❌ ERROR: Invalid bump type: $BUMP_TYPE"
        echo "Usage: $0 [major|minor|patch]"
        exit 1
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "$NEW_VERSION" > VERSION
echo "📌 Version: $CURRENT → $NEW_VERSION"
