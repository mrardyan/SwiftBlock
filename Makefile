# Makefile for SwiftBlock CLI

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
SHAREDIR ?= $(PREFIX)/share/swiftblock
CLI_NAME = swiftblock
BUILD_PATH = .build/release/$(CLI_NAME)

.PHONY: all build install uninstall test test-templates test-e2e clean

all: build

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
		cp -R Kits $(SHAREDIR)/ 2>/dev/null || true; \
	else \
		sudo mkdir -p $(BINDIR); \
		sudo cp -f $(BUILD_PATH) $(BINDIR)/$(CLI_NAME); \
		sudo mkdir -p $(SHAREDIR); \
		sudo rm -rf $(SHAREDIR)/*; \
		sudo cp -R Baseplates $(SHAREDIR)/ 2>/dev/null || true; \
		sudo cp -R Bricks $(SHAREDIR)/ 2>/dev/null || true; \
		sudo cp -R Kits $(SHAREDIR)/ 2>/dev/null || true; \
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
	swift test

test-templates:
	./Scripts/test_templates.sh

test-e2e:
	./Scripts/test_e2e.sh

clean:
	swift package clean
	rm -rf .build
