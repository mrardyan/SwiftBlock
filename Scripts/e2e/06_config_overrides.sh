#!/usr/bin/env bash

run_scenario() {
    log_step "Scenario 06: Testing Custom '.swiftblock' Project Config Overrides..."

    cd "$TEST_DIR/TestNewApp"

    mkdir -p .swiftblock
    cat << 'EOF' > .swiftblock/config.yml
projectName: TestNewApp
bundlePrefix: com.mycompany.newapp
packaging:
  feature: monolithic
  core: spm
organization: feature-first
generatorTool: xcodegen
overrides:
  scene: Custom/Scenes/{module}
  usecase: Custom/Domain/{module}
EOF

    "$SWIFTBLOCK_BIN" snap scene CustomDashboard

    assert_file_exists "Custom/Scenes/customdashboard/CustomDashboardView.swift" "Custom path override for scene respected"

    cd "$TEST_DIR"
}

run_scenario
