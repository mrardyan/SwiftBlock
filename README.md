<p align="center">
  <img src="Docs/Assets/SwiftBlock.svg" width="120" height="120" alt="SwiftBlock Logo">
  <h1 align="center">SwiftBlock</h1>
  <p align="center">
    <strong>Stop rewriting the same code. Start snapping blocks.</strong>
  </p>
  <p align="center">
    <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.10-orange.svg?style=flat-square" alt="Swift 5.10"></a>
    <a href="https://developer.apple.com"><img src="https://img.shields.io/badge/Platform-macOS%2012.0%2B-blue.svg?style=flat-square" alt="Platform macOS"></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg?style=flat-square" alt="License MIT"></a>
    <a href="https://github.com/mrardyan/SwiftBlock/actions/workflows/ci.yml"><img src="https://github.com/mrardyan/SwiftBlock/actions/workflows/ci.yml/badge.svg" alt="CI Status"></a>
  </p>
</p>

---

**SwiftBlock** turns production-ready architecture into modular building blocks for Swift. Skip hours of tedious setup and snap complete feature layers, network engines, auto-wired dependencies, and unit tests directly into your iOS, macOS, and Vapor codebases in seconds.

---

## Key Capabilities

- **Modular Brick Engine (125+ Bricks)**: Attach production-ready infrastructure, clean architecture layers, algorithms, data structures, and domain value types in seconds.
- **Dual Project Baseplates**: Lay down complete SwiftUI (iOS/macOS via Tuist/XcodeGen) or Vapor server-side Swift project baseplates ready for immediate development.
- **AI Agent-Native Integration**: Run `swiftblock agent setup` to embed architectural guidelines and skills for **Google Antigravity**, **Claude Code**, **Cursor**, and **GitHub Copilot**.
- **Automatic Integration**: Auto-registers dependencies in `DependencyContainer.swift` and routes in `AppCoordinator.swift` without manual boilerplate editing.
- **Composition Kits**: Generate complete architectural layers in a single command using pre-configured feature blueprints (`clean-feature`).
- **Team Box Registries**: Publish, fetch, and share team component blocks across monorepos via Git repositories (`swiftblock box`).
- **Interactive Wizard Mode**: Guided terminal prompt engine when arguments are omitted.
- **Automated Unit Tests**: Automatically transforms single-source brick test definitions into **Swift Testing** or **XCTest**.
- **Simulation Mode (`--dry-run`)**: Test component generation and code injections without writing to disk.

---

## Quick Start

### 1. Installation

#### Via Homebrew (Recommended)

```bash
brew install mrardyan/tap/swiftblock
```

#### Via Makefile (From Source)

```bash
git clone https://github.com/mrardyan/SwiftBlock.git
cd SwiftBlock
make install
```

---

### 2. Basic Workflow

#### Step 1: Initialize a Project Baseplate

```bash
# Initialize a SwiftUI App (Tuist or XcodeGen)
swiftblock baseplate MyApp --bundle-prefix com.mycompany
cd MyApp && make setup && make generate

# Or initialize a Vapor Backend API
swiftblock baseplate MyBackend --baseplate vapor
```

#### Step 2: Snap Infrastructure Bricks

```bash
swiftblock snap network
swiftblock snap auth
swiftblock snap tokenrefresher
swiftblock snap securestorage
```

#### Step 3: Snap a Feature Blueprint (Clean Architecture Module)

```bash
swiftblock kit run clean-feature Profile
```

#### Step 4: Supercharge AI Coding Assistants

```bash
# Embed guidelines for Antigravity, Claude Code, Cursor, and Copilot
swiftblock agent setup
```

---

## Documentation Index

Explore the complete SwiftBlock documentation guides:

| Guide                                                              | Description                                                                                    |
| ------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------- |
| 🚀 [**Getting Started**](Docs/01-Getting-Started.md)               | Step-by-step tutorial on initializing baseplates and snapping components.                      |
| 🧩 [**Core Concepts**](Docs/02-Core-Concepts.md)                   | Architecture breakdown, automatic dependency registration, and Stencil variable engine.        |
| 🏗️ [**Baseplates Guide**](Docs/03-Baseplates-Guide.md)             | Deep dive on Baseplate starters (`SwiftUI`/`Vapor`), Tuist/XcodeGen manifests, and guardrails. |
| 📚 [**Bricks Catalog**](Docs/04-Bricks-Catalog.md)                 | Comprehensive catalog of all 125 built-in Core, Feature, and Utility components.               |
| 📦 [**Custom Bricks & Boxes**](Docs/05-Custom-Bricks-and-Boxes.md) | Guide to writing `brick.yml` manifests, local overrides, and team Box registries.              |
| 📐 [**Composition Kits**](Docs/06-Composition-Kits.md)             | Multi-brick architectural blueprints (`clean-feature`).                                        |
| 📖 [**CLI Reference**](Docs/07-CLI-Reference.md)                   | Exhaustive CLI flags and subcommands reference.                                                |
| 🤖 [**AI Agent Integration**](Docs/08-AI-Agent-Integration.md)     | Guide to embedding skills and rules for Antigravity, Claude Code, Cursor, and Copilot.          |

---

## Local Development & Testing

```bash
# 1. Initial environment setup & hook installation
make setup

# 2. Start a new standardized branch
make dev

# 3. Run test suites during development (default: unit + templates)
make test

# 4. Verify quality gate before opening a PR (format, lint, tests)
make verify

# 5. Build release binary locally
make build

# 6. Run full integration test matrix (optional)
make test SUITE=e2e
```

---

## Contributing

We welcome community contributions! Please read our [Contributing Guide](CONTRIBUTING.md) to get started. By participating, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

---

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.
