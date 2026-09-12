.PHONY: setup build run test lint format docker-build docker-run clean help

.DEFAULT_GOAL := help

help: ## Show available Makefile targets
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Install dependencies, SwiftLint, SwiftFormat, and git pre-commit hooks
	@bash ./Scripts/setup.sh

build: ## Build Vapor project using Swift PM
	@swift build

run: ## Run local Vapor API server
	@swift run Run serve --hostname 0.0.0.0 --port 8080

test: ## Run unit and integration tests
	@swift test

lint: ## Run SwiftLint code analysis
	@swiftlint

format: ## Run SwiftFormat code formatter
	@swiftformat .

docker-build: ## Build Docker container image
	@docker build -t __PROJECT_NAME__ .

docker-run: ## Run Docker container on port 8080
	@docker run -p 8080:8080 __PROJECT_NAME__

clean: ## Clean build artifacts
	@swift package clean
	@rm -rf .build
