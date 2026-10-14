#!/usr/bin/env bash

run_scenario() {
    log_step "Scenario 04: Testing ALL 7 Core Block subcommands ('swiftblock core')..."

    cd "$TEST_DIR/TestNewApp"

    "$SWIFTBLOCK_BIN" snap storage Database
    "$SWIFTBLOCK_BIN" snap network HTTPClient
    "$SWIFTBLOCK_BIN" snap logger OSLogger
    "$SWIFTBLOCK_BIN" snap analytics Telemetry
    "$SWIFTBLOCK_BIN" snap config EnvConfig
    "$SWIFTBLOCK_BIN" snap auth UserSession
    "$SWIFTBLOCK_BIN" snap featureflag RemoteToggles

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
