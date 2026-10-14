#!/usr/bin/env bash
set -e

echo "🧪 [STEP] Scenario 17: Testing Project Smart Refactoring Engine ('swiftblock rename')..."

TEST_DIR=$(mktemp -d -t "swiftblock_e2e_rename_XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT

cd "$TEST_DIR"

# 1. Initialize Baseplate project
if [[ -n "$TEMPLATE_PATH" ]]; then
  "$SWIFTBLOCK_BIN" baseplate LegacyApp --bundle-prefix com.test.legacy --template-path "$TEMPLATE_PATH"
else
  "$SWIFTBLOCK_BIN" baseplate LegacyApp --bundle-prefix com.test.legacy
fi
cd LegacyApp

# Assert initial state
if [ ! -f "Project.swift" ] || ! grep -q "LegacyApp" Project.swift; then
  echo "✖ Failed initial project setup"
  exit 1
fi

# 2. Test Dry-Run Mode
echo "🔹 [Sub-test 17.1] Testing swiftblock rename --dry-run..."
DRY_OUTPUT=$("$SWIFTBLOCK_BIN" rename ModernApp --dry-run)
if echo "$DRY_OUTPUT" | grep -q "Would rename project 'LegacyApp' -> 'ModernApp'"; then
  echo "✔ Rename dry-run verified successfully!"
else
  echo "✖ Rename dry-run failed: $DRY_OUTPUT"
  exit 1
fi

# 3. Perform Real Rename
echo "🔹 [Sub-test 17.2] Performing real project rename..."
"$SWIFTBLOCK_BIN" rename ModernApp

# Assert updated config
if grep -q "projectName: ModernApp" .swiftblock/config.yml; then
  echo "✔ .swiftblock/config.yml updated successfully!"
else
  echo "✖ Failed to update .swiftblock/config.yml"
  exit 1
fi

# Assert updated Project.swift
if grep -q "ModernApp" Project.swift && ! grep -q "LegacyApp" Project.swift; then
  echo "✔ Project.swift target and project declarations updated!"
else
  echo "✖ Failed to update Project.swift"
  exit 1
fi

# Assert renamed test file
if [ -f "App/Tests/ModernAppTests.swift" ]; then
  echo "✔ Starter unit test file renamed to ModernAppTests.swift!"
else
  echo "✖ Failed to rename test file"
  exit 1
fi

# Assert updated Main.swift
if grep -q "ModernAppApp" App/Sources/Main.swift; then
  echo "✔ App/Sources/Main.swift struct entry point updated!"
else
  echo "✖ Failed to update Main.swift entry point"
  exit 1
fi

echo "✔ Scenario 17 Project Smart Rename verified successfully!"
