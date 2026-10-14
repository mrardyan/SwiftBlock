#!/usr/bin/env bash
# SwiftBlock Hotfix Branch Creator
# Creates an isolated patch branch directly from a specific release tag.

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

FROM_TAG="$1"
PATCH_NAME="$2"

echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}            SwiftBlock Hotfix Initiator             ${NC}"
echo -e "${BLUE}===================================================${NC}"
echo ""

# Check if any tags exist
AVAILABLE_TAGS=$(git tag -l | sort -V)
if [ -z "$AVAILABLE_TAGS" ]; then
    echo -e "${YELLOW}Notice: No release tags found in the repository yet.${NC}"
    echo "Hotfix branches are created from existing release tags (e.g. v1.0.0)."
    echo "If you need a bugfix on main, please use 'make dev' instead."
    exit 1
fi

if [ -z "$FROM_TAG" ]; then
    echo "Available release tags:"
    echo "$AVAILABLE_TAGS" | sed 's/^/  - /'
    echo ""
    read -p "Enter source tag to hotfix (e.g. v1.0.0): " FROM_TAG
fi

# Validate tag existence
if ! git rev-parse "$FROM_TAG" >/dev/null 2>&1; then
    echo -e "${RED}Error: Tag '$FROM_TAG' does not exist.${NC}"
    exit 1
fi

if [ -z "$PATCH_NAME" ]; then
    read -p "Enter hotfix name (e.g. 1.0.1 or fix-crash): " PATCH_NAME
fi

# Sanitize branch name
PATCH_NAME=$(echo "$PATCH_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
HOTFIX_BRANCH="hotfix/${PATCH_NAME}"

echo ""
echo "Creating hotfix branch '${HOTFIX_BRANCH}' from tag '${FROM_TAG}'..."
git checkout -b "$HOTFIX_BRANCH" "$FROM_TAG"

echo ""
echo -e "${GREEN}===================================================${NC}"
echo -e "${GREEN}✔ Hotfix branch ready: ${HOTFIX_BRANCH}${NC}"
echo -e "${GREEN}===================================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Apply your urgent bugfix and test with 'make verify'"
echo "  2. Run 'make release' when ready to tag the patch release (e.g. v1.0.1)"
echo "  3. Cherry-pick or open a PR to backport this fix into 'main'"
echo ""
