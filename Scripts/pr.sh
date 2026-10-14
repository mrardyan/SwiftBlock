#!/usr/bin/env bash
# SwiftBlock Pull Request Creator
# Verifies test suites, pushes branch to origin, and opens/creates a Pull Request.

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}          SwiftBlock Pull Request Creator          ${NC}"
echo -e "${BLUE}===================================================${NC}"
echo ""

# 1. Branch verification
if [ "$CURRENT_BRANCH" = "main" ]; then
    echo -e "${RED}Error: Cannot create a Pull Request directly from 'main'.${NC}"
    echo "Please create a feature branch using 'make dev' first."
    exit 1
fi

echo -e "Current branch: ${GREEN}${CURRENT_BRANCH}${NC}"

# 2. Check uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${RED}Error: You have uncommitted changes on '$CURRENT_BRANCH'.${NC}"
    echo "Please commit or stash your changes before opening a Pull Request."
    exit 1
fi

# 3. Check for --no-verify flag
SKIP_VERIFY=false
GH_EXTRA_ARGS=()

for arg in "$@"; do
    if [ "$arg" = "--no-verify" ] || [ "$arg" = "-n" ]; then
        SKIP_VERIFY=true
    else
        GH_EXTRA_ARGS+=("$arg")
    fi
done

# 4. Run verification unless skipped
if [ "$SKIP_VERIFY" = false ]; then
    echo ""
    echo -e "${BLUE}Running pre-PR verification suite (make verify)...${NC}"
    make verify
    echo ""
    echo -e "${GREEN}✔ Pre-PR verification passed!${NC}"
else
    echo -e "${YELLOW}Notice: Verification skipped via flag.${NC}"
fi

# 5. Push branch to remote
echo ""
echo -e "Pushing ${GREEN}${CURRENT_BRANCH}${NC} to origin..."
git push -u origin "$CURRENT_BRANCH"
echo -e "${GREEN}✔ Branch pushed successfully.${NC}"
echo ""

# 6. Parse GitHub repository slug (e.g. mrardyan/SwiftBlock)
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
REPO_SLUG=$(echo "$REMOTE_URL" | sed -E 's/.*github\.com[:\/]([^\/]+\/[^\/\.]+)(\.git)?/\1/')

if [ -z "$REPO_SLUG" ]; then
    REPO_SLUG="mrardyan/SwiftBlock"
fi

PR_URL="https://github.com/${REPO_SLUG}/compare/main...${CURRENT_BRANCH}?expand=1"

# 7. Create PR via GitHub CLI if available, else open browser
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    echo -e "${BLUE}GitHub CLI ('gh') detected. Creating Pull Request...${NC}"
    
    # Check if a PR already exists for this branch
    EXISTING_PR=$(gh pr view "$CURRENT_BRANCH" --json url -q .url 2>/dev/null || true)
    if [ -n "$EXISTING_PR" ]; then
        echo -e "${GREEN}✔ Pull Request already exists for this branch:${NC}"
        echo -e "👉 ${BLUE}${EXISTING_PR}${NC}"
        exit 0
    fi

    # Create Pull Request
    gh pr create --base main --head "$CURRENT_BRANCH" --fill "${GH_EXTRA_ARGS[@]}"
    echo ""
    echo -e "${GREEN}===================================================${NC}"
    echo -e "${GREEN}✔ Pull Request created successfully!               ${NC}"
    echo -e "${GREEN}===================================================${NC}"
else
    echo -e "${YELLOW}Notice: GitHub CLI ('gh') is not installed or not authenticated.${NC}"
    echo -e "${BLUE}Opening Pull Request page in your default browser...${NC}"
    echo -e "👉 URL: ${BLUE}${PR_URL}${NC}"
    
    if command -v open >/dev/null 2>&1; then
        open "$PR_URL"
    fi

    echo ""
    echo -e "${GREEN}===================================================${NC}"
    echo -e "${GREEN}✔ Link opened! Complete the PR details on GitHub.  ${NC}"
    echo -e "${GREEN}===================================================${NC}"
    echo ""
    echo -e "💡 ${YELLOW}Tip:${NC} Install GitHub CLI to create PRs entirely from terminal:"
    echo -e "   brew install gh && gh auth login"
fi
