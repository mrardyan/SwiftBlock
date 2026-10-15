#!/usr/bin/env bash
# SwiftBlock Setup Script
# Configures the local development environment, git hooks, and verifies dependencies.

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}        SwiftBlock Development Environment Setup    ${NC}"
echo -e "${BLUE}===================================================${NC}"
echo ""

# 1. Check Swift toolchain
echo -n "Checking Swift toolchain... "
if command -v swift >/dev/null 2>&1; then
    SWIFT_VERSION=$(swift --version | head -n 1)
    echo -e "${GREEN}Found ($SWIFT_VERSION)${NC}"
else
    echo -e "${RED}Not found! Please install Xcode or Swift 5.10+${NC}"
    exit 1
fi

# 2. Check SwiftLint
echo -n "Checking SwiftLint... "
if ! command -v swiftlint >/dev/null 2>&1; then
    echo -e "${YELLOW}Not found.${NC}"
    if command -v brew >/dev/null 2>&1; then
        echo -e "${BLUE}Installing SwiftLint via Homebrew...${NC}"
        brew install swiftlint || true
    fi
fi
if command -v swiftlint >/dev/null 2>&1; then
    echo -e "${GREEN}Found ($(swiftlint version))${NC}"
else
    echo -e "${YELLOW}Warning: swiftlint not found. Install via: brew install swiftlint${NC}"
fi

# 3. Check SwiftFormat
echo -n "Checking SwiftFormat... "
if ! command -v swiftformat >/dev/null 2>&1; then
    echo -e "${YELLOW}Not found.${NC}"
    if command -v brew >/dev/null 2>&1; then
        echo -e "${BLUE}Installing SwiftFormat via Homebrew...${NC}"
        brew install swiftformat || true
    fi
fi
if command -v swiftformat >/dev/null 2>&1; then
    echo -e "${GREEN}Found ($(swiftformat --version))${NC}"
else
    echo -e "${YELLOW}Warning: swiftformat not found. Install via: brew install swiftformat${NC}"
fi

# 4. Check GitHub CLI (gh)
echo -n "Checking GitHub CLI (gh)... "
if ! command -v gh >/dev/null 2>&1; then
    echo -e "${YELLOW}Not found.${NC}"
    if command -v brew >/dev/null 2>&1; then
        echo -e "${BLUE}Installing GitHub CLI via Homebrew...${NC}"
        brew install gh || true
    else
        echo -e "${YELLOW}Notice: Homebrew not found. Install gh manually: https://cli.github.com${NC}"
    fi
fi

if command -v gh >/dev/null 2>&1; then
    GH_VERSION=$(gh --version | head -n 1)
    echo -e "${GREEN}Found ($GH_VERSION)${NC}"
    if ! gh auth status >/dev/null 2>&1; then
        echo -e "${YELLOW}GitHub CLI is not authenticated.${NC}"
        if [ -t 0 ] && [ -z "$CI" ]; then
            echo -e "${BLUE}Launching interactive GitHub authentication...${NC}"
            gh auth login || echo -e "${YELLOW}Warning: Authentication cancelled. You can run 'gh auth login' later.${NC}"
        else
            echo -e "${YELLOW}Notice: Non-interactive session detected. Run 'gh auth login' manually.${NC}"
        fi
    else
        echo -e "${GREEN}GitHub CLI authenticated.${NC}"
    fi
else
    echo -e "${YELLOW}Warning: GitHub CLI is not installed. Automated PR creation via 'make pr' will be disabled.${NC}"
fi

# 5. Install Git Hooks
echo -n "Installing Git pre-commit hooks... "
mkdir -p .githooks
cp Scripts/pre-commit.sh .githooks/pre-commit
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
echo -e "${GREEN}Configured (.githooks/pre-commit)${NC}"

# 6. Build Project
echo ""
echo -e "${BLUE}Compiling SwiftBlock CLI in release mode...${NC}"
swift build -c release

echo ""
echo -e "${GREEN}===================================================${NC}"
echo -e "${GREEN}✔ Setup completed successfully!                     ${NC}"
echo -e "${GREEN}===================================================${NC}"
echo ""
echo "Next steps:"
echo "  - Run 'make dev' to start a new feature or bugfix branch"
echo "  - Run 'make verify' before submitting a Pull Request"
echo "  - Run 'make help' to see all available workflow commands"
echo ""
