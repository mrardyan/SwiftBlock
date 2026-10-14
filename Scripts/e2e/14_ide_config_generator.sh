#!/usr/bin/env bash
set -e

echo "🧪 [STEP] Scenario 14: Testing IDE Integration Config Generator ('swiftblock ide setup')..."

TEST_DIR=$(mktemp -d -t "swiftblock_e2e_ide_XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT

cd "$TEST_DIR"

# 1. Initialize a baseplate project
"$SWIFTBLOCK_BIN" baseplate IDEApp --bundle-prefix com.test
cd IDEApp

# 2. Run swiftblock ide setup
"$SWIFTBLOCK_BIN" ide setup

# 3. Assert VS Code tasks.json creation
if [ -f ".vscode/tasks.json" ] && grep -q "SwiftBlock: Snap Scene" .vscode/tasks.json; then
  echo "✔ .vscode/tasks.json generated successfully!"
else
  echo "✖ Failed to generate .vscode/tasks.json"
  exit 1
fi

# 4. Assert Makefile shortcuts
if [ -f "Makefile" ] && grep -q "snap-scene:" Makefile; then
  echo "✔ Makefile shortcuts added successfully!"
else
  echo "✖ Failed to add Makefile shortcuts"
  exit 1
fi

echo "✔ Scenario 14 IDE Config Generator verified successfully!"
