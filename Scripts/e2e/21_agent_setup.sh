#!/usr/bin/env bash

run_scenario_21() {
    log_step "Scenario 21: Testing AI Agent Setup command ('swiftblock agent setup')..."

    local AGENT_DIR
    AGENT_DIR=$(mktemp -d -t "swiftblock_e2e_agent_XXXXXX")
    cd "$AGENT_DIR"

    # 1. Test swiftblock agent setup (default: all targets)
    log_info "Sub-test 21.1: Default swiftblock agent setup (all targets)..."
    "$SWIFTBLOCK_BIN" agent setup

    assert_file_exists ".agents/skills/swiftblock/SKILL.md" ".agents/skills/swiftblock/SKILL.md present"
    assert_file_exists "AGENTS.md" "AGENTS.md universal guidelines present"
    assert_file_exists ".cursor/rules/swiftblock.mdc" ".cursor/rules/swiftblock.mdc present"
    assert_file_exists "CLAUDE.md" "CLAUDE.md present"
    assert_file_exists ".github/copilot-instructions.md" ".github/copilot-instructions.md present"

    # 2. Test specific target --target claude
    log_info "Sub-test 21.2: Specific target (--target claude)..."
    TEST_TARGET_DIR="$AGENT_DIR/AgentTargetTest"
    mkdir -p "$TEST_TARGET_DIR"
    "$SWIFTBLOCK_BIN" agent setup --path "$TEST_TARGET_DIR" --target claude

    assert_file_exists "$TEST_TARGET_DIR/CLAUDE.md" "Target CLAUDE.md generated"
    assert_file_not_exists "$TEST_TARGET_DIR/.cursor/rules/swiftblock.mdc" "Cursor rule omitted when only claude is targeted"

    # 3. Test --no-cursor flag
    log_info "Sub-test 21.3: Exclude cursor via --no-cursor..."
    TEST_NOCURSOR_DIR="$AGENT_DIR/AgentNoCursorTest"
    mkdir -p "$TEST_NOCURSOR_DIR"
    "$SWIFTBLOCK_BIN" agent setup --path "$TEST_NOCURSOR_DIR" --no-cursor

    assert_file_exists "$TEST_NOCURSOR_DIR/CLAUDE.md" "CLAUDE.md present with --no-cursor"
    assert_file_not_exists "$TEST_NOCURSOR_DIR/.cursor/rules/swiftblock.mdc" "Cursor rule omitted with --no-cursor"

    rm -rf "$AGENT_DIR"
    log_success "Scenario 21 AI Agent Setup verified successfully!"
}

run_scenario_21
