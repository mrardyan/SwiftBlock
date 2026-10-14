#!/usr/bin/env bash
set -e

echo "🧪 [STEP] Scenario 13: Testing Code Injector & Lifecycle Hooks Engine..."

TEST_DIR=$(mktemp -d -t "swiftblock_e2e_injector_XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT

cd "$TEST_DIR"

# 1. Initialize a baseplate project
"$SWIFTBLOCK_BIN" baseplate InjectorApp --bundle-prefix com.test
cd InjectorApp

# Create a target file for code injection
mkdir -p App/Sources/Core
cat << 'EOF' > App/Sources/Core/DependencyContainer.swift
import Foundation

public final class DependencyContainer {
    public static let shared = DependencyContainer()
    
    public func registerServices() {
        // MARK: - Register Services
    }
}
EOF

# Create a custom brick with brick.yml containing injections and post_snap hooks
mkdir -p .swiftblock/blocks/customservice
cat << 'EOF' > .swiftblock/blocks/customservice/brick.yml
name: customservice
category: architecture
instantiation: generative
defaultPath: "App/Sources/Features"
requiresNameArgument: true

injections:
  - target: "App/Sources/Core/DependencyContainer.swift"
    marker: "// MARK: - Register Services"
    content: "        // Registered {{moduleName}}Service"

hooks:
  post_snap:
    - "echo 'HookExecuted: {{moduleName}}' > hook_output.txt"
EOF

cat << 'EOF' > .swiftblock/blocks/customservice/{{name}}Service.swift
import Foundation

public struct {{name}}Service {
    public init() {}
}
EOF

# 2. Snap the custom service brick
"$SWIFTBLOCK_BIN" snap customservice Billing

# 3. Assert code injection
if grep -q "// Registered BillingService" App/Sources/Core/DependencyContainer.swift; then
  echo "✔ Code snippet injected into DependencyContainer.swift successfully!"
else
  echo "✖ Failed to inject code snippet into DependencyContainer.swift"
  exit 1
fi

# 4. Assert hook execution
if [ -f "hook_output.txt" ] && grep -q "HookExecuted: Billing" hook_output.txt; then
  echo "✔ Post-snap lifecycle hook executed successfully!"
else
  echo "✖ Post-snap lifecycle hook failed to execute"
  exit 1
fi

echo "✔ Scenario 13 Code Injector and Hooks verified successfully!"
