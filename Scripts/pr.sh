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

# 1. Parse arguments
SKIP_VERIFY=false
PREFER_WEB=false
EDIT_INTERACTIVE=false
CUSTOM_TITLE=""
CUSTOM_BODY=""
GH_EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            echo "Usage: make pr [ARGS=\"<options>\"]"
            echo ""
            echo "Options:"
            echo "  -n, --no-verify     Skip running 'make verify' before opening PR"
            echo "  -t, --title <text>  Set a custom Pull Request title"
            echo "  -b, --body <text>   Set a custom Pull Request body"
            echo "  -e, --edit          Open terminal editor to review/edit before submit"
            echo "  -w, --web           Open GitHub Pull Request comparison in browser"
            echo "  -h, --help          Show this help message"
            exit 0
            ;;
        --no-verify|-n)
            SKIP_VERIFY=true
            shift
            ;;
        --web|-w)
            PREFER_WEB=true
            shift
            ;;
        --edit|-e)
            EDIT_INTERACTIVE=true
            shift
            ;;
        --title|-t)
            CUSTOM_TITLE="$2"
            shift 2
            ;;
        --body|-b)
            CUSTOM_BODY="$2"
            shift 2
            ;;
        *)
            GH_EXTRA_ARGS+=("$1")
            shift
            ;;
    esac
done

# 2. Branch verification
if [ "$CURRENT_BRANCH" = "main" ]; then
    echo -e "${RED}Error: Cannot create a Pull Request directly from 'main'.${NC}"
    echo "Please create a feature branch using 'make dev' first."
    exit 1
fi

echo -e "Current branch: ${GREEN}${CURRENT_BRANCH}${NC}"

# 3. Check uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${RED}Error: You have uncommitted changes on '$CURRENT_BRANCH'.${NC}"
    echo "Please commit or stash your changes before opening a Pull Request."
    exit 1
fi

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

# 5. Push branch to remote with upstream tracking
echo ""
echo -e "${BLUE}Pushing branch ${GREEN}${CURRENT_BRANCH}${BLUE} to origin...${NC}"
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

# 7. Check / Install / Authenticate GitHub CLI ('gh')
if ! command -v gh >/dev/null 2>&1; then
    if [ "$PREFER_WEB" = true ]; then
        echo -e "${YELLOW}Notice: GitHub CLI ('gh') not found. Using browser fallback (--web).${NC}"
    else
        echo -e "${YELLOW}GitHub CLI ('gh') is not installed.${NC}"
        if command -v brew >/dev/null 2>&1 && [ -t 0 ] && [ -z "$CI" ]; then
            echo -e "${BLUE}Installing GitHub CLI via Homebrew...${NC}"
            brew install gh
        else
            echo -e "${RED}Error: GitHub CLI ('gh') is required for automated PR creation.${NC}"
            echo -e "Install via: ${YELLOW}brew install gh && gh auth login${NC}"
            echo -e "Or re-run with: ${YELLOW}make pr ARGS=\"--web\"${NC} to open in browser."
            exit 1
        fi
    fi
fi

if command -v gh >/dev/null 2>&1 && ! gh auth status >/dev/null 2>&1; then
    if [ "$PREFER_WEB" = true ]; then
        echo -e "${YELLOW}Notice: GitHub CLI ('gh') not authenticated. Using browser fallback (--web).${NC}"
    else
        echo -e "${YELLOW}GitHub CLI ('gh') is not authenticated.${NC}"
        if [ -t 0 ] && [ -z "$CI" ]; then
            echo -e "${BLUE}Launching interactive GitHub authentication...${NC}"
            gh auth login
        else
            echo -e "${RED}Error: GitHub CLI is not authenticated.${NC}"
            echo -e "Authenticate via: ${YELLOW}gh auth login${NC}"
            echo -e "Or re-run with: ${YELLOW}make pr ARGS=\"--web\"${NC} to open in browser."
            exit 1
        fi
    fi
fi

# 8. Web fallback if explicitly requested or gh unavailable
if [ "$PREFER_WEB" = true ] || ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
    echo -e "${BLUE}Opening Pull Request page in your default browser...${NC}"
    echo -e "👉 URL: ${BLUE}${PR_URL}${NC}"
    if command -v open >/dev/null 2>&1; then
        open "$PR_URL"
    fi
    echo ""
    echo -e "${GREEN}✔ Link opened! Complete the PR details on GitHub.${NC}"
    exit 0
fi

# 9. Check if a PR already exists for this branch
EXISTING_PR=$(gh pr view "$CURRENT_BRANCH" --json url -q .url 2>/dev/null || true)
if [ -n "$EXISTING_PR" ]; then
    echo -e "${GREEN}✔ Pull Request already exists for this branch:${NC}"
    echo -e "👉 ${BLUE}${EXISTING_PR}${NC}"
    exit 0
fi

# 10. Smart Title & Description Composition
PR_TITLE="$CUSTOM_TITLE"
if [ -z "$PR_TITLE" ]; then
    PR_TITLE=$(git log -1 --pretty=%s)
fi

PR_BODY="$CUSTOM_BODY"
if [ -z "$PR_BODY" ]; then
    # Collect commit bullet points
    COMMITS_LIST=$(git log origin/main..HEAD --pretty=format:"- %s" 2>/dev/null || git log -1 --pretty=format:"- %s")
    if [ -z "$COMMITS_LIST" ]; then
        COMMITS_LIST="- $(git log -1 --pretty=%s)"
    fi

    # Determine types of changes from commit history
    ALL_COMMITS=$(git log origin/main..HEAD --pretty=format:"%s" 2>/dev/null || git log -1 --pretty=format:"%s")
    IS_FEAT=false
    IS_FIX=false
    IS_DOCS=false
    IS_TOOLING=false

    if echo "$ALL_COMMITS" | grep -qiE "^feat(\(.*\))?:"; then IS_FEAT=true; fi
    if echo "$ALL_COMMITS" | grep -qiE "^fix(\(.*\))?:"; then IS_FIX=true; fi
    if echo "$ALL_COMMITS" | grep -qiE "^docs(\(.*\))?:"; then IS_DOCS=true; fi
    if echo "$ALL_COMMITS" | grep -qiE "^(refactor|chore|ci|test|build|style)(\(.*\))?:"; then IS_TOOLING=true; fi

    # Default to tooling if no specific prefix matched
    if [ "$IS_FEAT" = false ] && [ "$IS_FIX" = false ] && [ "$IS_DOCS" = false ] && [ "$IS_TOOLING" = false ]; then
        IS_FEAT=true
    fi

    BOX_FEAT=$([ "$IS_FEAT" = true ] && echo "x" || echo " ")
    BOX_FIX=$([ "$IS_FIX" = true ] && echo "x" || echo " ")
    BOX_DOCS=$([ "$IS_DOCS" = true ] && echo "x" || echo " ")
    BOX_TOOLING=$([ "$IS_TOOLING" = true ] && echo "x" || echo " ")

    PR_BODY=$(cat <<EOF
## Description

### Changes in this PR:
${COMMITS_LIST}

Fixes #none

## Type of Change

- [${BOX_FIX}] 🐛 Bug fix (non-breaking change which fixes an issue)
- [${BOX_FEAT}] ✨ New feature (non-breaking change which adds functionality or a new Brick)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [${BOX_DOCS}] 📖 Documentation update
- [${BOX_TOOLING}] 🧹 Tooling / Refactoring / CI maintenance

## Pre-PR Verification Checklist

Please verify that you have completed the following steps before opening this PR:

- [x] My code follows the code style guidelines of this project (\`make format\`).
- [x] I have run linter checks and resolved all warnings (\`make lint\`).
- [x] I have executed unit tests and template validation suites (\`make verify\`).
- [x] I have added appropriate tests for any new features or bug fixes.
- [ ] I have updated the documentation in \`Docs/\` or \`README.md\` if applicable.
- [x] My branch was created via \`make dev\` and is up to date with \`main\` (\`make sync\`).
EOF
)
fi

# 11. Create Pull Request
echo -e "${BLUE}Creating Pull Request via GitHub CLI...${NC}"

if [ "$EDIT_INTERACTIVE" = true ]; then
    gh pr create --base main --head "$CURRENT_BRANCH" --title "$PR_TITLE" --body "$PR_BODY" --editor "${GH_EXTRA_ARGS[@]}"
else
    CREATED_URL=$(gh pr create --base main --head "$CURRENT_BRANCH" --title "$PR_TITLE" --body "$PR_BODY" "${GH_EXTRA_ARGS[@]}")
    echo ""
    echo -e "${GREEN}===================================================${NC}"
    echo -e "${GREEN}✔ Pull Request created successfully!               ${NC}"
    echo -e "${GREEN}===================================================${NC}"
    echo ""
    echo -e "👉 ${BLUE}${CREATED_URL}${NC}"
fi
