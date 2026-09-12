.PHONY: setup generate open clean lint format test edit help

# Default target
.DEFAULT_GOAL := help

help: ## Show available Makefile targets
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Install dependencies, Tuist, SwiftLint, SwiftFormat, and pre-commit hooks
	@bash ./Scripts/setup.sh

generate: ## Generate Xcode project and workspace using Tuist
	@tuist generate --no-open

open: ## Open generated Xcode workspace or project in Xcode
	@open *.xcworkspace 2>/dev/null || open *.xcodeproj 2>/dev/null || tuist generate

clean: ## Clean Tuist cache and build artifacts
	@tuist clean

lint: ## Run SwiftLint code analysis
	@swiftlint

format: ## Run SwiftFormat code formatter
	@swiftformat .

test: ## Run unit tests using Tuist
	@tuist test

edit: ## Open Tuist manifest files for editing
	@tuist edit
