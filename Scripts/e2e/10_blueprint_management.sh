#!/usr/bin/env bash

run_scenario() {
    log_step "Scenario 10: Testing Blueprint CLI Management ('swiftblock blueprint' & 'swiftblock add <blueprint>')..."

    cd "$TEST_DIR/TestNewApp"

    # Reset .swiftblock to standard configuration without overrides
    cat << 'EOF' > .swiftblock
{
  "projectName": "TestNewApp",
  "bundlePrefix": "com.mycompany.newapp",
  "packaging": { "feature": "monolithic", "core": "spm" },
  "organization": "feature-first",
  "generatorTool": "xcodegen"
}
EOF

    # 1. Create a custom blueprint using flags
    "$SWIFTBLOCK_BIN" blueprint create custom_flow --blocks scene,usecase,service

    # 2. List blueprints and assert output contains custom_flow
    LIST_OUTPUT=$("$SWIFTBLOCK_BIN" blueprint list)
    if [[ "$LIST_OUTPUT" != *"custom_flow"* ]]; then
        log_error "Blueprint list output does not contain 'custom_flow': $LIST_OUTPUT"
        exit 1
    fi
    log_success "Blueprint 'custom_flow' present in blueprint list output"

    # 3. Generate module using 'swiftblock add custom_flow Checkout'
    "$SWIFTBLOCK_BIN" add custom_flow Checkout -t "$MODULES_PATH"
    assert_file_exists "App/Sources/Features/checkout/scene/CheckoutView.swift" "Blueprint scene CheckoutView.swift present"
    assert_file_exists "App/Sources/Features/checkout/usecase/CheckoutUseCase.swift" "Blueprint usecase CheckoutUseCase.swift present"
    assert_file_exists "App/Sources/Features/checkout/service/CheckoutService.swift" "Blueprint service CheckoutService.swift present"

    # 4. Generate module using 'swiftblock blueprint run feature Onboarding'
    "$SWIFTBLOCK_BIN" blueprint run feature Onboarding -t "$MODULES_PATH"
    assert_file_exists "App/Sources/Features/onboarding/scene/OnboardingView.swift" "Built-in blueprint scene OnboardingView.swift present"
    assert_file_exists "App/Sources/Features/onboarding/usecase/OnboardingUseCase.swift" "Built-in blueprint usecase OnboardingUseCase.swift present"
    assert_file_exists "App/Sources/Features/onboarding/repository/OnboardingRepository.swift" "Built-in blueprint repository OnboardingRepository.swift present"
    assert_file_exists "App/Sources/Features/onboarding/mapper/OnboardingMapper.swift" "Built-in blueprint mapper OnboardingMapper.swift present"

    # 5. Remove custom blueprint
    "$SWIFTBLOCK_BIN" blueprint remove custom_flow

    LIST_OUTPUT_AFTER=$("$SWIFTBLOCK_BIN" blueprint list)
    if [[ "$LIST_OUTPUT_AFTER" == *"custom_flow"* ]]; then
        log_error "Blueprint 'custom_flow' still present in list after remove"
        exit 1
    fi
    log_success "Blueprint 'custom_flow' successfully removed from .swiftblock"

    cd "$TEST_DIR"
}

run_scenario
