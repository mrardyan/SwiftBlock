# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0-rc.1] - 2026-10-14

### Added
- **Modular Brick Engine**: Scaffold Core, Feature, and Utility components with automated dependency injection.
- **Baseplates Engine**: Production starter kits for SwiftUI (iOS/macOS) and Vapor server-side Swift.
- **Auto-Wiring DI**: Automatically registers snapped dependencies into `DependencyContainer.swift` and `AppCoordinator.swift`.
- **Composition Kits**: Architectural blueprints (`clean-feature`) to generate complete clean architecture modules in a single command.
- **Dynamic Brick Discovery & Cartesian Flavors**: Discovers available bricks, supports Cartesian test permutations, and supports interactive terminal wizard prompts.
- **Automated Test Converter**: Single-source brick test conversion into modern Swift Testing and XCTest frameworks.
- **Developer Workflows**: Streamlined developer lifecycle commands via `Makefile` (`make setup`, `make dev`, `make sync`, `make verify`, `make hotfix`, `make release`).
- **Open Source Health**: Comprehensive documentation index, MIT License, Contributor guidelines, GitHub issue/PR templates, and GitHub Actions CI workflow.

### Security
- Hardened path traversal guardrails, hook execution boundaries, and YAML parser sanitization.
