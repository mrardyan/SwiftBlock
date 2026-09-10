#!/usr/bin/env bash

run_scenario() {
    log_step "Scenario 07: Testing Simulation Mode (--dry-run)..."

    cd "$TEST_DIR"

    "$SWIFTBLOCK_BIN" new DryRunApp --dry-run
    assert_file_not_exists "DryRunApp" "DryRunApp directory should not be created on --dry-run"

    cd "$TEST_DIR/TestNewApp"
    "$SWIFTBLOCK_BIN" add scene DryRunHome -t "$MODULES_PATH" --dry-run
    assert_file_not_exists "Custom/Scenes/dryrunhome" "DryRunHome module should not be created on --dry-run"

    cd "$TEST_DIR"
}

run_scenario
