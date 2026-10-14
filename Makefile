# Makefile for SwiftBlock CLI

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
SHAREDIR ?= $(PREFIX)/share/swiftblock
CLI_NAME = swiftblock
BUILD_PATH = .build/release/$(CLI_NAME)

.PHONY: all setup dev sync pr verify build install uninstall test test-unit test-templates test-e2e lint format install-hooks hotfix release clean help

all: build

help:
	@echo "SwiftBlock CLI - Developer Workflow Commands"
	@echo "Usage: make <command> [OPTIONS]"
	@echo ""
	@echo "Lifecycle Commands:"
	@echo "  setup            Verify dependencies, install git hooks, and build CLI"
	@echo "  dev              Start a new standardized branch (feat/*, fix/*, etc.)"
	@echo "  sync             Rebase current development branch onto latest origin/main"
	@echo "  pr               Run verification, push branch, and create Pull Request"
	@echo "  verify           Run full pre-PR quality gate (format + lint + tests)"
	@echo "  hotfix           Start an isolated patch branch from a specific release tag"
	@echo "  release          Verify test suites, tag a new release, and update Formula"
	@echo ""
	@echo "Testing & Quality Assurance:"
	@echo "  test             Run automated test suites (default: unit + templates)"
	@echo "                   Options:"
	@echo "                     make test SUITE=unit       (Swift unit tests only)"
	@echo "                     make test SUITE=templates  (Template validation only)"
	@echo "                     make test SUITE=e2e        (Full end-to-end matrix)"
	@echo "                     make test SUITE=all        (All test suites)"
	@echo "  lint             Lint codebase using SwiftLint"
	@echo "  format           Format codebase using SwiftFormat and SwiftLint auto-fix"
	@echo "  clean            Clean build artifacts and SPM cache"
	@echo ""
	@echo "Build & Installation:"
	@echo "  build            Build SwiftBlock CLI in release mode"
	@echo "  install          Build and install binary & templates to system ($(PREFIX))"
	@echo "  uninstall        Remove installed binary and shared asset templates"

setup:
	@./Scripts/setup.sh

dev:
	@./Scripts/dev.sh $(TYPE) $(NAME)

sync:
	@./Scripts/sync.sh

pr:
	@./Scripts/pr.sh $(ARGS)

verify: format lint test
	@echo ""
	@echo "==================================================="
	@echo "✔ All checks passed! Ready for Pull Request."
	@echo "==================================================="

hotfix:
	@./Scripts/hotfix.sh $(TAG) $(NAME)

release:
	@./Scripts/release.sh $(VERSION)

build:
	@echo "🔨 Building $(CLI_NAME) CLI in release mode..."
	swift build -c release

install: build
	@echo "🚀 Installing $(CLI_NAME) binary and asset templates..."
	@if [ -w "$(BINDIR)" ]; then \
		cp -f $(BUILD_PATH) $(BINDIR)/$(CLI_NAME); \
		mkdir -p $(SHAREDIR); \
		rm -rf $(SHAREDIR)/*; \
		cp -R Baseplates $(SHAREDIR)/ 2>/dev/null || true; \
		cp -R Bricks $(SHAREDIR)/ 2>/dev/null || true; \
	else \
		sudo mkdir -p $(BINDIR); \
		sudo cp -f $(BUILD_PATH) $(BINDIR)/$(CLI_NAME); \
		sudo mkdir -p $(SHAREDIR); \
		sudo rm -rf $(SHAREDIR)/*; \
		sudo cp -R Baseplates $(SHAREDIR)/ 2>/dev/null || true; \
		sudo cp -R Bricks $(SHAREDIR)/ 2>/dev/null || true; \
		ACTUAL_USER=$${SUDO_USER:-$$(whoami)}; \
		sudo chown -R $$ACTUAL_USER $(SHAREDIR); \
		sudo chmod -R u+rwX $(SHAREDIR); \
	fi
	@echo "✔ $(CLI_NAME) installed successfully!"
	@echo "👉 Run '$(CLI_NAME) --help' to get started."

uninstall:
	@echo "🗑 Removing $(CLI_NAME) binary and share assets..."
	@if [ -w "$(BINDIR)" ]; then \
		rm -f $(BINDIR)/$(CLI_NAME); \
		rm -rf $(SHAREDIR); \
	else \
		sudo rm -f $(BINDIR)/$(CLI_NAME); \
		sudo rm -rf $(SHAREDIR); \
	fi
	@echo "✔ $(CLI_NAME) uninstalled."

test:
	@if [ "$(SUITE)" = "e2e" ]; then \
		./Scripts/test_e2e.sh; \
	elif [ "$(SUITE)" = "templates" ]; then \
		./Scripts/test_templates.sh; \
	elif [ "$(SUITE)" = "unit" ]; then \
		swift test; \
	elif [ "$(SUITE)" = "all" ]; then \
		swift test && ./Scripts/test_templates.sh && ./Scripts/test_e2e.sh; \
	else \
		echo "🧪 Running unit tests & template validation suites..."; \
		swift test && ./Scripts/test_templates.sh; \
	fi

test-unit:
	swift test

test-templates:
	./Scripts/test_templates.sh

test-e2e:
	./Scripts/test_e2e.sh

lint:
	swiftlint lint
	swiftlint lint --fix

format:
	swiftformat .
	swiftlint lint --fix

install-hooks:
	@mkdir -p .githooks
	@cp Scripts/pre-commit.sh .githooks/pre-commit
	@chmod +x .githooks/pre-commit
	@git config core.hooksPath .githooks
	@echo "✔ Pre-commit hook installed (guardrails, lint, format)."

clean:
	swift package clean
	rm -rf .build
