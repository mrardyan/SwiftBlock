#!/usr/bin/env bash
# SwiftBlock Branch Pusher
# Pushes the current development branch to origin with upstream tracking.

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

if [ -z "$CURRENT_BRANCH" ]; then
    echo -e "${RED}Error: Not inside a valid git repository.${NC}"
    exit 1
fi

# 1. Protect main branch from direct push
if [ "$CURRENT_BRANCH" = "main" ]; then
    ALLOW_MAIN=false
    for arg in "$@"; do
        if [ "$arg" = "--force-main" ]; then
            ALLOW_MAIN=true
        fi
    done

    if [ "$ALLOW_MAIN" = false ]; then
        echo -e "${RED}Error: Direct push to 'main' is disallowed.${NC}"
        echo "Please create a standardized development branch first with 'make dev'."
        echo "To override intentionally, use: make push ARGS=\"--force-main\""
        exit 1
    fi
fi

# 2. Filter internal script flags
GIT_ARGS=()
for arg in "$@"; do
    if [ "$arg" != "--force-main" ]; then
        GIT_ARGS+=("$arg")
    fi
done

# 3. Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${YELLOW}Warning: You have uncommitted changes in your working tree.${NC}"
fi

# 4. Push to remote
echo -e "${BLUE}Pushing branch ${GREEN}${CURRENT_BRANCH}${BLUE} to origin...${NC}"
git push -u origin "$CURRENT_BRANCH" "${GIT_ARGS[@]}"

echo ""
echo -e "${GREEN}✔ Branch pushed successfully.${NC}"
echo -e "👉 Next step: Run '${YELLOW}make pr${NC}' to create a Pull Request."
