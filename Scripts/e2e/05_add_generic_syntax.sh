#!/usr/bin/env bash

run_scenario() {
    log_step "Scenario 05: Testing generic 'swiftblock add <block> <name>' syntax..."

    cd "$TEST_DIR/TestNewApp"

    "$SWIFTBLOCK_BIN" snap storage LocalStore
    "$SWIFTBLOCK_BIN" snap scene Settings

    assert_file_exists "Packages/Core/Sources/Core/storage/LocalStore.swift" "Generic add storage LocalStore present"
    assert_file_exists "App/Sources/Features/settings/scene/SettingsView.swift" "Generic add scene Settings present"

    cd "$TEST_DIR"
}

run_scenario
