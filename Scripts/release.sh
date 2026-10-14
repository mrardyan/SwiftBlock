#!/usr/bin/env bash
# SwiftBlock Release Orchestrator
# Verifies test suites, tags a new SemVer release, pushes tag, and updates Formula/swiftblock.rb.

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
TARGET_VERSION="$1"

echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}          SwiftBlock Release Orchestrator          ${NC}"
echo -e "${BLUE}===================================================${NC}"
echo ""

# 1. Branch verification
if [ "$CURRENT_BRANCH" != "main" ] && [[ ! "$CURRENT_BRANCH" == hotfix/* ]]; then
    echo -e "${RED}Error: Releases must be initiated from 'main' or a 'hotfix/*' branch.${NC}"
    echo "Current branch: $CURRENT_BRANCH"
    exit 1
fi

# 2. Check uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${RED}Error: Uncommitted changes detected.${NC}"
    echo "Please commit or stash your changes before proceeding with release."
    exit 1
fi

# 3. Prompt for version if not provided
if [ -z "$TARGET_VERSION" ]; then
    LATEST_TAG=$(git tag -l | sort -V | tail -n 1)
    echo "Latest tag: ${LATEST_TAG:-None}"
    read -p "Enter new release version (e.g. 1.0.0 or v1.0.0): " TARGET_VERSION
fi

# Normalize version
SEMVER="${TARGET_VERSION#v}"
TAG="v${SEMVER}"

# Check if tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo -e "${RED}Error: Git tag '$TAG' already exists.${NC}"
    exit 1
fi

# 4. Prompt for release title/summary
read -p "Enter release summary message: " RELEASE_MSG
RELEASE_MSG="${RELEASE_MSG:-SwiftBlock CLI release $TAG}"

# 5. Run full verification suite
echo ""
echo -e "${BLUE}Running verification suite before tagging...${NC}"
make verify

echo ""
echo -e "${GREEN}✔ Verification passed!${NC}"

# 6. Create annotated Git tag
echo "Creating annotated Git tag '$TAG'..."
git tag -a "$TAG" -m "$RELEASE_MSG"

echo -e "${GREEN}✔ Tag '$TAG' created locally.${NC}"

# 7. Ask to push tag
echo ""
read -p "Push tag '$TAG' to origin now? [y/N]: " PUSH_CONFIRM
if [[ "$PUSH_CONFIRM" =~ ^[Yy]$ ]]; then
    git push origin "$TAG"
    echo -e "${GREEN}✔ Tag '$TAG' pushed to origin.${NC}"

    # 8. Update Homebrew formula
    echo ""
    read -p "Update Formula/swiftblock.rb with new SHA256 now? [Y/n]: " FORMULA_CONFIRM
    if [[ ! "$FORMULA_CONFIRM" =~ ^[Nn]$ ]]; then
        echo "Waiting 3 seconds for GitHub tarball availability..."
        sleep 3
        ./Scripts/update_formula_sha.sh "$TAG"

        # Commit and push formula update if changed
        if ! git diff --quiet Formula/swiftblock.rb; then
            git add Formula/swiftblock.rb
            git commit -m "chore(formula): bump swiftblock to $TAG and update sha256"
            git push origin "$CURRENT_BRANCH"
            echo -e "${GREEN}✔ Formula updated and pushed to $CURRENT_BRANCH!${NC}"
        fi
    fi
else
    echo "Skipped pushing tag. To push manually later: git push origin $TAG"
fi

echo ""
echo -e "${GREEN}===================================================${NC}"
echo -e "${GREEN}✔ Release workflow for $TAG completed!              ${NC}"
echo -e "${GREEN}===================================================${NC}"
echo ""
