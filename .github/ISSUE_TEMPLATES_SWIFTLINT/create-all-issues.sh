#!/bin/bash
#
# Script to create GitHub issues from SwiftLint violation templates
# Run this script from the repository root
#

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Creating GitHub issues for SwiftLint violations...${NC}"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed.${NC}"
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

# Check if we're in the right directory
if [ ! -d ".github/ISSUE_TEMPLATES_SWIFTLINT" ]; then
    echo -e "${RED}Error: .github/ISSUE_TEMPLATES_SWIFTLINT directory not found.${NC}"
    echo "Run this script from the repository root."
    exit 1
fi

# Function to create an issue
create_issue() {
    local title="$1"
    local labels="$2"
    local body_file="$3"
    
    echo -e "${YELLOW}Creating issue: $title${NC}"
    
    # Extract just the body (skip frontmatter)
    local temp_body=$(mktemp)
    sed '1,/^---$/d; /^---$/d' "$body_file" > "$temp_body"
    
    if gh issue create --title "$title" --label "$labels" --body-file "$temp_body"; then
        echo -e "${GREEN}✓ Issue created successfully${NC}"
        echo ""
    else
        echo -e "${RED}✗ Failed to create issue${NC}"
        echo ""
    fi
    
    rm -f "$temp_body"
}

# Create issues
echo "Creating 4 issues from SwiftLint violations..."
echo ""

create_issue \
    "Fix line_length violations in source files" \
    "code-quality,swiftlint,good first issue" \
    ".github/ISSUE_TEMPLATES_SWIFTLINT/issue-1-line-length.md"

create_issue \
    "Refactor large tuple in PatternMatcherTests.swift" \
    "code-quality,swiftlint,testing" \
    ".github/ISSUE_TEMPLATES_SWIFTLINT/issue-2-large-tuple.md"

create_issue \
    "Remove trailing commas in collection literals" \
    "code-quality,swiftlint,testing,good first issue" \
    ".github/ISSUE_TEMPLATES_SWIFTLINT/issue-3-trailing-commas.md"

create_issue \
    "Fix vertical parameter alignment in function calls" \
    "code-quality,swiftlint,testing" \
    ".github/ISSUE_TEMPLATES_SWIFTLINT/issue-4-parameter-alignment.md"

echo -e "${GREEN}Done! All issues have been created.${NC}"
echo ""
echo "View issues at: https://github.com/tpak/renamescreenshots/issues"
