#!/usr/bin/env bash
set -e

# Master E2E Test Suite Runner
ORIGINAL_DIR="$(pwd)"

# Source Shared Shell Libraries
source "$ORIGINAL_DIR/Scripts/lib/colors.sh"
source "$ORIGINAL_DIR/Scripts/lib/assertions.sh"

echo -e "${CYAN}====================================================${RESET}"
echo -e "${CYAN}🚀 SwiftBlock End-to-End (E2E) Modular Suite${RESET}"
echo -e "${CYAN}====================================================${RESET}"

# 1. Build CLI release binary
log_info "Step 1: Compiling SwiftBlock release binary..."
swift build -c release

export SWIFTBLOCK_BIN="$ORIGINAL_DIR/.build/release/swiftblock"
export TEMPLATE_PATH="$ORIGINAL_DIR/Baseplates/Baseplate-SwiftUI"
export MODULES_PATH="$ORIGINAL_DIR/Bricks/Generatives/Architecture"
export SWIFTBLOCK_ROOT="$ORIGINAL_DIR"

if [[ ! -f "$SWIFTBLOCK_BIN" ]]; then
    log_error "SwiftBlock binary not found at $SWIFTBLOCK_BIN"
    exit 1
fi
log_success "Compiled executable at: $SWIFTBLOCK_BIN"

# 2. Setup Temporary Test Environment
export TEST_DIR=$(mktemp -d -t swiftblock_e2e_XXXXXX)
cleanup_e2e() {
    if pgrep -x "Xcode" > /dev/null; then
        osascript -e 'tell application "Xcode" to close every workspace document' 2>/dev/null || true
    fi
    rm -rf "$TEST_DIR"
}
trap cleanup_e2e EXIT

log_info "Step 2: Testing in temporary workspace: $TEST_DIR"
cd "$TEST_DIR"

# 3. Execute Scenarios in Order
for scenario_file in "$ORIGINAL_DIR"/Scripts/e2e/*.sh; do
    if [[ -f "$scenario_file" ]]; then
        source "$scenario_file"
    fi
done

echo -e "\n${GREEN}====================================================${RESET}"
echo -e "${GREEN}🎉 All End-to-End (E2E) Scenarios Passed Successfully!${RESET}"
echo -e "${GREEN}====================================================${RESET}"
