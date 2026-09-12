#!/usr/bin/env bash

run_scenario_11() {
    log_step "Scenario 11: Testing Wizard Matrix Combinations (GitLab, Bitrise, Xcode Cloud, Technical-First)..."

    # 1. Test GitLab CI (CI/CD Option 2)
    log_info "Sub-test 11.1: GitLab CI provider..."
    printf "1\nTestGitLabApp\ncom.company.gitlab\n1\n1\n1\n1\ny\n2\n1\ny\ny\n" | "$SWIFTBLOCK_BIN" init --template-path "$TEMPLATE_PATH" > /dev/null 2>&1

    assert_dir_exists "TestGitLabApp" "TestGitLabApp directory created"
    assert_file_exists "TestGitLabApp/.gitlab-ci.yml" ".gitlab-ci.yml generated"

    # 2. Test Bitrise CI (CI/CD Option 3)
    log_info "Sub-test 11.2: Bitrise CI provider..."
    printf "1\nTestBitriseApp\ncom.company.bitrise\n1\n1\n1\n1\ny\n3\n1\ny\ny\n" | "$SWIFTBLOCK_BIN" init --template-path "$TEMPLATE_PATH" > /dev/null 2>&1

    assert_dir_exists "TestBitriseApp" "TestBitriseApp directory created"
    assert_file_exists "TestBitriseApp/bitrise.yml" "bitrise.yml generated"

    # 3. Test Technical-First Organization Layout (Org Option 2)
    log_info "Sub-test 11.3: Technical-First Organization Layout..."
    printf "1\nTestTechFirstApp\ncom.company.techfirst\n1\n1\n1\n2\ny\n1\n1\ny\ny\n" | "$SWIFTBLOCK_BIN" init --template-path "$TEMPLATE_PATH" > /dev/null 2>&1

    assert_dir_exists "TestTechFirstApp" "TestTechFirstApp directory created"
    assert_file_exists "TestTechFirstApp/.swiftblock/config.yml" ".swiftblock/config.yml exists"
    assert_file_contains "TestTechFirstApp/.swiftblock/config.yml" "technical-first" ".swiftblock/config.yml contains technical-first strategy"

    log_success "Scenario 11 matrix combinations completed successfully!"
}

run_scenario_11
