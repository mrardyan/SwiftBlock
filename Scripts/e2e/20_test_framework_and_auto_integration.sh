#!/usr/bin/env bash

run_scenario_20() {
    log_step "Scenario 20: Testing Unit Test Framework Converter & Baseplate Auto-Integration..."

    # 1. Generate Baseplate SwiftUI project
    log_info "Sub-test 20.1: Generating baseplate SwiftUI project with DependencyContainer & AppCoordinator..."
    "$SWIFTBLOCK_BIN" baseplate TestIntegrationApp \
        --bundle-prefix com.company.integration \
        --template-path "$TEMPLATE_PATH" \
        --test-framework swift-testing > /dev/null 2>&1

    assert_dir_exists "TestIntegrationApp" "TestIntegrationApp directory created"
    assert_file_exists "TestIntegrationApp/App/Sources/DependencyContainer.swift" "DependencyContainer.swift created in baseplate"
    assert_file_exists "TestIntegrationApp/App/Sources/AppCoordinator.swift" "AppCoordinator.swift created in baseplate"

    cd TestIntegrationApp

    # 2. Snap Scene Brick and verify Auto-Integration injection
    log_info "Sub-test 20.2: Snapping Scene brick 'Payment' & checking auto-registration injections..."
    "$SWIFTBLOCK_BIN" snap scene Payment > /dev/null 2>&1

    assert_file_contains "App/Sources/DependencyContainer.swift" "PaymentViewModel" "DependencyContainer auto-wired PaymentViewModel"
    assert_file_contains "App/Sources/AppCoordinator.swift" "case payment" "AppCoordinator auto-wired case payment"

    # 3. Verify Swift Testing Transpilation
    log_info "Sub-test 20.3: Verifying Swift Testing syntax in snapped brick test suite..."
    assert_file_exists "App/Tests/Features/payment/scene/PaymentTests.swift" "PaymentTests.swift generated"
    assert_file_contains "App/Tests/Features/payment/scene/PaymentTests.swift" "import Testing" "Test file imports Testing"
    assert_file_contains "App/Tests/Features/payment/scene/PaymentTests.swift" "@Suite struct PaymentSceneTests" "Test file declares @Suite struct"
    assert_file_contains "App/Tests/Features/payment/scene/PaymentTests.swift" "@Test func" "Test file uses @Test func"

    cd "$TEST_DIR"
    log_success "Scenario 20 Unit Test Framework & Auto-Integration E2E completed successfully!"
}

run_scenario_20
