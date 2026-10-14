#!/usr/bin/env bash
# SwiftBlock Branch Synchronizer
# Rebase current development branch onto the latest origin/main.

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}          SwiftBlock Branch Synchronizer            ${NC}"
echo -e "${BLUE}===================================================${NC}"
echo ""

if [ "$CURRENT_BRANCH" = "main" ]; then
    echo "Currently on 'main'. Pulling latest changes from origin/main..."
    git pull --ff-only origin main
    echo -e "${GREEN}✔ 'main' is up to date.${NC}"
    exit 0
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${RED}Error: You have uncommitted changes on '$CURRENT_BRANCH'.${NC}"
    echo "Please commit or stash your changes before running 'make sync'."
    exit 1
fi

echo "Fetching latest origin/main..."
git fetch origin main

echo "Rebasing '$CURRENT_BRANCH' onto origin/main..."
if git rebase origin/main; then
    echo ""
    echo -e "${GREEN}✔ '$CURRENT_BRANCH' successfully rebased onto origin/main!${NC}"
else
    echo ""
    echo -e "${RED}Rebase conflict encountered!${NC}"
    echo "Resolve conflicts manually, then run 'git rebase --continue' or 'git rebase --abort'."
    exit 1
fi
