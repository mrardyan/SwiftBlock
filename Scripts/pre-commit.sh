#!/bin/sh
# SwiftBlock pre-commit hook: Branch guardrails, SwiftFormat, and SwiftLint.
# Installed via `make install-hooks`.

set -e

# 1. Branch Guardrail: Block direct commits to 'main'
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

if [ "$CURRENT_BRANCH" = "main" ]; then
  echo "❌ [Guardrail] Direct commits to 'main' are blocked!"
  echo "👉 Please run 'make dev' to create a standardized feature or fix branch."
  exit 1
fi

# 2. Branch Guardrail: Enforce naming convention (allow main-clean during setup)
if [ -n "$CURRENT_BRANCH" ] && [ "$CURRENT_BRANCH" != "main-clean" ] && [ "$CURRENT_BRANCH" != "HEAD" ]; then
  VALID_PATTERN="^(feat|fix|hotfix|docs|chore|test|archive)/"
  if ! echo "$CURRENT_BRANCH" | grep -Eq "$VALID_PATTERN"; then
    echo "❌ [Guardrail] Non-standard branch name: '$CURRENT_BRANCH'"
    echo "👉 Allowed branch prefixes: feat/*, fix/*, hotfix/*, docs/*, chore/*, test/*"
    echo "👉 Run 'make dev' to automatically create a valid branch."
    exit 1
  fi
fi

# 3. Formatting & Linting
echo "🔍 Running SwiftFormat..."
swiftformat --config .swiftformat Sources Tests 2>/dev/null || true
echo "✅ SwiftFormat done."

echo "🔍 Running SwiftLint..."
swiftlint lint --quiet Sources Tests
echo "✅ SwiftLint passed."

# Re-stage any files SwiftFormat rewrote
git add Sources Tests 2>/dev/null || true

exit 0