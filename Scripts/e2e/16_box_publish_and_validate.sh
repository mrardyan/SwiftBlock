#!/usr/bin/env bash
set -e

echo "🧪 [STEP] Scenario 16: Testing Remote Box Publishing & Versioning CLI ('swiftblock box validate / publish')..."

TEST_DIR=$(mktemp -d -t "swiftblock_e2e_pub_XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT

cd "$TEST_DIR"

# 1. Prepare brick repository
mkdir -p MyCustomBrick
cd MyCustomBrick

cat << 'EOF' > brick.yml
name: customlogger
instantiation: singleton
description: Team Custom Logger Brick
injections:
  - target: "App/Sources/AppDelegate.swift"
    marker: "// MARK: - Setup"
    content: "Logger.configure()"
EOF

git init
git config user.name "E2E Tester"
git config user.email "tester@example.com"
git add brick.yml
git commit -m "Initial brick commit"

# 2. Test swiftblock box validate
echo "🔹 [Sub-test 16.1] Testing swiftblock box validate..."
VAL_OUTPUT=$("$SWIFTBLOCK_BIN" box validate .)
if echo "$VAL_OUTPUT" | grep -q "ready to publish"; then
  echo "✔ Box validation passed successfully!"
else
  echo "✖ Box validation failed: $VAL_OUTPUT"
  exit 1
fi

# 3. Test swiftblock box publish --dry-run
echo "🔹 [Sub-test 16.2] Testing swiftblock box publish --dry-run..."
PUB_OUTPUT=$("$SWIFTBLOCK_BIN" box publish . --tag 2.0.0 --dry-run)
if echo "$PUB_OUTPUT" | grep -q "Target release tag: v2.0.0"; then
  echo "✔ Box publish dry-run passed successfully!"
else
  echo "✖ Box publish dry-run failed: $PUB_OUTPUT"
  exit 1
fi

echo "✔ Scenario 16 Box Publish & Validate verified successfully!"
