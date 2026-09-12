#!/usr/bin/env bash

run_scenario() {
    log_step "Scenario 09: Testing Piped Stdin Interactive Wizard..."

    cd "$TEST_DIR"

    printf "1\nInteractivePipedApp\ncom.piped.app\n1\n1\n1\n1\ny\n1\ny\ny\n" | "$SWIFTBLOCK_BIN" init --template-path "$TEMPLATE_PATH" > /dev/null 2>&1

    assert_dir_exists "InteractivePipedApp" "InteractivePipedApp generated via piped stdin"
    assert_file_exists "InteractivePipedApp/.swiftblock/config.yml" ".swiftblock/config.yml generated"

    cd "$TEST_DIR"
}

run_scenario
