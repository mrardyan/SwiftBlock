#!/usr/bin/env bash
# SwiftBlock Branch Creation Helper
# Creates and checks out a standardized branch (feat/*, fix/*, docs/*, chore/*, test/*)
# after syncing with the latest origin/main.

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BRANCH_TYPE="$1"
BRANCH_NAME="$2"

# Support one-argument syntax: ./Scripts/dev.sh feat/my-feature
if [[ "$BRANCH_TYPE" == *"/"* ]] && [ -z "$BRANCH_NAME" ]; then
    BRANCH_NAME="${BRANCH_TYPE#*/}"
    BRANCH_TYPE="${BRANCH_TYPE%%/*}"
fi

# Interactive menu if arguments are missing
if [ -z "$BRANCH_TYPE" ] || [ -z "$BRANCH_NAME" ]; then
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}          SwiftBlock Feature Branch Creator        ${NC}"
    echo -e "${BLUE}===================================================${NC}"
    echo ""
    echo "Select branch type:"
    echo "  1) feat   - New capability, brick, or enhancement"
    echo "  2) fix    - Bug fix or compiler issue resolution"
    echo "  3) docs   - Documentation guides or README updates"
    echo "  4) chore  - Tooling, dependencies, or CI updates"
    echo "  5) test   - Adding or refactoring test cases"
    echo ""
    read -p "Select option [1-5]: " TYPE_CHOICE

    case "$TYPE_CHOICE" in
        1|feat) BRANCH_TYPE="feat" ;;
        2|fix) BRANCH_TYPE="fix" ;;
        3|docs) BRANCH_TYPE="docs" ;;
        4|chore) BRANCH_TYPE="chore" ;;
        5|test) BRANCH_TYPE="test" ;;
        *)
            echo -e "${RED}Invalid selection. Aborted.${NC}"
            exit 1
            ;;
    esac

    echo ""
    read -p "Enter branch name (e.g. token-refresher or parse-fix): " BRANCH_NAME
fi

# Sanitize branch name to kebab-case
BRANCH_NAME=$(echo "$BRANCH_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')

if [ -z "$BRANCH_NAME" ]; then
    echo -e "${RED}Branch name cannot be empty. Aborted.${NC}"
    exit 1
fi

TARGET_BRANCH="${BRANCH_TYPE}/${BRANCH_NAME}"

echo ""
echo -e "${BLUE}Target branch:${NC} ${GREEN}${TARGET_BRANCH}${NC}"

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${YELLOW}Warning: You have uncommitted changes in your current working tree.${NC}"
    read -p "Do you want to stash them and continue? [y/N]: " STASH_CONFIRM
    if [[ "$STASH_CONFIRM" =~ ^[Yy]$ ]]; then
        git stash push -m "Auto-stashed by make dev before switching to $TARGET_BRANCH"
    else
        echo -e "${RED}Please commit or stash your changes first. Aborted.${NC}"
        exit 1
    fi
fi

# Switch to main and pull latest changes
echo "Syncing with origin/main..."
git checkout main
git pull --ff-only origin main || {
    echo -e "${YELLOW}Notice: Could not fast-forward main from origin. Continuing locally.${NC}"
}

# Create and checkout new branch
git checkout -b "$TARGET_BRANCH"

echo ""
echo -e "${GREEN}===================================================${NC}"
echo -e "${GREEN}✔ Switched to new branch: ${TARGET_BRANCH}${NC}"
echo -e "${GREEN}===================================================${NC}"
echo ""
echo "Development guidelines:"
echo "  1. Implement your changes and commit often (e.g. feat(brick): add XYZ)"
echo "  2. Run 'make verify' before opening your Pull Request"
echo "  3. Submit PR targeting 'main' (will be squashed upon merge)"
echo ""
