#!/usr/bin/env bash

run_scenario() {
    log_step "Scenario 07: Testing Simulation Mode (--dry-run)..."

    cd "$TEST_DIR"

    "$SWIFTBLOCK_BIN" baseplate DryRunApp --dry-run
    assert_file_not_exists "DryRunApp" "DryRunApp directory should not be created on --dry-run"

    cd "$TEST_DIR/TestNewApp"
    "$SWIFTBLOCK_BIN" snap scene DryRunHome --dry-run
    assert_file_not_exists "Custom/Scenes/dryrunhome" "DryRunHome module should not be created on --dry-run"

    cd "$TEST_DIR"
}

run_scenario
