#!/bin/bash

set -e

CLI_NAME="swiftblock"
BUILD_PATH=".build/release/$CLI_NAME"
INSTALL_BIN="/usr/local/bin/$CLI_NAME"
INSTALL_SHARE="/usr/local/share/$CLI_NAME"

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

echo "🧹 Cleaning old installation at $INSTALL_SHARE"
sudo rm -rf "$INSTALL_SHARE"

echo "📁 Installing Baseplates, Bricks, and Kits to $INSTALL_SHARE"
sudo mkdir -p "$INSTALL_SHARE"
sudo cp -R Baseplates "$INSTALL_SHARE/" 2>/dev/null || true
sudo cp -R Bricks "$INSTALL_SHARE/" 2>/dev/null || true
sudo cp -R Kits "$INSTALL_SHARE/" 2>/dev/null || true

echo "🔒 Setting permissions for $ACTUAL_USER"
sudo chown -R "$ACTUAL_USER" "$INSTALL_SHARE"
sudo chmod -R u+rwX "$INSTALL_SHARE"

echo "✅ Installation complete!"
echo "👉 You can now run '$CLI_NAME baseplate YourProjectName' from anywhere."
