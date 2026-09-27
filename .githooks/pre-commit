#!/bin/sh
# SwiftBlock pre-commit hook: SwiftFormat then SwiftLint, then stage reformatted files.
# Installed via `make install-hooks`.

set -e

echo "🔍 Running SwiftFormat..."
swiftformat --config .swiftformat Sources Tests 2>/dev/null || true
echo "✅ SwiftFormat done."

echo "🔍 Running SwiftLint..."
swiftlint lint --quiet Sources Tests
echo "✅ SwiftLint passed."

# Re-stage any files SwiftFormat rewrote
git add Sources Tests 2>/dev/null || true

exit 0