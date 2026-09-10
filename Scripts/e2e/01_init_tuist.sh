#!/usr/bin/env bash

run_scenario() {
    log_step "Scenario 01: 'swiftblock init' with Tuist & SPM Core..."

    "$SWIFTBLOCK_BIN" init TestTuistApp \
        --bundle-prefix com.company.tuist \
        --template-path "$TEMPLATE_PATH" \
        --tool tuist \
        --verbose

    assert_dir_exists "TestTuistApp" "TestTuistApp directory created"

    cd TestTuistApp

    # Validate Tuist Project.swift
    assert_file_contains "Project.swift" "TuistApp" "Project.swift contains app name"
    assert_file_contains "Project.swift" "com.company.tuist" "Project.swift contains bundle prefix"

    # Validate App sources (AppDelegate, SceneDelegate, Main)
    assert_file_exists "App/Sources/AppDelegate.swift" "AppDelegate.swift present in App target"
    assert_file_exists "App/Sources/SceneDelegate.swift" "SceneDelegate.swift present in App target"
    assert_file_contains "App/Sources/AppDelegate.swift" "SceneDelegate.self" "AppDelegate configures SceneDelegate"
    assert_file_contains "App/Sources/Main.swift" "CoreModule.configure()" "Main.swift configures CoreModule"

    # Validate Non-empty Core.swift SPM Target
    assert_file_exists "Packages/Core/Sources/Core/Core.swift" "Core.swift present in Core SPM target"

    # Validate Environment Setup Files
    assert_file_exists "Makefile" "Makefile generated"
    assert_file_exists ".mise.toml" ".mise.toml generated"
    assert_file_exists "Scripts/setup.sh" "Scripts/setup.sh generated"

    # Validate Guardrails
    assert_file_exists ".swiftlint.yml" ".swiftlint.yml present"
    assert_file_exists ".swiftformat" ".swiftformat present"
    assert_file_exists ".pre-commit-config.yaml" ".pre-commit-config.yaml present"
    assert_file_exists ".periphery.yml" ".periphery.yml present"
    assert_file_exists "Dangerfile.swift" "Dangerfile.swift present"
    assert_file_exists "swiftgen.yml" "swiftgen.yml present"

    # Validate CI/CD & Git
    assert_file_exists ".github/workflows/ci.yml" "GitHub Actions workflow generated"
    assert_dir_exists ".git" ".git directory initialized"
    assert_file_exists ".gitignore" ".gitignore present"

    # Validate real 'make setup' execution if make is available
    if which make > /dev/null 2>&1; then
        log_info "Testing real 'make setup' execution..."
        make setup
        log_success "'make setup' executed cleanly"
    fi

    cd "$TEST_DIR"
}

run_scenario
