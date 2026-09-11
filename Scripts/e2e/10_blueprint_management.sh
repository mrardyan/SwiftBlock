#!/usr/bin/env bash

run_scenario() {
    log_step "Scenario 10: Testing Kit CLI Management ('swiftblock kit' & 'swiftblock kit run <kit>')..."

    cd "$TEST_DIR/TestNewApp"

    # Reset .swiftblock/config.yml to standard configuration
    mkdir -p .swiftblock
    cat << 'EOF' > .swiftblock/config.yml
projectName: TestNewApp
bundlePrefix: com.mycompany.newapp
generatorTool: xcodegen
EOF

    # 1. List kits and assert output contains clean-feature
    LIST_OUTPUT=$("$SWIFTBLOCK_BIN" kit list)
    if [[ "$LIST_OUTPUT" != *"clean-feature"* ]]; then
        log_error "Kit list output does not contain 'clean-feature': $LIST_OUTPUT"
        exit 1
    fi
    log_success "Kit 'clean-feature' present in kit list output"

    # 2. Generate module using 'swiftblock kit run clean-feature Checkout'
    "$SWIFTBLOCK_BIN" kit run clean-feature Checkout
    assert_file_exists "App/Sources/Features/checkout/scene/CheckoutView.swift" "Kit scene CheckoutView.swift present"
    assert_file_exists "App/Sources/Features/checkout/usecase/CheckoutUseCase.swift" "Kit usecase CheckoutUseCase.swift present"
    assert_file_exists "App/Sources/Features/checkout/service/CheckoutService.swift" "Kit service CheckoutService.swift present"

    cd "$TEST_DIR"
}

run_scenario
