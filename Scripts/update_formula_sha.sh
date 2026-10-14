#!/usr/bin/env bash
# SwiftBlock Homebrew Formula SHA256 Updater
# Downloads release tarball from GitHub, computes SHA256 checksum, and updates Formula/swiftblock.rb.

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

VERSION="$1"
FORMULA_PATH="Formula/swiftblock.rb"

if [ ! -f "$FORMULA_PATH" ]; then
    echo -e "${RED}Error: $FORMULA_PATH not found.${NC}"
    exit 1
fi

if [ -z "$VERSION" ]; then
    # Try getting the latest git tag
    LATEST_TAG=$(git tag -l | sort -V | tail -n 1)
    if [ -n "$LATEST_TAG" ]; then
        read -p "Enter release version to update (default: $LATEST_TAG): " VERSION_INPUT
        VERSION="${VERSION_INPUT:-$LATEST_TAG}"
    else
        read -p "Enter release version (e.g. 1.0.0 or v1.0.0): " VERSION
    fi
fi

# Strip leading 'v' for standard SemVer
SEMVER="${VERSION#v}"
TAG="v${SEMVER}"

TARBALL_URL="https://github.com/mrardyan/SwiftBlock/archive/refs/tags/${TAG}.tar.gz"

echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}        Updating Homebrew Formula for ${TAG}       ${NC}"
echo -e "${BLUE}===================================================${NC}"
echo "URL: $TARBALL_URL"
echo ""

TEMP_TARBALL=$(mktemp /tmp/swiftblock-release-XXXXXX.tar.gz)
trap 'rm -f "$TEMP_TARBALL"' EXIT

echo "Downloading release tarball from GitHub..."
HTTP_STATUS=$(curl -sL -w "%{http_code}" -o "$TEMP_TARBALL" "$TARBALL_URL")

if [ "$HTTP_STATUS" != "200" ]; then
    echo -e "${RED}Failed to download tarball (HTTP $HTTP_STATUS).${NC}"
    echo "Make sure the tag '$TAG' has been pushed to GitHub origin."
    exit 1
fi

echo "Computing SHA256 checksum..."
SHA256_HASH=$(shasum -a 256 "$TEMP_TARBALL" | awk '{print $1}')

if [ -z "$SHA256_HASH" ]; then
    echo -e "${RED}Failed to compute SHA256 checksum.${NC}"
    exit 1
fi

echo -e "${GREEN}Computed SHA256:${NC} $SHA256_HASH"

# Update Formula/swiftblock.rb
sed -i '' "s|url \".*\"|url \"$TARBALL_URL\"|g" "$FORMULA_PATH"
sed -i '' "s|sha256 \".*\"|sha256 \"$SHA256_HASH\"|g" "$FORMULA_PATH"

echo ""
echo -e "${GREEN}✔ Successfully updated $FORMULA_PATH with version $TAG!${NC}"
