#!/usr/bin/env bash

# Terminal ANSI Color tokens
export GREEN='\033[0;32m'
export RED='\033[0;31m'
export CYAN='\033[0;36m'
export YELLOW='\033[1;33m'
export BOLD='\033[1m'
export RESET='\033[0m'

log_info() {
    echo -e "${CYAN}ℹ [INFO] $1${RESET}"
}

log_step() {
    echo -e "\n${YELLOW}🧪 [STEP] $1${RESET}"
}

log_success() {
    echo -e "${GREEN}✔ $1${RESET}"
}

log_error() {
    echo -e "${RED}✖ Error: $1${RESET}" >&2
}
