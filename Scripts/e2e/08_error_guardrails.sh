#!/usr/bin/env bash

run_scenario() {
    log_step "Scenario 08: Testing Error Guardrails (Destination Already Exists)..."

    cd "$TEST_DIR"

    if "$SWIFTBLOCK_BIN" new TestNewApp --template-path "$TEMPLATE_PATH" 2>/dev/null; then
        log_error "Overwriting existing directory should have failed!"
        exit 1
    else
        log_success "Destination already exists error correctly raised"
    fi
}

run_scenario
