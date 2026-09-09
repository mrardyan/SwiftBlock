#!/bin/bash

set -e

CLI_NAME="swiftblock"
BUILD_PATH=".build/release/$CLI_NAME"
INSTALL_BIN="/usr/local/bin/$CLI_NAME"
INSTALL_BLOCKS="/usr/local/share/$CLI_NAME/Blocks"

echo "📦 Building $CLI_NAME CLI..."
swift build -c release

if [ ! -f "$BUILD_PATH" ]; then
  echo "❌ Build failed: $BUILD_PATH not found"
  exit 1
fi

ACTUAL_USER="${SUDO_USER:-$(whoami)}"

echo "📥 Installing binary to $INSTALL_BIN"
sudo mkdir -p "$(dirname "$INSTALL_BIN")"
sudo cp "$BUILD_PATH" "$INSTALL_BIN"
sudo chmod +x "$INSTALL_BIN"

echo "🧹 Cleaning old blocks at $INSTALL_BLOCKS"
sudo rm -rf "$INSTALL_BLOCKS"

echo "📁 Installing building blocks to $INSTALL_BLOCKS"
sudo mkdir -p "$INSTALL_BLOCKS"
sudo cp -R Blocks/* "$INSTALL_BLOCKS"

echo "🔒 Setting permissions for $ACTUAL_USER"
sudo chown -R "$ACTUAL_USER" "$INSTALL_BLOCKS"
sudo chmod -R u+rwX "$INSTALL_BLOCKS"

echo "✅ Installation complete!"
echo "👉 You can now run '$CLI_NAME new YourProjectName' from anywhere."
