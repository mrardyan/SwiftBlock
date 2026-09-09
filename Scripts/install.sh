#!/bin/bash

set -e

CLI_NAME="swiftblock"
BUILD_PATH=".build/release/$CLI_NAME"
INSTALL_BIN="/usr/local/bin/$CLI_NAME"
INSTALL_TEMPLATE="/usr/local/share/$CLI_NAME/Templates"

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

echo "🧹 Cleaning old templates at $INSTALL_TEMPLATE"
sudo rm -rf "$INSTALL_TEMPLATE"

echo "📁 Installing templates to $INSTALL_TEMPLATE"
sudo mkdir -p "$INSTALL_TEMPLATE"
sudo cp -R Templates/* "$INSTALL_TEMPLATE"

echo "🔒 Setting permissions for $ACTUAL_USER"
sudo chown -R "$ACTUAL_USER" "$INSTALL_TEMPLATE"
sudo chmod -R u+rwX "$INSTALL_TEMPLATE"

echo "✅ Installation complete!"
echo "👉 You can now run '$CLI_NAME init YourProjectName' from anywhere."
