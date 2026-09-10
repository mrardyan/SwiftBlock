#!/usr/bin/env bash

run_scenario() {
    log_step "Scenario 05: Testing generic 'swiftblock add <block> <name>' syntax..."

    cd "$TEST_DIR/TestNewApp"

    "$SWIFTBLOCK_BIN" add storage LocalStore -t "$CORE_PATH"
    "$SWIFTBLOCK_BIN" add scene Settings -t "$MODULES_PATH"

    assert_file_exists "Packages/Core/Sources/Core/storage/LocalStore.swift" "Generic add storage LocalStore present"
    assert_file_exists "App/Sources/Features/settings/scene/SettingsView.swift" "Generic add scene Settings present"

    cd "$TEST_DIR"
}

run_scenario
