#!/usr/bin/env bash

run_scenario() {
    log_step "Scenario 04: Testing ALL 7 Core Block subcommands ('swiftblock core')..."

    cd "$TEST_DIR/TestNewApp"

    "$SWIFTBLOCK_BIN" core storage Database -t "$CORE_PATH"
    "$SWIFTBLOCK_BIN" core network HTTPClient -t "$CORE_PATH"
    "$SWIFTBLOCK_BIN" core logger OSLogger -t "$CORE_PATH"
    "$SWIFTBLOCK_BIN" core analytics Telemetry -t "$CORE_PATH"
    "$SWIFTBLOCK_BIN" core config EnvConfig -t "$CORE_PATH"
    "$SWIFTBLOCK_BIN" core auth UserSession -t "$CORE_PATH"
    "$SWIFTBLOCK_BIN" core featureflag RemoteToggles -t "$CORE_PATH"

    assert_file_exists "Packages/Core/Sources/Core/storage/Database.swift" "Core storage block present"
    assert_file_exists "Packages/Core/Sources/Core/network/HTTPClient.swift" "Core network block present"
    assert_file_exists "Packages/Core/Sources/Core/logger/OSLogger.swift" "Core logger block present"
    assert_file_exists "Packages/Core/Sources/Core/analytics/Telemetry.swift" "Core analytics block present"
    assert_file_exists "Packages/Core/Sources/Core/config/EnvConfig.swift" "Core config block present"
    assert_file_exists "Packages/Core/Sources/Core/auth/UserSession.swift" "Core auth block present"
    assert_file_exists "Packages/Core/Sources/Core/featureflag/RemoteToggles.swift" "Core featureflag block present"

    cd "$TEST_DIR"
}

run_scenario
