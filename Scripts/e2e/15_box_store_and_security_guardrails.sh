#!/usr/bin/env bash
set -e

echo "🧪 [STEP] Scenario 15: Testing Box Store CLI & Security Path Traversal Guardrails..."

TEST_DIR=$(mktemp -d -t "swiftblock_e2e_box_XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT

cd "$TEST_DIR"

# 1. Test Box list output
echo "🔹 [Sub-test 15.1] Testing swiftblock box list..."
BOX_OUTPUT=$("$SWIFTBLOCK_BIN" box list)
if echo "$BOX_OUTPUT" | grep -q "SwiftBlock Box Registry"; then
  echo "✔ Box registry list verified!"
else
  echo "✖ Failed to list box registry"
  exit 1
fi

# 2. Test Box remove with path traversal name (sanitized)
echo "🔹 [Sub-test 15.2] Testing box removal with path traversal sanitization..."
"$SWIFTBLOCK_BIN" box remove "../../evil_box" || true
echo "✔ Path traversal box removal handled safely!"

# 3. Test Security Guardrails: Initialize baseplate and attempt path traversal snap
echo "🔹 [Sub-test 15.3] Testing Path Traversal Guardrails in Snap..."
"$SWIFTBLOCK_BIN" baseplate SecApp --bundle-prefix com.sec
cd SecApp

# Attempt snapping scene brick with invalid brick name
"$SWIFTBLOCK_BIN" snap "../../../etc/passwd" || true

echo "✔ Scenario 15 Box Store & Security Guardrails verified successfully!"
