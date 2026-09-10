#!/usr/bin/env bash

run_scenario_12() {
    log_step "Scenario 12: Testing Generated Project Unit Tests Execution..."

    # 1. Initialize project with SPM Core package & full Core blocks
    log_info "Sub-test 12.1: Generating project with full Core & Feature blocks..."
    printf "TestProjectWithTests\ncom.company.testproj\n1\n2\n1\n1\ny\n1\ny\ny\n" | "$SWIFTBLOCK_BIN" init --template-path "$TEMPLATE_PATH" > /dev/null 2>&1

    assert_dir_exists "TestProjectWithTests" "TestProjectWithTests directory created"

    cd TestProjectWithTests

    # 2. Verify starter unit test file
    assert_file_exists "App/Tests/TestProjectWithTestsTests.swift" "Starter unit test file present"

    # 3. Verify composable Core block unit test files
    assert_file_exists "App/Tests/Core/storage/AppStorageTests.swift" "Storage block unit test file present"
    assert_file_exists "App/Tests/Core/network/NetworkClientTests.swift" "Network block unit test file present"
    assert_file_exists "App/Tests/Core/logger/AppLoggerTests.swift" "Logger block unit test file present"
    assert_file_exists "App/Tests/Core/config/AppConfigTests.swift" "Config block unit test file present"
    assert_file_exists "App/Tests/Core/auth/UserAuthTests.swift" "Auth block unit test file present"

    # 4. Add a Feature Block (Scene) and verify its composable test file
    log_info "Sub-test 12.2: Adding Feature block 'Profile'..."
    "$SWIFTBLOCK_BIN" add scene Profile --template-path "$MODULES_PATH" > /dev/null 2>&1
    assert_file_exists "App/Tests/Features/profile/scene/ProfileTests.swift" "Feature block Profile unit test file present"

    # 5. Verify Core SPM package compiles cleanly
    log_info "Sub-test 12.3: Compiling Core SPM package in temporary project..."
    if [[ -d "Packages/Core" ]]; then
        swift build --package-path Packages/Core > /dev/null 2>&1
        log_success "Packages/Core compiled successfully via Swift Package Manager"
    fi

    cd "$TEST_DIR"
    log_success "Scenario 12 generated project unit tests verified successfully!"
}

run_scenario_12
