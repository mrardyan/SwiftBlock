#!/usr/bin/env bash

# File and Directory Assertions for E2E Suite

assert_file_exists() {
    local file_path="$1"
    local message="${2:-File $file_path should exist}"
    if [[ -f "$file_path" ]]; then
        log_success "$message"
    else
        log_error "Assertion failed: $file_path missing!"
        exit 1
    fi
}

assert_dir_exists() {
    local dir_path="$1"
    local message="${2:-Directory $dir_path should exist}"
    if [[ -d "$dir_path" ]]; then
        log_success "$message"
    else
        log_error "Assertion failed: Directory $dir_path missing!"
        exit 1
    fi
}

assert_file_contains() {
    local file_path="$1"
    local pattern="$2"
    local message="${3:-File $file_path should contain '$pattern'}"
    if grep -q "$pattern" "$file_path"; then
        log_success "$message"
    else
        log_error "Assertion failed: Pattern '$pattern' not found in $file_path!"
        exit 1
    fi
}

assert_file_not_exists() {
    local file_path="$1"
    local message="${2:-File $file_path should NOT exist}"
    if [[ ! -e "$file_path" ]]; then
        log_success "$message"
    else
        log_error "Assertion failed: File/Directory $file_path should not exist!"
        exit 1
    fi
}
