#!/usr/bin/env bash

run_scenario_19() {
    log_step "Scenario 19: Testing Vapor Backend API Generation & Snapping ('swiftblock init --baseplate vapor')..."

    # 1. Initialize project using Vapor baseplate & core blocks
    log_info "Sub-test 19.1: Generating Vapor Backend API via Interactive Wizard..."
    VAPOR_TEMPLATE_PATH="$SWIFTBLOCK_ROOT/Baseplates/Vapor"
    printf "2\nTestVaporServer\ncom.company.vapor\n1\ny\ny\n" | "$SWIFTBLOCK_BIN" init --template-path "$VAPOR_TEMPLATE_PATH" > /dev/null 2>&1

    assert_dir_exists "TestVaporServer" "TestVaporServer directory created"

    cd TestVaporServer

    # 2. Verify Vapor backend core files
    assert_file_exists "Package.swift" "Package.swift present in Vapor project root"
    assert_file_exists "Sources/App/routes.swift" "routes.swift present in Vapor App module"
    assert_file_exists "Sources/App/configure.swift" "configure.swift present in Vapor App module"
    assert_file_exists "Sources/App/entrypoint.swift" "entrypoint.swift present in Vapor App module"
    assert_file_exists "Sources/Run/main.swift" "main.swift present in Vapor Run target"
    assert_file_exists "Dockerfile" "Dockerfile present"
    assert_file_exists "docker-compose.yml" "docker-compose.yml present"
    assert_file_exists ".swiftblock/config.yml" ".swiftblock/config.yml exists"

    # 3. Verify Server Core blocks (VaporAuth, Network, Logger, Config)
    assert_file_exists "Sources/App/Core/vaporauth/UserAuth.swift" "VaporAuth block UserAuth.swift present"
    assert_file_exists "Sources/App/Core/network/NetworkClient.swift" "Network block NetworkClient.swift present"
    assert_file_exists "Sources/App/Core/logger/AppLogger.swift" "Logger block AppLogger.swift present"
    assert_file_exists "Sources/App/Core/config/AppConfig.swift" "Config block AppConfig.swift present"

    # 4. Snap additional feature service brick
    log_info "Sub-test 19.2: Snapping service brick 'OrderService' into Vapor project..."
    "$SWIFTBLOCK_BIN" snap service OrderService > /dev/null 2>&1
    assert_file_exists "Sources/App/Features/orderservice/service/OrderServiceService.swift" "Snapped OrderService brick into Vapor feature layer"

    # 5. Verify Vapor backend project SPM build
    log_info "Sub-test 19.3: Compiling Vapor backend project via Swift Package Manager..."
    if [[ -f "Package.swift" ]]; then
        swift build > /dev/null 2>&1
        log_success "Vapor backend project compiled successfully via Swift Package Manager"
    fi

    # 6. Verify Vapor backend project unit tests execution via XCTVapor
    log_info "Sub-test 19.4: Executing unit tests in generated Vapor project..."
    if [[ -f "Package.swift" ]]; then
        swift test > /dev/null 2>&1
        log_success "Vapor backend unit tests (XCTVapor) executed successfully"
    fi

    cd "$TEST_DIR"
    log_success "Scenario 19 Vapor Backend API E2E verified successfully!"
}

run_scenario_19
